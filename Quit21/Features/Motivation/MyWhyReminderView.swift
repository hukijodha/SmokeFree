import SwiftUI

// MARK: - Section 21: the permanent "My Why." Shown full-screen with a
// powerful, calm animation whenever the user needs to remember.

struct MyWhyReminderView: View {
    let reason: PersonalReason
    @Environment(\.dismiss) private var dismiss
    @State private var appear = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("I AM QUITTING BECAUSE").font(Typography.caption(13)).tracking(2).foregroundStyle(Theme.textTertiary)
            Text(reason.text.isEmpty ? "my health" : reason.text)
                .font(Typography.title(30)).multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 32)
                .scaleEffect(appear ? 1 : 0.85)
                .opacity(appear ? 1 : 0)
            Spacer()
            PrimaryButton(title: "Close", action: { dismiss() }).padding(.horizontal, 40).padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { appear = true } }
    }
}
