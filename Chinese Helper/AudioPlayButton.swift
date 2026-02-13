//
//  AudioPlayButton.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 05/02/2026.
//


import SwiftUI

struct AudioPlayButton: View {
    let onPlay: () -> Void
    var size: CGFloat = 25

    @State private var animatePlay = false

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: 0.3)) {
                animatePlay = true
            }

            onPlay()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animatePlay = false
            }
        } label: {
            Image(systemName: animatePlay ? "speaker.wave.2" : "speaker.wave.2.fill")
                .font(.system(size: size))
                .scaleEffect(animatePlay ? 1.3 : 1.0)
                .foregroundStyle(animatePlay ? .blue : .primary)
                .animation(.easeInOut(duration: 0.15), value: animatePlay)
        }
        .buttonStyle(.plain)
    }
}
