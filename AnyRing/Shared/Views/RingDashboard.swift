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

    var body: some View {
        // Align ticks with calendar minutes, including midnight. Refresh readings
        // only when their calendar-day boundary changes, not on every tick.
        TimelineView(.periodic(from: calendar.startOfDay(for: .now), by: 60)) { context in
            let now = referenceDate ?? context.date
            VStack(spacing: 6) {
                Menu {
                    Picker("Tracking period", selection: Binding(get: { days }, set: { updatePeriod($0) })) {
                        ForEach(Array(Set([1, 2, 3, 5, 7, days])).sorted(), id: \.self) { count in
                            Text(count == 1 ? "1 day" : "\(count) days").tag(count)
                        }
                    }
                } label: {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Text("Tracking period").foregroundStyle(.secondary).fixedSize()
                            Spacer(minLength: 8)
                            periodValue.fixedSize()
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tracking period").foregroundStyle(.secondary)
                            periodValue
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Tracking period, \(days) days")
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
                        .foregroundStyle(day.included ? Color.primary : Color.secondary)
                        .background(day.included ? Color.accentColor.opacity(0.10) : .clear)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(day.included ? Color.accentColor : .clear).frame(height: 2)
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
            Image(systemName: "chevron.up.chevron.down").font(.caption2)
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

    var body: some View {
        VStack(spacing: 20) {
            TripleRingView(size: size, ring1: ring1.snapshot(), ring2: ring2.snapshot(),
                           ring3: ring3.snapshot(), shape: shape)
                .accessibilityHidden(true)
            #if os(iOS)
            if let updatePeriod { TrackingWeekView(days: days, updatePeriod: updatePeriod, refresh: refresh) }
            #endif
            VStack(spacing: 12) {
                RingMetricView(ring: ring1)
                Divider()
                RingMetricView(ring: ring2)
                Divider()
                RingMetricView(ring: ring3)
            }
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
