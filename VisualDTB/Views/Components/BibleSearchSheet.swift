import SwiftUI

// MARK: - Modelo de resultado

struct BibleSearchResult: Identifiable, Hashable {
    let bibleId: String
    let bibleName: String
    let book: String
    let chapter: Int   // 1-based
    let verse: Int     // 1-based
    let text: String

    var id: String { "\(bibleId)|\(book)|\(chapter)|\(verse)" }
    var reference: String { "\(book) \(chapter):\(verse)" }
}

// MARK: - Motor de búsqueda

enum BibleSearchEngine {
    static let foldOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
    static let locale = Locale(identifier: "es")

    static func fold(_ s: String) -> String {
        s.folding(options: foldOptions, locale: locale)
    }

    /// Busca `query` en todas las Biblias dadas. Ignora mayúsculas y acentos.
    /// Devuelve como máximo `limit` resultados y el total real de coincidencias.
    static func search(
        query rawQuery: String,
        in bibles: [LoadedBible],
        wholeWord: Bool,
        limit: Int
    ) -> (results: [BibleSearchResult], total: Int) {
        let query = fold(rawQuery.trimmingCharacters(in: .whitespacesAndNewlines))
        guard query.count >= 2 else { return ([], 0) }

        var regex: NSRegularExpression? = nil
        if wholeWord {
            let pattern = "(?<![\\p{L}\\p{N}])" + NSRegularExpression.escapedPattern(for: query) + "(?![\\p{L}\\p{N}])"
            regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        }

        var results: [BibleSearchResult] = []
        var total = 0

        for bible in bibles {
            for book in bible.books {
                if Task.isCancelled { return (results, total) }
                for (cIdx, chapter) in book.chapters.enumerated() {
                    for (vIdx, verse) in chapter.enumerated() {
                        let folded = fold(verse)
                        let matches: Bool
                        if let regex {
                            matches = regex.firstMatch(in: folded, range: NSRange(location: 0, length: (folded as NSString).length)) != nil
                        } else {
                            matches = folded.contains(query)
                        }
                        guard matches else { continue }
                        total += 1
                        if results.count < limit {
                            results.append(BibleSearchResult(
                                bibleId: bible.id,
                                bibleName: bible.name,
                                book: book.name,
                                chapter: cIdx + 1,
                                verse: vIdx + 1,
                                text: verse
                            ))
                        }
                    }
                }
            }
        }
        return (results, total)
    }

    /// Texto del versículo con las coincidencias resaltadas.
    static func highlighted(_ text: String, query rawQuery: String) -> AttributedString {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return AttributedString(text) }

        var output = AttributedString()
        var cursor = text.startIndex
        while cursor < text.endIndex,
              let r = text.range(of: query, options: foldOptions, range: cursor..<text.endIndex, locale: locale) {
            output += AttributedString(String(text[cursor..<r.lowerBound]))
            var hit = AttributedString(String(text[r]))
            hit.swiftUI.foregroundColor = Color.black
            hit.swiftUI.backgroundColor = Color(hex: "#facc15")
            hit.swiftUI.font = Font.system(size: 14, weight: .bold)
            output += hit
            cursor = r.upperBound
        }
        output += AttributedString(String(text[cursor..<text.endIndex]))
        return output
    }
}

// MARK: - Modal de búsqueda

struct BibleSearchSheet: View {
    let bibles: [LoadedBible]
    let onSelect: (BibleSearchResult) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var selectedBibleIds: Set<String> = []   // vacío = Todas
    @State private var wholeWord = false
    @State private var results: [BibleSearchResult] = []
    @State private var totalMatches = 0
    @State private var isSearching = false
    @FocusState private var fieldFocused: Bool

    private let resultLimit = 500

    private struct SearchKey: Equatable {
        let query: String
        let ids: Set<String>
        let wholeWord: Bool
    }

    private var searchKey: SearchKey {
        SearchKey(query: query, ids: selectedBibleIds, wholeWord: wholeWord)
    }

