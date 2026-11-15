import SwiftUI

struct SelectProviderScreen: View {
    let selected: String
    let onSelectWorkout: (WorkoutZoneMetric) -> Void
    let onSelect: (HealthKitProvider.HealthKitConfiguration) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        List {
            Section("Workouts") {
                ForEach(WorkoutZoneMetric.allCases.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }, id: \.self) { metric in
                    Button {
                        onSelectWorkout(metric)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(metric.name).font(.headline)
                                Text("Workout time only · minutes · requires OS 27 and stored zones")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if metric.name == selected { Image(systemName: "checkmark") }
                        }.padding(.vertical, 6)
                    }.buttonStyle(.plain)
                }
            }
            ForEach(healthKitProviders.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }, id: \.self) { provider in
                Button {
                    onSelect(provider)
                    dismiss()
                } label: {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(provider.name).font(.headline).foregroundStyle(.primary)
                            Text(provider.description).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if provider.name == selected { Image(systemName: "checkmark").foregroundStyle(.tint) }
                    }.padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(provider.name == selected ? .isSelected : [])
            }
        }
        .searchable(text: $searchText, prompt: "Search health metrics")
        .navigationTitle("Health Metrics")
    }
}
