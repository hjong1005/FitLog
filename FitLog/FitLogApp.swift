//
//  FitLogApp.swift
//  FitLog
//
//  Created by Ong Han jie on 3/5/26.
//

import SwiftUI
import CoreData

@main
struct FitLogApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
