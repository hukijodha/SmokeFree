import Foundation

// MARK: - Section 8/43/44: deterministic (no cloud LLM — section 40) daily
// motivation. Uses quit day, recent events and the user's own stated reason
// to select a message. Never repeats the same generic "great job!" line.

struct MotivationContext {
    let day: Int
    let recentSmokingEvents: [SmokingEvent]
    let recentCravingEvents: [CravingEvent]
    let primaryReasonText: String?
    let strongestTrigger: Trigger?
}

enum MotivationEngine {
    /// Hand-authored beats for the emotionally significant early/late days
    /// (spec sections 8 and the "21 days" refinement — the emotional spine,
    /// never a medical claim).
    private static let dayScript: [Int: String] = [
        1: "You made the decision. Today, we protect it.",
        2: "Your last cigarette is behind you. Every smoke-free hour means less exposure to tobacco smoke.",
        3: "A craving is not a command. Let it pass.",
        4: "Your decision is becoming a pattern.",
        5: "You are not waiting to feel different. You're building a different life.",
        7: "One week. You've already experienced 7 days of life without cigarettes.",
        10: "You're not just avoiding cigarettes. You're changing the routines that used to lead you to them.",
        14: "Two weeks. Your decision is becoming a pattern.",
        21: "21 days. You didn't become smoke-free because a timer said so. You became smoke-free because, day after day, you chose not to smoke.",
    ]

    static func message(for context: MotivationContext) -> String {
        if let scripted = dayScript[context.day] { return scripted }

        // Recent-event-aware beats take priority over the generic fallback.
        if let last = context.recentSmokingEvents.first,
           Calendar.current.isDateInToday(last.timestamp) {
            return "You're still quitting. Let's understand what happened, and get back to your plan."
        }
        if let resolved = context.recentCravingEvents.first(where: { $0.resolved }),
           Calendar.current.isDateInToday(resolved.timestamp) {
            return "You handled a craving today. Remember how you did it — that's a skill you're building."
        }
        if let trigger = context.strongestTrigger {
            return "You've handled \(trigger.label.lowercased()) before. You can handle it again."
        }
        if let reason = context.primaryReasonText, !reason.isEmpty {
            return "Day \(context.day). You're still choosing: \(reason)."
        }
        return genericFallback(for: context.day)
    }

    private static func genericFallback(for day: Int) -> String {
        let pool = [
            "This craving is temporary. You are not.",
            "Every smoke-free hour is one your body didn't have to spend recovering from smoke.",
            "You're proving that a craving can pass without a cigarette.",
            "You're becoming someone who doesn't need a cigarette to get through this.",
            "One cigarette does not have to become another. Today is still yours.",
        ]
        return pool[day % pool.count]
    }
}
