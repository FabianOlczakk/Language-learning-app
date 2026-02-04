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
    @State private var isCorrect: Bool = false

    var body: some View {
        VStack(spacing: 20) {

            Text(direction == .plToZh
                 ? word.polish
                 : "\(word.hanzi) \(word.pinyin)")
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 50)

            ForEach(options, id: \.id) { option in
                Button {
                    guard !isAnswered else { return }
                    selectedID = option.id
                    isAnswered = true
                    isCorrect = (option.id == word.id)
                    onResult(isCorrect)
                } label: {
                    Text(direction == .plToZh
                         ? "\(option.hanzi) \(option.pinyin)"
                         : option.polish)
                    .padding()
                    .frame(maxWidth: .infinity)

                }
                .buttonStyle(.glass)
                .glassEffect(.regular.tint(backgroundColor(for: option)).interactive())

            }
        }
        .padding()
        .task(id: word.id) {
            if options.isEmpty {
                generateOptions()
            }
        }
        .onChange(of: word.id) { _ in
            reset()
            generateOptions()
        }
    }

    // MARK: - Helpers

    private func generateOptions() {
        var pool = allWords.filter { $0.id != word.id }

        if pool.count < 3 {
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
        isCorrect = false
    }

    private func backgroundColor(for option: WordEntry) -> Color {
        guard isAnswered else {
            return Color.gray.opacity(0.15)
        }

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
