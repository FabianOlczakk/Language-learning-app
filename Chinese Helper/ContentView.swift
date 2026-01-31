//
//  ContentView.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            StudyView()
                .tabItem { Label("Study", systemImage: "book")}
            
            DatabaseView()
                .tabItem { Label("Database", systemImage: "rectangle.stack") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
