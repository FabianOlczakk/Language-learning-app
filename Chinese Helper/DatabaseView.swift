//
//  StudyView.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import SwiftUI
import SwiftData

private let reviewDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
}()

struct DatabaseView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \WordEntry.createdAt, order: .reverse) private var words: [WordEntry]
    @StateObject private var player = AudioPlayer()
    @State private var fetchCount: Int = -1
    @State private var fetchError: String = ""

    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredWords) { w in
                    WordRow(
                        w: w,
                        onPlay: { play(w) },
                        onDelete: delete
                    )
                }
                .onDelete(perform: deleteAtOffsets)
            }
            .navigationTitle("Words")
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Categorie", selection: $selectedCategory) {
                            Text("All").tag("All")
                            ForEach(allCategories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .task {
                do {
                    fetchCount = try ctx.fetchCount(FetchDescriptor<WordEntry>())
                    fetchError = ""
                } catch {
                    fetchCount = -1
                    fetchError = "Fetch error: \(error.localizedDescription)"
                }
            }
        }
    }

    private var allCategories: [String] {
        let set = Set(words.map { $0.category })
        return set.sorted()
    }

    private var filteredWords: [WordEntry] {
        var arr = words

        if selectedCategory != "All" {
            arr = arr.filter { $0.category == selectedCategory }
        }

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            arr = arr.filter {
                $0.polish.lowercased().contains(q) ||
                $0.pinyin.lowercased().contains(q) ||
                $0.hanzi.lowercased().contains(q) ||
                $0.category.lowercased().contains(q)
            }
        }

        return arr
    }

    func play(_ w: WordEntry) {
        guard let rel = w.audioRelativePath else { return }
        do {
            let url = try AudioStore.resolve(relativePath: rel)
            player.play(url: url)
        } catch {
            print("Resolve audio error:", error)
        }
    }
    
    private func delete(_ w: WordEntry) {
        ctx.delete(w)
        try? ctx.save()
    }

    private func deleteAtOffsets(offsets: IndexSet) {
        for idx in offsets {
            let w = filteredWords[idx]
            ctx.delete(w)
        }
        try? ctx.save()
    }
}

struct WordRow: View {
    let w: WordEntry
    let onPlay: () -> Void
    let onDelete: (WordEntry) -> Void
    @State private var animatePlay: Bool = false

    private var statusText: String {
        if w.repetition == 0 {
            return "New"
        }
        if w.nextReview <= Date() {
            return "Due"
        }
        return "Scheduled"
    }

    private var statusIcon: String {
        switch statusText {
        case "New": return "sparkles"
        case "Due": return "clock.badge.exclamationmark"
        default: return "calendar"
        }
    }

    private var statusColor: Color {
        switch statusText {
        case "New": return .blue
        case "Due": return .orange
        default: return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(w.hanzi)
                    .font(.title2)
                Spacer()
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

            Text("\(w.polish) • \(w.pinyin)")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label(statusText, systemImage: statusIcon)
                    .font(.caption)
                    .foregroundStyle(statusColor)

                Text("Reps: \(w.repetition)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Next: \(reviewDateFormatter.string(from: w.nextReview))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    DatabaseView()
}
