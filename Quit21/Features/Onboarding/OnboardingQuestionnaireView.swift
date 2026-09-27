import SwiftUI

// MARK: - Section 7: one question per screen, large tappable choices, no
// forms. Builds a UserProfile + PersonalReason as the user answers.

struct OnboardingQuestionnaireView: View {
    let onFinished: (UserProfile, PersonalReason) -> Void

    @State private var step = 0
    @State private var smokingType: SmokingType = .cigarettes
    @State private var frequency: FrequencyBand = .eleven_20
    @State private var customCount: Int = 15
    @State private var wakeToFirst: WakeToFirstCigarette = .six_30
    @State private var years: Int = 3
    @State private var strongestTimes: Set<Trigger> = []
    @State private var commonPrompts: Set<Trigger> = []
    @State private var triedBefore: Bool? = nil
    @State private var relapseCauses: Set<RelapseCause> = []
    @State private var reasons: Set<QuitMotivationReason> = []
    @State private var primaryReason: QuitMotivationReason? = nil
    @State private var whyText: String = ""

    private let promptTriggers: [Trigger] = [.morning, .afterFood, .coffeeOrTea, .driving, .work, .stress,
                                             .anxiety, .anger, .alcohol, .social, .boredom, .phoneCalls,
                                             .breaks, .beforeSleep, .seeingSomeoneSmoke, .other]

    private var totalSteps: Int { triedBefore == true ? 9 : 8 }

