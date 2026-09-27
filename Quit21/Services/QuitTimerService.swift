import Foundation

// MARK: - Section 12/54: the live smoke-free timer. Always derives elapsed
// time from a timestamp — never accumulates seconds in storage.

struct ElapsedBreakdown: Equatable {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
    let totalSeconds: TimeInterval
}

enum QuitTimerService {
    static func breakdown(seconds: TimeInterval) -> ElapsedBreakdown {
        let total = max(0, Int(seconds))
        return ElapsedBreakdown(
            days: total / 86400,
            hours: (total % 86400) / 3600,
            minutes: (total % 3600) / 60,
            seconds: total % 60,
            totalSeconds: seconds
        )
    }

    static func humanized(seconds: TimeInterval) -> String {
        let b = breakdown(seconds: seconds)
        if b.days > 0 { return "\(b.days)d \(b.hours)h \(b.minutes)m" }
        if b.hours > 0 { return "\(b.hours)h \(b.minutes)m" }
        return "\(b.minutes)m \(b.seconds)s"
    }
}
