import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ModuleTitle(text: "Configuración del Sistema")

                // Fila del interruptor de pantalla externa
                HStack {
                    Text("Proyectar a TV Externa (Airplay/HDMI)")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Toggle("", isOn: $appState.externalDisplayEnabled)
                        .labelsHidden()
                        .tint(Theme.blue)
                }
                .padding(16)
                .chip(fill: Theme.panel, radius: 8)

                // Cartel de estado
                if appState.hasExternalDisplay {
                    HStack(spacing: 8) {
                        Image(systemName: "tv.fill")
                            .foregroundStyle(Theme.greenLight)
                        Text("Pantalla externa detectada (AirPlay / HDMI).")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.greenLight)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .chip(fill: Color(hex: "#064e3b"), radius: 6)
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
                    .chip(fill: Color(hex: "#78350f"), radius: 6)
                }
            }
            .padding(20)
        }
        .background(Theme.bg)
    }
}
