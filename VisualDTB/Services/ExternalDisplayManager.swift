import UIKit
import SwiftUI
import Combine

@MainActor
final class ExternalDisplayManager: ObservableObject {
    static let shared = ExternalDisplayManager()

    @Published var isExternalScreenConnected: Bool = false
    private var externalWindow: UIWindow? = nil
    private var cancellables = Set<AnyCancellable>()

    private init() {
        checkScreens()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidConnect(_:)),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidDisconnect(_:)),
            name: UIScreen.didDisconnectNotification,
            object: nil
        )
    }

    private func checkScreens() {
        if UIScreen.screens.count > 1 {
            isExternalScreenConnected = true
        } else {
            isExternalScreenConnected = false
        }
    }

    @objc private func screenDidConnect(_ notification: Notification) {
        checkScreens()
    }

    @objc private func screenDidDisconnect(_ notification: Notification) {
        checkScreens()
        tearDownExternalWindow()
    }

    func syncWith(appState: AppState) {
        appState.hasExternalDisplay = isExternalScreenConnected

        if isExternalScreenConnected && appState.externalDisplayEnabled {
            setupExternalWindow(with: appState)
        } else {
            tearDownExternalWindow()
        }
    }

    private func setupExternalWindow(with appState: AppState) {
        guard let externalScreen = UIScreen.screens.first(where: { $0 != UIScreen.main }) else {
            tearDownExternalWindow()
            return
        }

        if externalWindow == nil || externalWindow?.screen != externalScreen {
            let window = UIWindow(frame: externalScreen.bounds)
            window.screen = externalScreen
            let rootView = ExternalProjectionContainerView()
                .environmentObject(appState)
            window.rootViewController = UIHostingController(rootView: rootView)
            window.isHidden = false
            self.externalWindow = window
        }
    }

    private func tearDownExternalWindow() {
        externalWindow?.isHidden = true
        externalWindow = nil
    }
}

/// Vista contenedora que se muestra exclusivamente en la pantalla externa (TV / Proyector)
struct ExternalProjectionContainerView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ProjectionView(mode: .external)
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}
