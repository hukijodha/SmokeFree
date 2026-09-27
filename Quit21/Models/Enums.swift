import Foundation

// MARK: - Shared vocabulary (section 38)

enum SmokingType: String, Codable, CaseIterable, Identifiable {
    case cigarettes, vape, hookah, cigars, otherTobacco, multiple
    var id: String { rawValue }
    var label: String {
        switch self {
        case .cigarettes: return "Cigarettes"
        case .vape: return "Vape"
        case .hookah: return "Hookah"
        case .cigars: return "Cigars"
        case .otherTobacco: return "Other tobacco"
        case .multiple: return "Multiple"
        }
    }
}

enum FrequencyBand: String, Codable, CaseIterable, Identifiable {
    case under5, five_10, eleven_20, twentyOne_30, over30, custom
    var id: String { rawValue }
    var label: String {
        switch self {
        case .under5: return "Less than 5/day"
        case .five_10: return "5–10/day"
        case .eleven_20: return "11–20/day"
        case .twentyOne_30: return "21–30/day"
        case .over30: return "More than 30/day"
        case .custom: return "Custom"
        }
    }
}

enum WakeToFirstCigarette: String, Codable, CaseIterable, Identifiable {
    case within5, six_30, thirtyOne_60, afterOneHour
    var id: String { rawValue }
    var label: String {
        switch self {
        case .within5: return "Within 5 minutes"
        case .six_30: return "6–30 minutes"
        case .thirtyOne_60: return "31–60 minutes"
        case .afterOneHour: return "After 1 hour"
        }
    }
}

/// Triggers are the backbone of the personalization engine (sections 7, 39).
enum Trigger: String, Codable, CaseIterable, Identifiable {
    case morning, afterFood, coffeeOrTea, driving, work, stress, anxiety, anger
    case alcohol, social, boredom, phoneCalls, breaks, beforeSleep, seeingSomeoneSmoke
    case habit, cravingAlone, other

    var id: String { rawValue }
    var label: String {
        switch self {
        case .morning: return "Morning"
        case .afterFood: return "After food"
        case .coffeeOrTea: return "Coffee/tea"
        case .driving: return "Driving"
        case .work: return "Work"
        case .stress: return "Stress"
        case .anxiety: return "Anxiety"
        case .anger: return "Anger"
        case .alcohol: return "Alcohol"
        case .social: return "Social situations"
        case .boredom: return "Boredom"
        case .phoneCalls: return "Phone calls"
        case .breaks: return "Breaks"
        case .beforeSleep: return "Before sleeping"
        case .seeingSomeoneSmoke: return "Seeing someone smoke"
        case .habit: return "Habit"
        case .cravingAlone: return "Craving"
        case .other: return "Other"
        }
    }
}

enum QuitMotivationReason: String, Codable, CaseIterable, Identifiable {
    case health, breathing, heart, family, future, fitness, control, dontWantControlled, doctorAdvised, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .health: return "My health"
        case .breathing: return "My breathing"
        case .heart: return "My heart health"
        case .family: return "My family"
        case .future: return "My future"
        case .fitness: return "My fitness"
        case .control: return "I want control back"
        case .dontWantControlled: return "I don't want smoking to control my day"
        case .doctorAdvised: return "Doctor advised me"
        case .other: return "Other"
        }
    }
}

enum RelapseCause: String, Codable, CaseIterable, Identifiable {
    case stress, cravings, alcohol, friends, work, social, boredom, justOne, withdrawal, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .stress: return "Stress"
        case .cravings: return "Cravings"
        case .alcohol: return "Alcohol"
        case .friends: return "Friends"
        case .work: return "Work"
        case .social: return "Social situations"
        case .boredom: return "Boredom"
        case .justOne: return "“Just one cigarette”"
        case .withdrawal: return "Withdrawal symptoms"
        case .other: return "Other"
        }
    }
}

/// Context recorded with a smoking event or craving.
enum EventContext: String, Codable, CaseIterable, Identifiable {
    case afterDinner, morning, driving, work, social, alone, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .afterDinner: return "After a meal"
        case .morning: return "Morning"
        case .driving: return "Driving"
        case .work: return "Work"
        case .social: return "Social situation"
        case .alone: return "Alone"
        case .other: return "Other"
        }
    }
}

enum InterventionKind: String, Codable, CaseIterable, Identifiable {
    case breathing, walk, water, checkIn, delay, changeLocation, breakFromSituation, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .breathing: return "Breathing exercise"
        case .walk: return "Short walk"
        case .water: return "Drink water"
        case .checkIn: return "Check in with yourself"
        case .delay: return "Delay the urge"
        case .changeLocation: return "Change location"
        case .breakFromSituation: return "Take a short break"
        case .other: return "Other"
        }
    }
}

enum QuitStatus: String, Codable {
    case notStarted, active, completed21, staying
}
