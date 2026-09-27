import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable, Identifiable {
    case home, health, progress, me
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Home"
        case .health: return "Health"
        case .progress: return "Progress"
        case .me: return "Me"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .health: return "heart.fill"
        case .progress: return "chart.xyaxis.line"
        case .me: return "person.fill"
        }
    }
}

/// Cross-cutting UI state (section 53: four tabs + one always-reachable
/// craving action + a smoked action always available from Home).
@Observable
final class AppEnvironment {
    var settings = AppSettings()
    var selectedTab: AppTab = .home
    var showCravingFlow = false
    var showSmokedFlow = false
    var showMyWhyReminder = false
    var showReadyToQuit = false
    var lastTick: Date = .now

    func startClock() {
        Task { @MainActor in
            while true {
                try? await Task.sleep(for: .seconds(1))
                lastTick = .now
            }
        }
    }
}

/// Small helpers shared by several features to avoid duplicating SwiftData
/// fetch/create boilerplate.
enum JourneyStore {
    @MainActor
    static func fetchOrCreateJourney(context: ModelContext) -> QuitJourney {
        let descriptor = FetchDescriptor<QuitJourney>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        if let existing = try? context.fetch(descriptor).first { return existing }
        let created = QuitJourney()
        context.insert(created)
        try? context.save()
        return created
    }

    @MainActor
    static func fetchOrCreateProfile(context: ModelContext) -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? context.fetch(descriptor).first { return existing }
        let created = UserProfile()
        context.insert(created)
        try? context.save()
        return created
    }

    @MainActor
    static func fetchOrCreateReason(context: ModelContext) -> PersonalReason {
        let descriptor = FetchDescriptor<PersonalReason>()
        if let existing = try? context.fetch(descriptor).first { return existing }
        let created = PersonalReason()
        context.insert(created)
        try? context.save()
        return created
    }
}
