//
//  MultipleChoiceStudyView.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//


import SwiftUI
import SwiftData

struct MultipleChoiceStudyView: View {
    let word: WordEntry
    let onResult: (Bool) -> Void
    let direction: StudyView.StudyDirection

    @Query private var allWords: [WordEntry]

    @State private var options: [WordEntry] = []
    @State private var selectedID: UUID? = nil
    @State private var isAnswered: Bool = false

    @StateObject private var audioPlayer = AudioPlayer()
    @State private var didAutoPlay = false

    var body: some View {
        VStack(spacing: 20) {

            // ===== QUESTION =====
            HStack(spacing: 12) {
                Text(questionText)
                    .font(.system(size: 36, weight: .bold))
                    .multilineTextAlignment(.center)

                if direction == .zhToPl {
                    AudioPlayButton() {
                        playAudio(for: word)
                    }
                }
            }
            .padding(.bottom, 40)

            // ===== OPTIONS =====
            ForEach(options, id: \.id) { option in
                Button {
                    guard !isAnswered else { return }

                    selectedID = option.id
                    isAnswered = true

                    let correct = option.id == word.id
                    onResult(correct)

                    if direction == .plToZh {
                        playAudio(for: option)
                    }

                } label: {
                    HStack(spacing: 12) {

                        Text(optionText(option))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if direction == .plToZh {
                            AudioPlayButton() {
                                playAudio(for: option)
                            }
                        }
                    }
                    .padding()
                }
                .buttonStyle(.glass)
                .glassEffect(.regular.tint(backgroundColor(for: option)).interactive())
            }
        }
        .padding()
        .task(id: word.id) {
            reset()
            generateOptions()

            // ▶️ AUTO PLAY (zh → pl)
            if direction == .zhToPl, !didAutoPlay {
                didAutoPlay = true
                playAudio(for: word)
            }
        }
    }

    // MARK: - Text helpers

    private var questionText: String {
        direction == .plToZh
        ? word.polish
        : "\(word.hanzi) \(word.pinyin)"
    }

    private func optionText(_ option: WordEntry) -> String {
        direction == .plToZh
        ? "\(option.hanzi) \(option.pinyin)"
        : option.polish
    }

    private func playAudio(for word: WordEntry) {
        guard let rel = word.audioRelativePath,
              let url = try? AudioStore.resolve(relativePath: rel) else { return }
        audioPlayer.play(url: url)
    }

    // MARK: - Logic

    private func generateOptions() {
        var pool = allWords.filter { $0.id != word.id }

        guard pool.count >= 3 else {
            options = [word]
            return
        }

        var rng1 = SeededGenerator(seed: word.id.hashValue)
        pool.shuffle(using: &rng1)

        let distractors = Array(pool.prefix(3))
        var result = distractors + [word]

        var rng2 = SeededGenerator(seed: word.id.hashValue ^ 0xDEADBEEF)
        result.shuffle(using: &rng2)

        options = result
    }

    private func reset() {
        selectedID = nil
        isAnswered = false
        didAutoPlay = false
    }

    private func backgroundColor(for option: WordEntry) -> Color {
        guard isAnswered else { return Color.gray.opacity(0.15) }

        if option.id == word.id {
            return Color.green.opacity(0.3)
        }

        if option.id == selectedID {
            return Color.red.opacity(0.3)
        }

        return Color.clear
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([WordEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    let ctx = container.mainContext

    let word = WordEntry(
        polish: "apple",
        pinyin: "píngguǒ",
        hanzi: "苹果"
    )

    let other1 = WordEntry(
        polish: "banana",
        pinyin: "xiāngjiāo",
        hanzi: "香蕉"
    )

    let other2 = WordEntry(
        polish: "orange",
        pinyin: "chéngzi",
        hanzi: "橙子"
    )

    let other3 = WordEntry(
        polish: "pear",
        pinyin: "lí",
        hanzi: "梨"
    )

    let _ = {
        ctx.insert(word)
        ctx.insert(other1)
        ctx.insert(other2)
        ctx.insert(other3)
    }()

    MultipleChoiceStudyView(
        word: word,
        onResult: { correct in
            print("Result:", correct)
        },
        direction: .plToZh
    )
    .modelContainer(container)
    .padding()
}
