import SwiftUI

struct RingPalette: Identifiable, Sendable {
    let name: String
    let snapshots: RingWrapper<RingSnapshot>
    var id: String { name }

    static let all: [Self] = [
        palette("Aurora", [0x6D5EF5, 0x21C7D9, 0xFF7D8B]),
        palette("Ocean", [0x3478F6, 0x13B8A6, 0x8CE9F0], gradient: true),
        palette("Sunset", [0xF35E92, 0xFF9257, 0xF7C55A], gradient: true),
        palette("Forest", [0x158B67, 0x68B784, 0xB7D9A5]),
        palette("Arctic", [0x62CBDF, 0x6889E8, 0xB6A4EC]),
        palette("Ember", [0xE86137, 0xF19C54, 0xF8D197], gradient: true),
        palette("Berry", [0xB94D91, 0x855FD5, 0xD9A0DB]),
        palette("Citrus", [0x96C83C, 0xE8BF38, 0xF48B38]),
        palette("Lagoon", [0x087F9E, 0x22BDAA, 0x91DDC3], gradient: true),
        palette("Candy", [0xF08FC0, 0x7ABCEB, 0xB6A0E8]),
        palette("Graphite", [0x65748B, 0x97A4B6, 0xC5CDDB]),
        palette("Neon", [0xA553FF, 0x89E863, 0xFF4D9C], glow: true),
        palette("Moss", [0xF4FF3F, 0x71C13F, 0x255C26], gradient: true, secondaryColors: [0x223A26, 0x062419, nil]),
        palette("Rose Quartz", [0xFFE6E6, 0xFFABE1, 0xA685E2], glow: true),
        palette("Golden Hour", [0xFDD489, 0xFFC074, 0xCCDFA2], gradient: true, secondaryColors: [0xB91D73, 0x11998E, 0x0083B0]),
        palette("Terracotta", [0x734046, 0xA05344, 0xE79E4F]),
        palette("Sea Glass", [0x9DDFD3, 0xDBF6E9, 0xFFDADA]),
        palette("Classic", [0x30C75A, 0xFF335F, 0xF4C400])
    ]

    private static func palette(_ name: String, _ colors: [UInt], gradient: Bool = false, glow: Bool = false, secondaryColors: [UInt?]? = nil) -> Self {
        Self(name: name, snapshots: RingWrapper(colors.enumerated().map { index, hex in
            let enabled = gradient && (secondaryColors == nil || secondaryColors?[index] != nil)
            let secondary = secondaryColors?[index].map { Color(hex: $0).codable } ?? (enabled ? Color(hex: hex).darker(by: 20)?.codable : nil)
            return RingSnapshot(progress: [0.85, 0.65, 0.45][index], mainColor: Color(hex: hex).codable,
                         gradient: enabled, secondaryColor: secondary,
                         outerGlow: glow, innerGlow: glow)
        }))
    }
}

struct TemplatesView: View {
    var shape: RingShape = .roundedSquare
    var current: RingWrapper<RingSnapshot>?
    var onSelect: ((RingWrapper<RingSnapshot>) -> Void)?

    private func selected(_ palette: RingPalette) -> Bool {
        guard let current else { return false }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return zip(current.list, palette.snapshots.list).allSatisfy { lhs, rhs in
            var appearance = lhs
            appearance = RingSnapshot(progress: rhs.progress, mainColor: appearance.mainColor,
                gradient: appearance.gradient, secondaryColor: appearance.secondaryColor,
                outerGlow: appearance.outerGlow, innerGlow: appearance.innerGlow)
            return (try? encoder.encode(appearance)) == (try? encoder.encode(rhs))
        }
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                ForEach(RingPalette.all) { palette in
                    Button { onSelect?(palette.snapshots) } label: {
                        VStack(spacing: 8) {
                            TripleRingView(size: 62, ring1: palette.snapshots.first, ring2: palette.snapshots.second,
                                           ring3: palette.snapshots.third, simplified: true, shape: shape)
                            HStack(spacing: 3) {
                                Text(palette.name)
                                if selected(palette) { Image(systemName: "checkmark.circle.fill") }
                            }.font(.caption).foregroundStyle(.primary)
                        }
                        .frame(width: 86).padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(palette.name) palette")
                    .accessibilityAddTraits(selected(palette) ? .isSelected : [])
                    .accessibilityIdentifier("palette.\(palette.id)")
                }
            }
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("paletteCarousel")
    }

    static func snapshotForColor(_ color: Color) -> RingSnapshot {
        RingSnapshot(progress: 0.8, mainColor: color.codable, outerGlow: false)
    }
    static func snapshotForColorWithGlow(_ color: Color) -> RingSnapshot {
        RingSnapshot(progress: 0.8, mainColor: color.codable, outerGlow: true, innerGlow: true)
    }
    static func snapshotGradients(_ color: Color, _ secondary: Color) -> RingSnapshot {
        RingSnapshot(progress: 0.8, mainColor: color.codable, gradient: true, secondaryColor: secondary.codable, outerGlow: false)
    }
}

