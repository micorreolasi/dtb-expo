import SwiftUI

struct ServiceOrderView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.layoutInfo) var layout

    // Modales
    @State private var showNewServiceModal = false
    @State private var newServiceName = ""
    @State private var newServiceDate = "Domingo"

    @State private var showSongModal = false
    @State private var songSearch = ""

    @State private var showVerseModal = false
    @State private var verseModalTab: VerseModalTab = .recent
    @State private var selectedBook = "Mateo"
    @State private var selectedChapter = 1
    @State private var selectedVerseNum = 1

    @State private var showMediaModal = false
    @State private var showNoteModal = false
    @State private var noteTitle = "Bienvenida"
    @State private var noteContent = ""

    @State private var bgTarget: BgTarget? = nil

    enum VerseModalTab { case recent, manual }
    enum BgTarget: Equatable { case service, item(id: String) }

    private var currentService: ServiceOrder? {
        appState.services.first(where: { $0.id == appState.activeServiceId }) ?? appState.services.first
    }

    var body: some View {
        VStack(spacing: 0) {
            // 1. Selector de Cultos / Servicios (Pills)
            servicesHeaderView

            // 2. Barra de Detalles del Servicio Activo y Fondo General
            if let service = currentService {
                serviceBarView(service: service)
            }

            // 3. Botonera de Acción: Añadir a Orden de Culto
            addButtonsBarView

            // 4. Lista Cronológica de Orden de Culto
            if let service = currentService, service.items.isEmpty {
                EmptyStateView(
                    icon: "square.stack.3d.up",
                    title: "El orden de este culto está vacío",
                    message: "Usa los botones de arriba para planificar canciones, versículos bíblicos y momentos del servicio."
                )
            } else if let service = currentService {
                itemsListView(service: service)
            }
        }
        .background(Theme.bgDeep)
        // MARK: Modales
        .sheet(isPresented: $showNewServiceModal) { newServiceSheet }
        .sheet(isPresented: $showSongModal) { songSheet }
        .sheet(isPresented: $showVerseModal) { verseSheet }
        .sheet(isPresented: $showMediaModal) { mediaSheet }
        .sheet(isPresented: $showNoteModal) { noteSheet }
        .sheet(item: Binding(
            get: { bgTarget.map { IdentifiableBgTarget(target: $0) } },
            set: { bgTarget = $0?.target }
        )) { wrapper in
            backgroundPickerSheet(target: wrapper.target)
        }
    }

    // MARK: - Subvistas Principales
    private var servicesHeaderView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(appState.services) { srv in
                    let isSelected = srv.id == currentService?.id
                    HStack(spacing: 6) {
                        Button {
                            appState.activeServiceId = srv.id
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 13))
                                    .foregroundStyle(isSelected ? .white : Theme.muted)
                                Text(srv.name)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(isSelected ? .white : Theme.muted)
                                    .lineLimit(1)
                                Text("(\(srv.items.count))")
                                    .font(.system(size: 10))
                                    .foregroundStyle(isSelected ? Color(hex: "#93c5fd") : Theme.dim)
                            }
                        }
                        .buttonStyle(.plain)

                        // Botón directo para eliminar culto
                        Button {
                            confirmDeleteService(srv)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(isSelected ? Color(hex: "#fca5a5") : Theme.dim)
                                .padding(4)
                                .background(Color.black.opacity(0.2), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 8)
                    .padding(.vertical, 6)
                    .chip(
                        fill: isSelected ? Color(hex: "#1e40af") : Theme.panel,
                        border: isSelected ? Theme.blue : Theme.border,
                        radius: 8
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            confirmDeleteService(srv)
                        } label: {
                            Label("Eliminar Culto \"\(srv.name)\"", systemImage: "trash")
                        }
                    }
                }

                // Botón Nuevo Culto
                Button {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "es_ES")
                    formatter.dateFormat = "EEE d MMM"
                    newServiceName = "Culto \(formatter.string(from: Date()))"
                    newServiceDate = "Domingo"
                    showNewServiceModal = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("+ Nuevo Culto")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Theme.green, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(Theme.bg)
        .bottomBorder()
    }

    private func serviceBarView(service: ServiceOrder) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(service.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(service.date)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.lightBlue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .chip(fill: Color(hex: "#1e3a8a").opacity(0.4), radius: 4)
                }
                Text(service.items.isEmpty ? "Sin elementos agregados aún" : "\(service.items.count) momentos planificados en el culto")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.dim)
            }

            Spacer()

            HStack(spacing: 8) {
                // Selector de fondo general del culto
                Button {
                    bgTarget = .service
                } label: {
                    HStack(spacing: 6) {
                        if let uri = service.defaultBackgroundUri {
                            ProjectionImageView(uri: uri, contentMode: .fill)
                                .frame(width: 28, height: 28)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.bgDeep)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    Image(systemName: "paintpalette")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.dim)
                                }
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Fondo Culto")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textSoft)
                            Text(service.defaultBackgroundUri != nil ? "Asignado" : "A Negro")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.sky)
                        }
                    }
                    .padding(4)
                    .chip(fill: Theme.panel, border: Theme.border, radius: 6)
                }
                .buttonStyle(.plain)

                // Botón Eliminar Culto siempre accesible
                Button {
                    confirmDeleteService(service)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 12))
                        Text("Eliminar Culto")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Theme.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .chip(fill: Theme.red.opacity(0.12), border: Theme.red.opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.bgBar)
        .bottomBorder()
    }

    private var addButtonsBarView: some View {
        HStack(spacing: layout.isCompact ? 4 : 6) {
            addActionButton(title: "+ Canción", icon: "music.note", color: Theme.blue, fill: Color(hex: "#3b82f6").opacity(0.15)) {
                showSongModal = true
            }
            addActionButton(title: "+ Versículo", icon: "book.fill", color: Theme.amberLight, fill: Color(hex: "#f59e0b").opacity(0.15)) {
                verseModalTab = appState.recentVerses.isEmpty ? .manual : .recent
                showVerseModal = true
            }
            addActionButton(title: "+ Multimedia", icon: "photo.on.rectangle.angled", color: Theme.violetLight, fill: Color(hex: "#8b5cf6").opacity(0.15)) {
                showMediaModal = true
            }
            addActionButton(title: "+ Bloque", icon: "doc.text.fill", color: Theme.greenLight, fill: Color(hex: "#10b981").opacity(0.15)) {
                showNoteModal = true
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.bg)
        .bottomBorder()
    }

    private func addActionButton(title: String, icon: String, color: Color, fill: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: layout.isCompact ? 2 : 4) {
                Image(systemName: icon)
                    .font(.system(size: layout.isCompact ? 11 : 13))
                Text(title)
                    .font(.system(size: layout.isCompact ? 10 : 11, weight: .bold))
            }
            .foregroundStyle(color)
            .padding(.horizontal, layout.isCompact ? 6 : 10)
            .padding(.vertical, layout.isCompact ? 4 : 6)
            .chip(fill: fill, border: color.opacity(0.35), radius: 6)
        }
        .buttonStyle(.plain)
    }

    private func itemsListView(service: ServiceOrder) -> some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(Array(service.items.enumerated()), id: \.element.id) { index, item in
                    let isProjecting = appState.activeServiceItemId == item.id
                    let bgUri = item.backgroundUri ?? service.defaultBackgroundUri

                    HStack(spacing: 8) {
                        // 1. Número y orden
                        VStack(spacing: 2) {
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(isProjecting ? .white : Theme.muted)
                                .frame(width: 22, height: 22)
                                .background(isProjecting ? Theme.blue : Theme.panel, in: Circle())
                            if isProjecting {
                                Text("EN VIVO")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(Theme.red, in: RoundedRectangle(cornerRadius: 3))
                            }
                        }
                        .frame(width: 32)

                        // 2. Ícono de tipo
                        Image(systemName: item.type.icon)
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: item.type.colorHex))
                            .frame(width: 32, height: 32)
                            .chip(fill: Color(hex: item.type.backgroundHex), radius: 6)

                        // 3. Título y subtítulo
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isProjecting ? Theme.lightBlue : Theme.textBright)
                                .lineLimit(1)
                            Text(item.subtitle ?? item.content.replacingOccurrences(of: "\n", with: " "))
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.muted)
                                .lineLimit(1)
                        }

                        Spacer()

                        // 4. Fondo Asignado
                        Button {
                            bgTarget = .item(id: item.id)
                        } label: {
                            VStack(spacing: 2) {
                                if let uri = bgUri {
                                    ProjectionImageView(uri: uri, contentMode: .fill)
                                        .frame(width: 26, height: 26)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                } else {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Theme.bgDeep)
                                        .frame(width: 26, height: 26)
                                        .overlay {
                                            Image(systemName: "moon.fill")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Theme.dim)
                                        }
                                }
                                Text(item.backgroundUri != nil ? "Propio" : (bgUri != nil ? "Culto" : "Negro"))
                                    .font(.system(size: 8))
                                    .foregroundStyle(Theme.dim)
                            }
                        }
                        .buttonStyle(.plain)

                        // 5. Controles (Subir, Bajar, Borrar)
                        HStack(spacing: 4) {
                            Button {
                                appState.reorderItemInService(serviceId: service.id, itemId: item.id, direction: .up)
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.muted)
                                    .padding(6)
                                    .chip(fill: Theme.panel, radius: 4)
                            }
                            .buttonStyle(.plain)
                            .disabled(index == 0)
                            .opacity(index == 0 ? 0.3 : 1)

                            Button {
                                appState.reorderItemInService(serviceId: service.id, itemId: item.id, direction: .down)
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.muted)
                                    .padding(6)
                                    .chip(fill: Theme.panel, radius: 4)
                            }
                            .buttonStyle(.plain)
                            .disabled(index == service.items.count - 1)
                            .opacity(index == service.items.count - 1 ? 0.3 : 1)

                            Button {
                                appState.removeItemFromService(serviceId: service.id, itemId: item.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.red)
                                    .padding(6)
                                    .chip(fill: Theme.red.opacity(0.12), radius: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .chip(
                        fill: isProjecting ? Theme.panel : Theme.bg,
                        border: isProjecting ? Theme.blue : Theme.panel,
                        radius: 8
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        appState.projectServiceItem(item)
                    }
                }
            }
            .padding(10)
        }
    }

    // MARK: - Modales Sheets
    private var newServiceSheet: some View {
        NavigationStack {
            Form {
                Section("Nombre del Culto / Reunión") {
                    TextField("Ej. Culto Dominical Mañana", text: $newServiceName)
                }
                Section("Fecha o Día") {
                    TextField("Ej. Domingo 10:00 AM", text: $newServiceDate)
                }
            }
            .navigationTitle("Nuevo Orden de Culto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showNewServiceModal = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        if !newServiceName.trimmingCharacters(in: .whitespaces).isEmpty {
                            appState.createService(name: newServiceName, date: newServiceDate)
                            showNewServiceModal = false
                        }
                    }
                }
            }
        }
        .presentationDetents([.height(300)])
    }

    private var songSheet: some View {
        NavigationStack {
            VStack {
                DarkTextField(placeholder: "Buscar por título...", text: $songSearch)
                    .padding(10)
                    .chip(fill: Theme.panel, border: Theme.border, radius: 8)
                    .padding(.horizontal)
                    .padding(.top, 8)

                List {
                    let filtered = appState.songsList.filter {
                        songSearch.isEmpty || $0.title.localizedCaseInsensitiveContains(songSearch)
                    }
                    ForEach(filtered) { song in
                        Button {
                            appState.quickAddSongToActiveService(song)
                            showSongModal = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(song.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                    Text("\(song.stanzas.count) estrofas disponibles")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Theme.muted)
                                }
                                Spacer()
                                HStack(spacing: 3) {
                                    Image(systemName: "plus")
                                    Text("Añadir")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.sky)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .chip(fill: Theme.blue.opacity(0.15), border: Theme.blue.opacity(0.3), radius: 6)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .background(Theme.bgDeep)
            .navigationTitle("Añadir Canción al Culto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showSongModal = false }
                }
            }
        }
    }

    private var verseSheet: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Modo", selection: $verseModalTab) {
                    Text("Vistos Recientes (\(appState.recentVerses.count))").tag(VerseModalTab.recent)
                    Text("Buscar en Biblia").tag(VerseModalTab.manual)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if verseModalTab == .recent {
                    if appState.recentVerses.isEmpty {
                        EmptyStateView(
                            icon: "clock",
                            title: "Sin versículos recientes",
                            message: "Explora versículos en la pestaña Biblia para que aparezcan aquí automáticamente."
                        )
                    } else {
                        List(appState.recentVerses, id: \.ref) { v in
                            Button {
                                appState.quickAddVerseToActiveService(ref: v.ref, text: v.text, fullContent: v.fullContent)
                                showVerseModal = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(v.ref)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(Theme.amberLight)
                                        Text(v.text)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Theme.textSoft)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    HStack(spacing: 3) {
                                        Image(systemName: "plus")
                                        Text("Añadir")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Theme.amberLight)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .chip(fill: Theme.amber.opacity(0.15), border: Theme.amber.opacity(0.3), radius: 6)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                } else {
                    manualBiblePickerView
                }
            }
            .background(Theme.bgDeep)
            .navigationTitle("Añadir Versículo al Culto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showVerseModal = false }
                }
            }
        }
    }

    private var manualBiblePickerView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                let currentBible = appState.loadedBibles.first(where: { $0.id == appState.activeBibleId }) ?? appState.loadedBibles.first
                let books = currentBible?.books ?? []

                Text("1. Selecciona Libro:")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textSoft)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(books, id: \.name) { b in
                            Button {
                                selectedBook = b.name
                                selectedChapter = 1
                                selectedVerseNum = 1
                            } label: {
                                Text(b.name)
                                    .font(.system(size: 12, weight: selectedBook == b.name ? .bold : .regular))
                                    .foregroundStyle(selectedBook == b.name ? .white : Theme.muted)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .chip(fill: selectedBook == b.name ? Theme.amber : Theme.panel, radius: 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                let currentBookData = books.first(where: { $0.name == selectedBook })
                let totalChapters = currentBookData?.chapters.count ?? 1

                Text("2. Capítulo \(selectedChapter):")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textSoft)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(1...totalChapters, id: \.self) { ch in
                            Button {
                                selectedChapter = ch
                                selectedVerseNum = 1
                            } label: {
                                Text("\(ch)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(selectedChapter == ch ? .white : Theme.muted)
                                    .frame(width: 34, height: 34)
                                    .background(selectedChapter == ch ? Theme.amber : Theme.panel, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                let totalVerses = (currentBookData?.chapters.indices.contains(selectedChapter - 1) == true)
                    ? (currentBookData?.chapters[selectedChapter - 1].count ?? 1)
                    : 1

                Text("3. Versículo \(selectedVerseNum):")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textSoft)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(1...totalVerses, id: \.self) { v in
                            Button {
                                selectedVerseNum = v
                            } label: {
                                Text("\(v)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(selectedVerseNum == v ? .white : Theme.muted)
                                    .frame(width: 34, height: 34)
                                    .background(selectedVerseNum == v ? Theme.amber : Theme.panel, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button {
                    let verseText = (currentBookData?.chapters[selectedChapter - 1].indices.contains(selectedVerseNum - 1) == true)
                        ? currentBookData!.chapters[selectedChapter - 1][selectedVerseNum - 1]
                        : ""
                    let ref = "\(selectedBook) \(selectedChapter):\(selectedVerseNum)"
                    let fullContent = "\(ref)\n\(verseText)"
                    appState.quickAddVerseToActiveService(ref: ref, text: verseText, fullContent: fullContent)
                    showVerseModal = false
                } label: {
                    Text("Añadir \(selectedBook) \(selectedChapter):\(selectedVerseNum)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Theme.amber, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }
            .padding()
        }
    }

    private var mediaSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                    ForEach(appState.customBackgrounds) { bg in
                        Button {
                            if let srv = currentService {
                                appState.addItemToService(
                                    serviceId: srv.id,
                                    item: NewServiceItem(
                                        type: .media,
                                        title: bg.name,
                                        subtitle: bg.type == .video ? "Video animado" : "Imagen fija",
                                        content: bg.uri,
                                        backgroundUri: bg.uri,
                                        backgroundType: bg.type
                                    )
                                )
                            }
                            showMediaModal = false
                        } label: {
                            VStack(spacing: 4) {
                                ProjectionImageView(uri: bg.thumbnail, contentMode: .fill)
                                    .frame(height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(alignment: .topLeading) {
                                        Text(bg.type == .video ? "VIDEO" : "IMAGEN")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(3)
                                            .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 3))
                                            .padding(4)
                                    }
                                Text(bg.name)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Theme.textSoft)
                                    .lineLimit(1)
                            }
                            .padding(4)
                            .chip(fill: Theme.panel, border: Theme.border, radius: 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Theme.bgDeep)
            .navigationTitle("Añadir Fondo o Video al Culto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showMediaModal = false }
                }
            }
        }
    }

    private var noteSheet: some View {
        NavigationStack {
            Form {
                Section("Plantillas Rápidas") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(DefaultData.presetNotes, id: \.title) { p in
                                Button {
                                    noteTitle = p.title
                                    noteContent = p.content
                                } label: {
                                    Text(p.title)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Theme.greenLight)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .chip(fill: Theme.green.opacity(0.15), border: Theme.green.opacity(0.3), radius: 6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("Título del Bloque") {
                    TextField("Ej. Anuncios y Avisos", text: $noteTitle)
                }

                Section("Texto a Proyectar (Opcional)") {
                    TextEditor(text: $noteContent)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Añadir Bloque de Servicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showNoteModal = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Añadir") {
                        if let srv = currentService {
                            appState.addItemToService(
                                serviceId: srv.id,
                                item: NewServiceItem(
                                    type: .note,
                                    title: noteTitle.trimmingCharacters(in: .whitespaces).nilIfEmpty ?? "Momento del Servicio",
                                    subtitle: "Momento de Culto",
                                    content: noteContent.trimmingCharacters(in: .whitespaces).nilIfEmpty ?? noteTitle.uppercased(),
                                    backgroundUri: srv.defaultBackgroundUri,
                                    backgroundType: srv.defaultBackgroundType
                                )
                            )
                        }
                        showNoteModal = false
                    }
                }
            }
        }
    }

    private func backgroundPickerSheet(target: BgTarget) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Opción fondo a negro
                    Button {
                        applyBackground(nil, to: target)
                        bgTarget = nil
                    } label: {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundStyle(Theme.red)
                            Text("Sin Fondo (Fondo a Negro)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.red)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.red)
                        }
                        .padding(12)
                        .chip(fill: Theme.red.opacity(0.12), border: Theme.red.opacity(0.3), radius: 8)
                    }
                    .buttonStyle(.plain)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                        ForEach(appState.customBackgrounds) { bg in
                            Button {
                                applyBackground(BackgroundMedia(type: bg.type, uri: bg.uri), to: target)
                                bgTarget = nil
                            } label: {
                                VStack(spacing: 4) {
                                    ProjectionImageView(uri: bg.thumbnail, contentMode: .fill)
                                        .frame(height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    Text(bg.name)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Theme.textSoft)
                                        .lineLimit(1)
                                }
                                .padding(4)
                                .chip(fill: Theme.panel, border: Theme.border, radius: 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.bgDeep)
            .navigationTitle(target == .service ? "Fondo General del Culto" : "Fondo de este Elemento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { bgTarget = nil }
                }
            }
        }
    }

    private func applyBackground(_ bg: BackgroundMedia?, to target: BgTarget) {
        guard let srv = currentService else { return }
        switch target {
        case .service:
            appState.updateServiceBackground(serviceId: srv.id, bg: bg)
        case .item(let itemId):
            appState.updateItemBackground(serviceId: srv.id, itemId: itemId, bg: bg)
        }
    }

    private func confirmDeleteService(_ service: ServiceOrder) {
        appState.currentAlert = AppAlert(
            title: "Eliminar Orden de Culto",
            message: "¿Estás seguro de que deseas eliminar \"\(service.name)\"? Esta acción borrará los momentos y cantos planificados en este culto.",
            confirmTitle: "Eliminar",
            onConfirm: {
                appState.deleteService(serviceId: service.id)
            }
        )
    }
}

private struct IdentifiableBgTarget: Identifiable {
    var id: String {
        switch target {
        case .service: return "service"
        case .item(let id): return "item-\(id)"
        }
    }
    let target: ServiceOrderView.BgTarget
}
