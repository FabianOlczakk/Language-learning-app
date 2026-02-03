//
//  Untitled.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import Foundation
import SwiftUI

actor GoogleTranslateTTSService {

    @AppStorage("ttsDelaySeconds") private var ttsDelaySeconds: Double = 5
    private var lastRequestTime: Date? = nil

    func synthesize(text: String, lang: String = "zh-CN") async throws -> Data {

        // RATE LIMIT
        if let last = lastRequestTime {
            let elapsed = Date().timeIntervalSince(last)
            let wait = ttsDelaySeconds - elapsed
            if wait > 0 {
                try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
        }
        lastRequestTime = Date()

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
