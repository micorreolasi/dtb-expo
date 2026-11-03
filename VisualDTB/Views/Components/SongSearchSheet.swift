import SwiftUI

// MARK: - Modelo de resultado de búsqueda de canción

struct SongSearchResult: Identifiable, Hashable {
    let songId: String
    let songTitle: String
    let stanzaIndex: Int // 0-based
    let stanzaName: String
    let stanzaText: String

    var id: String { "\(songId)|\(stanzaIndex)" }
}

enum SongSearchScope: String, CaseIterable {
    case all = "Todo"
    case lyricsOnly = "Solo letra"
    case titleOnly = "Solo título"
}

// MARK: - Motor de búsqueda en canciones

enum SongSearchEngine {
    static let foldOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
    static let locale = Locale(identifier: "es")

    static func fold(_ s: String) -> String {
        s.folding(options: foldOptions, locale: locale)
    }

    static func search(
        query rawQuery: String,
        in songs: [Song],
        scope: SongSearchScope,
        wholeWord: Bool,
        limit: Int
    ) -> (results: [SongSearchResult], total: Int) {
        let query = fold(rawQuery.trimmingCharacters(in: .whitespacesAndNewlines))
        guard query.count >= 2 else { return ([], 0) }

        var regex: NSRegularExpression? = nil
        if wholeWord {
            let pattern = "(?<![\\p{L}\\p{N}])" + NSRegularExpression.escapedPattern(for: query) + "(?![\\p{L}\\p{N}])"
            regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        }

        func textMatches(_ text: String) -> Bool {
            let folded = fold(text)
            if let regex {
                return regex.firstMatch(in: folded, range: NSRange(location: 0, length: (folded as NSString).length)) != nil
            } else {
                return folded.contains(query)
            }
        }

        var results: [SongSearchResult] = []
        var total = 0

        for song in songs {
            if Task.isCancelled { return (results, total) }
            let titleMatches = (scope == .all || scope == .titleOnly) && textMatches(song.title)

            if scope == .titleOnly {
                guard titleMatches, let first = song.stanzas.first else { continue }
                total += 1
                if results.count < limit {
                    results.append(SongSearchResult(
                        songId: song.id,
                        songTitle: song.title,
                        stanzaIndex: 0,
                        stanzaName: first.name,
                        stanzaText: first.text
                    ))
                }
                continue
            }

            var matchedAnyStanza = false
            for (sIdx, stanza) in song.stanzas.enumerated() {
                if textMatches(stanza.text) {
                    matchedAnyStanza = true
                    total += 1
                    if results.count < limit {
                        results.append(SongSearchResult(
                            songId: song.id,
                            songTitle: song.title,
                            stanzaIndex: sIdx,
                            stanzaName: stanza.name,
                            stanzaText: stanza.text
                        ))
                    }
                }
            }

            // Si coincidió en el título pero no en la letra (y el alcance es "Todo"), incluir la primera estrofa
            if !matchedAnyStanza, titleMatches, let first = song.stanzas.first {
                total += 1
                if results.count < limit {
                    results.append(SongSearchResult(
                        songId: song.id,
                        songTitle: song.title,
                        stanzaIndex: 0,
                        stanzaName: first.name,
                        stanzaText: first.text
                    ))
                }
            }
        }
        return (results, total)
    }
}

// MARK: - Modal de búsqueda en Canciones

struct SongSearchSheet: View {
    let songs: [Song]
    let onSelect: (SongSearchResult) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var scope: SongSearchScope = .all
    @State private var wholeWord = false
    @State private var results: [SongSearchResult] = []
    @State private var totalMatches = 0
    @State private var isSearching = false
    @FocusState private var fieldFocused: Bool

    private let resultLimit = 500

    private struct SearchKey: Equatable {
        let query: String
        let scope: SongSearchScope
        let wholeWord: Bool
    }

    private var searchKey: SearchKey {
        SearchKey(query: query, scope: scope, wholeWord: wholeWord)
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchField
            filterChips
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
            Image(systemName: "music.note.list")
                .foregroundStyle(Theme.blue)
            Text("Buscar en Canciones")
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
            TextField("", text: $query, prompt: Text("Escribe una palabra o frase de la canción...").foregroundColor(Theme.dim))
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

    // MARK: Filtros (Todo / Solo letra / Solo título + Palabra completa)
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SongSearchScope.allCases, id: \.self) { s in
                    chip(title: s.rawValue, isOn: scope == s) {
                        scope = s
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
            } else if songs.isEmpty {
                Text("No hay canciones cargadas.")
            } else if trimmedQuery.count < 2 {
                Text("Escribe al menos 2 letras para buscar en \(songs.count) canciones.")
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
                                Text(BibleSearchEngine.highlighted(r.songTitle, query: trimmedQuery))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.blue)
                                    .lineLimit(1)
                                Text(r.stanzaName)
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
                            Text(BibleSearchEngine.highlighted(r.stanzaText, query: trimmedQuery))
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
            try await Task.sleep(nanoseconds: 250_000_000)
        } catch { return }

        isSearching = true
        let source = songs
        let currentScope = scope
        let whole = wholeWord
        let limit = resultLimit
        let output = await Task.detached(priority: .userInitiated) {
            SongSearchEngine.search(query: q, in: source, scope: currentScope, wholeWord: whole, limit: limit)
        }.value

        if Task.isCancelled { return }
        results = output.results
        totalMatches = output.total
        isSearching = false
    }
}

