import SwiftUI

struct SelectProviderScreen: View {
    let selected: String
    let onSelect: (HealthKitProvider.HealthKitConfiguration) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        List {
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
                .accessibilityAddTraits(provider.name == selected ? .isSelected : [])
            }
        }
        .searchable(text: $searchText, prompt: "Search health metrics")
        .navigationTitle("Health Metrics")
    }
}
