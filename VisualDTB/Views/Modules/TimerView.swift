import SwiftUI

struct TimerView: View {
    @EnvironmentObject var appState: AppState
    @State private var customMinutesText: String = "5"
    @FocusState private var isFieldFocused: Bool

    // Tiempos predefinidos más utilizados en servicios y reuniones (por defecto 5 min)
    private let presetMinutes: [Int] = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60]

    private var isProjectingOnTV: Bool {
        appState.projection.content.contains("⏳") || appState.projection.content.contains("Tiempo Finalizado")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Cabecera del módulo con estado de proyección en TV
                HStack {
                    ModuleTitle(text: "Cuenta Regresiva (Timer)")

                    Spacer()

                    if isProjectingOnTV {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(appState.timerRunning ? Theme.green : Theme.amber)
                                .frame(width: 8, height: 8)
                            Text(appState.timerRunning ? "EN VIVO EN TV" : "PAUSADO EN TV")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(appState.timerRunning ? Theme.green : Theme.amber)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .chip(fill: (appState.timerRunning ? Theme.green : Theme.amber).opacity(0.12), radius: 6)
                    }
                }

                // Gran display digital del tiempo restante
                VStack(spacing: 6) {
                    Text(appState.formatTime(appState.timeLeft))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(appState.timeLeft <= 30 && appState.timeLeft > 0 ? Theme.red : Theme.textBright)

                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.dim)

                        Text("Duración base: \(appState.timerMinutes) min")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.muted)

                        if appState.timerRunning {
                            Text("• Corriendo")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.green)
                        } else if appState.timeLeft <= 0 {
                            Text("• ¡Tiempo Finalizado!")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.red)
                        } else {
                            Text("• En pausa / Listo")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.dim)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .chip(fill: Theme.panel, border: isProjectingOnTV ? Theme.green.opacity(0.4) : Theme.border, radius: 12)

                // Botones principales de acción
                HStack(spacing: 10) {
                    // Iniciar / Continuar
                    Button {
                        appState.startTimer()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: appState.timerRunning ? "play.circle.fill" : "play.fill")
                                .font(.system(size: 15))
                            Text(appState.timerRunning ? "Corriendo..." : (isProjectingOnTV ? "Reanudar" : "Iniciar en TV"))
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.green, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    // Pausar
                    Button {
                        appState.pauseTimer()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 14))
                            Text("Pausar")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.amber, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(!appState.timerRunning)
                    .opacity(appState.timerRunning ? 1.0 : 0.5)

                    // Reiniciar
                    Button {
                        appState.resetTimer()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14))
                            Text("Reiniciar")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.blue, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    // Ocultar de TV
                    if isProjectingOnTV {
                        Button {
                            appState.clearProjection()
                            appState.pauseTimer()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "tv.slash")
                                    .font(.system(size: 13))
                                Text("Ocultar")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(Theme.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .chip(fill: Theme.red.opacity(0.12), border: Theme.red.opacity(0.35), radius: 8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Sección 1: Tiempos Predefinidos (Con 5 min destacado por defecto)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tiempos Rápidos (Por defecto: 5 min):")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textBright)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 8)], spacing: 8) {
                        ForEach(presetMinutes, id: \.self) { mins in
                            let isSelected = appState.timerMinutes == mins
                            Button {
                                appState.setTimerDuration(minutes: mins)
                                customMinutesText = "\(mins)"
                            } label: {
                                HStack(spacing: 4) {
                                    Text("\(mins) min")
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                    if mins == 5 {
                                        Text("(Default)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(isSelected ? .white : Theme.greenLight)
                                    }
                                }
                                .foregroundStyle(isSelected ? .white : Theme.textSoft)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .chip(
                                    fill: isSelected ? Theme.blue : Theme.panel,
                                    border: isSelected ? Theme.blue : Theme.border,
                                    radius: 8
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(14)
                .chip(fill: Theme.bgBar, border: Theme.border, radius: 10)

                // Sección 2: Ajuste Personalizado (El usuario puede poner exactamente lo que quiera)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duración Personalizada:")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textBright)

                    HStack(spacing: 10) {
                        // Entrada numérica libre de minutos
                        HStack(spacing: 6) {
                            Text("Minutos:")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.muted)

                            TextField("5", text: $customMinutesText)
                                .keyboardType(.numberPad)
                                .focused($isFieldFocused)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.textBright)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(Theme.bgDeep, in: RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                                .onSubmit {
                                    applyCustomMinutes()
                                }
                        }

                        // Botón Establecer
                        Button {
                            applyCustomMinutes()
                            isFieldFocused = false
                        } label: {
                            Text("Establecer")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Theme.blue, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Stepper rápido: -1 min / +1 min / +5 min
                        HStack(spacing: 6) {
                            Button {
                                let newM = max(1, appState.timerMinutes - 1)
                                appState.setTimerDuration(minutes: newM)
                                customMinutesText = "\(newM)"
                            } label: {
                                Text("-1m")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.textSoft)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .chip(fill: Theme.panel, border: Theme.border, radius: 6)
                            }
                            .buttonStyle(.plain)

                            Button {
                                let newM = appState.timerMinutes + 1
                                appState.setTimerDuration(minutes: newM)
                                customMinutesText = "\(newM)"
                            } label: {
                                Text("+1m")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.textSoft)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .chip(fill: Theme.panel, border: Theme.border, radius: 6)
                            }
                            .buttonStyle(.plain)

                            Button {
                                let newM = appState.timerMinutes + 5
                                appState.setTimerDuration(minutes: newM)
                                customMinutesText = "\(newM)"
                            } label: {
                                Text("+5m")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.greenLight)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .chip(fill: Theme.green.opacity(0.15), border: Theme.green.opacity(0.35), radius: 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(14)
                .chip(fill: Theme.bgBar, border: Theme.border, radius: 10)
            }
            .padding(20)
        }
        .background(Theme.bg)
        .onAppear {
            customMinutesText = "\(appState.timerMinutes)"
        }
    }

    private func applyCustomMinutes() {
        if let val = Int(customMinutesText.trimmingCharacters(in: .whitespacesAndNewlines)), val > 0 {
            appState.setTimerDuration(minutes: val)
        } else {
            customMinutesText = "\(appState.timerMinutes)"
        }
    }
}
