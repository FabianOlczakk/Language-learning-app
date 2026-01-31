//
//  Chinese_HelperApp.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import SwiftUI
import SwiftData

@main
struct ChineseHelperApp: App {

    // JEDEN wspólny kontener dla całej aplikacji
    let container: ModelContainer = {
        do {
            let schema = Schema([WordEntry.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
