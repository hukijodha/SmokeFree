import SwiftUI

// MARK: - Section 6: first-launch cinematic intro. No forms yet — just three
// calm, high-impact statements before anything is asked of the user.
//
// Layout note: the root view is the VStack itself (background applied via
// .background()), not a VStack nested as a ZStack sibling. A VStack nested
// inside a ZStack is not automatically stretched to the ZStack's full size,
// which silently starves Text of a wrapping width — this is the reliable
// pattern; see git history for the debugging trail if this regresses.

struct CinematicIntroView: View {
    let onStart: () -> Void
    let onLearnFirst: () -> Void

    @State private var index = 0
    @State private var glow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let lines = [
        "Your next cigarette doesn't have to happen.",
        "Your body can begin recovering after your last cigarette.",
        "Let's make today the beginning.",
    ]

    var body: some View {
        VStack {
            Spacer()

            Text(lines[index])
                .font(Typography.title(30))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 36)
            Spacer()

            if index < lines.count - 1 {
                SecondaryButton(title: "Continue") {
                    withAnimation(.easeInOut(duration: 0.6)) { index += 1 }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 12)
            } else {
                VStack(spacing: 12) {
                    PrimaryButton(title: "START MY QUIT JOURNEY", action: onStart)
                    Button("I want to understand first", action: onLearnFirst)
                        .font(Typography.body(15))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Theme.backgroundGradient
                Circle()
                    .fill(RadialGradient(colors: [Theme.healthy.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: 260))
                    .frame(width: 520, height: 520)
                    .scaleEffect(glow ? 1.08 : 0.92)
                    .opacity(glow ? 0.9 : 0.5)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: glow)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            glow = true
            guard !reduceMotion else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.4))
                if index == 0 { withAnimation(.easeInOut(duration: 0.6)) { index = 1 } }
                try? await Task.sleep(for: .seconds(2.6))
                if index == 1 { withAnimation(.easeInOut(duration: 0.6)) { index = 2 } }
            }
        }
    }
}
