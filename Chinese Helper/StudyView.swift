//
//  StudyView.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//
import Foundation
import SwiftData
import SwiftUI

struct StudyView: View {
    
    enum StudyMode: CaseIterable {
        case flashcards
        case multipleChoice
        case audioFirst
        case sentence
    }
    
    enum StudyDirection {
        case plToZh
        case zhToPl
    }
    
    @Environment(\.modelContext) private var ctx
    @StateObject private var audioPlayer = AudioPlayer()
    
    @Query(sort: \WordEntry.nextReview)
    private var allWords: [WordEntry]
    
    @StateObject private var session = LearningSession(words: [])
    
    @State private var currentMode: StudyMode = .flashcards
    @State private var flipped = false
    
    // odpowiedzi (blokują przejście dalej)
    @State private var multipleAnswered = false
    @State private var audioAnswered = false
    
    @AppStorage("learningDirection") private var learningDirectionRaw: String = "plToZh"
    
    @State private var didInitialSetup = false
    
    @AppStorage("modeFlashcards") private var modeFlashcards: Bool = true
    @AppStorage("modeMultipleChoice") private var modeMultipleChoice: Bool = false
    @AppStorage("modeAudioFirst") private var modeAudioFirst: Bool = false
    @AppStorage("modeSentence") private var modeSentence: Bool = false
    
    @AppStorage("batchSize") private var batchSize: Int = 15
    @AppStorage("minShowsPerCard") private var minShowsPerCard: Int = 2
    @AppStorage("easyRequiredEasy") private var easyRequiredEasy: Int = 2
    @AppStorage("mediumRequiredEasy") private var mediumRequiredEasy: Int = 3
    @AppStorage("hardRequiredEasy") private var hardRequiredEasy: Int = 3
    @AppStorage("hardReinsertOffset") private var hardReinsertOffset: Int = 4
    @AppStorage("shuffleNewBatch") private var shuffleNewBatch: Bool = true
    
    @State private var sentenceAnswered = false
    
    @State private var hardButtonCenter: CGPoint = .zero
    @State private var mediumButtonCenter: CGPoint = .zero
    @State private var easyButtonCenter: CGPoint = .zero
    @State private var showTransition = false
    @State private var transitionColor: Color = .clear
    @State private var transitionScale: CGFloat = 0.01
    @State private var transitionOrigin: CGPoint = .zero
    @State private var transitionProgress: CGFloat = 0
    @State private var transitionSeed: Int = 0
    @AppStorage("enableTransitionAnimation")
    private var enableTransitionAnimation: Bool = true
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let screenSize = geo.size

