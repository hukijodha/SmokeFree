import Foundation

// MARK: - Section 41/42: medical content is deliberately separated from the
// personalization engine, so health copy can be reviewed/updated
// independently of behavioral logic.
//
// IMPORTANT: the milestones below reflect the long-published, widely cited
// CDC "Health Benefits of Quitting Smoking Over Time" timeline and the WHO
// tobacco fact sheet. Language is deliberately hedged ("many people",
// "begins", "over time") per section 42 — never an individual guarantee.
// This copy should still receive a real clinical/legal review before
// shipping to production, as the product spec itself requires.

struct MedicalContentItem: Identifiable, Hashable {
    enum Category: String, CaseIterable { case heart, lungs, circulation, cancerRisk, respiratory, withdrawal, cravings, cessation }
    let id: String
    let title: String
    let body: String
    let source: String
    let category: Category
}

enum MedicalContentLibrary {
    static let items: [MedicalContentItem] = [
        .init(id: "heart-overview", title: "Heart",
              body: "Your cardiovascular health can begin benefiting soon after your last cigarette. For many people, heart rate and blood pressure start moving toward normal within the first hour.",
              source: "CDC, Health Benefits of Quitting Smoking Over Time", category: .heart),
        .init(id: "lungs-overview", title: "Lungs",
              body: "Your respiratory health can improve after quitting. Coughing and shortness of breath tend to decrease for many people over the following months as lung function improves.",
              source: "CDC, Health Benefits of Quitting Smoking Over Time", category: .lungs),
        .init(id: "circulation-overview", title: "Circulation",
              body: "Circulation can begin improving within the first weeks smoke-free, which may make everyday activity and exercise feel easier over time.",
              source: "CDC, Health Benefits of Quitting Smoking Over Time", category: .circulation),
        .init(id: "cancer-overview", title: "Long-term health",
              body: "The risk of smoking-related cancers and other long-term disease generally declines the longer someone stays smoke-free, continuing to drop over years.",
              source: "WHO Tobacco Fact Sheet; CDC", category: .cancerRisk),
        .init(id: "respiratory-overview", title: "Respiratory symptoms",
              body: "Many people notice less coughing and easier breathing within the first months of being smoke-free, as airways and lung tissue begin to recover.",
              source: "CDC, Health Benefits of Quitting Smoking Over Time", category: .respiratory),
        .init(id: "withdrawal-overview", title: "Withdrawal",
              body: "Cravings and withdrawal symptoms are strongest in the first weeks and are a normal, temporary part of quitting — not a sign that something is wrong.",
              source: "CDC / WHO cessation guidance", category: .withdrawal),
    ]

    static func items(in category: MedicalContentItem.Category) -> [MedicalContentItem] {
        items.filter { $0.category == category }
    }
}

/// A single point on the recovery timeline (section 9, 20).
struct HealthMilestoneItem: Identifiable, Hashable {
    let id: String
    let offset: TimeInterval // seconds after quitting
    let title: String
    let detail: String

    static let timeline: [HealthMilestoneItem] = [
        .init(id: "20min", offset: 20 * 60, title: "20 minutes",
              detail: "Your body begins adjusting. Heart rate and blood pressure can start moving toward normal."),
        .init(id: "12hr", offset: 12 * 3600, title: "12 hours",
              detail: "Carbon monoxide levels in your blood can return toward normal, for many people."),
        .init(id: "2wk", offset: 14 * 86400, title: "2 weeks",
              detail: "Circulation continues improving and lung function can begin increasing over the following weeks."),
        .init(id: "12wk", offset: 84 * 86400, title: "2–12 weeks",
              detail: "For many people, circulation and lung function keep improving through this period."),
        .init(id: "9mo", offset: 270 * 86400, title: "1–9 months",
              detail: "Coughing and shortness of breath can decrease as airways and lungs continue to recover."),
        .init(id: "1yr", offset: 365 * 86400, title: "1 year",
              detail: "For many people, excess risk of heart disease drops meaningfully compared to continuing to smoke."),
        .init(id: "5yr", offset: 5 * 365 * 86400, title: "5 years",
              detail: "Risk of stroke and several smoking-related cancers can continue to decline over this period."),
        .init(id: "10yr", offset: 10 * 365 * 86400, title: "10 years",
              detail: "Long-term risk of lung cancer death is generally much lower than for someone who continues smoking."),
        .init(id: "15yr", offset: 15 * 365 * 86400, title: "15 years",
              detail: "For many people, heart disease risk over this timeframe approaches that of someone who never smoked."),
    ]

    static func unlocked(secondsSmokeFree: TimeInterval) -> [HealthMilestoneItem] {
        timeline.filter { $0.offset <= secondsSmokeFree }
    }
    static func next(secondsSmokeFree: TimeInterval) -> HealthMilestoneItem? {
        timeline.first { $0.offset > secondsSmokeFree }
    }
}
