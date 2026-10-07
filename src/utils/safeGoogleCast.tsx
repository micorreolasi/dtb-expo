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

export default {
  SafeCastButton,
  useCastSessionSafe,
  useCastStateSafe,
  showCastDialogSafe,
  isGoogleCastAvailable,
};
