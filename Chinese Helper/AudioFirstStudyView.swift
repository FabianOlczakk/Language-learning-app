import SwiftUI
import SwiftData

struct AudioFirstStudyView: View {
    let word: WordEntry
    let audioPlayer: AudioPlayer
    let onResult: (Bool) -> Void   // true = correct, false = wrong
    let direction: StudyView.StudyDirection
    
    @Query private var allWords: [WordEntry]

    @State private var options: [WordEntry] = []
    @State private var selectedID: UUID? = nil
    @State private var isAnswered = false
    
    @State private var finalCorrectID: UUID? = nil
    
    @State private var animatePlay = false

    var body: some View {
        VStack(spacing: 24) {

            // Play audio
            Button {
                withAnimation(.easeOut(duration: 0.3)) {
                    animatePlay = true
                }
                playAudio()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animatePlay = false
                }
            } label: {
                Image(systemName: animatePlay ? "speaker.wave.2" : "speaker.wave.2.fill")
                    .font(.system(size: 48))
                    .scaleEffect(animatePlay ? 1.3 : 1.0)
                    .foregroundStyle(animatePlay ? .blue : .primary)
                    .animation(.easeInOut(duration: 0.15), value: animatePlay)
            }
            .padding(.bottom, 20)

            // Meaning options (Polish)
            ForEach(options, id: \.id) { option in
                Button {
                    guard !isAnswered else { return }
                    selectedID = option.id
                    finalCorrectID = word.id
                    isAnswered = true
                    onResult(option.id == word.id)
                } label: {
                    Text(direction == .zhToPl
                         ? option.polish
                         : "\(option.hanzi) \(option.pinyin)")
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .glassEffect(.regular.tint(backgroundColor(for: option)).interactive())
            }
        }
        .padding()
        .task(id: word.id) {
            reset()
            generateOptions()
            playAudio()
        }
    }

    // MARK: - Helpers

    private func generateOptions() {
        let others = allWords.filter { $0.id != word.id }.shuffled()
        let distractors = Array(others.prefix(3))
        options = (distractors + [word]).shuffled()
    }

    private func reset() {
        selectedID = nil
        finalCorrectID = nil
        isAnswered = false
    }

    private func backgroundColor(for option: WordEntry) -> Color {
        guard isAnswered else {
            return Color.gray.opacity(0.15)
        }

        if option.id == finalCorrectID {
            return Color.green.opacity(0.3)
        }

        if option.id == selectedID {
            return Color.red.opacity(0.3)
        }

        return Color.gray.opacity(0.15)
    }

    private func playAudio() {
        if let rel = word.audioRelativePath,
           let url = try? AudioStore.resolve(relativePath: rel) {
            audioPlayer.play(url: url)
        }
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([WordEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    let ctx = container.mainContext

    let word = WordEntry(
        polish: "apple",
        pinyin: "píngguǒ",
        hanzi: "苹果"
    )

    let other1 = WordEntry(
        polish: "banana",
        pinyin: "xiāngjiāo",
        hanzi: "香蕉"
    )

    let other2 = WordEntry(
        polish: "orange",
        pinyin: "chéngzi",
        hanzi: "橙子"
    )

    let other3 = WordEntry(
        polish: "pear",
        pinyin: "lí",
        hanzi: "梨"
    )

    // side-effects – MUSI być opakowane
    let _ = {
        ctx.insert(word)
        ctx.insert(other1)
        ctx.insert(other2)
        ctx.insert(other3)
    }()

    AudioFirstStudyView(
        word: word,
        audioPlayer: AudioPlayer(),
        onResult: { correct in
            print("Result:", correct)
        },
        direction: .zhToPl
    )
    .modelContainer(container)
    .padding()
}
