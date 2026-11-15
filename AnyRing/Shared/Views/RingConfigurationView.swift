import SwiftUI
import HealthKit

struct RingConfigurationView: View {
    @ObservedObject var ring: RingViewModel
    @EnvironmentObject private var viewModel: AnyRingViewModel
    @State private var permissionTask: Task<Void, Never>?
    @State private var nameDraft = ""
    @State private var workoutGoalDraft = ""
    @FocusState private var editingName: Bool

    private func binding<Value>(_ get: @escaping (any ProviderConfiguration) -> Value,
                                _ set: @escaping (inout any ProviderConfiguration, Value) -> Void) -> Binding<Value> {
        Binding(get: { get(ring.configuration) }, set: { value in
            var changed = ring.configuration
            set(&changed, value)
            ring.update(config: changed)
        })
    }

    var body: some View {
        Section {
            HStack {
                TextField("Name", text: $nameDraft, prompt: Text(ring.metricName))
                    .accessibilityIdentifier("ringName")
                    .focused($editingName)
                    .submitLabel(.done)
                    .onSubmit { editingName = false }
                    .onAppear { nameDraft = ring.configuration.customName ?? "" }
                    .onChange(of: nameDraft) { _, value in
                        let bounded = String(value.prefix(RingName.maximumLength))
                        if value != bounded { nameDraft = bounded }
                        var changed = ring.configuration
                        changed.customName = RingName.normalized(bounded)
                        // Keep the editing buffer's spaces; normalize only the persisted label.
                        if changed.customName != ring.configuration.customName { ring.update(config: changed) }
                    }
                if !nameDraft.isEmpty {
                    Button {
                        nameDraft = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Clear Name")
                    .accessibilityIdentifier("clearRingName")
                }
            }
        } header: {
            Text("Ring Name")
        } footer: {
            Text("Optional. Leave blank to use the metric name. Up to 40 characters.")
        }
        Section("Data Source") {
            NavigationLink {
                SelectProviderScreen(selected: ring.metricName, onSelectWorkout: { metric in
                    guard var changed = ring.configuration as? HealthKitProvider.Configuration else { return }
                    changed.selectWorkoutMetric(metric)
                    select(changed)
                }) { parameters in
                    guard var changed = ring.configuration as? HealthKitProvider.Configuration else { return }
                    changed.workoutMetric = nil
                    changed.healthKitParams = parameters
                    select(changed)
                }
            } label: { Label(ring.metricName, systemImage: "heart.fill") }
            if let config = ring.configuration as? HealthKitProvider.Configuration {
                if config.workoutMetric != nil {
                    HStack {
                        Text("Goal (min)")
                        TextField("Goal (min)", text: $workoutGoalDraft)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("goal")
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .onAppear { workoutGoalDraft = config.maxValue.formatted(.number.grouping(.never)) }
                            .onChange(of: workoutGoalDraft) { _, text in
                                guard let value = try? Double(text, format: .number), value.isFinite, value > 0 else { return }
                                var changed = ring.configuration
                                changed.maxValue = value
                                ring.update(config: changed)
                            }
                    }
                    Text("Total workout minutes over the selected days. Set your own goal; the default is not a training recommendation.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else {
                numericField(config.healthKitParams.reversed ? "Goal" : "Start From", value: binding({ $0.minValue }, { $0.minValue = $1 }))
                numericField(config.healthKitParams.reversed ? "Start From" : "Goal", value: binding({ $0.maxValue }, { $0.maxValue = $1 }))
                if config.minValue >= config.maxValue {
                    Text("The lower value must be less than the upper value.").font(.footnote).foregroundStyle(.orange)
                }
                Toggle("Reversed Direction", isOn: Binding(get: {
                    (ring.configuration as? HealthKitProvider.Configuration)?.healthKitParams.reversed ?? false
                }, set: { value in
                    guard var changed = ring.configuration as? HealthKitProvider.Configuration else { return }
                    changed.healthKitParams.reversed = value
                    ring.update(config: changed)
                }))
                Picker("Aggregation", selection: Binding(get: {
                    (ring.configuration as? HealthKitProvider.Configuration)?.healthKitParams.aggregation ?? .avg
                }, set: { value in
                    guard var changed = ring.configuration as? HealthKitProvider.Configuration else { return }
                    changed.healthKitParams.aggregation = value
                    ring.update(config: changed)
                })) {
                    let cumulative = (config.healthKitParams.sampleType.hkSampleType as? HKQuantityType)?.aggregationStyle == .cumulative
                    if cumulative { Text("Sum").tag(Aggregation.sum) }
                    else {
                        Text("Average").tag(Aggregation.avg)
                        Text("Minimum").tag(Aggregation.min)
                        Text("Maximum").tag(Aggregation.max)
                    }
                }
                }
                if let error = ring.error { Text(error.localizedDescription).font(.footnote).foregroundStyle(.secondary) }
            }
        }
        Section("Appearance") {
            ColorPicker("Main Color", selection: binding({ $0.appearance.mainColor.color }, { $0.appearance.mainColor = CodableColor($1) }), supportsOpacity: false)
            Toggle("Gradient", isOn: binding({ $0.appearance.gradient }, { $0.appearance.gradient = $1 }))
            if ring.configuration.appearance.gradient {
                ColorPicker("Second Color", selection: binding({ $0.appearance.secondaryColor?.color ?? $0.appearance.mainColor.color }, { $0.appearance.secondaryColor = CodableColor($1) }), supportsOpacity: false)
            }
            Toggle("Inner Glow", isOn: binding({ $0.appearance.innerGlow }, { $0.appearance.innerGlow = $1 }))
            Toggle("Outer Glow", isOn: binding({ $0.appearance.outerGlow }, { $0.appearance.outerGlow = $1 }))
        }
        .onDisappear { permissionTask?.cancel() }
    }

    private func select(_ changed: HealthKitProvider.Configuration) {
        if changed.workoutMetric != nil { workoutGoalDraft = changed.maxValue.formatted(.number.grouping(.never)) }
        ring.update(config: changed)
        permissionTask?.cancel()
        permissionTask = Task {
            if (try? await viewModel.handlePermissions(permissions: Array(changed.readTypes))) != nil,
               !Task.isCancelled { viewModel.refresh() }
        }
    }

    private func numericField(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
            TextField(label, value: value, format: .number)
                .multilineTextAlignment(.trailing)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .accessibilityIdentifier(label.hasPrefix("Goal") ? "goal" : "startFrom")
        }
    }
}
