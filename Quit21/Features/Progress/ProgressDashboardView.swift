import SwiftUI
import SwiftData

// MARK: - Section 28: premium, serious stats. No childish gamification.

struct ProgressDashboardView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.modelContext) private var context
    @Query private var smoking: [SmokingEvent]
    @Query private var cravings: [CravingEvent]
    @State private var journey: QuitJourney?

    private var longest: TimeInterval {
        max(journey?.previousStreakSeconds ?? 0, journey?.currentStreakSeconds(now: env.lastTick) ?? 0)
    }
    private var handled: Int { cravings.filter(\.resolved).count }
    private var insights: [TriggerInsight] { TriggerAnalysisService.insights(smokingEvents: smoking, cravingEvents: cravings) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Progress").font(Typography.title(28)).foregroundStyle(Theme.textPrimary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    stat("Smoke-free", QuitTimerService.humanized(seconds: journey?.currentStreakSeconds(now: env.lastTick) ?? 0))
                    stat("Longest streak", QuitTimerService.humanized(seconds: longest))
                    stat("Cravings handled", "\(handled)")
                    stat("Smoking events", "\(smoking.count)")
                }

                if !insights.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PATTERNS").font(Typography.caption()).foregroundStyle(Theme.textTertiary)
                            ForEach(insights) { insight in
                                Text(insight.text).font(Typography.body(14)).foregroundStyle(Theme.textPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("21-DAY PROGRESS").font(Typography.caption()).foregroundStyle(Theme.textTertiary)
                        ProgressView(value: Double(min(journey?.currentDay(now: env.lastTick) ?? 0, 21)), total: 21)
                            .tint(Theme.healthy)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .onAppear { journey = JourneyStore.fetchOrCreateJourney(context: context) }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(Typography.title(20)).foregroundStyle(Theme.textPrimary)
                Text(label).font(Typography.caption(12)).foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
