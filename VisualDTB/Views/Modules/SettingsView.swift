import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ModuleTitle(text: "Configuración del Sistema")

                // SECCIÓN 1: TEMA DE LA APLICACIÓN (MODO CLARO / MODO OSCURO)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "circle.righthalf.filled")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.blue)
                        Text("Tema de la Interfaz")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.textBright)
                        Spacer()
                    }

                    Text("Diseñado acorde al icono de la app (Azul cobalto del proyector y el iPad con azul hielo).")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)

                    HStack(spacing: 12) {
                        // Opción Modo Claro
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.isDarkMode = false
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Theme.amber)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Modo Claro")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(!appState.isDarkMode ? Theme.blue : Theme.text)
                                    Text("Fondo azul hielo y blanco")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.dim)
                                }
                                Spacer()

                                if !appState.isDarkMode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.blue)
                                }
                            }
                            .padding(12)
                            .chip(
                                fill: !appState.isDarkMode ? Theme.blue.opacity(0.12) : Theme.bgDeep,
                                border: !appState.isDarkMode ? Theme.blue : Theme.border,
                                radius: 8,
                                lineWidth: !appState.isDarkMode ? 2 : 1
                            )
                        }
                        .buttonStyle(.plain)

                        // Opción Modo Oscuro
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.isDarkMode = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Theme.sky)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Modo Oscuro")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(appState.isDarkMode ? Theme.sky : Theme.text)
                                    Text("Azul marino cobalto")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.dim)
                                }
                                Spacer()

                                if appState.isDarkMode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.sky)
                                }
                            }
                            .padding(12)
                            .chip(
                                fill: appState.isDarkMode ? Theme.blue.opacity(0.15) : Theme.bgDeep,
                                border: appState.isDarkMode ? Theme.sky : Theme.border,
                                radius: 8,
                                lineWidth: appState.isDarkMode ? 2 : 1
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .chip(fill: Theme.panel, border: Theme.border, radius: 10)

                // SECCIÓN 2: PANTALLA EXTERNA
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "tv")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.blue)
                        Text("Salida a Pantalla Externa (TV / Proyector)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.textBright)
                        Spacer()
                        Toggle("", isOn: $appState.externalDisplayEnabled)
                            .labelsHidden()
                            .tint(Theme.blue)
                    }

                    // Cartel de estado
                    if appState.hasExternalDisplay {
                        HStack(spacing: 8) {
                            Image(systemName: "tv.fill")
                                .foregroundStyle(Theme.greenLight)
                            Text("Pantalla externa detectada: \(appState.externalDisplayName)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.greenLight)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .chip(fill: Theme.green.opacity(0.15), border: Theme.green.opacity(0.35), radius: 6)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "tv")
                                .foregroundStyle(Theme.amberLight)
                            Text("No se detecta pantalla externa. Conecta por HDMI o AirPlay.")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.amberLight)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .chip(fill: Theme.amber.opacity(0.15), border: Theme.amber.opacity(0.35), radius: 6)
                    }
                }
                .padding(16)
                .chip(fill: Theme.panel, border: Theme.border, radius: 10)
            }
            .padding(20)
        }
        .background(Theme.bg)
    }
}
