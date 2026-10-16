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

                WebViewRepresentable(urlString: appState.projection.content) { newURL in
                    if newURL != appState.projection.content && newURL.starts(with: "http") {
                        appState.webUrl = newURL
                        appState.projection = ProjectionData(type: .web, content: newURL)
                    }
                }
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ModuleTitle(text: "Navegador Integrado")

                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.green)

                        DarkTextField(
                            placeholder: "https://www.google.com",
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
                        VStack {
                            Text("Proyectar y Visualizar Web")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
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