                ZStack {
                    VStack(spacing: 24) {
                        BatchProgressBar(items: session.queue)
                            .padding(.top, 10)
                        
                        Spacer()
                        
                        if let word = session.current() {
                            
                            GlassEffectContainer {
                                ZStack {
                                    switch currentMode {
                                        
                                    case .flashcards:
                                        let dir = resolvedDirection()
                                        
                                        FlipCardView(
                                            front: dir == .plToZh ? word.polish : "\(word.hanzi)\n\(word.pinyin)",
                                            back:  dir == .plToZh ? "\(word.hanzi)\n\(word.pinyin)" : word.polish,
                                            audioOnFront: dir == .zhToPl,
                                            onPlay: { playAudio(for: word) }
                                        )
                                        .id(word.id)
                                        
                                    case .multipleChoice:
                                        MultipleChoiceStudyView(
                                            word: word,
                                            onResult: { _ in
                                                multipleAnswered = true
                                            },
                                            direction: resolvedDirection()
                                        )
                                        
                                    case .audioFirst:
                                        AudioFirstStudyView(
                                            word: word,
                                            audioPlayer: audioPlayer,
                                            onResult: { _ in
                                                audioAnswered = true
                                            },
                                            direction: resolvedDirection()
                                        )
                                        
                                    case .sentence:
                                        SentenceStudyView(
                                            word: word,
                                            direction: resolvedDirection(),
                                            onAnswered: { _ in sentenceAnswered = true }
                                        )
                                    }
                                }
                                .frame(minHeight: 260)
                            }
                            
                            GlassEffectContainer {
                                HStack(spacing: 12) {
                                    
                                    Button("Hard") {
                                        guard canAdvance else { return }
                                        if enableTransitionAnimation {
                                            animateTransition(
                                                color: .red,
                                                origin: hardButtonCenter,
                                                screenSize: screenSize
                                            ) {
                                                session.answerHard()
                                                advance()
                                            }
                                        } else {
                                            session.answerHard()
                                            advance()
                                        }
                                    }
                                    .glassEffect(.regular.tint(.red))
                                    .buttonStyle(.glass)
                                    .tint(.red)
                                    .captureCenterInStudySpace { center in
                                        hardButtonCenter = center
                                    }
                                    
                                    Button("Medium") {
                                        guard canAdvance else { return }
                                        if enableTransitionAnimation {
                                            animateTransition(
                                                color: .orange,
                                                origin: mediumButtonCenter,
                                                screenSize: screenSize
                                            ) {
                                                session.answerMedium()
                                                advance()
                                            }
                                        } else {
                                            session.answerMedium()
                                            advance()
                                        }
                                    }
                                    .glassEffect(.regular.tint(.orange))
                                    .buttonStyle(.glass)
                                    .tint(.orange)
                                    .captureCenterInStudySpace { center in
                                        mediumButtonCenter = center
                                    }
                                    
                                    Button("Easy") {
                                        guard canAdvance else { return }
                                        if enableTransitionAnimation {
                                            animateTransition(
                                                color: .green,
                                                origin: easyButtonCenter,
                                                screenSize: screenSize
                                            ) {
                                                session.answerEasy()
                                                advance()
                                            }
                                        } else {
                                            session.answerEasy()
                                            advance()
                                        }
                                    }
                                    .glassEffect(.regular.tint(.green))
                                    .buttonStyle(.glass)
                                    .tint(.green)
                                    .captureCenterInStudySpace { center in
                                        easyButtonCenter = center
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Text("Remaining in batch: \(session.queue.count)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.top, 10)
                            
                        } else {
                            ProgressView("Starting next batch…")
                        }
                    }
                    .padding()
                    //.navigationTitle("Study")
                    .onAppear {
                        guard !didInitialSetup else { return }
                        didInitialSetup = true
                        
                        if session.queue.isEmpty {
                            session.applySettings(
                                batchSize: batchSize,
                                minShowsPerCard: minShowsPerCard,
                                easyRequiredEasy: easyRequiredEasy,
                                mediumRequiredEasy: mediumRequiredEasy,
                                hardRequiredEasy: hardRequiredEasy,
                                hardReinsertOffset: hardReinsertOffset,
                                shuffleNewBatch: shuffleNewBatch
                            )
                            session.startNewSession(from: allWords)
                        }
                        selectNextMode()
                    }
                    .onChange(of: session.isFinished) { finished in
                        if finished {
                            session.applySettings(
                                batchSize: batchSize,
                                minShowsPerCard: minShowsPerCard,
                                easyRequiredEasy: easyRequiredEasy,
                                mediumRequiredEasy: mediumRequiredEasy,
                                hardRequiredEasy: hardRequiredEasy,
                                hardReinsertOffset: hardReinsertOffset,
                                shuffleNewBatch: shuffleNewBatch
                            )
                            session.startNewSession(from: allWords)
                            selectNextMode()
                        }
                    }
                    .onChange(of: allWords.count) { newCount in
                        guard newCount > 0 else { return }

                        // jeśli wcześniej nie było słówek → startuj sesję
                        if session.queue.isEmpty {
                            session.applySettings(
                                batchSize: batchSize,
                                minShowsPerCard: minShowsPerCard,
                                easyRequiredEasy: easyRequiredEasy,
                                mediumRequiredEasy: mediumRequiredEasy,
                                hardRequiredEasy: hardRequiredEasy,
                                hardReinsertOffset: hardReinsertOffset,
                                shuffleNewBatch: shuffleNewBatch
                            )

                            session.startNewSession(from: allWords)
                            selectNextMode()
                        }
                    }
                    
                    let c0 = transitionColor.adjusted(brightness: +0.18, saturation: +0.15)
                    let c1 = transitionColor
                    let c2 = transitionColor.adjusted(brightness: -0.18, saturation: +0.42)

                    RadialGradient(
                        colors: [c0, c1, c2],
                        center: .center,
                        startRadius: 0,
                        endRadius: max(screenSize.width, screenSize.height)
                    )
                    .ignoresSafeArea()
                    .mask(
                        ExplosionBlob(progress: transitionProgress, seed: transitionSeed)
                            .frame(width: screenSize.width * 2,
                                   height: screenSize.height * 2)
                            .position(transitionOrigin)
                    )
                    .opacity(showTransition ? 1 : 0)  // <-- fade overlay ok
                    
                }
                .coordinateSpace(name: "studySpace")
                .onPreferenceChange(ButtonCenterPreferenceKey.self) { point in
                    easyButtonCenter = point
                    mediumButtonCenter = point
                    hardButtonCenter = point
                }
            }
        }
    }
    
    private var canAdvance: Bool {
        switch currentMode {
        case .flashcards:
            return true
        case .multipleChoice:
            return multipleAnswered
        case .audioFirst:
            return audioAnswered
        case .sentence:
            return sentenceAnswered
        }
    }
    
    private func advance() {
        multipleAnswered = false
        audioAnswered = false
        sentenceAnswered = false
        selectNextMode()
    }
    
    private func selectNextMode() {
        var enabled: [StudyMode] = []
        if modeFlashcards { enabled.append(.flashcards) }
        if modeMultipleChoice { enabled.append(.multipleChoice) }
        if modeAudioFirst { enabled.append(.audioFirst) }
        if modeSentence { enabled.append(.sentence) }
        
        if enabled.isEmpty {
            currentMode = .flashcards
        } else {
            currentMode = enabled.randomElement()!
        }
    }
    
    private func playAudio(for word: WordEntry) {
        if let rel = word.audioRelativePath,
           let url = try? AudioStore.resolve(relativePath: rel) {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            audioPlayer.play(url: url)
        }
    }
    
    private func resolvedDirection() -> StudyDirection {
        switch learningDirectionRaw {
        case "zhToPl":
            return .zhToPl
        case "random":
            return Bool.random() ? .plToZh : .zhToPl
        default:
            return .plToZh
        }
    }
    
    private func animateTransition(
        color: Color,
        origin: CGPoint,
        screenSize: CGSize,
        completion: @escaping () -> Void
    ) {
        transitionColor = color
        transitionOrigin = origin
        transitionSeed = Int.random(in: 0...10_000)

        transitionProgress = 0
        showTransition = true

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        withAnimation(.easeOut(duration: 0.32)) {
            transitionProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            withAnimation(.easeIn(duration: 0.12)) {
                showTransition = false
                transitionProgress = 0
            }
        }
    }
}

struct ButtonCenterPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

struct ExplosionBlob: Shape {
    var progress: CGFloat   // 0 → 1
    var seed: Int

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let pointsCount = 32
        let maxRadius = max(rect.width, rect.height) * progress

