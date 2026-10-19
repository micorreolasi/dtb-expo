import SwiftUI

struct DocumentRadarTouchpadView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.layoutInfo) var layout
    var compactMode: Bool = false

    @State private var isDragging: Bool = false

    private var radarImage: UIImage? {
        if let url = Bundle.module.url(forResource: "grid_radar", withExtension: "png") ?? Bundle.main.url(forResource: "grid_radar", withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        if let url = Bundle.module.url(forResource: "Assets/grid_radar", withExtension: "png") ?? Bundle.main.url(forResource: "Assets/grid_radar", withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        return UIImage(named: "grid_radar")
    }

    var body: some View {
        VStack(spacing: compactMode ? 6 : 10) {
            // Header / HUD Info
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "scope")
                        .font(.system(size: compactMode ? 11 : 13, weight: .bold))
                        .foregroundStyle(Theme.sky)
                    Text("Radar Táctil 2D (TV)")
                        .font(.system(size: compactMode ? 10 : 12, weight: .bold))
                        .foregroundStyle(Theme.textBright)
                }

                Spacer()

                // Indicador de coordenadas y zoom
                HStack(spacing: 6) {
                    Text("X: \(Int(appState.documentScrollOffsetRatio.x * 100))%  Y: \(Int(appState.documentScrollOffsetRatio.y * 100))%")
                        .font(.system(size: compactMode ? 8 : 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.sky)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .chip(fill: Theme.sky.opacity(0.12), border: Theme.sky.opacity(0.3), radius: 4)

                    Text("\(Int(appState.documentZoomScale * 100))%")
                        .font(.system(size: compactMode ? 8 : 10, weight: .bold))
                        .foregroundStyle(appState.documentZoomScale > 1.05 ? Theme.green : Theme.textSoft)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .chip(fill: Theme.panel, border: Theme.border, radius: 4)
                }
            }

            // Radar interactivo 2D
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                // Tamaño de la caja de visualización TV relativa al zoom
                let boxW = max(30, w / max(1.0, appState.documentZoomScale))
                let boxH = max(30, h / max(1.0, appState.documentZoomScale))

                // Coordenadas del centro de la caja en base a documentScrollOffsetRatio
                let maxShiftX = max(0, w - boxW)
                let maxShiftY = max(0, h - boxH)
                let boxPosX = (boxW / 2) + (maxShiftX * appState.documentScrollOffsetRatio.x)
                let boxPosY = (boxH / 2) + (maxShiftY * appState.documentScrollOffsetRatio.y)

                ZStack {
                    // Fondo de imagen del radar subida por el usuario
                    if let img = radarImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: w, height: h)
                            .clipped()
                    } else {
                        // Fallback vectorial de alta precisión
                        Color.black
                        GridLinesPattern()
                            .stroke(Theme.sky.opacity(0.35), lineWidth: 1)
                    }

                    // Cuadro de enfoque de la TV (Se mueve de un lado a otro y arriba/abajo)
                    ZStack {
                        // Borde brillante con resplandor cyan
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Theme.sky, lineWidth: isDragging ? 2.5 : 1.8)
                            .background(Theme.sky.opacity(isDragging ? 0.22 : 0.12))

                        // Retícula / Cruz de mira en el centro
                        VStack(spacing: 0) {
                            Rectangle().fill(Theme.sky).frame(width: 1, height: 6)
                            Spacer()
                            Rectangle().fill(Theme.sky).frame(width: 1, height: 6)
                        }
                        HStack(spacing: 0) {
                            Rectangle().fill(Theme.sky).frame(width: 6, height: 1)
                            Spacer()
                            Rectangle().fill(Theme.sky).frame(width: 6, height: 1)
                        }

                        // Etiqueta TV
                        Text("TV")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(Theme.sky.opacity(0.85), in: RoundedRectangle(cornerRadius: 2))
                    }
                    .frame(width: boxW, height: boxH)
                    .position(x: boxPosX, y: boxPosY)
                    .shadow(color: Theme.sky.opacity(0.6), radius: isDragging ? 8 : 4)

                    // Overlay con instrucción táctil si no está tocando
                    if !isDragging && appState.documentZoomScale <= 1.05 {
                        VStack(spacing: 2) {
                            Image(systemName: "hand.draw")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.sky)
                            Text("Aumenta zoom para mover en TV")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Theme.sky)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.sky.opacity(0.4), lineWidth: 1.5)
                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let touchX = value.location.x
                            let touchY = value.location.y

                            let usableW = max(1, w - boxW)
                            let usableH = max(1, h - boxH)

                            let ratioX = max(0.0, min(1.0, (touchX - (boxW / 2)) / usableW))
                            let ratioY = max(0.0, min(1.0, (touchY - (boxH / 2)) / usableH))

                            appState.setDocumentScrollOffset(x: ratioX, y: ratioY)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: compactMode ? 140 : 220)

            // Botonera de precisión 2D: [◄] [▲] [▼] [►] y [Centrar]
            HStack(spacing: 6) {
                Button {
                    appState.scrollDocumentLeft()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: compactMode ? 10 : 12, weight: .bold))
                        .foregroundStyle(Theme.sky)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, compactMode ? 5 : 7)
                        .chip(fill: Theme.sky.opacity(0.12), border: Theme.sky.opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)

                Button {
                    appState.scrollDocumentUp()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: compactMode ? 10 : 12, weight: .bold))
                        .foregroundStyle(Theme.sky)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, compactMode ? 5 : 7)
                        .chip(fill: Theme.sky.opacity(0.12), border: Theme.sky.opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)

                Button {
                    appState.centerDocumentScroll()
                } label: {
                    Text("Centrar")
                        .font(.system(size: compactMode ? 8 : 10, weight: .bold))
                        .foregroundStyle(Theme.textBright)
                        .padding(.horizontal, 8)
                        .padding(.vertical, compactMode ? 5 : 7)
                        .chip(fill: Theme.border, radius: 6)
                }
                .buttonStyle(.plain)

                Button {
                    appState.scrollDocumentDown()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: compactMode ? 10 : 12, weight: .bold))
                        .foregroundStyle(Theme.sky)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, compactMode ? 5 : 7)
                        .chip(fill: Theme.sky.opacity(0.12), border: Theme.sky.opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)

                Button {
                    appState.scrollDocumentRight()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: compactMode ? 10 : 12, weight: .bold))
                        .foregroundStyle(Theme.sky)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, compactMode ? 5 : 7)
                        .chip(fill: Theme.sky.opacity(0.12), border: Theme.sky.opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(compactMode ? 8 : 12)
        .chip(fill: Theme.panel, border: Theme.border, radius: 10)
    }
}

private struct GridLinesPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let stepX: CGFloat = rect.width / 8
        let stepY: CGFloat = rect.height / 8

        for i in 0...8 {
            let x = CGFloat(i) * stepX
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }

        for j in 0...8 {
            let y = CGFloat(j) * stepY
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }

        return path
    }
}
