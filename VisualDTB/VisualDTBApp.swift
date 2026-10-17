import SwiftUI

@main
struct VisualDTBApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var externalDisplay = ExternalDisplayManager.shared

    var body: some Scene {
        WindowGroup {
            GeometryReader { proxy in
                let info = LayoutInfo(width: proxy.size.width, height: proxy.size.height)

                MainContentView()
                    .environmentObject(appState)
                    .environment(\.layoutInfo, info)
                    .preferredColorScheme(appState.isDarkMode ? .dark : .light)
                    .onAppear {
                        externalDisplay.syncWith(appState: appState)
                    }
                    .onChange(of: externalDisplay.isExternalScreenConnected) { _ in
                        externalDisplay.syncWith(appState: appState)
                    }
                    .onChange(of: appState.externalDisplayEnabled) { _ in
                        externalDisplay.syncWith(appState: appState)
                    }
            }
        }
    }
}
