import SwiftUI

// MARK: - Section 9/19/20: interactive body-recovery timeline + dashboard.
// All copy uses hedged, population-level language (section 42) — never an
// individual guarantee or invented personal measurement.

struct HealthJourneyView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var journey: QuitJourney?
    @Environment(\.modelContext) private var context

    private var seconds: TimeInterval { journey?.currentStreakSeconds(now: env.lastTick) ?? 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                timelineSection
                dashboardSection
                sourceNote
            }
            .padding(20)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .onAppear { journey = JourneyStore.fetchOrCreateJourney(context: context) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("YOUR BODY").font(Typography.caption()).foregroundStyle(Theme.textTertiary)
            Text("Health Journey").font(Typography.title(28)).foregroundStyle(Theme.textPrimary)
            if let next = HealthMilestoneItem.next(secondsSmokeFree: seconds) {
                Text("Next milestone: \(next.title)").font(Typography.body(14)).foregroundStyle(Theme.healthy)
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(HealthMilestoneItem.timeline) { item in
                let unlocked = item.offset <= seconds
                HStack(alignment: .top, spacing: 14) {
                    Circle()
                        .fill(unlocked ? Theme.healthy : Theme.card)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(unlocked ? Theme.healthy : Theme.cardBorder, lineWidth: 1))
                        .padding(.top, 4)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(Typography.headline(16)).foregroundStyle(unlocked ? Theme.textPrimary : Theme.textTertiary)
                        Text(item.detail).font(Typography.body(13)).foregroundStyle(unlocked ? Theme.textSecondary : Theme.textTertiary)
                    }
                }
            }
        }
    }

    private var dashboardSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("YOUR SYSTEMS").font(Typography.caption()).foregroundStyle(Theme.textTertiary)
            ForEach([MedicalContentItem.Category.heart, .lungs, .circulation, .respiratory, .cancerRisk], id: \.self) { cat in
                if let item = MedicalContentLibrary.items(in: cat).first {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title).font(Typography.headline(16)).foregroundStyle(Theme.textPrimary)
                            Text(item.body).font(Typography.body(13)).foregroundStyle(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var sourceNote: some View {
        Text("Health information reflects publicly available CDC and WHO guidance on smoking cessation, and describes population-level patterns rather than an individual medical measurement. It is not a substitute for advice from a healthcare professional.")
            .font(Typography.caption(11)).foregroundStyle(Theme.textTertiary)
            .padding(.bottom, 20)
    }
}