#if os(iOS)
/// Full saved settings live here; TemplatesView above remains appearance-only.
struct SavedConfigurationsView: View {
    @EnvironmentObject private var model: AnyRingViewModel
    @State private var name = ""
    @State private var naming = false
    @State private var renaming: UUID?
    @State private var pending: SavedConfiguration?
    @State private var confirmSwitch = false
    @State private var deleting: SavedConfiguration?
    @State private var confirmDelete = false
    @State private var error: String?
    @ScaledMetric(relativeTo: .caption2) private var thumbnailWidth: CGFloat = 72

    private var saveButton: some View {
        Button {
            name = ""; renaming = nil; naming = true
        } label: {
            Label(model.savedConfigurations.isEmpty ? "Save current setup" : "Save current", systemImage: "plus")
                .labelStyle(.titleAndIcon)
                .font(.subheadline)
                .frame(minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityIdentifier("saveConfiguration")
        .disabled(model.savedConfigurationsError != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if model.savedConfigurations.isEmpty {
                saveButton
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack {
                        Text("Saved templates").font(.caption).foregroundStyle(.secondary).fixedSize()
                        Spacer(minLength: 12)
                        saveButton.fixedSize()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Saved templates").font(.caption).foregroundStyle(.secondary)
                        saveButton
                    }.fixedSize(horizontal: false, vertical: true)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            if let message = model.savedConfigurationsError {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
            if !model.savedConfigurations.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(model.savedConfigurations) { record in
                            Button {
                                guard record.config != model.config else { return }
                                pending = record
                                if model.savedConfigurations.contains(where: { $0.config == model.config }) {
                                    choosePending()
                                } else { confirmSwitch = true }
                            } label: {
                                VStack(spacing: 4) {
                                    let snapshots = preview(record.config)
                                    TripleRingView(size: 44, ring1: snapshots.first, ring2: snapshots.second,
                                        ring3: snapshots.third, simplified: true, shape: record.config.global.shape)
                                        .padding(6)
                                    Text(record.name).font(.caption2).lineLimit(2)
                                    if record.config == model.config {
                                        Image(systemName: "checkmark").font(.caption2)
                                    }
                                }.frame(width: thumbnailWidth, alignment: .top)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(record.name)
                            .accessibilityHint("Applies saved data sources, goals, period and appearance")
                            .accessibilityAddTraits(record.config == model.config ? .isSelected : [])
                            .accessibilityIdentifier("savedConfiguration.\(record.id.uuidString)")
                            .contextMenu {
                                Button("Rename", systemImage: "pencil") {
                                    renaming = record.id; name = record.name; naming = true
                                }
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    deleting = record; confirmDelete = true
                                }
                            }
                        }
                    }.padding(.vertical, 4)
                }.scrollIndicators(.hidden)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .alert(renaming == nil ? "Save template" : "Rename template", isPresented: $naming) {
            TextField("Template name", text: $name)
            Button("Cancel", role: .cancel) { pending = nil }
            Button("Save") {
                perform {
                    if let renaming { try model.renameConfiguration(id: renaming, name: name) }
                    else { try model.saveConfiguration(named: name) }
                    choosePending()
                }
            }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: { Text("Includes data sources, goals, period and appearance.") }
        .alert("Save current settings?", isPresented: $confirmSwitch) {
            Button("Save current") { name = ""; renaming = nil; naming = true }
            Button("Use template", role: .destructive) { choosePending() }
            Button("Cancel", role: .cancel) { pending = nil }
        } message: { Text("These settings are not in a saved template. Switching will replace the current settings, not your saved templates.") }
        .alert("Delete template?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                if let deleting { perform { try model.deleteConfiguration(id: deleting.id) } }
                deleting = nil
            }
            Button("Cancel", role: .cancel) { deleting = nil }
        } message: { Text("Current settings will not change.") }
        .alert("Template unavailable", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) { error = nil }
        } message: { Text(error ?? "") }
    }

    private func choosePending() {
        guard let pending else { return }
        perform { try model.selectConfiguration(id: pending.id) }
        self.pending = nil
    }

    private func perform(_ action: () throws -> Void) {
        do { try action() }
        catch { self.error = error.localizedDescription }
    }

    private func preview(_ config: AnyRingConfig) -> RingWrapper<RingSnapshot> {
        RingWrapper(config.configs.enumerated().map { index, ring in
            RingSnapshot(progress: [0.85, 0.65, 0.45][index], mainColor: ring.appearance.mainColor,
                gradient: ring.appearance.gradient, secondaryColor: ring.appearance.secondaryColor,
                outerGlow: ring.appearance.outerGlow, innerGlow: ring.appearance.innerGlow)
        })
    }
}

#endif

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255, opacity: alpha)
    }
}
