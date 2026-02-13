//
//  LearningSession.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import Foundation
import SwiftData
import SwiftUI

final class LearningSession: ObservableObject {

    //@Published var queue: [WordEntry] = []
    @Published var queue: [BatchItem] = []

    // SETTINGS (domyślne wartości)
    var batchSize: Int = 15
    var minShowsPerCard: Int = 2
    var easyRequiredEasy: Int = 2
    var mediumRequiredEasy: Int = 3
    var hardRequiredEasy: Int = 3
    var hardReinsertOffset: Int = 4
    var shuffleNewBatch: Bool = true

    init(words: [WordEntry] = []) {
        if !words.isEmpty {
            startNewSession(from: words)
        }
    }

    func applySettings(
        batchSize: Int,
        minShowsPerCard: Int,
        easyRequiredEasy: Int,
        mediumRequiredEasy: Int,
        hardRequiredEasy: Int,
        hardReinsertOffset: Int,
        shuffleNewBatch: Bool
    ) {
        self.batchSize = batchSize
        self.minShowsPerCard = minShowsPerCard
        self.easyRequiredEasy = easyRequiredEasy
        self.mediumRequiredEasy = mediumRequiredEasy
        self.hardRequiredEasy = hardRequiredEasy
        self.hardReinsertOffset = hardReinsertOffset
        self.shuffleNewBatch = shuffleNewBatch
    }

    func startNewSession(from allWords: [WordEntry]) {
        let shuffled = shuffleNewBatch ? allWords.shuffled() : allWords
        let slice = Array(shuffled.prefix(batchSize))

        queue = slice.map {
            BatchItem(id: $0.id, word: $0, mark: .none)
        }

        for item in queue {
            item.word.easyCount = 0
            item.word.seenCount = 0
            item.word.isLearned = false
        }
    }

    func current() -> WordEntry? {
        queue.first?.word
    }

    func answerEasy() {
        guard var item = queue.first else { return }

        item.mark = .easy
        item.word.seenCount += 1
        item.word.easyCount += 1

        queue.removeFirst()

        if item.word.easyCount >= requiredEasy(for: item.word),
           item.word.seenCount >= minShowsPerCard {
            confirm(item.word)
        } else {
            queue.append(item)   // ⬅️ kwadrat idzie na koniec
        }
    }

    func answerMedium() {
        guard var item = queue.first else { return }

        item.mark = .medium
        item.word.seenCount += 1

        queue.removeFirst()
        queue.append(item)
    }

    func answerHard() {
        guard var item = queue.first else { return }

        item.mark = .hard
        item.word.seenCount += 1

        queue.removeFirst()
        let idx = min(hardReinsertOffset, queue.count)
        queue.insert(item, at: idx)
    }

    private func requiredEasy(for w: WordEntry) -> Int {
        // jeśli był hard/medium wcześniej, easyCount będzie rosło i porównujemy do ustawionych progów
        // prosta logika:
        // - jeśli seenCount == 1: wymagaj easyRequiredEasy
        // - jeśli użytkownik wciska medium/hard, to i tak musi dobić do mediumRequiredEasy/hardRequiredEasy
        //   (w praktyce użyjemy max zależnie od historii – brak historii, więc bazujemy na seenCount)
        if w.seenCount == 1 { return easyRequiredEasy }
        return mediumRequiredEasy // sensownie: po pierwszym pokazie wymagaj większej liczby easy
    }

    private func confirm(_ w: WordEntry) {
        w.isLearned = true
        w.nextReview = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    }

    var isFinished: Bool { queue.isEmpty }
}

enum BatchMark {
    case none
    case hard
    case medium
    case easy

    var color: Color {
        switch self {
        case .none:   return Color.gray.opacity(0.3)
        case .hard:   return .red
        case .medium: return .orange
        case .easy:   return .green
        }
    }
}

struct BatchItem: Identifiable {
    let id: UUID
    let word: WordEntry
    var mark: BatchMark = .none
}
