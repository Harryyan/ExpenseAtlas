import SwiftUI
import SwiftData

@main
struct ExpenseAtlasApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Folder.self,
            StatementDoc.self,
            Transaction.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .environment(environment)
    }
}
