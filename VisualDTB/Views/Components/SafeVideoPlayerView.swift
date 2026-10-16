import SwiftUI
import AVKit

struct SafeVideoPlayerView: View {
    let uri: String
    var contentFit: ContentMode = .fit
    var muted: Bool = false
    var volume: Float = 1.0
    var loop: Bool = true
    var isPaused: Bool = false
    var nativeControls: Bool = false

    @State private var player: AVPlayer? = nil
    @State private var endObserver: Any? = nil

    var body: some View {
        ZStack {
            Color.black
            if let player {
                if nativeControls {
                    VideoPlayer(player: player)
                        .id(ObjectIdentifier(player))
                } else {
                    CustomAVPlayerRepresentable(player: player, videoGravity: contentFit == .fill ? .resizeAspectFill : .resizeAspect)
                        .id(ObjectIdentifier(player))
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.gray)
                    Text("Cargando video...")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.gray)
                }
            }
        }
        .onAppear {
            setupPlayer(for: uri)
        }
        .onDisappear {
            tearDownPlayer()
        }
        .onChange(of: uri) { newUri in
            setupPlayer(for: newUri)
        }
        .onChange(of: muted) { isMuted in
            player?.isMuted = isMuted
        }
        .onChange(of: volume) { vol in
            player?.volume = muted ? 0 : vol
        }
        .onChange(of: isPaused) { paused in
            if paused {
                player?.pause()
            } else {
                player?.play()
            }
        }
    }

    private func resolveVideoURL(from string: String) -> URL? {
        if string.hasPrefix("http://") || string.hasPrefix("https://") {
            return URL(string: string)
        }
        let cleanPath: String = {
            if string.hasPrefix("file://") {
                if let u = URL(string: string) {
                    return u.path
                }
                return String(string.dropFirst(7))
            }
            return string
        }().removingPercentEncoding ?? string
        let resolved = BackgroundStorage.resolveURI(cleanPath)
        return URL(fileURLWithPath: resolved)
    }

    private func setupPlayer(for targetUri: String) {
        tearDownPlayer()
        guard let url = resolveVideoURL(from: targetUri) else { return }
        let playerItem = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer.isMuted = muted
        avPlayer.volume = muted ? 0 : volume

        if loop {
            avPlayer.actionAtItemEnd = .none
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak avPlayer] _ in
                avPlayer?.seek(to: .zero)
                avPlayer?.play()
            }
        }

        self.player = avPlayer
        if !isPaused {
            avPlayer.play()
        }
    }

    private func tearDownPlayer() {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }
}

private struct CustomAVPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = videoGravity
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
        uiView.playerLayer.videoGravity = videoGravity
    }

    class PlayerUIView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .black
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            backgroundColor = .black
        }
    }
}
