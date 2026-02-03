//
//  SentenceStudyView.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//


import SwiftUI

struct SentenceStudyView: View {
    let word: WordEntry
    let direction: StudyView.StudyDirection
    let onAnswered: (Bool) -> Void

    @State private var input: String = ""
    @State private var checked: Bool = false
    @State private var correct: Bool = false
    
    @FocusState private var inputFocused: Bool
    
    private let accentChars = ["ā","á","ǎ","à","ē","é","ě","è","ī","í","ǐ","ì","ō","ó","ǒ","ò","ū","ú","ǔ","ù","ü"]

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(prompt)
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
            
            GlassEffectContainer {
                HStack {
                    TextField("Your answer…", text: $input)
                        .focused($inputFocused)
                        .disabled(checked)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.asciiCapable)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(accentChars, id: \.self) { char in
                                            Button(char) {
                                                input.append(char)
                                            }
                                            .buttonStyle(.glass)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .glassEffect()
                    
                    Button("Check") {
                        guard !checked else { return }
                        checked = true
                        inputFocused = false
                        correct = normalized(input) == normalized(expected)
                        onAnswered(correct)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || checked)
                }
            }
            
            if checked {
                Text(correct ? "Correct" : "Correct answer: \(expected)")
                    .foregroundStyle(correct ? .green : .red)
            }

        }
        .padding()
        .onChange(of: word.id) { _ in
            input = ""
            checked = false
            correct = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                inputFocused = true
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                inputFocused = true
            }
        }
    }

    private var prompt: String {
        direction == .plToZh ? word.polish : "\(word.hanzi) \(word.pinyin)"
    }

    private var expected: String {
        direction == .plToZh ? word.pinyin : word.polish
    }

    private func normalized(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
         .lowercased()
    }
}

#Preview {
    let word = WordEntry(
        polish: "hello",
        pinyin: "nǐ hǎo",
        hanzi: "你好",
        category: "greetings"
    )

    SentenceStudyView(
        word: word,
        direction: .plToZh,
        onAnswered: { result in
            print("Answered:", result)
        }
    )
    .padding()
}
