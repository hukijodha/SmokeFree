import Foundation

// MARK: - Section 16/30: pattern analysis, never shame. Purely descriptive
// ("Three recent smoking events happened after alcohol"), never predictive
// of failure (section 30: "Do not predict that they will relapse").

struct TriggerInsight: Identifiable {
    let id = UUID()
    let text: String
}

enum TriggerAnalysisService {
    static func insights(smokingEvents: [SmokingEvent], cravingEvents: [CravingEvent]) -> [TriggerInsight] {
        guard !smokingEvents.isEmpty else { return [] }
        var insights: [TriggerInsight] = []

        let counts = Dictionary(grouping: smokingEvents, by: \.trigger).mapValues(\.count)
        if let (trigger, count) = counts.max(by: { $0.value < $1.value }), count >= 2 {
            let word = count == 2 ? "Two" : "\(count)"
            insights.append(.init(text: "\(word) recent smoking events happened after \(trigger.label.lowercased())."))
            insights.append(.init(text: "Your strongest recorded trigger is \(trigger.label.lowercased())."))
        }

        let handled = cravingEvents.filter { $0.resolved }
        let handledCounts = Dictionary(grouping: handled, by: \.trigger).mapValues(\.count)
        if let (trigger, count) = handledCounts.max(by: { $0.value < $1.value }), count >= 2 {
            insights.append(.init(text: "You've successfully handled \(trigger.label.lowercased()) cravings \(count) times."))
        }

        return insights
    }

    /// The trigger most worth protecting against next (used to pick which
    /// intervention script to lead with, and for Settings > My Triggers).
    static func strongestTrigger(smokingEvents: [SmokingEvent]) -> Trigger? {
        let counts = Dictionary(grouping: smokingEvents, by: \.trigger).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    /// Which intervention kind most often resolved a craving with this trigger.
    static func mostSuccessfulIntervention(for trigger: Trigger, cravingEvents: [CravingEvent]) -> InterventionKind? {
        let matches = cravingEvents.filter { $0.trigger == trigger && $0.resolved }
        let counts = Dictionary(grouping: matches, by: \.intervention).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
