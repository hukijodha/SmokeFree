import SwiftUI

// MARK: - Section 13/14: craving emergency mode. Calm, slowed, personalized.

struct CravingFlowView: View {
    let priorEvents: [CravingEvent]
    let onComplete: (CravingEvent) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = .intro
    @State private var intensity: Double = 5
    @State private var trigger: Trigger? = nil
    @State private var afterIntensity: Double = 5
    @State private var stillStrong = false

    enum Stage { case intro, intensity, trigger, intervention, timer, resolution }

    var body: some View {
        VStack {
            switch stage {
            case .intro: introView
            case .intensity: intensityView
            case .trigger: triggerView
            case .intervention: interventionView
            case .timer: timerView
            case .resolution: resolutionView
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.4), value: stage)
        .background(
            LinearGradient(colors: [Theme.bgTop, Theme.craving.opacity(0.18), Theme.bgBottom],
                          startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        )
        .interactiveDismissDisabled(stage != .intro && stage != .resolution)
    }

    private var introView: some View {
        VStack(spacing: 24) {
            Spacer()
            BreathingPulse(color: Theme.craving, size: 220)
                .overlay(Image(systemName: "wind").font(.system(size: 40)).foregroundStyle(Theme.craving))
            Text("Stay with me for the next few minutes.")
                .font(Typography.title(26)).multilineTextAlignment(.center).foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            PrimaryButton(title: "Continue", color: Theme.craving) { stage = .intensity }
        }
    }

    private var intensityView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("How strong is it?").font(Typography.title(26)).foregroundStyle(Theme.textPrimary)
            Text("\(Int(intensity))").font(Typography.hero(64)).foregroundStyle(Theme.craving)
            Slider(value: $intensity, in: 1...10, step: 1).tint(Theme.craving)
            Spacer()
            PrimaryButton(title: "Continue", color: Theme.craving) { stage = .trigger }
        }
    }

    private var triggerView: some View {
        let options: [Trigger] = [.stress, .coffeeOrTea, .afterFood, .alcohol, .boredom, .anger, .work, .social, .seeingSomeoneSmoke, .habit, .other]
        return VStack(alignment: .leading, spacing: 20) {
            Text("What triggered it?").font(Typography.title(26)).foregroundStyle(Theme.textPrimary)
            FlowChips(items: options, label: \.label, isSelected: { trigger == $0 }) { trigger = $0; stage = .intervention }
            Spacer()
        }
    }

    private var priorSuccess: InterventionKind? {
        guard let trigger else { return nil }
        return TriggerAnalysisService.mostSuccessfulIntervention(for: trigger, cravingEvents: priorEvents)
    }

    private var interventionView: some View {
        let plan = InterventionEngine.steps(for: trigger ?? .other, priorSuccess: priorSuccess)
        return VStack(alignment: .leading, spacing: 18) {
            Text(plan.intro).font(Typography.title(22)).foregroundStyle(Theme.textPrimary)
            ForEach(plan.steps) { step in
                GlassCard(padding: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: icon(for: step.kind)).foregroundStyle(Theme.craving)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title).font(Typography.headline(16)).foregroundStyle(Theme.textPrimary)
                            if !step.detail.isEmpty { Text(step.detail).font(Typography.body(13)).foregroundStyle(Theme.textSecondary) }
                        }
                        Spacer()
                    }
                }
            }
            Spacer()
            PrimaryButton(title: "Start", color: Theme.craving) { stage = .timer }
        }
    }

    private func icon(for kind: InterventionKind) -> String {
        switch kind {
        case .breathing: return "wind"
        case .walk: return "figure.walk"
        case .water: return "drop.fill"
        case .checkIn: return "heart.text.square"
        case .delay: return "clock"
        case .changeLocation: return "location"
        case .breakFromSituation: return "figure.stand"
        case .other: return "sparkles"
        }
    }

    private var timerView: some View {
        CravingTimerView(seconds: 180) { stage = .resolution }
    }

    private var resolutionView: some View {
        VStack(spacing: 22) {
            Spacer()
            Text("Did the craving pass?").font(Typography.title(26)).foregroundStyle(Theme.textPrimary)
            if stillStrong {
                Text("How strong now?").font(Typography.body()).foregroundStyle(Theme.textSecondary)
                Text("\(Int(afterIntensity))").font(Typography.hero(48)).foregroundStyle(Theme.craving)
                Slider(value: $afterIntensity, in: 1...10, step: 1).tint(Theme.craving)
            }
            Spacer()
            PrimaryButton(title: "Yes", color: Theme.healthy) { finish(resolved: true) }
            if !stillStrong {
                SecondaryButton(title: "Still strong") { stillStrong = true }
                SecondaryButton(title: "Give me another strategy") { stage = .intervention }
            } else {
                PrimaryButton(title: "Log and continue", color: Theme.craving) { finish(resolved: false) }
            }
        }
    }

    private func finish(resolved: Bool) {
        Haptics.success()
        let event = CravingEvent(beforeIntensity: Int(intensity), trigger: trigger ?? .other,
                                 intervention: priorSuccess ?? .breathing,
                                 afterIntensity: stillStrong ? Int(afterIntensity) : nil, resolved: resolved)
        onComplete(event)
        dismiss()
    }
}

/// Beautiful, calm circular countdown (section 14).
struct CravingTimerView: View {
    let seconds: Int
    let onDone: () -> Void

    @State private var remaining: Int
    @State private var messageIndex = 0
    private let messages = ["Breathe.", "Move.", "Drink water.", "Change location.", "Remember why you quit."]

    init(seconds: Int, onDone: @escaping () -> Void) {
        self.seconds = seconds
        self.onDone = onDone
        _remaining = State(initialValue: seconds)
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("Don't solve forever.").font(Typography.body(15)).foregroundStyle(Theme.textSecondary)
            Text("Just get through this moment.").font(Typography.title(24)).foregroundStyle(Theme.textPrimary)
            ZStack {
                ProgressRing(progress: 1 - Double(remaining) / Double(seconds), color: Theme.craving, lineWidth: 12)
                Text(timeString).font(Typography.hero(36)).foregroundStyle(Theme.textPrimary).monospacedDigit()
            }
            .frame(width: 220, height: 220)
            Text(messages[messageIndex]).font(Typography.headline()).foregroundStyle(Theme.craving)
                .id(messageIndex).transition(.opacity)
            Spacer()
            SecondaryButton(title: "I'm done early") { onDone() }
        }
        .onAppear { tick() }
    }

    private var timeString: String { String(format: "%d:%02d", remaining / 60, remaining % 60) }

    private func tick() {
        Task { @MainActor in
            while remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                remaining -= 1
                if remaining % 36 == 0 { withAnimation { messageIndex = (messageIndex + 1) % messages.count } }
            }
            onDone()
        }
    }
}
