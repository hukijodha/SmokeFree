import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

// MARK: - Section 24/59: Apple Watch ARCHITECTURE for v1 (a full paired
// watchOS app target is deferred — see project README). This session
// manager defines the exact, minimal payload a future watch app would
// exchange with the phone: current streak, day number, and the three
// one-tap actions (Craving / Smoked / I'm Okay), all derived on-device.
//
// No personal data crosses a network boundary here either — WatchConnectivity
// is a direct device-to-device channel (section 3, 37 still hold).

struct WatchStatePayload: Codable {
    let smokeFreeSeconds: TimeInterval
    let day: Int
    let dayTarget: Int
}

enum WatchAction: String, Codable {
    case craving, smoked, imOkay
}

#if canImport(WatchConnectivity)
final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func send(_ payload: WatchStatePayload) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? WCSession.default.updateApplicationContext(["state": data])
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}
#else
final class WatchSessionManager {
    static let shared = WatchSessionManager()
    func send(_ payload: WatchStatePayload) {}
}
#endif
