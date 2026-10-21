import SwiftUI

struct WebViewModule: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.projection.type == .web {
            VStack(spacing: 0) {
                // Barra superior de navegación interactiva
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.green)

                    DarkTextField(
                        placeholder: "https://...",
                        text: $appState.webUrl,
                        fontSize: 14,
                        autocapitalize: false,
                        onSubmit: {
                            appState.projection = ProjectionData(type: .web, content: appState.webUrl)
                        }
                    )

                    Button {
                        appState.projection = ProjectionData(type: .web, content: appState.webUrl)
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Theme.blue, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    Button {
                        appState.projection = .text("")
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Theme.red, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Theme.panel)
                .bottomBorder(Theme.border)

                // Barra de Controles de Video en TV y Vista Previa (YouTube y Web)
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "play.tv.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.green)
                        Text("Controles de Video:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.textBright)
                    }

                    Spacer()

                    // Retroceder 10 segundos
                    Button {
                        appState.sendWebCommand(.rewind(seconds: 10))
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "gobackward.10")
                                .font(.system(size: 11))
                            Text("-10s")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .chip(fill: Theme.blue.opacity(0.15), border: Theme.blue.opacity(0.4), radius: 6)
                    }
                    .buttonStyle(.plain)

                    // Pausa / Play
                    Button {
                        appState.sendWebCommand(.playPause)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "playpause.fill")
                                .font(.system(size: 11))
                            Text("Pausa / Play")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.blue, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    // Adelantar 10 segundos
                    Button {
                        appState.sendWebCommand(.forward(seconds: 10))
                    } label: {
                        HStack(spacing: 3) {
                            Text("+10s")
                                .font(.system(size: 11, weight: .bold))
                            Image(systemName: "goforward.10")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 6)
                    }
                    .buttonStyle(.plain)

                    // Silenciar / Mute
                    Button {
                        appState.sendWebCommand(.toggleMute)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSoft)
                            .frame(width: 28, height: 28)
                            .chip(fill: Theme.border, radius: 6)
                    }
                    .buttonStyle(.plain)

                    // Pantalla Completa TV
                    Button {
                        appState.sendWebCommand(.toggleFullscreen)
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 11, weight: .bold))
                            Text("Pantalla Completa TV")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 6)
                    }
                    .buttonStyle(.plain)

                    // Quitar Popups TV (Cerrar Google Sign-in, banners y avisos en la TV)
                    Button {
                        appState.sendExternalWebCommand(.dismissPopups)
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 11, weight: .bold))
                            Text("Quitar Popups TV")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(Theme.textSoft)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .chip(fill: Theme.border, radius: 6)
                    }
                    .buttonStyle(.plain)

                    // Recargar
                    Button {
                        appState.sendWebCommand(.reload)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSoft)
                            .frame(width: 28, height: 28)
                            .chip(fill: Theme.border, radius: 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.bg)
                .bottomBorder(Theme.border)

                // Visualización 1:1 con la TV (proporción exacta de la pantalla externa)
                ZStack {
                    Color.black

                    WebViewRepresentable(
                        urlString: appState.projection.content,
                        mode: .presentation,
                        scrollRatio: appState.webScrollRatio
                    ) { newURL in
                        if newURL.starts(with: "http") {
                            appState.webUrl = newURL
                            if appState.projection.content != newURL {
                                appState.projection = ProjectionData(type: .web, content: newURL)
                            }
                        }
                    }
                }
                .aspectRatio(appState.externalDisplayAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ModuleTitle(text: "Navegador Integrado y Videos Web")

                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.green)

                        DarkTextField(
                            placeholder: "https://www.youtube.com",
                            text: $appState.webUrl,
                            fontSize: 15,
                            autocapitalize: false
                        )
                    }
                    .padding(12)
                    .chip(fill: Theme.panel, radius: 8)


                    Button {
                        appState.projection = ProjectionData(type: .web, content: appState.webUrl)
                    } label: {
                        VStack(spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "tv.and.mediabox")
                                    .font(.system(size: 20))
                                Text("Proyectar y Visualizar Web")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            Text("Sincronización automática de videos y controles en TV")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 90)
                        .background(Theme.green, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(Theme.bg)
        }
    }
}
