import Foundation
import SwiftData

// MARK: - Section 35: migration strategy.
//
// There is only one shipped schema so far (V1), so there is nothing to
// migrate FROM yet — that's expected for a pre-launch app, not a gap. What
// this file establishes is the STRUCTURE so that the day a field is added,
// removed or renamed, it happens through a documented VersionedSchema +
// SchemaMigrationPlan stage instead of a silent, destructive change that
// wipes a real user's quit journey.
//
// When you need to change a model:
//   1. Duplicate the current `SchemaV1` enum below as `SchemaV2`, with the
//      new model shapes.
//   2. Add a `MigrationStage` to `stages` in `Quit21MigrationPlan` —
//      `.lightweight` for additive/optional changes, `.custom` with explicit
//      `willMigrate`/`didMigrate` closures for anything that renames or
//      reshapes existing data.
//   3. Add `SchemaV2.self` to `schemas`.
//   4. Write a test that builds a SchemaV1 store, seeds it with representative
//      data, runs the migration, and asserts the data survived intact.

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [UserProfile.self, PersonalReason.self, QuitJourney.self,
         SmokingEvent.self, CravingEvent.self, DailyCheckIn.self, ProgramDayCompletion.self]
    }
}

enum Quit21MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
