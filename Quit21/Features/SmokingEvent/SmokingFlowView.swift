import SwiftUI

// MARK: - Section 15/46: no failure screen. Understand → learn → adjust
// → continue. Previous smoke-free time is always preserved and shown back.

struct SmokingFlowView: View {
    let journey: QuitJourney?
    let onComplete: (SmokingEvent, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var stage = 0
    @State private var quantity = 1
    @State private var when: WhenChoice = .now
    @State private var trigger: Trigger = .stress
    @State private var feeling = ""

    enum WhenChoice: String, CaseIterable, Identifiable { case now, earlierToday, yesterday
        var id: String { rawValue }
        var label: String { self == .now ? "Now" : self == .earlierToday ? "Earlier today" : "Yesterday" }
    }

    var body: some View {
            VStack(alignment: .leading, spacing: 22) {
                Text("You're still quitting.").font(Typography.title(28)).foregroundStyle(Theme.textPrimary)

                switch stage {
                case 0:
                    Text("How many?").font(Typography.headline()).foregroundStyle(Theme.textSecondary)
                    HStack(spacing: 10) {
                        ForEach([1, 2, 3, 4, 5], id: \.self) { n in
                            Button { quantity = n; stage = 1 } label: {
                                Text(n == 5 ? "5+" : "\(n)").font(Typography.headline())
                                    .frame(width: 52, height: 52)
                                    .foregroundStyle(Theme.textPrimary)
                                    .background(Circle().fill(Theme.card))
                                    .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                            }.buttonStyle(.plain)
                        }
                    }
                case 1:
                    Text("When?").font(Typography.headline()).foregroundStyle(Theme.textSecondary)
                    ForEach(WhenChoice.allCases) { w in
                        choiceRow(w.label) { when = w; stage = 2 }
                    }
                case 2:
                    Text("What happened immediately before?").font(Typography.headline()).foregroundStyle(Theme.textSecondary)
                    FlowChips(items: [Trigger.stress, .alcohol, .afterFood, .coffeeOrTea, .social, .boredom, .anger, .work, .cravingAlone, .habit, .other],
                             label: \.label, isSelected: { trigger == $0 }) { trigger = $0; stage = 3 }
                case 3:
                    Text("What did you feel? (optional)").font(Typography.headline()).foregroundStyle(Theme.textSecondary)
                    TextField("optional", text: $feeling, axis: .vertical)
                        .padding().background(Theme.card, in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(Theme.textPrimary)
                    PrimaryButton(title: "Let's learn from this", color: Theme.neutral) { stage = 4 }
                default:
                    learnView
                }
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .animation(.easeInOut(duration: 0.3), value: stage)
            .background(Theme.backgroundGradient.ignoresSafeArea())
    }

    private var learnView: some View {
        VStack(alignment: .leading, spacing: 18) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your next decision matters.").font(Typography.headline()).foregroundStyle(Theme.textPrimary)
                    Text("The trigger you noted: \(trigger.label).").font(Typography.body(14)).foregroundStyle(Theme.textSecondary)
                }
            }
            if let journey, journey.currentStreakSeconds() > 3600 {
                GlassCard {
                    Text("Your previous smoke-free period: \(QuitTimerService.humanized(seconds: journey.currentStreakSeconds())). That experience is still yours.")
                        .font(Typography.body(14)).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            PrimaryButton(title: "CONTINUE QUITTING") {
                let event = SmokingEvent(timestamp: whenDate, quantity: quantity, trigger: trigger,
                                         notes: nil, feeling: feeling.isEmpty ? nil : feeling)
                onComplete(event, true)
                Haptics.success()
                dismiss()
            }
        }
    }

    private var whenDate: Date {
        switch when {
        case .now: return .now
        case .earlierToday: return Calendar.current.date(bySettingHour: max(0, Calendar.current.component(.hour, from: .now) - 2), minute: 0, second: 0, of: .now) ?? .now
        case .yesterday: return Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        }
    }

    private func choiceRow(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(Typography.body()).frame(maxWidth: .infinity, alignment: .leading)
                .padding().foregroundStyle(Theme.textPrimary)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardBorder, lineWidth: 1))
        }.buttonStyle(.plain)
    }
}
