//
//  LearningCard.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

final class LearningSession: ObservableObject {

    @Published var queue: [WordEntry] = []
    let batchSize = 15

    init(words: [WordEntry]) {
        startNewSession(from: words)
    }

    func startNewSession(from allWords: [WordEntry]) {
        let shuffled = allWords.shuffled()
        queue = Array(shuffled.prefix(batchSize))

        for w in queue {
            w.easyCount = 0
            w.seenCount = 0
            w.isLearned = false
        }
    }

    func current() -> WordEntry? {
        queue.first
    }

    func answerEasy() {
        guard let w = queue.first else { return }
        w.seenCount += 1
        w.easyCount += 1

        queue.removeFirst()

        if w.easyCount >= requiredEasy(for: w) && w.seenCount >= 2 {
            confirm(w)
        } else {
            queue.append(w)
        }
    }

    func answerMedium() {
        guard let w = queue.first else { return }
        w.seenCount += 1
        queue.removeFirst()
        queue.append(w)
    }

    func answerHard() {
        guard let w = queue.first else { return }
        w.seenCount += 1
        queue.removeFirst()

        let idx = min(4, queue.count)
        queue.insert(w, at: idx)
    }

    private func requiredEasy(for w: WordEntry) -> Int {
        return w.seenCount == 1 ? 2 : 3
    }

    private func confirm(_ w: WordEntry) {
        w.isLearned = true
        w.nextReview = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    }

    var isFinished: Bool {
        queue.isEmpty
    }
}
