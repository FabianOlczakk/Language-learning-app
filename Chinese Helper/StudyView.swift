//
//  StudyView.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import Foundation
import SwiftData
import SwiftUI

struct StudyView: View {
    @Environment(\.modelContext) private var ctx
    @StateObject private var audioPlayer = AudioPlayer()

    @Query(sort: \WordEntry.nextReview)
    private var allWords: [WordEntry]

    @StateObject private var session = LearningSession(words: [])

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let word = session.current() {

                    FlipCardView(
                        front: word.polish,
                        back: "\(word.hanzi)\n\(word.pinyin)",
                        onPlay: {
                            if let rel = word.audioRelativePath,
                               let url = try? AudioStore.resolve(relativePath: rel) {
                                audioPlayer.play(url: url)
                            }
                        }
                    )

                    HStack(spacing: 12) {
                        Button("Hard") {
                            session.answerHard()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)

                        Button("Medium") {
                            session.answerMedium()
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)

                        Button("Easy") {
                            session.answerEasy()
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }

                    Text("Remaining in batch: \(session.queue.count)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                } else {
                    ProgressView("Starting next batch…")
                }
            }
            .padding()
            .navigationTitle("Study")
            .onAppear {
                if session.queue.isEmpty {
                    session.startNewSession(from: allWords)
                }
            }
            .onChange(of: session.isFinished) { finished in
                if finished {
                    session.startNewSession(from: allWords)
                }
            }
        }
    }

}

#Preview {
    ContentView()
}
