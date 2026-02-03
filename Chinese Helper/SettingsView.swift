//
//  SettingsView.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    
    @AppStorage("ttsDelaySeconds") private var ttsDelaySeconds: Double = 5
    @AppStorage("batchSize") private var batchSize: Int = 15
    @AppStorage("minShowsPerCard") private var minShowsPerCard: Int = 2
    @AppStorage("easyRequiredEasy") private var easyRequiredEasy: Int = 2
    @AppStorage("mediumRequiredEasy") private var mediumRequiredEasy: Int = 3
    @AppStorage("hardRequiredEasy") private var hardRequiredEasy: Int = 3
    @AppStorage("hardReinsertOffset") private var hardReinsertOffset: Int = 4
    @AppStorage("autoPlayDelayMs") private var autoPlayDelayMs: Int = 200
    @AppStorage("shuffleNewBatch") private var shuffleNewBatch: Bool = true

    @AppStorage("modeFlashcards") private var modeFlashcards: Bool = true
    @AppStorage("modeMultipleChoice") private var modeMultipleChoice: Bool = false
    @AppStorage("modeAudioFirst") private var modeAudioFirst: Bool = false
    @AppStorage("modeSentence") private var modeSentence: Bool = false
    @AppStorage("learningDirection") private var learningDirection: LearningDirection = .plToZh
    
    @AppStorage("enableTransitionAnimation")
    private var enableTransitionAnimation: Bool = true

    @Environment(\.modelContext) private var ctx

    var body: some View {
        NavigationStack {
            Form {
                Section ("Learning"){
                    VStack {
                        Label("Answer in:", systemImage: "flag.badge.ellipsis")
                        Spacer(minLength: 15.0)
                        Picker("Learning direction", selection: $learningDirection) {
                            ForEach(LearningDirection.allCases) { dir in
                                Text(dir.label).tag(dir)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Toggle("Flashcards", isOn: $modeFlashcards)
                    
                    Toggle("Multiple choice", isOn: $modeMultipleChoice)
                    
                    Toggle("Audio first", isOn: $modeAudioFirst)
                    
                    Toggle("Sentence mode", isOn: $modeSentence)
                    
                    NavigationLink {
                        Form {
                            Section ("Batch"){
                                Stepper("Size: \(batchSize)", value: $batchSize, in: 5...50)
                                
                                Stepper("Minimum shows per card: \(minShowsPerCard)", value: $minShowsPerCard, in: 1...5)
                                
                                Toggle("Shuffle new batch", isOn: $shuffleNewBatch)
                            }
                            
                            Section ("Required Easy taps"){
                                HStack {
                                    Button("Easy") {}
                                        .glassEffect(.regular.tint(.green))
                                        .buttonStyle(.glass)
                                        .tint(.green)
                                    Spacer()
                                    Stepper("\(easyRequiredEasy) taps",
                                            value: $easyRequiredEasy, in: 1...5)
                                }
                                
                                HStack {
                                    Button("Medium") {}
                                        .glassEffect(.regular.tint(.orange))
                                        .buttonStyle(.glass)
                                        .tint(.orange)
                                    
                                    Stepper("\(mediumRequiredEasy) taps",
                                            value: $mediumRequiredEasy, in: 1...5)
                                }
                                
                                HStack {
                                    Button("Hard") {}
                                        .glassEffect(.regular.tint(.red))
                                        .buttonStyle(.glass)
                                        .tint(.red)
                                    
                                    Stepper("\(hardRequiredEasy) taps",
                                            value: $hardRequiredEasy, in: 1...5)
                                }
                            }
                            
                            Section ("Reinsert card after") {
                                HStack {
                                    Button("Hard") {}
                                        .glassEffect(.regular.tint(.red))
                                        .buttonStyle(.glass)
                                        .tint(.red)
                                    Stepper("\(hardReinsertOffset) cards",
                                            value: $hardReinsertOffset, in: 1...10)
                                }
                            }
                            
                        }
                        .navigationTitle("Learning algorithm")
                    } label: {
                        Label("Algorithm settings", systemImage: "brain.head.profile")
                    }
                }
                .onChange(of: [
                    modeFlashcards,
                    modeMultipleChoice,
                    modeAudioFirst,
                    modeSentence
                ]) { _ in
                    if !modeFlashcards &&
                       !modeMultipleChoice &&
                       !modeAudioFirst &&
                       !modeSentence {
                        modeFlashcards = true
                    }
                }
                
                Section("Appearance") {
                    Toggle("Transition animation", isOn: $enableTransitionAnimation)
                }
                
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

                Section("Danger zone") {

                    Button(role: .destructive) {
                        resetLearningProgress()
                    } label: {
                        Text("Reset learning progress")
                    }

                    Button(role: .destructive) {
                        deleteAllWords()
                    } label: {
                        Text("Delete all words")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func resetLearningProgress() {
        do {
            let words = try ctx.fetch(FetchDescriptor<WordEntry>())
            for w in words {
                w.seenCount = 0
                w.easyCount = 0
                w.isLearned = false
                w.nextReview = Date.distantPast
            }
            try ctx.save()
        } catch {
            print("Failed to reset learning progress:", error)
        }
    }

    private func deleteAllWords() {
        do {
            let words = try ctx.fetch(FetchDescriptor<WordEntry>())
            for w in words {
                ctx.delete(w)
            }
            try ctx.save()
        } catch {
            print("Failed to delete all words:", error)
        }
    }
}

enum LearningDirection: String, CaseIterable, Identifiable {
    case plToZh
    case zhToPl
    case random

    var id: String { rawValue }

    var label: String {
        switch self {
        case .plToZh: return "Chinese"
        case .zhToPl: return "English"
        case .random: return "Random"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: WordEntry.self, inMemory: true)
}
