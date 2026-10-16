import Foundation
import AVFoundation

/// Administrador centralizado de la sesión de audio de iOS
/// Asegura que los videos se reproduzcan con sonido tanto en el iPad
/// como a través de la salida HDMI / TV externa, ignorando el modo silencio del dispositivo.
enum AudioSessionManager {

    private static var isConfigured = false

    /// Configura y activa la sesión de audio en modo .playback
    static func configurePlaybackSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.duckOthers, .defaultToSpeaker, .allowAirPlay]
            )
            try session.setActive(true, options: [])
            isConfigured = true
            print("🔊 AVAudioSession configurada exitosamente en modo .playback (con sonido para TV y altavoces)")
        } catch {
            print("⚠️ Error al configurar AVAudioSession:", error.localizedDescription)
        }
    }

    /// Asegura que la sesión esté lista antes de reproducir medios
    static func ensureActive() {
        if !isConfigured {
            configurePlaybackSession()
        } else {
            try? AVAudioSession.sharedInstance().setActive(true, options: [])
        }
    }
}
