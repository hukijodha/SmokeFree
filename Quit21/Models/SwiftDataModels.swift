import Foundation
import SwiftData

// MARK: - Section 38: local data model. Everything here lives only in the
// on-device SwiftData store (see Persistence/ModelContainerFactory). Nothing
// in this file is ever transmitted anywhere (section 3, 37).

@Model
final class UserProfile {
    var smokingType: SmokingType
    var frequencyBand: FrequencyBand
    var customDailyCount: Int?
    var wakeToFirst: WakeToFirstCigarette
    var yearsSmoking: Int
    var strongestTimes: [Trigger]
    var commonPrompts: [Trigger]
    var hasTriedQuittingBefore: Bool
    var previousRelapseCauses: [RelapseCause]
    var motivationReasons: [QuitMotivationReason]
    var primaryReason: QuitMotivationReason?
    var createdAt: Date

    init(smokingType: SmokingType = .cigarettes,
         frequencyBand: FrequencyBand = .eleven_20,
         customDailyCount: Int? = nil,
         wakeToFirst: WakeToFirstCigarette = .six_30,
         yearsSmoking: Int = 1,
         strongestTimes: [Trigger] = [],
         commonPrompts: [Trigger] = [],
         hasTriedQuittingBefore: Bool = false,
         previousRelapseCauses: [RelapseCause] = [],
         motivationReasons: [QuitMotivationReason] = [],
         primaryReason: QuitMotivationReason? = nil) {
        self.smokingType = smokingType
        self.frequencyBand = frequencyBand
        self.customDailyCount = customDailyCount
        self.wakeToFirst = wakeToFirst
        self.yearsSmoking = yearsSmoking
        self.strongestTimes = strongestTimes
        self.commonPrompts = commonPrompts
        self.hasTriedQuittingBefore = hasTriedQuittingBefore
        self.previousRelapseCauses = previousRelapseCauses
        self.motivationReasons = motivationReasons
        self.primaryReason = primaryReason
        self.createdAt = .now
    }
}

/// The user's own words: "I am quitting because ___." Shown during cravings
/// (section 21, "My Why").
@Model
final class PersonalReason {
    var text: String
    var updatedAt: Date
    init(text: String = "") { self.text = text; self.updatedAt = .now }
}

/// The single source of truth for "how long have I been smoke-free."
/// Elapsed time is always computed from `quitDate`, never accumulated
/// (section 54 — timers must derive from timestamps, not stored counters).
@Model
final class QuitJourney {
    var startDate: Date
    var quitDate: Date?
    var statusRaw: String
    var longestStreakSeconds: TimeInterval
    var lastSmokingEventDate: Date?
    var day21CompletedAt: Date?
    /// Smoke-free duration accumulated *before* the most recent smoking
    /// event — preserved forever so a relapse never erases history
    /// (section 15: "Your previous smoke-free period is still yours.").
    var previousStreakSeconds: TimeInterval

    var status: QuitStatus {
        get { QuitStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }

    init(startDate: Date = .now, quitDate: Date? = nil) {
        self.startDate = startDate
        self.quitDate = quitDate
        self.statusRaw = quitDate == nil ? QuitStatus.notStarted.rawValue : QuitStatus.active.rawValue
        self.longestStreakSeconds = 0
        self.lastSmokingEventDate = nil
        self.day21CompletedAt = nil
        self.previousStreakSeconds = 0
    }

    /// Seconds smoke-free right now, anchored to quitDate or the last
    /// smoking event, whichever is more recent.
    func currentStreakSeconds(now: Date = .now) -> TimeInterval {
        let anchor = lastSmokingEventDate ?? quitDate ?? startDate
        return max(0, now.timeIntervalSince(anchor))
    }

    func currentDay(now: Date = .now) -> Int {
        Int(currentStreakSeconds(now: now) / 86400) + 1
    }
}

@Model
final class SmokingEvent {
    var timestamp: Date
    var quantity: Int
    var trigger: Trigger
    var context: EventContext?
    var notes: String?
    var feeling: String?

    init(timestamp: Date = .now, quantity: Int = 1, trigger: Trigger, context: EventContext? = nil,
         notes: String? = nil, feeling: String? = nil) {
        self.timestamp = timestamp
        self.quantity = quantity
        self.trigger = trigger
        self.context = context
        self.notes = notes
        self.feeling = feeling
    }
}

@Model
final class CravingEvent {
    var timestamp: Date
    var beforeIntensity: Int // 1...10
    var trigger: Trigger
    var interventionRaw: String
    var afterIntensity: Int?
    var resolved: Bool // true = did not smoke

    var intervention: InterventionKind {
        get { InterventionKind(rawValue: interventionRaw) ?? .other }
        set { interventionRaw = newValue.rawValue }
    }

    init(timestamp: Date = .now, beforeIntensity: Int, trigger: Trigger,
         intervention: InterventionKind = .breathing, afterIntensity: Int? = nil, resolved: Bool = true) {
        self.timestamp = timestamp
        self.beforeIntensity = beforeIntensity
        self.trigger = trigger
        self.interventionRaw = intervention.rawValue
        self.afterIntensity = afterIntensity
        self.resolved = resolved
    }
}

@Model
final class DailyCheckIn {
    var date: Date
    var smokedToday: Bool
    var strongestCraving: Int // 1...10
    var biggestTrigger: Trigger?
    var confidenceTomorrow: Int // 1...10

    init(date: Date = .now, smokedToday: Bool, strongestCraving: Int, biggestTrigger: Trigger?, confidenceTomorrow: Int) {
        self.date = date
        self.smokedToday = smokedToday
        self.strongestCraving = strongestCraving
        self.biggestTrigger = biggestTrigger
        self.confidenceTomorrow = confidenceTomorrow
    }
}

/// A day-21-program day the user has explicitly marked done (section 17).
@Model
final class ProgramDayCompletion {
    var day: Int
    var completedAt: Date
    init(day: Int, completedAt: Date = .now) { self.day = day; self.completedAt = completedAt }
}

/// Free-form notification/appearance/accessibility preferences.
/// Small and simple enough to not warrant SwiftData; UserDefaults-backed.
@Observable
final class AppSettings {
    private let defaults = UserDefaults.standard
    private enum Key: String {
        case notificationsEnabled, voiceLoggingEnabled, reduceMotionOverride,
             appearanceRaw, hasCompletedOnboarding, healthKitEnabled
    }

    var notificationsEnabled: Bool {
        get { defaults.object(forKey: Key.notificationsEnabled.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.notificationsEnabled.rawValue) }
    }
    var voiceLoggingEnabled: Bool {
        get { defaults.object(forKey: Key.voiceLoggingEnabled.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.voiceLoggingEnabled.rawValue) }
    }
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Key.hasCompletedOnboarding.rawValue) }
        set { defaults.set(newValue, forKey: Key.hasCompletedOnboarding.rawValue) }
    }
    /// HealthKit writes are architected but not enabled by default in v1
    /// (no clean HK sample type maps to "smoke-free"; see Health/HealthKitService.swift).
    var healthKitEnabled: Bool {
        get { defaults.bool(forKey: Key.healthKitEnabled.rawValue) }
        set { defaults.set(newValue, forKey: Key.healthKitEnabled.rawValue) }
    }
}
