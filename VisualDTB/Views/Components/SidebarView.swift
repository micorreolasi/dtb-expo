import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.layoutInfo) var layout

    var body: some View {
        VStack(spacing: 0) {
            // Header del Sidebar
            VStack(spacing: 4) {
                if let logoURL = Bundle.module.url(forResource: "icon", withExtension: "png") ?? Bundle.main.url(forResource: "icon", withExtension: "png"),
                   let uiImg = UIImage(contentsOfFile: logoURL.path) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: layout.isCompact ? 24 : 36, height: layout.isCompact ? 24 : 36)
                        .clipShape(RoundedRectangle(cornerRadius: layout.isCompact ? 6 : 8))
                } else {
                    Image(systemName: "tv.fill")
                        .font(.system(size: layout.isCompact ? 18 : 26))
                        .foregroundStyle(Theme.blue)
                }
                if !layout.isCompact {
                    Text("DTB")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.text)
                }
            }
            .padding(.top, layout.isCompact ? 8 : 16)
            .padding(.bottom, layout.isCompact ? 8 : 16)

            // Lista de Módulos
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: layout.isCompact ? 2 : 6) {
                    ForEach(ModuleType.allCases) { item in
                        let isActive = appState.activeModule == item

                        Button {
                            appState.activeModule = item
                            if item == .songs {
                                appState.selectedSongId = ""
                                appState.isAddingSong = false
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: item.icon)
                                    .font(.system(size: layout.isCompact ? 16 : 22))
                                    .foregroundStyle(isActive ? Theme.lightBlue : Theme.muted)

                                if !layout.isCompact {
                                    Text(item.label)
                                        .font(.system(size: 10, weight: isActive ? .bold : .regular))
                                        .foregroundStyle(isActive ? Theme.lightBlue : Theme.muted)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, layout.isCompact ? 6 : 10)
                            .background(isActive ? Theme.blue.opacity(0.12) : Color.clear)
                            .overlay(alignment: .leading) {
                                if isActive {
                                    Rectangle().fill(Theme.blue).frame(width: 3)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .frame(width: layout.isCompact ? 46 : 80)
        .background(Theme.panel)
        .trailingBorder(Theme.border)
    }
}
