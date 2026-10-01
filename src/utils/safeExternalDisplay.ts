import React from 'react';

let ExternalDisplayComponent: any = ({ children }: any) => null;
let useExternalDisplayHook: (props?: any) => Record<string, any> = () => ({});

try {
  const mod = require('react-native-external-display');
  if (mod) {
    ExternalDisplayComponent = mod.default || mod;
    useExternalDisplayHook = mod.useExternalDisplay || (() => ({}));
  }
} catch (error) {
  // Graceful fallback for Expo Go and environments without native external display support
  ExternalDisplayComponent = ({ children }: any) => null;
  useExternalDisplayHook = () => ({});
}

export default ExternalDisplayComponent;
export const useExternalDisplay = useExternalDisplayHook;
