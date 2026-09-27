import SwiftUI
import SwiftData

// MARK: - Section 10/44: the most important screen. One glance answers "how
// am I doing" and "what should I do right now."

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppEnvironment.self) private var env
    @Query(sort: \SmokingEvent.timestamp, order: .reverse) private var smokingEvents: [SmokingEvent]
    @Query(sort: \CravingEvent.timestamp, order: .reverse) private var cravingEvents: [CravingEvent]

    @State private var journey: QuitJourney?
    @State private var reason: PersonalReason?
    @State private var showFeelingGood = false

    var body: some View {
        @Bindable var env = env
        ScrollView {
            VStack(spacing: 22) {
                statusHero
                dayProgress
                actionGrid
                motivationCard
            }
            .padding(20)
            .padding(.top, 8)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .onAppear {
            journey = JourneyStore.fetchOrCreateJourney(context: context)
            reason = JourneyStore.fetchOrCreateReason(context: context)
        }
        .sheet(isPresented: $env.showCravingFlow) {
            CravingFlowView(priorEvents: cravingEvents) { event in
                context.insert(event)
                try? context.save()
            }
        }
        .sheet(isPresented: $env.showSmokedFlow) {
            SmokingFlowView(journey: journey) { event, restartTimer in
                context.insert(event)
                if restartTimer, let journey {
                    journey.previousStreakSeconds += journey.currentStreakSeconds()
                    journey.lastSmokingEventDate = event.timestamp
                }
                try? context.save()
            }
        }
        .sheet(isPresented: $env.showMyWhyReminder) {
            if let reason { MyWhyReminderView(reason: reason) }
        }
        .alert("Feeling good?", isPresented: $showFeelingGood) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("That's worth noticing. This is what smoke-free feels like.")
        }
    }

    private var seconds: TimeInterval { journey?.currentStreakSeconds(now: env.lastTick) ?? 0 }
    private var day: Int { journey?.currentDay(now: env.lastTick) ?? 1 }

    private var statusHero: some View {
        VStack(spacing: 14) {
            ZStack {
                BreathingPulse(size: 260)
                VStack(spacing: 6) {
                    Text(journey?.quitDate == nil ? "READY WHEN YOU ARE" : "YOU ARE SMOKE-FREE")
                        .font(Typography.caption(13)).tracking(1.5).foregroundStyle(Theme.textSecondary)
                    if journey?.quitDate != nil {
                        Text(QuitTimerService.humanized(seconds: seconds))
                            .font(Typography.hero(40)).foregroundStyle(Theme.textPrimary)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: Int(seconds))
                    } else {
                        Text("Your health, starting today.")
                            .font(Typography.body(15)).foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center).padding(.horizontal, 40)
                    }
                }
            }
            .frame(height: 260)

            if journey?.quitDate == nil {
                PrimaryButton(title: "I'M READY TO QUIT") { env.showReadyToQuit = true }
            }
        }
    }

    private var dayProgress: some View {
        Group {
            if journey?.quitDate != nil {
                GlassCard {
                    HStack(spacing: 18) {
                        ZStack {
                            ProgressRing(progress: Double(min(day, 21)) / 21.0)
                            VStack {
                                Text("\(min(day, 21))").font(Typography.title(24)).foregroundStyle(Theme.textPrimary)
                                Text("of 21").font(Typography.caption()).foregroundStyle(Theme.textTertiary)
                            }
                        }
                        .frame(width: 74, height: 74)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day <= 21 ? "DAY \(day) OF 21" : "STAY QUIT").font(Typography.headline())
                                .foregroundStyle(Theme.textPrimary)
                            if let focus = ProgramContent.day(min(day, 21))?.focus {
                                Text(focus).font(Typography.body(14)).foregroundStyle(Theme.textSecondary)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private var actionGrid: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: "I'M HAVING A CRAVING", color: Theme.craving, systemImage: "wind") {
                env.showCravingFlow = true
            }
            HStack(spacing: 12) {
                SecondaryButton(title: "I SMOKED", systemImage: "smoke") { env.showSmokedFlow = true }
                SecondaryButton(title: "FEELING GOOD", systemImage: "sparkles") { showFeelingGood = true }
            }
            SecondaryButton(title: "VIEW MY HEALTH", systemImage: "heart.text.square") {
                env.selectedTab = .health
            }
        }
    }

    private var motivationCard: some View {
        let context = MotivationContext(
            day: min(day, 21),
            recentSmokingEvents: Array(smokingEvents.prefix(5)),
            recentCravingEvents: Array(cravingEvents.prefix(5)),
            primaryReasonText: reason?.text,
            strongestTrigger: TriggerAnalysisService.strongestTrigger(smokingEvents: smokingEvents)
        )
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("TODAY").font(Typography.caption()).foregroundStyle(Theme.textTertiary)
                Text(MotivationEngine.message(for: context))
                    .font(Typography.body(16)).foregroundStyle(Theme.textPrimary)
                Button("Remind me why") { env.showMyWhyReminder = true }
                    .font(Typography.caption(13)).foregroundStyle(Theme.healthy).padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
