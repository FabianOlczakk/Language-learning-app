//
//  AudioPlayer.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import Foundation
import AVFAudio

@MainActor
final class AudioPlayer: ObservableObject {
    private var player: AVAudioPlayer?

    func play(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Audio play error:", error)
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
