import SwiftUI

/// Semantic color system. Colors carry meaning (state), not decoration —
/// see spec section 34. Never rely on color alone (accessibility: section 35).
enum Theme {
    // Healthy / smoke-free: calm green-blue.
    static let healthy = Color(red: 0.20, green: 0.62, blue: 0.58)
    static let healthyDeep = Color(red: 0.10, green: 0.42, blue: 0.46)
    // Craving: warm amber.
    static let craving = Color(red: 0.93, green: 0.62, blue: 0.20)
    // Critical craving: deep but never alarming orange.
    static let cravingCritical = Color(red: 0.86, green: 0.42, blue: 0.24)
    // Relapse / smoking event: neutral, no red "failure" color.
    static let neutral = Color(red: 0.52, green: 0.52, blue: 0.56)
    // Milestone / celebration: bright, warm accent.
    static let celebration = Color(red: 0.98, green: 0.78, blue: 0.35)

    static let bgTop = Color(red: 0.05, green: 0.08, blue: 0.11)
    static let bgBottom = Color(red: 0.02, green: 0.04, blue: 0.06)
    static let card = Color.white.opacity(0.06)
    static let cardBorder = Color.white.opacity(0.10)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.68)
    static let textTertiary = Color.white.opacity(0.45)

    static var backgroundGradient: LinearGradient {
        LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)
    }
}

/// Type scale. Uses Dynamic Type throughout (accessibility: section 35) —
/// every font is `.system(..., design: .rounded)` scaled via relativeTo.
enum Typography {
    static func hero(_ size: CGFloat = 56) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func title(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func headline(_ size: CGFloat = 20) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func caption(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .medium, design: .rounded) }
}

/// Frosted glass surface used for cards throughout the app.
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
    }
}

/// Full-width primary call-to-action. One-tap, unmistakable (section 32).
struct PrimaryButton: View {
    let title: String
    var color: Color = Theme.healthy
    var systemImage: String? = nil
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 10) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(Typography.headline())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: [color, color.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .shadow(color: color.opacity(0.35), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.97 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: pressed)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressed = true }
            .onEnded { _ in pressed = false })
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(Typography.body(15))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Slow ambient pulse used behind hero status text — communicates "alive,
/// breathing" without being distracting (section 33).
struct BreathingPulse: View {
    var color: Color = Theme.healthy
    var size: CGFloat = 260
    @State private var expand = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.14)).frame(width: size, height: size)
                .scaleEffect(expand ? 1.12 : 0.94)
            Circle().fill(color.opacity(0.10)).frame(width: size * 0.7, height: size * 0.7)
                .scaleEffect(expand ? 1.08 : 0.96)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 4).repeatForever(autoreverses: true), value: expand)
        .onAppear { expand = true }
        .allowsHitTesting(false)
    }
}

/// Circular day-progress ring ("DAY 4 of 21").
struct ProgressRing: View {
    let progress: Double // 0...1
    var color: Color = Theme.healthy
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            Circle().stroke(Theme.card, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.02, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
        }
    }
}

/// Smoothly-morphing numeral used by the live timer.
struct AnimatedNumberText: View {
    let value: Int
    var font: Font = Typography.hero(40)

    var body: some View {
        Text("\(value)")
            .font(font)
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(.snappy, value: value)
    }
}

enum Haptics {
    static func tap() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    static func success() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    static func milestone() {
        #if os(iOS)
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { gen.impactOccurred() }
        #endif
    }
}
