import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.layoutInfo) var layout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ModuleTitle(
                    text: "Anuncios Tipo Cintillo (Marquee)",
                    size: layout.isCompact ? 18 : 24,
                    bottom: layout.isCompact ? 12 : 20
                )

                // Entrada del anuncio
                DarkTextEditor(
                    placeholder: "Escribe un anuncio para que aparezca abajo en movimiento...",
                    text: $appState.messageInput,
                    fontSize: layout.isCompact ? 14 : 16
                )
                .frame(height: layout.isCompact ? 90 : 120)
                .padding(14)
                .chip(fill: Theme.panel, border: Theme.border, radius: 8)

                // Selector de Velocidad
                VStack(alignment: .leading, spacing: 6) {
                    Text("Velocidad del Cintillo:")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.muted)

                    HStack(spacing: layout.isCompact ? 4 : 6) {
                        ForEach(MarqueeSpeed.allCases) { s in
                            let isSelected = appState.marqueeSpeed == s
                            Button {
                                appState.marqueeSpeed = s
                            } label: {
                                Text(s.label)
                                    .font(.system(size: layout.isCompact ? 10 : 12, weight: .bold))
                                    .foregroundStyle(isSelected ? .white : Theme.muted)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, layout.isCompact ? 7 : 10)
                                    .chip(
                                        fill: isSelected ? Theme.blue : Theme.panel,
                                        border: isSelected ? Theme.lightBlue : Theme.border,
                                        radius: 8
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Selector de Repeticiones
                HStack(spacing: 8) {
                    Text("Repeticiones:")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.muted)

                    DarkTextField(
                        placeholder: "3",
                        text: $appState.messageReps,
                        fontSize: 13,
                        keyboard: .numberPad
                    )
                    .frame(width: 55, height: 36)
                    .multilineTextAlignment(.center)
                    .chip(fill: Theme.panel, border: Theme.border, radius: 6)

                    HStack(spacing: 4) {
                        ForEach(["1", "3", "5", "∞"], id: \.self) { r in
                            let isSelected = (appState.messageReps == r) || (r == "∞" && appState.messageReps == "999")
                            Button {
                                appState.messageReps = (r == "∞" ? "999" : r)
                            } label: {
                                Text(r)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .chip(
                                        fill: isSelected ? Theme.blue : Theme.panel,
                                        border: isSelected ? Theme.lightBlue : Theme.border,
                                        radius: 6
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Botón Lanzar Cintillo
                ProjectButton(title: "Lanzar Cintillo Animado", icon: "play.fill", color: Theme.blue) {
                    appState.playMarquee()
                }

                // Botón Detener si está activo
                if !appState.activeMarquee.isEmpty {
                    ProjectButton(title: "Detener Cintillo", icon: "stop.fill", color: Theme.red) {
                        appState.stopMarquee()
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bg)
    }
}
