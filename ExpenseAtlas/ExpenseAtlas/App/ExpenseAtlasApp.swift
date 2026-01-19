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
        
        let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("ExpenseAtlas.store")
        let modelConfiguration = if let storeURL {
            ModelConfiguration(schema: schema, url: storeURL)
        } else {
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var environment = AppEnvironment.live()
    
    var body: some Scene {
        WindowGroup {
            RootView(vm: environment.library.makeRootViewModel())
                .environment(environment)
        }
        .modelContainer(sharedModelContainer)
    }
}
