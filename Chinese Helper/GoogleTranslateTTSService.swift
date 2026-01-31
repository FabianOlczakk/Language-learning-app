//
//  Untitled.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import Foundation

struct GoogleTranslateTTSService {

    /// Google Translate TTS (nieoficjalne, bez klucza API).
    /// Użycie osobiste/edukacyjne — endpoint może się zmienić w przyszłości.
    func synthesize(text: String, lang: String = "zh-CN") async throws -> Data {
        var components = URLComponents(string: "https://translate.google.com/translate_tts")!
        components.queryItems = [
            .init(name: "ie", value: "UTF-8"),
            .init(name: "client", value: "tw-ob"),
            .init(name: "tl", value: lang),
            .init(name: "q", value: text)
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        // 🔴 KLUCZOWE NAGŁÓWKI
        req.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
            forHTTPHeaderField: "User-Agent"
        )
        req.setValue("https://translate.google.com/", forHTTPHeaderField: "Referer")
        req.setValue("audio/mpeg", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard http.statusCode == 200 else {
            throw NSError(
                domain: "GoogleTTS",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode) from Google TTS"]
            )
        }

        return data
    }
}
