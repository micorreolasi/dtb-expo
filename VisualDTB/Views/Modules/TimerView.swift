import SwiftUI

struct TimerView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ModuleTitle(text: "Cuenta Regresiva")

                // Caja del Timer grande
                VStack {
                    Text(appState.formatTime(appState.timeLeft))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .chip(fill: Theme.panel, radius: 8)

                // Botones de acción
                HStack(spacing: 12) {
                    ProjectButton(
                        title: appState.timerRunning ? "Corriendo..." : "Iniciar Timer",
                        color: Theme.green
                    ) {
                        appState.startTimer()
                    }

                    ProjectButton(title: "Pausar", color: Theme.red) {
                        appState.pauseTimer()
                    }

                    ProjectButton(title: "Reset", color: Theme.dim) {
                        appState.resetTimer()
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bg)
    }
}
