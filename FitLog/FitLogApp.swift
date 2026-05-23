import SwiftUI
import CoreData

@main
struct FitLogApp: App {
    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
