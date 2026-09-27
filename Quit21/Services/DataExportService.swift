import Foundation
import SwiftData

// MARK: - Section 49/50: user-initiated export, never automatic, never
// uploaded by the app itself (section 3, 37). JSON + CSV supported now;
// PDF summary is straightforward to add on top of the same snapshot.

struct ExportSnapshot: Codable {
    struct SmokingEventDTO: Codable { let timestamp: Date; let quantity: Int; let trigger: String; let context: String? }
    struct CravingEventDTO: Codable { let timestamp: Date; let beforeIntensity: Int; let trigger: String; let intervention: String; let afterIntensity: Int?; let resolved: Bool }
    struct CheckInDTO: Codable { let date: Date; let smokedToday: Bool; let strongestCraving: Int; let confidenceTomorrow: Int }

    let exportedAt: Date
    let quitStartDate: Date?
    let quitDate: Date?
    let smokingEvents: [SmokingEventDTO]
    let cravingEvents: [CravingEventDTO]
    let checkIns: [CheckInDTO]
}

enum DataExportService {
    static func snapshot(journey: QuitJourney?, smoking: [SmokingEvent], craving: [CravingEvent], checkIns: [DailyCheckIn]) -> ExportSnapshot {
        ExportSnapshot(
            exportedAt: .now,
            quitStartDate: journey?.startDate,
            quitDate: journey?.quitDate,
            smokingEvents: smoking.map { .init(timestamp: $0.timestamp, quantity: $0.quantity, trigger: $0.trigger.rawValue, context: $0.context?.rawValue) },
            cravingEvents: craving.map { .init(timestamp: $0.timestamp, beforeIntensity: $0.beforeIntensity, trigger: $0.trigger.rawValue, intervention: $0.interventionRaw, afterIntensity: $0.afterIntensity, resolved: $0.resolved) },
            checkIns: checkIns.map { .init(date: $0.date, smokedToday: $0.smokedToday, strongestCraving: $0.strongestCraving, confidenceTomorrow: $0.confidenceTomorrow) }
        )
    }

    static func json(_ snapshot: ExportSnapshot) -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(snapshot)) ?? Data()
    }

    static func csv(_ snapshot: ExportSnapshot) -> Data {
        var lines = ["type,timestamp,quantity_or_intensity,trigger,detail"]
        let iso = ISO8601DateFormatter()
        for e in snapshot.smokingEvents {
            lines.append("smoking,\(iso.string(from: e.timestamp)),\(e.quantity),\(e.trigger),\(e.context ?? "")")
        }
        for c in snapshot.cravingEvents {
            lines.append("craving,\(iso.string(from: c.timestamp)),\(c.beforeIntensity),\(c.trigger),\(c.intervention);resolved=\(c.resolved)")
        }
        for k in snapshot.checkIns {
            lines.append("checkin,\(iso.string(from: k.date)),\(k.strongestCraving),,smoked=\(k.smokedToday)")
        }
        return lines.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    /// Deletes every locally stored record. Irreversible — callers must
    /// confirm with the user first (section 48: "Delete My Data").
    static func deleteEverything(context: ModelContext) throws {
        try context.delete(model: SmokingEvent.self)
        try context.delete(model: CravingEvent.self)
        try context.delete(model: DailyCheckIn.self)
        try context.delete(model: ProgramDayCompletion.self)
        try context.delete(model: QuitJourney.self)
        try context.delete(model: UserProfile.self)
        try context.delete(model: PersonalReason.self)
        try context.save()
    }
}
