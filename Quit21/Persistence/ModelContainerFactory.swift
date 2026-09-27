import Foundation
import SwiftData

/// Single, local-only persistence stack (section 37: no server, ever).
/// No CloudKit container is configured — `cloudKitDatabase: .none` makes
/// this explicit and future-proof against an accidental sync turn-on.
enum ModelContainerFactory {
    static func make() -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, migrationPlan: Quit21MigrationPlan.self, configurations: [config])
        } catch {
            // Fall back to an in-memory store rather than crash the app.
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            return (try? ModelContainer(for: schema, migrationPlan: Quit21MigrationPlan.self, configurations: [memoryConfig]))
                ?? fatalErrorContainer()
        }
    }

    private static func fatalErrorContainer() -> ModelContainer {
        fatalError("Unable to create even an in-memory ModelContainer.")
    }
}
