//
//  ImportView.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var ctx

    @State private var showImporter = false
    @State private var isWorking = false
    @State private var progressText: String = ""

    @State private var importMode: ImportMode = .skipExisting
    @State private var languageCode: String = "zh-CN"
    
    @AppStorage("ttsDelaySeconds") private var ttsDelaySeconds: Double = 5

    enum ImportMode: String, CaseIterable, Identifiable {
        case skipExisting = "Skip duplicates"
        case addDuplicates = "Add duplicates"

        var id: String { rawValue }
    }

    var body: some View {
        Group {
            Picker("Import mode", selection: $importMode) {
                ForEach(ImportMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            
            HStack {
                Text("TTS language:")
                Spacer()
                TextField("zh-CN", text: $languageCode)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(width: 90)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Request delay: \(Int(ttsDelaySeconds))s")
                Slider(
                    value: $ttsDelaySeconds,
                    in: 1...20,
                    step: 1
                ) {
                    Text("Delay")
                }
                //Text("\(Int(ttsDelaySeconds))s")
            }
            
            HStack {
                Spacer()
                Button {
                    showImporter = true
                } label: {
                    Label("Select CSV file", systemImage: "doc")
                }
                .disabled(isWorking)
                //.frame(maxWidth: .infinity, alignment: .center)
                .glassEffect(.regular.tint(.blue))
                .buttonStyle(.glass)
                .tint(.blue)
                Spacer()
            }

            if isWorking {
                ProgressView()
                Text(progressText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if !progressText.isEmpty {
                Text(progressText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
    }

    private var allowedTypes: [UTType] {
        var types: [UTType] = [.commaSeparatedText, .plainText]
        if let csv = UTType(filenameExtension: "csv") { types.append(csv) }
        return types
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        Task { @MainActor in
            do {
                let urls = try result.get()
                guard let url = urls.first else { return }

                isWorking = true
                progressText = "Opening file…"
                defer { isWorking = false }

                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }

                let rows = try CSVImporter.loadRows(from: url)
                guard !rows.isEmpty else {
                    progressText = "No data in CSV file."
                    return
                }

                progressText = "Loaded \(rows.count) rows. Importing…"

                let tts = GoogleTranslateTTSService()

                let existing = try ctx.fetch(FetchDescriptor<WordEntry>())
                let existingHanzi = Set(existing.map { $0.hanzi })

                var imported = 0
                var skipped = 0

                for (idx, r) in rows.enumerated() {
                    progressText = "(\(idx+1)/\(rows.count)) \(r.hanzi)"

                    if importMode == .skipExisting && existingHanzi.contains(r.hanzi) {
                        skipped += 1
                        continue
                    }

                    let entry = WordEntry(
                        polish: r.polish,
                        pinyin: r.pinyin,
                        hanzi: r.hanzi,
                        category: r.category
                    )

                    ctx.insert(entry)
                    try ctx.save()

                    let audioData = try await tts.synthesize(text: r.hanzi, lang: languageCode)
                    let fileURL = try AudioStore.fileURL(for: entry.id)
                    try audioData.write(to: fileURL, options: [.atomic])

                    entry.audioRelativePath = AudioStore.relativePath(for: entry.id)
                    try ctx.save()

                    imported += 1
                    let delay = UInt64(ttsDelaySeconds * 1_000)
                    try await Task.sleep(nanoseconds: delay)
                }

                let totalCount = try ctx.fetchCount(FetchDescriptor<WordEntry>())
                progressText = "Import ended successfully. Imported: \(imported), skipped: \(skipped). Total in database: \(totalCount)."
            } catch {
                progressText = "Error: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    SettingsView()
}
