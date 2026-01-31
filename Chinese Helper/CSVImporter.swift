//
//  CSVImporter.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import Foundation

struct CSVRow {
    let polish: String
    let pinyin: String
    let hanzi: String
    let category: String
}

enum CSVImporter {

    static func loadRows(from url: URL) throws -> [CSVRow] {
        let data = try Data(contentsOf: url)
        let text = String(decoding: data, as: UTF8.self)

        var lines = text.split(whereSeparator: \.isNewline).map(String.init)
        guard !lines.isEmpty else { return [] }

        // Usuń nagłówek jeśli wygląda jak nagłówek
        let header = lines[0].lowercased()
        if header.contains("polish") && header.contains("hanzi") {
            lines.removeFirst()
        }

        return lines.compactMap { line in
            // Prosty parser: pola bez przecinków w środku.
            // Jeśli będziesz mieć "pola, z przecinkami" — dopiszemy pełny parser CSV.
            let cols = line.split(separator: ",", omittingEmptySubsequences: false)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

            guard cols.count >= 3 else { return nil }

            let category = cols.count >= 4 && !cols[3].isEmpty ? cols[3] : "General"
            return CSVRow(polish: cols[0], pinyin: cols[1], hanzi: cols[2], category: category)
        }
    }
}