    private var biblesToSearch: [LoadedBible] {
        selectedBibleIds.isEmpty ? bibles : bibles.filter { selectedBibleIds.contains($0.id) }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchField
            versionChips
            statusBar
            resultsList
        }
        .background(Theme.bg)
        .task(id: searchKey) { await runSearch() }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { fieldFocused = true }
        }
    }

    // MARK: Encabezado
    private var header: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.blue)
            Text("Buscar en la Biblia")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.text)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.muted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .bottomBorder(Theme.border)
    }

    // MARK: Campo de búsqueda
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "text.magnifyingglass")
                .foregroundStyle(Theme.muted)
            TextField("", text: $query, prompt: Text("Escribe una palabra o frase (ej. amor, fe, pastor)...").foregroundColor(Theme.dim))
                .font(.system(size: 15))
                .foregroundStyle(Theme.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.search)
                .focused($fieldFocused)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.dim)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .chip(fill: Theme.panel, border: Theme.border, radius: 8)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: Selector de versiones
    private var versionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "Todas", isOn: selectedBibleIds.isEmpty) {
                    selectedBibleIds = []
                }
                ForEach(bibles) { b in
                    chip(title: b.name, isOn: selectedBibleIds.contains(b.id)) {
                        if selectedBibleIds.contains(b.id) {
                            selectedBibleIds.remove(b.id)
                        } else {
                            selectedBibleIds.insert(b.id)
                            if selectedBibleIds.count == bibles.count { selectedBibleIds = [] }
                        }
                    }
                }

                Rectangle().fill(Theme.border).frame(width: 1, height: 20)

                chip(title: "Palabra completa", isOn: wholeWord, icon: wholeWord ? "checkmark.square.fill" : "square") {
                    wholeWord.toggle()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func chip(title: String, isOn: Bool, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.system(size: 11)) }
                Text(title).font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(isOn ? .white : Theme.textSoft)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .chip(fill: isOn ? Theme.blue : Theme.panel, border: isOn ? Theme.blue : Theme.border, radius: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: Estado
    private var statusBar: some View {
        HStack(spacing: 6) {
            if isSearching {
                ProgressView().scaleEffect(0.7)
                Text("Buscando...")
            } else if trimmedQuery.count < 2 {
                Text("Escribe al menos 2 letras para buscar.")
            } else if totalMatches == 0 {
                Text("Sin resultados.")
            } else if totalMatches > results.count {
                Text("Mostrando \(results.count) de \(totalMatches) resultados. Refina la búsqueda.")
            } else {
                Text("\(totalMatches) resultado\(totalMatches == 1 ? "" : "s")")
            }
            Spacer()
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(Theme.muted)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .bottomBorder(Theme.border)
    }

    // MARK: Resultados
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(results) { r in
                    Button {
                        onSelect(r)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(r.reference)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.blue)
                                Text(r.bibleName)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Theme.textSoft)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .chip(fill: Theme.bgDeep, border: Theme.border, radius: 4)
                                Spacer()
                                Image(systemName: "play.tv.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.muted)
                            }
                            Text(BibleSearchEngine.highlighted(r.text, query: trimmedQuery))
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.text)
                                .lineSpacing(3)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        .chip(fill: Theme.panel, radius: 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Ejecución (con debounce y cancelación)
    private func runSearch() async {
        let q = trimmedQuery
        guard q.count >= 2 else {
            results = []
            totalMatches = 0
            isSearching = false
            return
        }
        do {
            try await Task.sleep(nanoseconds: 300_000_000)
        } catch { return }

        isSearching = true
        let source = biblesToSearch
        let whole = wholeWord
        let limit = resultLimit
        let output = await Task.detached(priority: .userInitiated) {
            BibleSearchEngine.search(query: q, in: source, wholeWord: whole, limit: limit)
        }.value

        if Task.isCancelled { return }
        results = output.results
        totalMatches = output.total
        isSearching = false
    }
}
