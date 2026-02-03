//
//  WordEntry.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import Foundation
import SwiftData

@Model
final class WordEntry {
    @Attribute(.unique) var id: UUID

    var polish: String
    var pinyin: String
    var hanzi: String
    var category: String
    var easeFactor: Double = 2.5
    var nextReview: Date = Date.distantPast
    var easyCount: Int = 0
    var seenCount: Int = 0
    var isLearned: Bool = false

    /// Ścieżka względna do pliku MP3 w Application Support, np. "audio/<uuid>.mp3"
    var audioRelativePath: String?

    var createdAt: Date

    init(polish: String, pinyin: String, hanzi: String, category: String = "General") {
        self.id = UUID()
        self.polish = polish
        self.pinyin = pinyin
        self.hanzi = hanzi
        self.category = category
        self.audioRelativePath = nil
        self.createdAt = Date()
        self.easeFactor = 2.5
        self.nextReview = Date()
    }
}
