import SwiftUI

struct MainContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.layoutInfo) var layout

    var body: some View {
        Group {
            if appState.isPresentationMode {
                PresentationModeView()
            } else {
                HStack(spacing: 0) {
                    // Barra Lateral (Sidebar)
                    SidebarView()

                    // Área Principal
                    VStack(spacing: 0) {
                        // Barra Superior (Top Bar)
                        topBarView

                        // Espacio de Trabajo Dividido (Módulo + Previsualización de TV)
                        workspaceView

                        // Barra de Herramientas Inferior (Toolbar)
                        BottomToolbarView()
                    }
                }
                .background(Theme.bg)
            }
        }
        .alert(item: $appState.currentAlert) { alertData in
            if let confirmTitle = alertData.confirmTitle, let onConfirm = alertData.onConfirm {
                return Alert(
                    title: Text(alertData.title),
                    message: Text(alertData.message),
                    primaryButton: .destructive(Text(confirmTitle), action: onConfirm),
                    secondaryButton: .cancel(Text("Cancelar"))
                )
            } else {
                return Alert(
                    title: Text(alertData.title),
                    message: Text(alertData.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Barra Superior (Top Bar)
    private var topBarView: some View {
        HStack {
            Text("VisualDTB — \(appState.activeModule == .service ? "Orden de Culto" : appState.activeModule.label)")
                .font(.system(size: layout.isCompact ? 14 : 20, weight: .bold))
                .foregroundStyle(Theme.textBright)
                .lineLimit(1)

            Spacer()

            HStack(spacing: layout.isCompact ? 6 : 14) {
                // Botón Presentar en Pantalla Completa
                Button {
                    appState.isPresentationMode = true
                } label: {
                    HStack(spacing: layout.isCompact ? 3 : 6) {
                        Image(systemName: "tv")
                            .font(.system(size: layout.isCompact ? 12 : 15))
                        Text("Presentar")
                            .font(.system(size: layout.isCompact ? 10 : 13, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, layout.isCompact ? 8 : 14)
                    .padding(.vertical, layout.isCompact ? 5 : 8)
                    .background(Theme.violet, in: RoundedRectangle(cornerRadius: layout.isCompact ? 6 : 8))
                }
                .buttonStyle(.plain)

                // Insignia de estado de TV Externa
                if !layout.isCompact {
                    HStack(spacing: 6) {
                        Image(systemName: appState.hasExternalDisplay ? "tv.fill" : "tv")
                            .font(.system(size: 14))
                            .foregroundStyle(appState.hasExternalDisplay ? Theme.green : Theme.muted)
                        Text(appState.hasExternalDisplay ? "TV Conectada" : "Preview Mode")
                            .font(.system(size: 13))
                            .foregroundStyle(appState.hasExternalDisplay ? Theme.green : Theme.muted)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .chip(fill: Theme.panel, radius: 8)
                }
            }
        }
        .padding(.horizontal, layout.isCompact ? 10 : 20)
        .frame(height: layout.isCompact ? 44 : 60)
        .background(Theme.bg)
        .bottomBorder()
    }

    // MARK: - Espacio de Trabajo Dividido
    private var workspaceView: some View {
        Group {
            if layout.isPortrait && layout.isCompact {
                VStack(spacing: 0) {
                    moduleControlsArea
                    previewArea
                        .frame(height: 70)
                        .overlay(alignment: .top) { Rectangle().fill(Theme.panel).frame(height: 1) }
                }
            } else {
                HStack(spacing: 0) {
                    moduleControlsArea
                    previewArea
                        .frame(width: layout.isCompact ? 120 : 280)
                        .overlay(alignment: .leading) { Rectangle().fill(Theme.panel).frame(width: 1) }
                }
            }
        }
    }

    // Área del Módulo Activo
    private var moduleControlsArea: some View {
        ZStack {
            switch appState.activeModule {
            case .service: ServiceOrderView()
            case .bible: BibleView()
            case .songs: SongsView()
            case .media: MediaView()
            case .documents: DocumentsView()
            case .messages: MessagesView()
            case .timer: TimerView()
            case .web: WebViewModule()
            case .settings: SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Área de Vista Previa de TV
    private var previewArea: some View {
        VStack(spacing: layout.isCompact ? 2 : 10) {
            // Header del preview con resolución real de la TV
            HStack(spacing: 4) {
                Image(systemName: "tv.fill")
                    .font(.system(size: layout.isCompact ? 10 : 13))
                    .foregroundStyle(appState.hasExternalDisplay ? Theme.green : Theme.muted)
                Text("TV: \(appState.externalDisplayName)")
                    .font(.system(size: layout.isCompact ? 8 : 11, weight: .bold))
                    .foregroundStyle(appState.hasExternalDisplay ? Theme.green : Theme.muted)
                    .lineLimit(1)
                Spacer()
            }

            // Pantalla con la relación de aspecto real de la TV (HDMI / Cable)
            ZStack {
                Color.black

                ProjectionView(mode: .miniPreview)
            }
            .aspectRatio(appState.externalDisplayAspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(appState.isFullscreen ? 1.08 : 1.0)
            .shadow(color: appState.isFullscreen ? Theme.green.opacity(0.4) : Color.clear, radius: 15)

            if !layout.isCompact {
                Text(appState.isPaused ? "PAUSADO" : (appState.hasExternalDisplay ? "Reflejando en Pantalla Externa" : "Vista Previa de Salida"))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.dim)
            }
        }
        .padding(layout.isCompact ? 4 : 14)
        .background(Theme.bg)
    }
}
