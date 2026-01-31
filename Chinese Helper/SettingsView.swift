//
//  SettingsView.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("ttsDelaySeconds") private var ttsDelaySeconds: Double = 2

    var body: some View {
        NavigationStack {
            Form {
                Section("TTS — delay between requests") {
                    HStack {
                        Slider(
                            value: $ttsDelaySeconds,
                            in: 1...20,
                            step: 1
                        ) {
                            Text("Delay")
                        }
                        Text("\(Int(ttsDelaySeconds))s")
                    }
                }
                
                Section("Import CSV with speech generation") {
                    ImportView()
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Item.self, inMemory: true)
}