        // 1. Generujemy punkty
        var points: [CGPoint] = []
        for i in 0..<pointsCount {
            let angle = CGFloat(i) / CGFloat(pointsCount) * 2 * .pi
            let chaos = CGFloat((seed + i * 31) % 10) / 15
            let radius = maxRadius * (0.85 + chaos)

            points.append(
                CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
            )
        }

        // 2. Zamykamy pętlę (potrzebne do spline)
        points.append(points[0])
        points.append(points[1])
        points.insert(points[pointsCount - 1], at: 0)

        // 3. Rysujemy spline
        var path = Path()
        path.move(to: points[1])

        for i in 1..<points.count - 2 {
            let p0 = points[i - 1]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = points[i + 2]

            let control1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6,
                y: p1.y + (p2.y - p0.y) / 6
            )

            let control2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6,
                y: p2.y - (p3.y - p1.y) / 6
            )

            path.addCurve(to: p2, control1: control1, control2: control2)
        }

        path.closeSubpath()
        return path
    }
}

struct CenterInStudySpace: ViewModifier {
    let onChange: (CGPoint) -> Void

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: ButtonCenterPreferenceKey.self,
                        value: CGPoint(
                            x: geo.frame(in: .named("studySpace")).midX,
                            y: geo.frame(in: .named("studySpace")).midY
                        )
                    )
            }
        )
        .onPreferenceChange(ButtonCenterPreferenceKey.self, perform: onChange)
    }
}

extension View {
    func captureCenterInStudySpace(_ onChange: @escaping (CGPoint) -> Void) -> some View {
        self.modifier(CenterInStudySpace(onChange: onChange))
    }
}

import UIKit

extension Color {
    func adjusted(brightness delta: CGFloat, saturation satDelta: CGFloat = 0) -> Color {
        let ui = UIColor(self)

        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return self
        }

        let newB = min(max(b + delta, 0), 1)
        let newS = min(max(s + satDelta, 0), 1)

        return Color(hue: Double(h), saturation: Double(newS), brightness: Double(newB), opacity: Double(a))
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([WordEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    let ctx = container.mainContext

    let word1 = WordEntry(
        polish: "apple",
        pinyin: "píngguǒ",
        hanzi: "苹果"
    )

    let word2 = WordEntry(
        polish: "banana",
        pinyin: "xiāngjiāo",
        hanzi: "香蕉"
    )

    let word3 = WordEntry(
        polish: "orange",
        pinyin: "chéngzi",
        hanzi: "橙子"
    )

    let word4 = WordEntry(
        polish: "pear",
        pinyin: "lí",
        hanzi: "梨"
    )

    // side-effects MUSZĄ być opakowane
    let _ = {
        ctx.insert(word1)
        ctx.insert(word2)
        ctx.insert(word3)
        ctx.insert(word4)
    }()

    StudyView()
        .modelContainer(container)
}
