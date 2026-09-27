import Foundation

// MARK: - Section 17: the 21-day program. Explicitly NOT framed as a medical
// guarantee (see the "emotional spine, not a claim" refinement) — each day
// is a practice focus, not a promise.

struct ProgramDay: Identifiable {
    var id: Int { day }
    let day: Int
    let focus: String
}

enum ProgramContent {
    static let days: [ProgramDay] = [
        .init(day: 0, focus: "Commit."),
        .init(day: 1, focus: "Survive the first day."),
        .init(day: 2, focus: "Understand cravings."),
        .init(day: 3, focus: "Break automatic routines."),
        .init(day: 4, focus: "Identify your strongest trigger."),
        .init(day: 5, focus: "Practice delaying the urge."),
        .init(day: 6, focus: "Change your environment."),
        .init(day: 7, focus: "Protect one week."),
        .init(day: 8, focus: "Strengthen your new routine."),
        .init(day: 9, focus: "Handle stress without smoking."),
        .init(day: 10, focus: "Break a smoking association."),
        .init(day: 11, focus: "Strengthen your identity."),
        .init(day: 12, focus: "Prepare for social situations."),
        .init(day: 13, focus: "Handle unexpected cravings."),
        .init(day: 14, focus: "Two-week milestone."),
        .init(day: 15, focus: "Review your patterns."),
        .init(day: 16, focus: "Build confidence."),
        .init(day: 17, focus: "Prepare for high-risk situations."),
        .init(day: 18, focus: "Strengthen your reasons."),
        .init(day: 19, focus: "Protect your future."),
        .init(day: 20, focus: "Prepare for Day 21."),
        .init(day: 21, focus: "Celebrate the transformation."),
    ]

    static func day(_ n: Int) -> ProgramDay? { days.first { $0.day == n } }

    /// One small, concrete action per day, shown on Home (section 18).
    static func todaysAction(for day: Int) -> String {
        let actions = [
            "Identify one situation where you'd normally smoke, and experience it without one.",
            "Notice the moment right before a craving — what happens just before it?",
            "Change one small routine that used to lead to a cigarette.",
            "Write down the trigger that feels strongest today.",
            "Next time you want to smoke, wait 3 minutes first.",
            "Move one thing in your environment that reminds you of smoking.",
            "Tell one person you've made it a week.",
            "Notice one moment today where the new routine felt normal.",
            "Try a breathing exercise the next time stress shows up.",
            "Do the thing you'd normally pair with a cigarette — without one.",
        ]
        return actions[day % actions.count]
    }
}
