import SwiftUI
import SwiftData

// MARK: - Section 26: chronological personal history. Nothing is ever
// erased — this is the user's own record (section 46).

private enum TimelineEntry: Identifiable {
    case smoking(SmokingEvent)
    case craving(CravingEvent)
    case checkIn(DailyCheckIn)

    var id: String {
        switch self {
        case .smoking(let e): return "s-\(e.timestamp.timeIntervalSince1970)"
        case .craving(let e): return "c-\(e.timestamp.timeIntervalSince1970)"
        case .checkIn(let e): return "k-\(e.date.timeIntervalSince1970)"
        }
    }
    var date: Date {
        switch self {
        case .smoking(let e): return e.timestamp
        case .craving(let e): return e.timestamp
        case .checkIn(let e): return e.date
        }
    }
}

struct PersonalTimelineView: View {
    @Query(sort: \SmokingEvent.timestamp, order: .reverse) private var smoking: [SmokingEvent]
    @Query(sort: \CravingEvent.timestamp, order: .reverse) private var cravings: [CravingEvent]
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]

    private var entries: [TimelineEntry] {
        (smoking.map(TimelineEntry.smoking) + cravings.map(TimelineEntry.craving) + checkIns.map(TimelineEntry.checkIn))
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Timeline").font(Typography.title(26)).foregroundStyle(Theme.textPrimary)
                if entries.isEmpty {
                    GlassCard { Text("Your history will appear here as you log cravings and check-ins.").font(Typography.body(14)).foregroundStyle(Theme.textSecondary) }
                }
                ForEach(entries) { entry in row(entry) }
            }
            .padding(20)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
    }

    @ViewBuilder private func row(_ entry: TimelineEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(entry.date, style: .time).font(Typography.caption(12)).foregroundStyle(Theme.textTertiary).frame(width: 56, alignment: .leading)
            GlassCard(padding: 12) {
                switch entry {
                case .smoking(let e):
                    Text("Smoking event — \(e.trigger.label)").font(Typography.body(14)).foregroundStyle(Theme.textPrimary)
                case .craving(let e):
                    Text("Craving \(e.beforeIntensity)\(e.afterIntensity.map { " → \($0)" } ?? "") — \(e.trigger.label) — \(e.resolved ? "handled" : "logged")")
                        .font(Typography.body(14)).foregroundStyle(Theme.textPrimary)
                case .checkIn:
                    Text("Daily check-in").font(Typography.body(14)).foregroundStyle(Theme.textPrimary)
                }
            }
        }
    }
}
