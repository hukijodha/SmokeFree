import SwiftUI

// MARK: - Section 11: the quit button. Cinematic confirmation, then a choice
// of start time — never a throwaway single tap for something this significant.

struct ReadyToQuitView: View {
    let onConfirm: (Date) -> Void

    @State private var stage = 0
    @State private var choice: DateChoice = .now
    @State private var customDate = Date().addingTimeInterval(86400)

    enum DateChoice: String, CaseIterable, Identifiable { case now, tomorrow, custom
        var id: String { rawValue }
        var label: String { self == .now ? "Now" : self == .tomorrow ? "Tomorrow" : "Choose a date" }
    }

    var body: some View {
        Group {
            if stage == 0 {
                VStack(spacing: 28) {
                    Spacer()
                    BreathingPulse(size: 220)
                        .overlay(Image(systemName: "heart.fill").font(.system(size: 44)).foregroundStyle(Theme.healthy))
                    Text("You are choosing your health.")
                        .font(Typography.title(28)).multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textPrimary).padding(.horizontal, 32)
                    Spacer()
                    PrimaryButton(title: "Continue") { withAnimation { stage = 1 } }
                        .padding(.horizontal, 32).padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer().frame(height: 40)
                    Text("QUIT STARTS").font(Typography.caption()).foregroundStyle(Theme.textTertiary)
                    Text("When do you want to begin?").font(Typography.title(28)).foregroundStyle(Theme.textPrimary)

                    VStack(spacing: 10) {
                        ForEach(DateChoice.allCases) { c in
                            Button { choice = c } label: {
                                HStack {
                                    Text(c.label).font(Typography.headline())
                                    Spacer()
                                    if choice == c { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.healthy) }
                                }
                                .padding().foregroundStyle(Theme.textPrimary)
                                .background(choice == c ? Theme.healthy.opacity(0.18) : Theme.card, in: RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(choice == c ? Theme.healthy : Theme.cardBorder, lineWidth: 1))
                            }.buttonStyle(.plain)
                        }
                    }
                    if choice == .custom {
                        DatePicker("Quit date", selection: $customDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(Theme.healthy)
                            .colorScheme(.dark)
                    }
                    Spacer()
                    PrimaryButton(title: "QUIT STARTS NOW") {
                        let date: Date = choice == .now ? .now : choice == .tomorrow ? Date().addingTimeInterval(86400) : customDate
                        onConfirm(date)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
    }
}
