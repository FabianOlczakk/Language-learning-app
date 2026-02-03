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

    @Published var queue: [WordEntry] = []

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
        let source = shuffleNewBatch ? allWords.shuffled() : allWords
        queue = Array(source.prefix(max(1, batchSize)))

        for w in queue {
            w.easyCount = 0
            w.seenCount = 0
            w.isLearned = false
        }
    }

    func current() -> WordEntry? { queue.first }

    func answerEasy() {
        guard let w = queue.first else { return }
        w.seenCount += 1
        w.easyCount += 1
        queue.removeFirst()

        let required = requiredEasy(for: w)
        if w.easyCount >= required && w.seenCount >= minShowsPerCard {
            confirm(w)
        } else {
            queue.append(w)
        }
    }

    func answerMedium() {
        guard let w = queue.first else { return }
        w.seenCount += 1
        queue.removeFirst()

        // medium: przerzucamy na koniec, ale wymaga mediumRequiredEasy easy-tapów do zaliczenia
        // (wymaganie realizuje requiredEasy(for:))
        queue.append(w)
    }

    func answerHard() {
        guard let w = queue.first else { return }
        w.seenCount += 1
        queue.removeFirst()

        let idx = min(max(1, hardReinsertOffset), queue.count)
        queue.insert(w, at: idx)
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
