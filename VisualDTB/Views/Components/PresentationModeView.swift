import SwiftUI

struct PresentationModeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showControls: Bool = true
    @State private var hideTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ProjectionView(mode: .presentation)
                .ignoresSafeArea()

            // Floating auto-hiding controls at bottom
            if showControls {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        // Navegación de Diapositivas o Hojas de Documento
                        if appState.playlist != nil || appState.isDocumentActive {
                            Button {
                                appState.handlePrevSlide()
                                resetHideTimer()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Theme.blue.opacity(0.85), in: Circle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                appState.handleNextSlide()
                                resetHideTimer()
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Theme.blue.opacity(0.85), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        // Blackout toggle
                        Button {
                            appState.isBlackout.toggle()
                            resetHideTimer()
                        } label: {
                            Image(systemName: appState.isBlackout ? "eye.slash.fill" : "eye.slash")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(appState.isBlackout ? Theme.red.opacity(0.9) : Color.gray.opacity(0.6), in: Circle())
                        }
                        .buttonStyle(.plain)

                        // Salir del modo presentación
                        Button {
                            appState.isPresentationMode = false
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Salir")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 44)
                            .background(Theme.red.opacity(0.9), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            resetHideTimer()
        }
        .onAppear {
            resetHideTimer()
        }
        .onDisappear {
            hideTask?.cancel()
        }
    }

    private func resetHideTimer() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showControls = true
        }
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = false
                }
            }
        }
    }
}
