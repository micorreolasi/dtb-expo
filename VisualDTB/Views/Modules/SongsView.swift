import SwiftUI

struct SongsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.layoutInfo) var layout

    private var activeSong: Song? {
        appState.songsList.first(where: { $0.id == appState.selectedSongId })
    }

    private var filteredSongs: [Song] {
        if appState.songSearch.isEmpty { return appState.songsList }
        return appState.songsList.filter { $0.title.localizedCaseInsensitiveContains(appState.songSearch) }
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
    }

    // MARK: - Columna Izquierda: Lista de Canciones
    private var leftColumnView: some View {
        VStack(spacing: 0) {
            // Buscador + Botón "+ Nueva"
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.muted)
                DarkTextField(placeholder: "Buscar canción...", text: $appState.songSearch)
                Button {
                    appState.newSongTitle = ""
                    appState.newSongLyrics = ""
                    appState.isAddingSong = true
                } label: {
                    Text("+ Nueva")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.green, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(Theme.panel)
            .bottomBorder(Theme.border)

            // Lista de canciones
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredSongs) { song in
                        let isExpanded = appState.selectedSongId == song.id

                        VStack(spacing: 0) {
                            HStack {
                                Button {
                                    if isExpanded {
                                        appState.selectedSongId = ""
                                    } else {
                                        appState.selectedSongId = song.id
                                        appState.isAddingSong = false
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "music.note")
                                            .font(.system(size: 14))
                                            .foregroundStyle(isExpanded ? Theme.sky : Theme.muted)
                                        Text(song.title)
                                            .font(.system(size: 13, weight: isExpanded ? .bold : .medium))
                                            .foregroundStyle(isExpanded ? Theme.sky : Theme.text)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)

                                HStack(spacing: 6) {
                                    // Botón añadir al culto
                                    Button {
                                        appState.quickAddSongToActiveService(song)
                                    } label: {
                                        HStack(spacing: 2) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 10))
                                            Text("Culto")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundStyle(Theme.lightBlue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .chip(fill: Theme.blue.opacity(0.15), border: Theme.blue.opacity(0.3), radius: 4)
                                    }
                                    .buttonStyle(.plain)

                                    // Botones de editar / borrar si es canción personalizada
                                    if song.id.starts(with: "custom") {
                                        Button {
                                            appState.editSong(id: song.id)
                                        } label: {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 13))
                                                .foregroundStyle(Theme.lightBlue)
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            appState.deleteSong(id: song.id)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 13))
                                                .foregroundStyle(Theme.red)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(isExpanded ? Theme.sky : Theme.dim)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(isExpanded ? Theme.panel : Theme.bg)

                            // Desglose de estrofas cuando está expandido
                            if isExpanded {
                                VStack(spacing: 3) {
                                    ForEach(Array(song.stanzas.enumerated()), id: \.offset) { stIdx, stanza in
                                        let isCurrentStanza = appState.playlist?.currentItem == stanza.text

                                        Button {
                                            let items = song.stanzas.map { $0.text }
                                            appState.playlist = Playlist(items: items, currentIndex: stIdx)
                                            appState.projection = .text(items[stIdx])
                                        } label: {
                                            HStack(spacing: 8) {
                                                Text(stanza.name)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(Theme.sky)
                                                    .frame(width: 65, alignment: .leading)
                                                Text(stanza.text.replacingOccurrences(of: "\n", with: " "))
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(Theme.muted)
                                                    .lineLimit(1)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .chip(fill: isCurrentStanza ? Theme.blue.opacity(0.35) : Theme.panel, radius: 6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(8)
                                .background(Theme.bgDeep)
                            }
                        }
                        .bottomBorder(Theme.panel)
                    }
                }
            }
        }
    }

    // MARK: - Columna Derecha: Estrofas o Formulario de Creación
    private var rightColumnView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if appState.isAddingSong {
                createSongFormView
            } else if let song = activeSong {
                VStack(spacing: 0) {
                    HStack {
                        Text(song.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            appState.quickAddSongToActiveService(song)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 13))
                                Text("Añadir al Culto")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(Theme.lightBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .chip(fill: Theme.blue.opacity(0.15), border: Theme.blue.opacity(0.3), radius: 6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .bottomBorder()

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(song.stanzas.enumerated()), id: \.offset) { index, stanza in
                                let isCurrentStanza = appState.playlist?.currentItem == stanza.text

                                HStack(alignment: .top, spacing: 14) {
                                    Text(stanza.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Theme.blue)
                                        .frame(width: 75, alignment: .leading)

                                    Text(stanza.text)
                                        .font(.system(size: 15))
                                        .foregroundStyle(Theme.text)
                                        .lineSpacing(4)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(14)
                                .chip(
                                    fill: Theme.panel,
                                    border: isCurrentStanza ? Theme.blue : nil,
                                    radius: 8,
                                    lineWidth: 2
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    let items = song.stanzas.map { $0.text }
                                    appState.playlist = Playlist(items: items, currentIndex: index)
                                    appState.projection = .text(items[index])
                                }
                            }
                        }
                        .padding(14)
                    }
                }
            } else {
                EmptyStateView(
                    icon: "music.note.list",
                    title: "Ninguna canción seleccionada",
                    message: "Toca una canción en la columna izquierda para desplegarla y proyectar sus estrofas."
                )
            }
        }
    }

    private var createSongFormView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Crear Nueva Canción")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Text("Pega la letra completa. Un doble salto de línea (espacio vacío) creará una estrofa separada automáticamente.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)

                DarkTextField(placeholder: "Título de la canción...", text: $appState.newSongTitle)
                    .padding(12)
                    .chip(fill: Theme.panel, border: Theme.border, radius: 8)

                DarkTextEditor(
                    placeholder: "Letra de la canción...\n\n(Doble 'Enter' para separar estrofas)",
                    text: $appState.newSongLyrics
                )
                .frame(minHeight: 250)
                .padding(12)
                .chip(fill: Theme.panel, border: Theme.border, radius: 8)

                HStack(spacing: 12) {
                    ProjectButton(title: "Guardar Canción", color: Theme.green) {
                        appState.saveSong()
                    }
                    ProjectButton(title: "Cancelar", color: Theme.red, expand: false) {
                        appState.isAddingSong = false
                    }
                }
            }
            .padding(16)
        }
    }
}
