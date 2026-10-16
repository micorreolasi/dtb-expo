import UIKit
import SwiftUI
import Combine

@MainActor
final class ExternalDisplayManager: ObservableObject {
    static let shared = ExternalDisplayManager()

    @Published var isExternalScreenConnected: Bool = false
    private var externalWindow: UIWindow? = nil
    private weak var currentAppState: AppState? = nil
    private var cancellables = Set<AnyCancellable>()

    private init() {
        checkScreensAndScenes()

        // 1. Notificaciones modernas de escenas (iOS 13-18 / iPadOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneNotification(_:)),
            name: UIScene.didActivateNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneNotification(_:)),
            name: UIScene.willConnectNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneNotification(_:)),
            name: UIScene.didDisconnectNotification,
            object: nil
        )

        // 2. Notificaciones de pantallas clásicas como respaldo
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenNotification(_:)),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenNotification(_:)),
            name: UIScreen.didDisconnectNotification,
            object: nil
        )
    }

    private func checkScreensAndScenes() {
        let externalScene = findExternalWindowScene()
        let externalScreen = externalScene?.screen ?? UIScreen.screens.first(where: { $0 != UIScreen.main })
        let hasExternalScreen = (externalScene != nil) || (externalScreen != nil)
        isExternalScreenConnected = hasExternalScreen
        
        if let appState = currentAppState {
            appState.hasExternalDisplay = hasExternalScreen
            if let target = externalScreen {
                let pixelSize = target.currentMode?.size ?? target.bounds.size
                let width = max(320, pixelSize.width)
                let height = max(240, pixelSize.height)
                let ratio = width / height
                appState.externalDisplayResolution = CGSize(width: width, height: height)
                appState.externalDisplayAspectRatio = ratio
                appState.externalDisplayName = "\(Int(width))×\(Int(height))"
            } else {
                appState.externalDisplayResolution = CGSize(width: 1920, height: 1080)
                appState.externalDisplayAspectRatio = 16.0 / 9.0
                appState.externalDisplayName = "1920×1080 (16:9)"
            }
        }
    }

    private func findExternalWindowScene() -> UIWindowScene? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            if windowScene.session.role == .windowExternalDisplayNonInteractive ||
               windowScene.session.role.rawValue == "UIWindowExternalDisplaySessionRole" {
                return windowScene
            }
            if windowScene.screen != UIScreen.main {
                return windowScene
            }
        }
        return nil
    }

    @objc private func handleSceneNotification(_ notification: Notification) {
        checkScreensAndScenes()
        if let appState = currentAppState {
            syncWith(appState: appState)
        }
    }

    @objc private func handleScreenNotification(_ notification: Notification) {
        checkScreensAndScenes()
        if let appState = currentAppState {
            syncWith(appState: appState)
        }
    }

    func syncWith(appState: AppState) {
        self.currentAppState = appState
        checkScreensAndScenes()

        if isExternalScreenConnected && appState.externalDisplayEnabled {
            setupExternalWindow(with: appState)
        } else {
            tearDownExternalWindow()
        }
    }

    private func setupExternalWindow(with appState: AppState) {
        let externalScene = findExternalWindowScene()
        let externalScreen = externalScene?.screen ?? UIScreen.screens.first(where: { $0 != UIScreen.main })

        guard let targetScreen = externalScreen else {
            tearDownExternalWindow()
            return
        }

        // Si ya tenemos una ventana creada para esta escena/pantalla activa, aseguramos visibilidad
        if let currentWindow = externalWindow {
            if let externalScene, currentWindow.windowScene == externalScene {
                currentWindow.isHidden = false
                return
            } else if currentWindow.screen == targetScreen {
                currentWindow.isHidden = false
                return
            }
        }

        tearDownExternalWindow()

        let window: UIWindow
        if let externalScene {
            window = UIWindow(windowScene: externalScene)
            window.frame = externalScene.coordinateSpace.bounds
        } else {
            window = UIWindow(frame: targetScreen.bounds)
            window.screen = targetScreen
        }

        let pixelSize = targetScreen.currentMode?.size ?? targetScreen.bounds.size
        let width = max(320, pixelSize.width)
        let height = max(240, pixelSize.height)
        appState.externalDisplayResolution = CGSize(width: width, height: height)
        appState.externalDisplayAspectRatio = width / height
        appState.externalDisplayName = "\(Int(width))×\(Int(height))"

        let rootView = ExternalProjectionContainerView()
            .environmentObject(appState)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .black
        window.rootViewController = hostingController
        window.backgroundColor = .black
        window.isHidden = false

        self.externalWindow = window
        self.isExternalScreenConnected = true
        appState.hasExternalDisplay = true
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
