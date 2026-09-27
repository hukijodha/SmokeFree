import Foundation

// MARK: - Section 13: personalized craving interventions. Deterministic
// rule-based logic (section 39), not generative — because the exact
// per-trigger scripts are specified and safety-relevant (e.g. alcohol).

struct InterventionStep: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let kind: InterventionKind
}

enum InterventionEngine {
    /// `priorSuccess` is the intervention kind that most recently resolved a
    /// craving with this same trigger, if any — surfaced first (section 39:
    /// "Walking helped you handle this before. Try it again.").
    static func steps(for trigger: Trigger, priorSuccess: InterventionKind?) -> (intro: String, steps: [InterventionStep]) {
        var steps: [InterventionStep] = []
        let intro: String

        switch trigger {
        case .stress, .anxiety, .anger, .work:
            intro = "Let's interrupt the stress → cigarette pattern."
            steps = [
                .init(title: "Breathe", detail: "60 seconds of slow breathing.", kind: .breathing),
                .init(title: "Take a short walk", detail: "Two minutes, anywhere.", kind: .walk),
                .init(title: "Drink some water", detail: "", kind: .water),
                .init(title: "Check in with yourself", detail: "How does it feel now?", kind: .checkIn),
            ]
        case .coffeeOrTea, .morning:
            intro = "Your brain connected this moment with smoking. Today we're breaking that connection."
            steps = [
                .init(title: "Change location", detail: "Step away from where you'd usually smoke.", kind: .changeLocation),
                .init(title: "Drink it differently", detail: "Try a different cup, a different spot.", kind: .other),
                .init(title: "Delay", detail: "Give it 3 minutes before deciding anything.", kind: .delay),
                .init(title: "Breathe", detail: "A short breathing exercise.", kind: .breathing),
            ]
        case .social, .seeingSomeoneSmoke:
            intro = "Someone else smoking doesn't mean you need to."
            steps = [
                .init(title: "Take a 5-minute break", detail: "Step away from the situation.", kind: .breakFromSituation),
                .init(title: "Breathe", detail: "Ground yourself for a minute.", kind: .breathing),
                .init(title: "Check in with yourself", detail: "What do you actually need right now?", kind: .checkIn),
            ]
        case .alcohol:
            intro = "Alcohol can make resisting a cigarette harder. Let's get you through this moment."
            steps = [
                .init(title: "Step outside the situation", detail: "Even briefly.", kind: .breakFromSituation),
                .init(title: "Drink water", detail: "", kind: .water),
                .init(title: "Remember why", detail: "Bring your reason to mind.", kind: .checkIn),
            ]
        case .boredom, .phoneCalls, .breaks, .habit, .driving, .afterFood, .beforeSleep, .cravingAlone, .other:
            intro = "Let's get through this craving together."
            steps = [
                .init(title: "Breathe", detail: "60 seconds, slow and steady.", kind: .breathing),
                .init(title: "Move", detail: "Stand up, stretch, or take a short walk.", kind: .walk),
                .init(title: "Drink water", detail: "", kind: .water),
                .init(title: "Remember why", detail: "Bring your reason to mind.", kind: .checkIn),
            ]
        }

        if let priorSuccess, let idx = steps.firstIndex(where: { $0.kind == priorSuccess }), idx != 0 {
            let step = steps.remove(at: idx)
            steps.insert(step, at: 0)
        }
        return (intro, steps)
    }
}
