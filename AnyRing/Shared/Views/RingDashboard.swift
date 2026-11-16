import SwiftUI

/// Calendar arithmetic, not elapsed 24-hour intervals or a Monday–Sunday grid.
enum RollingWeek {
    struct Day: Identifiable {
        let date: Date
        let included: Bool
        let isToday: Bool
        var id: Date { date }
    }
    static func days(count: Int, now: Date, calendar: Calendar = .current) -> [Day] {
        let today = calendar.startOfDay(for: now)
        return (-6...0).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today).map {
                Day(date: $0, included: offset > -max(count, 1), isToday: offset == 0)
            }
        }
    }
}

#if os(iOS)
struct TrackingWeekView: View {
    let days: Int
    let updatePeriod: (Int) -> Void
    var referenceDate: Date? = nil
    var refresh: () -> Void = {}
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme

    // Explicit neutral colors avoid Menu's inherited accent tint. Keep these
    // local: ring colors and the rest of the app retain their selected palette.
    private var periodPrimary: Color { Color(uiColor: .label) }
    private var periodSecondary: Color { Color(white: colorScheme == .dark ? 0.65 : 0.40) }
    private var includedBackground: Color { Color(white: colorScheme == .dark ? 0.18 : 0.92) }

    var body: some View {
        // Align ticks with calendar minutes, including midnight. Refresh readings
        // only when their calendar-day boundary changes, not on every tick.
        TimelineView(.periodic(from: calendar.startOfDay(for: .now), by: 60)) { context in
            let now = referenceDate ?? context.date
            VStack(spacing: 6) {
                Menu {
                    Picker("Period", selection: Binding(get: { days }, set: { updatePeriod($0) })) {
                        ForEach(Array(Set([1, 2, 3, 5, 7, days])).sorted(), id: \.self) { count in
                            Text(count == 1 ? "1 day" : "\(count) days").tag(count)
                        }
                    }
                } label: {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Text("Period").foregroundStyle(periodSecondary).fixedSize()
                            Spacer(minLength: 8)
                            periodValue.fixedSize()
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Period").foregroundStyle(periodSecondary)
                            periodValue
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.subheadline)
                    .foregroundStyle(periodPrimary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .tint(periodPrimary)
                .accessibilityLabel("Period")
                .accessibilityValue(days == 1 ? "1 day" : "\(days) days")
                .accessibilityHint("Changes the number of calendar days included through today")
                .accessibilityIdentifier("trackingPeriod")
                HStack(spacing: 0) {
                    ForEach(RollingWeek.days(count: days, now: now, calendar: calendar)) { day in
                        VStack(spacing: 4) {
                            Text(day.date.formatted(.dateTime.weekday(.narrow).locale(locale)))
                                .font(.caption2)
                            Text(day.date.formatted(.dateTime.day().locale(locale)))
                                .font(.subheadline.weight(day.included ? .semibold : .regular))
                                .monospacedDigit()
                            Text(day.isToday ? "Today" : " ").font(.caption2.weight(.medium))
                        }
                        // Keep all seven calendar dates legible in this overview;
                        // full dates remain available to VoiceOver at every text size.
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity).padding(.vertical, 5)
                        .foregroundStyle(day.included ? periodPrimary : periodSecondary)
                        .background(day.included ? includedBackground : .clear)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(day.included ? periodSecondary : .clear).frame(height: 2)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(day.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year().locale(locale)))
                        .accessibilityValue((day.isToday ? "Today, " : "") + (day.included ? "Included" : "Not included"))
                    }
                }
                .accessibilityIdentifier("trackingWeek")
            }
            .onChange(of: calendar.startOfDay(for: now)) { _, _ in refresh() }
        }
    }

    private var periodValue: some View {
        HStack(spacing: 5) {
            Text(days == 1 ? "1 day" : "\(days) days")
                .foregroundStyle(periodPrimary)
            Image(systemName: "chevron.up.chevron.down").font(.caption2)
                .foregroundStyle(periodSecondary)
        }
    }
}
#endif

struct RingDashboard: View {
    let size: CGFloat
    @ObservedObject var ring1: RingViewModel
    @ObservedObject var ring2: RingViewModel
    @ObservedObject var ring3: RingViewModel
    var days = 3
    var shape: RingShape = .roundedSquare
    var updatePeriod: ((Int) -> Void)?
    var refresh: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private func graphic(_ dimension: CGFloat) -> some View {
        TripleRingView(size: dimension, ring1: ring1.snapshot(), ring2: ring2.snapshot(),
                       ring3: ring3.snapshot(), shape: shape)
            .accessibilityHidden(true)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 12) {
            RingDashboardLegend(ring: ring1)
            RingDashboardLegend(ring: ring2)
            RingDashboardLegend(ring: ring3)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        VStack(spacing: 16) {
            if dynamicTypeSize.isAccessibilitySize || dynamicTypeSize > .xLarge {
                graphic(min(size, 180))
                legend
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 16) {
                        graphic(min(size, 140))
                        legend.frame(minWidth: 140)
                    }
                    VStack(spacing: 16) { graphic(min(size, 180)); legend }
                }
            }
            #if os(iOS)
            if let updatePeriod { TrackingWeekView(days: days, updatePeriod: updatePeriod, refresh: refresh) }
            #endif
            if [ring1, ring2, ring3].allSatisfy({ $0.progress.empty && !$0.isRefreshing }) {
                Text("No health data yet. If you expected data, check AnyProgress’s access in Apple Health.")
                    .font(.footnote).foregroundStyle(.secondary)
                #if os(iOS)
                Link("Open Apple Health", destination: URL(string: "x-apple-health://")!)
                #endif
            }
            #if !os(iOS)
            Text(days == 1 ? "Today" : "Today and the previous \(days - 1) days")
                .font(.caption).foregroundStyle(.secondary)
            #endif
        }
    }
}
