import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

// MARK: - Section 4/19: HealthKit architecture, deliberately NOT wired to a
// live capability in v1.
//
// WHY: there is no HealthKit sample type that cleanly represents "smoke-free
// streak" or "quit date." Writing arbitrary/adjacent types (e.g. mindful
// minutes) to represent smoking-cessation data would misrepresent the data
// to other apps reading HealthKit and risks App Review scrutiny. This
// service defines the intended surface (read basic vitals context, no
// writes) so a future version can add the HealthKit capability + usage
// strings deliberately, rather than half-wiring it now.

protocol HealthKitServicing {
    var isAvailable: Bool { get }
    func requestAuthorization() async -> Bool
}

final class HealthKitService: HealthKitServicing {
    static let shared = HealthKitService()

    var isAvailable: Bool {
        #if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    /// Returns false until the HealthKit capability + Info.plist usage
    /// strings + explicit read/write type list are added in a future build.
    func requestAuthorization() async -> Bool { false }
}
