import SwiftUI
import SwiftData

// MARK: - Section 53: four tabs, one always-reachable craving action.

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.modelContext) private var context
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var onboardingStage: OnboardingStage = .intro

    enum OnboardingStage { case intro, questions, readyToQuit, done }

    var body: some View {
        @Bindable var env = env
        Group {
            if hasCompletedOnboarding {
                TabView(selection: $env.selectedTab) {
                    ForEach(AppTab.allCases) { tab in
                        tabContent(tab)
                            .tabItem { Label(tab.title, systemImage: tab.icon) }
                            .tag(tab)
                    }
                }
                .tint(Theme.healthy)
                .fullScreenCover(isPresented: $env.showReadyToQuit) {
                    ReadyToQuitView { date in
                        beginQuit(on: date)
                        env.showReadyToQuit = false
                    }
                }
            } else {
                onboardingFlow
            }
        }
        .onAppear {
            env.startClock()
            #if DEBUG
            let d = UserDefaults.standard
            if d.bool(forKey: "uiSkipOnboarding") { hasCompletedOnboarding = true }
            if let days = d.object(forKey: "uiDemoDay").flatMap({ ($0 as? Int) ?? Int("\($0)") }) {
                let journey = JourneyStore.fetchOrCreateJourney(context: context)
                journey.quitDate = Calendar.current.date(byAdding: .day, value: -days, to: .now)
                journey.status = .active
                try? context.save()
                let reason = JourneyStore.fetchOrCreateReason(context: context)
                reason.text = "I want to be healthy for my children"
                try? context.save()
            }
            if let tab = d.string(forKey: "uiTab"), let t = AppTab(rawValue: tab) { env.selectedTab = t }
            if d.bool(forKey: "uiShowCraving") { env.showCravingFlow = true }
            if d.bool(forKey: "uiShowSmoked") { env.showSmokedFlow = true }
            #endif
        }
    }

    @ViewBuilder private func tabContent(_ tab: AppTab) -> some View {
        switch tab {
        case .home: HomeView()
        case .health: HealthJourneyView()
        case .progress: ProgressDashboardView()
        case .me: ProfileView()
        }
    }

    @ViewBuilder private var onboardingFlow: some View {
        switch onboardingStage {
        case .intro:
            CinematicIntroView(onStart: { onboardingStage = .questions }, onLearnFirst: { onboardingStage = .questions })
        case .questions:
            OnboardingQuestionnaireView { profile, reason in
                context.insert(profile)
                context.insert(reason)
                try? context.save()
                onboardingStage = .readyToQuit
            }
        case .readyToQuit:
            ReadyToQuitView { date in
                beginQuit(on: date)
                hasCompletedOnboarding = true
                onboardingStage = .done
            }
        case .done:
            EmptyView()
        }
    }

    /// Commits the quit date and, only now that the user has meaningfully
    /// opted in, asks for notification permission (never at cold launch).
    private func beginQuit(on date: Date) {
        let journey = JourneyStore.fetchOrCreateJourney(context: context)
        journey.quitDate = date
        journey.status = .active
        try? context.save()
        Haptics.milestone()
        if env.settings.notificationsEnabled {
            Task {
                if await NotificationScheduler.requestAuthorization() {
                    NotificationScheduler.scheduleMorning(day: journey.currentDay())
                }
            }
        }
    }
}
