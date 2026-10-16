import SwiftUI
import UniformTypeIdentifiers

struct BibleView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.layoutInfo) var layout

    @State private var expandedBook: String? = "Mateo"
    @State private var showFileImporter = false

    private var activeBible: LoadedBible? {
        appState.loadedBibles.first(where: { $0.id == appState.activeBibleId }) ?? appState.loadedBibles.first
    }

    private var filteredBooks: [BibleBook] {
        guard let books = activeBible?.books else { return [] }
        if appState.bibleSearch.isEmpty { return books }
        return books.filter { $0.name.localizedCaseInsensitiveContains(appState.bibleSearch) }
    }

    private var activeBookData: BibleBook? {
        activeBible?.books.first(where: { $0.name == appState.selectedBook })
    }

    private var activeChapterVerses: [String] {
        guard let book = activeBookData else { return [] }
        let idx = appState.selectedChapter - 1
        if book.chapters.indices.contains(idx) {
            return book.chapters[idx]
        }
        return book.chapters.first ?? []
    }

    var body: some View {
        Group {
            if layout.isPortrait {
                VStack(spacing: 0) {
                    leftColumnView
                        .frame(height: layout.isCompact ? 180 : 240)
                        .bottomBorder()
                    rightColumnView
                }
            } else {
                HStack(spacing: 0) {
                    leftColumnView
                        .frame(width: min(260, layout.width * 0.32))
                        .trailingBorder()
                    rightColumnView
                }
            }
        }
        .background(Theme.bg)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json, .plainText, .data, .item, .text, UTType(filenameExtension: "json") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            handleImportBibleJSON(result)
        }
        .onAppear {
            if expandedBook == nil || (activeBookData == nil) {
                if let mateo = activeBible?.books.first(where: { $0.name.localizedCaseInsensitiveContains("Mateo") }) {
                    expandedBook = mateo.name
                    appState.selectedBook = mateo.name
                } else if let first = activeBible?.books.first {
                    expandedBook = first.name
                    appState.selectedBook = first.name
                }
            }
        }
    }

    // MARK: - Columna Izquierda: Buscador, Biblias y Libros
    private var leftColumnView: some View {
        VStack(spacing: 0) {
            // Pills de Biblias cargadas + botón Añadir JSON
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(appState.loadedBibles) { b in
                        let isSelected = b.id == appState.activeBibleId
                        Button {
                            appState.activeBibleId = b.id
                            if let first = b.books.first {
                                appState.selectedBook = first.name
                                appState.selectedChapter = 1
                                expandedBook = first.name
                            }
                        } label: {
                            Text(b.name)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .chip(
                                    fill: isSelected ? Theme.blue : Theme.panel,
                                    radius: 6
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showFileImporter = true
                    } label: {
                        Text("+ Añadir JSON")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Theme.green, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
            }
            .bottomBorder()

            // Barra de Búsqueda
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.muted)
                DarkTextField(placeholder: "Buscar libro (ej. Mateo)...", text: $appState.bibleSearch)
            }
            .padding(10)
            .background(Theme.panel)
            .bottomBorder(Theme.border)

            // Lista de Libros desplegables
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredBooks, id: \.name) { b in
                        let isExpanded = expandedBook == b.name

                        VStack(spacing: 0) {
                            Button {
                                if isExpanded {
                                    expandedBook = nil
                                } else {
                                    expandedBook = b.name
                                    appState.selectedBook = b.name
                                    appState.selectedChapter = 1
                                }
                            } label: {
                                HStack {
                                    Text(b.name)
                                        .font(.system(size: 13, weight: isExpanded ? .bold : .medium))
                                        .foregroundStyle(isExpanded ? Theme.sky : Theme.text)
                                    Spacer()
                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(isExpanded ? Theme.sky : Theme.dim)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(isExpanded ? Theme.panel : Theme.bg)
                                .overlay(alignment: .leading) {
                                    if isExpanded {
                                        Rectangle().fill(Theme.sky).frame(width: 3)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .bottomBorder(Color(hex: "#0f172a"))

                            // Cuadrícula de Capítulos si está expandido
                            if isExpanded {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: layout.isCompact ? 30 : 38), spacing: 6)], spacing: 6) {
                                    ForEach(1...b.chapters.count, id: \.self) { ch in
                                        let isCurrentCh = appState.selectedBook == b.name && appState.selectedChapter == ch
                                        Button {
                                            appState.selectedBook = b.name
                                            appState.selectedChapter = ch
                                        } label: {
                                            Text("\(ch)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(isCurrentCh ? .white : Theme.muted)
                                                .frame(width: layout.isCompact ? 28 : 36, height: layout.isCompact ? 28 : 36)
                                                .background(isCurrentCh ? Theme.blue : Theme.panel, in: Circle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(8)
                                .background(Color(hex: "#0f172a"))
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Columna Derecha: Versículos
    private var rightColumnView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let book = activeBookData {
                HStack {
                    Text("\(book.name) \(appState.selectedChapter) (\(activeBible?.name ?? "Biblia"))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.text)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .bottomBorder()

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(activeChapterVerses.enumerated()), id: \.offset) { index, verseText in
                            let verseNum = index + 1
                            let fullRef = "\(book.name) \(appState.selectedChapter):\(verseNum)"
                            let fullContent = "\(fullRef)\n\(verseText)"

                            HStack(alignment: .top, spacing: 10) {
                                Text("\(verseNum)")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Theme.blue)
                                    .frame(width: 24, alignment: .trailing)

                                Text(verseText)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.text)
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                // Botón rápido "+ Culto"
                                Button {
                                    appState.addRecentVerse(RecentVerse(ref: fullRef, text: verseText, fullContent: fullContent))
                                    appState.quickAddVerseToActiveService(ref: fullRef, text: verseText, fullContent: fullContent)
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 12))
                                        Text("+ Culto")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundStyle(Theme.amberLight)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .chip(fill: Theme.amber.opacity(0.15), border: Theme.amber.opacity(0.3), radius: 6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .chip(fill: Theme.panel, radius: 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                appState.addRecentVerse(RecentVerse(ref: fullRef, text: verseText, fullContent: fullContent))
                                let items = activeChapterVerses.enumerated().map { i, v in
                                    "\(book.name) \(appState.selectedChapter):\(i + 1)\n\(v)"
                                }
                                appState.playlist = Playlist(items: items, currentIndex: index)
                                appState.projection = .text(items[index])
                            }
                        }
                    }
                    .padding(12)
                }
            } else {
                EmptyStateView(
                    icon: "book",
                    title: "Ningún libro seleccionado",
                    message: "Toca un libro en la columna izquierda para desplegar sus capítulos y versículos."
                )
            }
        }
    }

    private func handleImportBibleJSON(_ result: Result<[URL], Error>) {
        do {
            guard let selectedURL = try result.get().first else { return }
            let data = try MediaStorage.readData(from: selectedURL)
            let books = try JSONDecoder().decode([BibleBook].self, from: data)
            guard !books.isEmpty, let firstBook = books.first, !firstBook.chapters.isEmpty else {
                appState.currentAlert = AppAlert(title: "Error", message: "El formato del archivo JSON no es compatible.")
                return
            }

            var cleanName = selectedURL.deletingPathExtension().lastPathComponent
            if cleanName.count > 12 { cleanName = String(cleanName.prefix(12)) + "..." }
            let newId = "bible-\(Int(Date().timeIntervalSince1970 * 1000))"
            let newBible = LoadedBible(id: newId, name: cleanName, books: books)
            appState.loadedBibles.append(newBible)
            appState.activeBibleId = newId
            appState.selectedBook = firstBook.name
            appState.selectedChapter = 1
            expandedBook = firstBook.name
            appState.currentAlert = AppAlert(title: "Éxito", message: "Biblia cargada correctamente.")
        } catch {
            appState.currentAlert = AppAlert(title: "Error", message: "No se pudo leer el archivo: \(error.localizedDescription)")
        }
    }
}
