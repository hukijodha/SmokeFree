import SwiftUI
import SwiftData

@main
struct Quit21App: App {
    let container = ModelContainerFactory.make()
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(env)
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
