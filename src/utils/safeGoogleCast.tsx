import React from 'react';
import { View, Platform, TouchableOpacity, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

let NativeCastButton: any = null;
let useNativeCastSession: any = () => null;
let useNativeCastState: any = () => null;
let CastContext: any = null;
let isGoogleCastAvailable = false;

// Solo evaluamos e importamos en Android para garantizar que iOS (iPad) quede 100% puro
if (Platform.OS === 'android') {
  try {
    const GoogleCastModule = require('react-native-google-cast');
    if (GoogleCastModule) {
      NativeCastButton = GoogleCastModule.CastButton;
      useNativeCastSession = GoogleCastModule.useCastSession;
      useNativeCastState = GoogleCastModule.useCastState;
      CastContext = GoogleCastModule.CastContext || GoogleCastModule.default;
      isGoogleCastAvailable = true;
    }
  } catch (e) {
    // Fallback silencioso para entornos sin binario nativo (ej. Expo Go)
    isGoogleCastAvailable = false;
  }
}

export { isGoogleCastAvailable };

export const useCastSessionSafe = () => {
  if (Platform.OS !== 'android' || !isGoogleCastAvailable) {
    return null;
  }
  try {
    return useNativeCastSession();
  } catch (e) {
    return null;
  }
};

export const useCastStateSafe = () => {
  if (Platform.OS !== 'android' || !isGoogleCastAvailable) {
    return null;
  }
  try {
    return useNativeCastState();
  } catch (e) {
    return null;
  }
};

export const showCastDialogSafe = async () => {
  if (Platform.OS !== 'android' || !isGoogleCastAvailable || !CastContext) {
    Alert.alert(
      'Google Cast (Chromecast)',
      'La función de Google Cast se activa automáticamente en Android con la versión APK compilada.',
      [{ text: 'Entendido' }]
    );
    return false;
  }
  try {
    return await CastContext.showCastDialog();
  } catch (e) {
    console.warn('Cast Dialog error:', e);
    return false;
  }
};

interface SafeCastButtonProps {
  style?: any;
  tintColor?: string;
  isCompact?: boolean;
}

export const SafeCastButton: React.FC<SafeCastButtonProps> = ({
  style,
  tintColor = '#ffffff',
  isCompact = false,
}) => {
  // En iOS (iPad) NUNCA se muestra para no interferir con la interfaz nativa de iPadOS
  if (Platform.OS !== 'android') {
    return null;
  }

  if (isGoogleCastAvailable && NativeCastButton) {
    return (
      <View style={[{ width: isCompact ? 28 : 36, height: isCompact ? 28 : 36, justifyContent: 'center', alignItems: 'center' }, style]}>
        <NativeCastButton
          style={{ width: isCompact ? 22 : 28, height: isCompact ? 22 : 28, tintColor }}
        />
      </View>
    );
  }

  // Fallback elegante para pruebas
  return (
    <TouchableOpacity
      style={[{
        width: isCompact ? 28 : 36,
        height: isCompact ? 28 : 36,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: 'rgba(59,130,246,0.15)',
        borderRadius: 8,
      }, style]}
      onPress={showCastDialogSafe}
      activeOpacity={0.7}
    >
      <Ionicons name="tv" size={isCompact ? 16 : 20} color={tintColor} />
    </TouchableOpacity>
  );
};

let lastCastRequestTime = 0;
let pendingCastTimeout: any = null;

export interface CastSlidePayload {
  isBlackout: boolean;
  projection: { type: string; content: string; title?: string };
  backgroundMedia?: { type: 'image' | 'video'; uri: string } | null;
  textColor?: string;
  textHasBackground?: boolean;
}

export const castMediaSlide = (
  castSession: any,
  payload: CastSlidePayload
) => {
  if (Platform.OS !== 'android' || !castSession) return;

  // Debounce de 120ms para evitar saturar el buffer de Chromecast al navegar rápido
  if (pendingCastTimeout) clearTimeout(pendingCastTimeout);

  pendingCastTimeout = setTimeout(async () => {
    try {
      const client = castSession.client || (castSession.getClient && castSession.getClient());
      if (!client || typeof client.loadMedia !== 'function') return;

      const { isBlackout, projection, backgroundMedia } = payload;

      // 1. Apagado de pantalla (Blackout)
      if (isBlackout) {
        await client.loadMedia({
          autoplay: true,
          mediaInfo: {
            contentUrl: 'https://placehold.co/1920x1080/000000/000000.png?text=%20',
            contentType: 'image/png',
          },
        });
        return;
      }

      // 2. Video directo o de alabanza
      if (projection && projection.type === 'video' && projection.content) {
        const isRemoteUrl = projection.content.startsWith('http://') || projection.content.startsWith('https://');
        if (isRemoteUrl) {
          await client.loadMedia({
            autoplay: true,
            mediaInfo: {
              contentUrl: projection.content,
              contentType: 'video/mp4',
            },
          });
          return;
        }
      }

      // 3. Imagen directa proyectada
      if (projection && projection.type === 'image' && projection.content) {
        const isRemoteUrl = projection.content.startsWith('http://') || projection.content.startsWith('https://');
        if (isRemoteUrl) {
          await client.loadMedia({
            autoplay: true,
            mediaInfo: {
              contentUrl: projection.content,
              contentType: 'image/jpeg',
            },
          });
          return;
        }
      }

      // 4. Video de fondo
      if (backgroundMedia && backgroundMedia.type === 'video' && backgroundMedia.uri && (!projection || !projection.content)) {
        const isRemoteUrl = backgroundMedia.uri.startsWith('http://') || backgroundMedia.uri.startsWith('https://');
        if (isRemoteUrl) {
          await client.loadMedia({
            autoplay: true,
            mediaInfo: {
              contentUrl: backgroundMedia.uri,
              contentType: 'video/mp4',
            },
          });
          return;
        }
      }

      // 5. Diapositiva de Texto (Biblia, Canciones, Notas)
      if (projection && projection.type === 'text' && projection.content) {
        const rawText = projection.content.trim();
        // Limitar a 450 caracteres para asegurar URLs HTTP seguras
        const truncated = rawText.length > 450 ? rawText.substring(0, 447) + '...' : rawText;
        const encodedText = encodeURIComponent(truncated);
        const bgHex = payload.textHasBackground ? '0f172a' : '000000';
        const fgHex = (payload.textColor || 'ffffff').replace('#', '');
        
        const slideUrl = `https://placehold.co/1920x1080/${bgHex}/${fgHex}.png?font=roboto&text=${encodedText}`;

        await client.loadMedia({
          autoplay: true,
          mediaInfo: {
            contentUrl: slideUrl,
            contentType: 'image/png',
          },
        });
        return;
      }

      // 6. Imagen de fondo pura
      if (backgroundMedia && backgroundMedia.type === 'image' && backgroundMedia.uri) {
        const isRemoteUrl = backgroundMedia.uri.startsWith('http://') || backgroundMedia.uri.startsWith('https://');
        if (isRemoteUrl) {
          await client.loadMedia({
            autoplay: true,
            mediaInfo: {
              contentUrl: backgroundMedia.uri,
              contentType: 'image/jpeg',
            },
          });
          return;
        }
      }
    } catch (err) {
      console.warn('Google Cast loadMedia error:', err);
    }
  }, 120);
};

export default {
  SafeCastButton,
  useCastSessionSafe,
  useCastStateSafe,
  showCastDialogSafe,
  castMediaSlide,
  isGoogleCastAvailable,
};