    var body: some View {
        VStack(spacing: 0) {
            ProgressRing(progress: Double(step + 1) / Double(totalSteps), lineWidth: 6)
                .frame(width: 34, height: 34)
                .overlay(Text("\(step + 1)").font(Typography.caption()).foregroundStyle(Theme.textSecondary))
                .padding(.top, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    content
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    @ViewBuilder private var content: some View {
        switch step {
        case 0: question("What do you smoke?") {
            choiceGrid(SmokingType.allCases, selection: Binding(get: { smokingType }, set: { smokingType = $0; advance() })) { $0.label }
        }
        case 1: question("How often do you currently smoke?") {
            VStack(spacing: 12) {
                choiceList(FrequencyBand.allCases, selection: Binding(get: { frequency }, set: { if let v = $0 { frequency = v } })) { $0.label }
                if frequency == .custom {
                    Stepper("\(customCount) per day", value: $customCount, in: 1...100)
                        .padding().background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
                }
                PrimaryButton(title: "Continue", action: advance)
            }
        }
        case 2: question("How soon after waking do you usually smoke?") {
            choiceList(WakeToFirstCigarette.allCases, selection: Binding(get: { wakeToFirst }, set: { if let v = $0 { wakeToFirst = v }; advance() })) { $0.label }
        }
        case 3: question("How long have you been smoking?") {
            VStack(spacing: 16) {
                Text("\(years) year\(years == 1 ? "" : "s")").font(Typography.hero(44)).foregroundStyle(Theme.textPrimary)
                Slider(value: Binding(get: { Double(years) }, set: { years = Int($0) }), in: 0...50, step: 1)
                PrimaryButton(title: "Continue", action: advance)
            }
        }
        case 4: question("When do you most strongly want to smoke?", subtitle: "Select all that apply.") {
            VStack(spacing: 16) {
                multiChoiceGrid(promptTriggers, selection: $strongestTimes)
                PrimaryButton(title: "Continue", action: advance)
            }
        }
        case 5: question("What usually makes you want to smoke?", subtitle: "Select all that apply.") {
            VStack(spacing: 16) {
                multiChoiceGrid(promptTriggers, selection: $commonPrompts)
                PrimaryButton(title: "Continue", action: advance)
            }
        }
        case 6: question("Have you tried quitting before?") {
            VStack(spacing: 12) {
                choiceRow("Yes") { triedBefore = true; advance() }
                choiceRow("No") { triedBefore = false; advanceSkippingRelapse() }
            }
        }
        case 7 where triedBefore == true:
            question("What usually brought you back?", subtitle: "Select all that apply.") {
                VStack(spacing: 16) {
                    multiChoiceGridRelapse(RelapseCause.allCases, selection: $relapseCauses)
                    PrimaryButton(title: "Continue", action: advance)
                }
            }
        case reasonStepIndex:
            question("What is your biggest reason for quitting?", subtitle: "Select all that apply.") {
                VStack(spacing: 16) {
                    multiChoiceGridReasons(QuitMotivationReason.allCases, selection: $reasons)
                    PrimaryButton(title: "Continue", action: advance)
                }
            }
        default:
            question("Which ONE matters most?") {
                VStack(alignment: .leading, spacing: 16) {
                    choiceList(Array(reasons), selection: Binding(get: { primaryReason ?? reasons.first }, set: { primaryReason = $0 })) { $0.label }
                    Text("I am quitting because…").font(Typography.body(15)).foregroundStyle(Theme.textSecondary)
                    TextField("your own words", text: $whyText, axis: .vertical)
                        .lineLimit(3...6)
                        .padding()
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(Theme.textPrimary)
                    PrimaryButton(title: "Begin", action: finish)
                }
            }
        }
    }

    private var reasonStepIndex: Int { triedBefore == true ? 8 : 7 }

    private func advance() { withAnimation { step += 1 } }
    private func advanceSkippingRelapse() { withAnimation { step = reasonStepIndex } }

    private func finish() {
        let profile = UserProfile(smokingType: smokingType, frequencyBand: frequency,
                                  customDailyCount: frequency == .custom ? customCount : nil,
                                  wakeToFirst: wakeToFirst, yearsSmoking: years,
                                  strongestTimes: Array(strongestTimes), commonPrompts: Array(commonPrompts),
                                  hasTriedQuittingBefore: triedBefore ?? false,
                                  previousRelapseCauses: Array(relapseCauses),
                                  motivationReasons: Array(reasons), primaryReason: primaryReason)
        let text = whyText.isEmpty ? (primaryReason?.label ?? "my health") : whyText
        let reason = PersonalReason(text: text)
        onFinished(profile, reason)
    }

    // MARK: - Reusable question chrome / choice widgets

    @ViewBuilder private func question<Content: View>(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(Typography.title(26)).foregroundStyle(Theme.textPrimary)
            if let subtitle { Text(subtitle).font(Typography.body(15)).foregroundStyle(Theme.textSecondary) }
        }
        content()
    }

    private func choiceRow(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(Typography.headline())
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .foregroundStyle(Theme.textPrimary)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.cardBorder, lineWidth: 1))
        }.buttonStyle(.plain)
    }

    private func choiceList<T: Identifiable & Hashable>(_ items: [T], selection: Binding<T?>, label: @escaping (T) -> String) -> some View {
        VStack(spacing: 10) {
            ForEach(items) { item in
                Button { selection.wrappedValue = item } label: {
                    HStack {
                        Text(label(item)).font(Typography.body())
                        Spacer()
                        if selection.wrappedValue == item { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.healthy) }
                    }
                    .padding().foregroundStyle(Theme.textPrimary)
                    .background(selection.wrappedValue == item ? Theme.healthy.opacity(0.18) : Theme.card, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(selection.wrappedValue == item ? Theme.healthy : Theme.cardBorder, lineWidth: 1))
                }.buttonStyle(.plain)
            }
        }
    }

    private func choiceGrid<T: Identifiable & Hashable>(_ items: [T], selection: Binding<T>, label: @escaping (T) -> String) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(items) { item in
                Button { selection.wrappedValue = item } label: {
                    Text(label(item)).font(Typography.body())
                        .frame(maxWidth: .infinity).padding(.vertical, 20)
                        .foregroundStyle(Theme.textPrimary)
                        .background(selection.wrappedValue == item ? Theme.healthy.opacity(0.22) : Theme.card, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(selection.wrappedValue == item ? Theme.healthy : Theme.cardBorder, lineWidth: 1))
                }.buttonStyle(.plain)
            }
        }
    }

    private func multiChoiceGrid(_ items: [Trigger], selection: Binding<Set<Trigger>>) -> some View {
        FlowChips(items: items, label: \.label, isSelected: { selection.wrappedValue.contains($0) }) { item in
            if selection.wrappedValue.contains(item) { selection.wrappedValue.remove(item) } else { selection.wrappedValue.insert(item) }
        }
    }
    private func multiChoiceGridRelapse(_ items: [RelapseCause], selection: Binding<Set<RelapseCause>>) -> some View {
        FlowChips(items: items, label: \.label, isSelected: { selection.wrappedValue.contains($0) }) { item in
            if selection.wrappedValue.contains(item) { selection.wrappedValue.remove(item) } else { selection.wrappedValue.insert(item) }
        }
    }
    private func multiChoiceGridReasons(_ items: [QuitMotivationReason], selection: Binding<Set<QuitMotivationReason>>) -> some View {
        FlowChips(items: items, label: \.label, isSelected: { selection.wrappedValue.contains($0) }) { item in
            if selection.wrappedValue.contains(item) { selection.wrappedValue.remove(item) } else { selection.wrappedValue.insert(item) }
        }
    }
}

/// Simple wrapping chip layout used for multi-select questions.
struct FlowChips<Item: Identifiable & Hashable>: View {
    let items: [Item]
    let label: (Item) -> String
    let isSelected: (Item) -> Bool
    let toggle: (Item) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                Button { toggle(item) } label: {
                    Text(label(item)).font(Typography.body(14))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .foregroundStyle(Theme.textPrimary)
                        .background(isSelected(item) ? Theme.healthy.opacity(0.24) : Theme.card, in: Capsule())
                        .overlay(Capsule().stroke(isSelected(item) ? Theme.healthy : Theme.cardBorder, lineWidth: 1))
                }.buttonStyle(.plain)
            }
        }
    }
}
