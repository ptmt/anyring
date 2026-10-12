import SwiftUI

struct RingLabel: View {
    let name: String
    let value: String
    let units: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading) {
            Text(name).font(.footnote)
            Text("\(Text(value).bold()) \(Text(units).font(.footnote))").foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
    }
}
