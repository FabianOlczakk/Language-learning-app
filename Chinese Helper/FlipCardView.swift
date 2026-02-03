//
//  FlipCardView.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import SwiftUI

struct FlipCardView: View {
    let front: String
    let back: String
    let audioOnFront: Bool
    let onPlay: (() -> Void)?

    @State private var flipped = false
    @State private var animatePlay: Bool = false

    var body: some View {
        ZStack {
            // FRONT (Polish)
            cardSide(text: front, showAudio: audioOnFront)
                .opacity(flipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(flipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )

            // BACK (Chinese + audio)
            cardSide(text: back, showAudio: !audioOnFront)
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(flipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                flipped.toggle()
            }
        }
        .onChange(of: flipped) { newValue in
            let audioSideIsVisible =
                (audioOnFront && !newValue) ||
                (!audioOnFront && newValue)

            guard audioSideIsVisible else { return }

            Task {
                try? await Task.sleep(nanoseconds: 150_000_000)
                onPlay?()
                withAnimation(.easeOut(duration: 0.3)) {
                    animatePlay = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animatePlay = false
                }
            }
        }
    }

    @ViewBuilder
    private func cardSide(text: String, showAudio: Bool) -> some View {
        VStack(spacing: 16) {
            Text(text)
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)

            if showAudio, let onPlay {
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
                        .font(.title2)
                        .scaleEffect(animatePlay ? 1.3 : 1.0)
                        .foregroundStyle(animatePlay ? .blue : .primary)
                        .animation(.easeInOut(duration: 0.15), value: animatePlay)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 220)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
        )
    }
}
