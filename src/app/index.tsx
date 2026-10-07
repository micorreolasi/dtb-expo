import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, TextInput, ScrollView, Image, Animated, Easing, Platform, useWindowDimensions, Alert, NativeModules, LayoutChangeEvent } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import * as DocumentPicker from 'expo-document-picker';
import * as FileSystemLegacy from 'expo-file-system/legacy';
import { File as ExpoFile } from 'expo-file-system';
import { WebView } from 'react-native-webview';
import * as Sharing from 'expo-sharing';
import Slider from '@react-native-community/slider';
import ExternalDisplay, { useExternalDisplay } from '../utils/safeExternalDisplay';
import { SafeCastButton, useCastSessionSafe } from '../utils/safeGoogleCast';
import fullBible from '../bible.json';
import ServiceOrderModule from '../components/ServiceOrderModule';
import {
  ServiceOrder,
  ServiceItem,
  defaultServices,
  loadSavedServices,
  saveServicesToDisk,
} from '../utils/serviceStorage';

let NativeVideoView: any = null;
let useNativeVideoPlayer: any = null;
try {
  const expoVideo = require('expo-video');
  NativeVideoView = expoVideo.VideoView;
  useNativeVideoPlayer = expoVideo.useVideoPlayer;
} catch (e) {
  // Not available in standard Expo Go without native build
}

const RealVideoPlayer = ({ 
  uri, 
  contentFit, 
  style, 
  muted = false, 
  loop = true, 
  volume = 1.0, 
  nativeControls = false,
  isPaused = false,
}: { 
  uri: string; 
  contentFit: 'contain' | 'cover'; 
  style?: any; 
  muted?: boolean; 
  loop?: boolean; 
  volume?: number; 
  nativeControls?: boolean; 
  isPaused?: boolean;
}) => {
  const player = useNativeVideoPlayer(uri, (p: any) => {
    p.loop = loop;
    p.muted = muted;
    p.volume = muted ? 0 : volume;
    if (isPaused) {
      p.pause();
    } else {
      p.play();
    }
  });

  useEffect(() => {
    if (player) {
      player.muted = muted;
      player.volume = muted ? 0 : volume;
      player.loop = loop;
      if (isPaused) {
        player.pause();
      } else {
        player.play();
      }
    }
  }, [player, muted, volume, loop, isPaused]);

  return (
    <NativeVideoView
      style={style || { width: '100%', height: '100%' }}
      player={player}
      contentFit={contentFit}
      nativeControls={nativeControls}
    />
  );
};

const SafeVideoView = ({ 
  uri, 
  contentFit = 'contain', 
  style,
  muted = false,
  loop = true,
  volume = 1.0,
  nativeControls = false,
  isPaused = false,
}: { 
  uri: string; 
  contentFit?: 'contain' | 'cover'; 
  style?: any; 
  muted?: boolean;
  loop?: boolean;
  volume?: number;
  nativeControls?: boolean;
  isPaused?: boolean;
}) => {
  if (NativeVideoView && useNativeVideoPlayer) {
    return (
      <RealVideoPlayer 
        uri={uri} 
        contentFit={contentFit} 
        style={style} 
        muted={muted} 
        loop={loop} 
        volume={volume} 
        nativeControls={nativeControls} 
        isPaused={isPaused}
      />
    );
  }

  return (
    <View style={[style || { width: '100%', height: '100%' }, { backgroundColor: 'black', justifyContent: 'center', alignItems: 'center' }]}>
      <Ionicons name="videocam" size={48} color="#94a3b8" />
      <Text style={{ color: '#94a3b8', marginTop: 8, fontSize: 12 }}>Video activo en Development Build</Text>
    </View>
  );
};

type ModuleType = 'Service' | 'Bible' | 'Songs' | 'Media' | 'Documents' | 'Messages' | 'Timer' | 'Web' | 'Settings';

type ProjectionData = {
  type: 'text' | 'image' | 'video' | 'web' | 'pdf' | 'document';
  content: string; 
  title?: string;
};

const readFileAsText = async (uri: string): Promise<string> => {
  try {
    const file = new ExpoFile(uri);
    if (typeof (file as any).text === 'function') {
      const txt = await (file as any).text();
      if (txt) return txt;
    }
  } catch (e) {
    // Fallback to legacy API
  }

  return await FileSystemLegacy.readAsStringAsync(uri);
};

const defaultBackgrounds = [
  {
    id: 'bg1',
    type: 'video',
    thumbnail: 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=300&q=80',
    uri: 'https://vjs.zencdn.net/v/oceans.mp4',
    name: 'Océano (Video)'
  },
  {
    id: 'bg2',
    type: 'video',
    thumbnail: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=300&q=80',
    uri: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
    name: 'Naturaleza (Video)'
  },
  {
    id: 'bg3',
    type: 'image',
    thumbnail: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=300&q=80',
    uri: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=1920&auto=format&fit=crop',
    name: 'Abstracto (Imagen)'
  },
  {
    id: 'bg4',
    type: 'image',
    thumbnail: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=300&q=80',
    uri: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1920&auto=format&fit=crop',
    name: 'Montañas (Imagen)'
  }
];

// --- MOCK DATA ---
const mockSongs = [
  {
    id: 's1',
    title: 'Cuan Grande Es Él',
    stanzas: [
      { name: 'Estrofa 1', text: 'Señor mi Dios\nAl contemplar los cielos\nEl firmamento y las estrellas mil' },
      { name: 'Coro', text: 'Mi corazón entona la canción\nCuan grande es Él\nCuan grande es Él' },
      { name: 'Estrofa 2', text: 'Al recorrer los montes y los valles\nY ver las bellas flores al pasar' }
    ]
  },
  {
    id: 's2',
    title: 'Way Maker',
    stanzas: [
      { name: 'Estrofa 1', text: 'Aquí estás\nTe vemos mover\nTe adoraré\nTe adoraré' },
      { name: 'Coro', text: 'Milagroso, abres camino\nCumples promesas\nLuz en tinieblas\nMi Dios, así eres Tú' },
      { name: 'Puente', text: 'Aunque no pueda ver, estás obrando\nAunque no pueda ver, estás obrando\nSiempre estás, siempre estás obrando' }
    ]
  },
  {
    id: 's3',
    title: 'Hermoso Nombre',
    stanzas: [
      { name: 'Estrofa 1', text: 'Tú fuiste el Verbo en el principio\nUnigénito de Dios\nEl misterio de Tu gloria revelado en Tu amor' },
      { name: 'Coro', text: 'Cuan hermoso Su nombre es\nCuan hermoso Su nombre es\nEl nombre de Jesús mi Rey' }
    ]
  }
];

// Eliminamos mockBible ya que usaremos fullBible.

// =============================================
// DYNAMIC TEXT ENGINE: AUTO-FIT PER SCREEN
// Guarantees zero text overflow and zero clipping across Phone, iPad, TV & Mini-Preview
// =============================================

interface DynamicProjectionTextProps {
  content: string;
  mode: 'miniPreview' | 'presentation' | 'external';
  textColor: string;
  textHasBackground: boolean;
  sizeMultiplier?: number;
  isCompact?: boolean;
}

function computeOptimalFontSize(
  bodyText: string,
  referenceText: string | null,
  safeWidth: number,
  safeHeight: number,
  mode: 'miniPreview' | 'presentation' | 'external',
  isCompact: boolean,
  sizeMultiplier: number = 1.0
): {
  fontSize: number;
  lineHeight: number;
  refFontSize: number;
  refLineHeight: number;
  refMarginBottom: number;
} {
  const paragraphs = bodyText.split('\n');

  let maxWordLen = 1;
  for (const p of paragraphs) {
    const words = p.split(/\s+/);
    for (const w of words) {
      if (w.length > maxWordLen) maxWordLen = w.length;
    }
  }

  // Bounds depending on screen mode
  let minFont = 4.5;
  let maxFont = 22;

  if (mode === 'miniPreview') {
    if (isCompact) {
      minFont = 5;
      maxFont = 10;
    } else {
      minFont = 7;
      maxFont = 16;
    }
  } else if (mode === 'presentation') {
    if (isCompact) {
      minFont = 12;
      maxFont = 28;
    } else {
      minFont = 18;
      maxFont = 44;
    }
  } else {
    // External display (1080p / 4K)
    minFont = 22;
    maxFont = 56;
  }

  const step = mode === 'miniPreview' ? 0.5 : 1;
  let bestFont = minFont;

  for (let f = maxFont; f >= minFont; f -= step) {
    // 1. Longest word must fit horizontally in safeWidth
    const longestWordWidth = maxWordLen * (0.58 * f);
    if (longestWordWidth > safeWidth * 0.95) {
      continue;
    }

    // 2. Reference height if present
    let refH = 0;
    if (referenceText) {
      const rf = Math.max(minFont * 0.85, f * 0.82);
      const rlh = rf * 1.3;
      const rmb = mode === 'miniPreview' ? 2 : Math.max(4, f * 0.28);
      refH = rlh + rmb;
    }

    const availableH = safeHeight - refH;
    if (availableH <= 0) continue;

    // 3. Line wrapping calculation
    const charsPerLine = Math.max(1, Math.floor((safeWidth * 0.94) / (0.53 * f)));
    let totalLines = 0;
    for (const p of paragraphs) {
      const pLen = p.trim().length;
      if (pLen === 0) {
        totalLines += 0.5;
      } else {
        totalLines += Math.max(1, Math.ceil(pLen / charsPerLine));
      }
    }

    // 4. Total body height
    const lineH = f * 1.34;
    const totalBodyH = totalLines * lineH;

    if (totalBodyH <= availableH * 0.93) {
      bestFont = f;
      break;
    }
  }

  // Apply user custom multiplier
  let finalFontSize = Math.round(bestFont * sizeMultiplier * 10) / 10;
  finalFontSize = Math.max(minFont * 0.8, Math.min(finalFontSize, maxFont * 1.3));
  const finalLineHeight = Math.round(finalFontSize * 1.34 * 10) / 10;

  const refFontSize = Math.max(minFont * 0.85, Math.round(finalFontSize * 0.82 * 10) / 10);
  const refLineHeight = Math.round(refFontSize * 1.3 * 10) / 10;
  const refMarginBottom = mode === 'miniPreview' ? 2 : Math.max(3, Math.round(finalFontSize * 0.28));

  return {
    fontSize: finalFontSize,
    lineHeight: finalLineHeight,
    refFontSize,
    refLineHeight,
    refMarginBottom,
  };
}

const DynamicProjectionText: React.FC<DynamicProjectionTextProps> = ({
  content,
  mode,
  textColor,
  textHasBackground,
  sizeMultiplier = 1.0,
  isCompact = false,
}) => {
  const { width: winWidth, height: winHeight } = useWindowDimensions();

  const getInitialSize = () => {
    if (mode === 'presentation') {
      return { width: winWidth, height: winHeight };
    }
    if (mode === 'miniPreview') {
      return isCompact ? { width: 100, height: 50 } : { width: 260, height: 146 };
    }
    return { width: 1920, height: 1080 };
  };

  const [measuredSize, setMeasuredSize] = useState(getInitialSize());

  const handleLayout = (e: LayoutChangeEvent) => {
    const { width: w, height: h } = e.nativeEvent.layout;
    if (w > 20 && h > 20) {
      if (Math.abs(w - measuredSize.width) > 3 || Math.abs(h - measuredSize.height) > 3) {
        setMeasuredSize({ width: w, height: h });
      }
    }
  };

  const cleanContent = content ? content.trim() : '';
  if (!cleanContent) return null;

  // Safe padding per mode
  const padHoriz = mode === 'miniPreview' 
    ? (isCompact ? 6 : 10) 
    : (mode === 'presentation' ? (isCompact ? 20 : 44) : 60);

  const padTop = mode === 'miniPreview' 
    ? (isCompact ? 4 : 6) 
    : (mode === 'presentation' ? (isCompact ? 16 : 28) : 40);

  const padBottom = mode === 'miniPreview' 
    ? (isCompact ? 4 : 6) 
    : (mode === 'presentation' ? (isCompact ? 75 : 85) : 50);

  const safeW = Math.max(40, measuredSize.width - padHoriz * 2);
  const safeH = Math.max(30, measuredSize.height - (padTop + padBottom));

  const lines = cleanContent.split('\n');
  const firstLine = lines[0]?.trim() || '';
  const hasReference = lines.length > 1 && /^([1-3]?\s?[A-Za-zÁÉÍÓÚáéíóúñÑ]+)\s+\d+:\d+(-\d+)?$/.test(firstLine);

  const referenceText = hasReference ? firstLine : null;
  const bodyText = hasReference ? lines.slice(1).join('\n').trim() : cleanContent;

  const fontConfig = computeOptimalFontSize(
    bodyText,
    referenceText,
    safeW,
    safeH,
    mode,
    isCompact,
    sizeMultiplier
  );

  return (
    <View 
      style={{
        flex: 1,
        width: '100%',
        height: '100%',
        alignSelf: 'stretch',
        justifyContent: 'center',
        alignItems: 'center',
        paddingHorizontal: padHoriz,
        paddingTop: padTop,
        paddingBottom: padBottom,
        zIndex: 1,
      }}
      onLayout={handleLayout}
    >
      <View
        style={[
          {
            width: '100%',
            alignSelf: 'stretch',
            alignItems: 'center',
            justifyContent: 'center',
          },
          textHasBackground && {
            backgroundColor: 'rgba(0, 0, 0, 0.85)',
            paddingHorizontal: mode === 'miniPreview' ? 4 : (isCompact ? 14 : 22),
            paddingVertical: mode === 'miniPreview' ? 2 : (isCompact ? 8 : 14),
            borderRadius: mode === 'miniPreview' ? 4 : 10,
          }
        ]}
      >
        {referenceText && (
          <Text
            style={{
              width: '100%',
              alignSelf: 'stretch',
              textAlign: 'center',
              fontSize: fontConfig.refFontSize,
              lineHeight: fontConfig.refLineHeight,
              color: textColor === '#ffffff' ? '#93c5fd' : textColor,
              fontWeight: 'bold',
              marginBottom: fontConfig.refMarginBottom,
              textShadowColor: 'rgba(0, 0, 0, 0.85)',
              textShadowOffset: { width: -1, height: 1 },
              textShadowRadius: 8,
            }}
          >
            {referenceText}
          </Text>
        )}
        <Text
          style={{
            width: '100%',
            alignSelf: 'stretch',
            textAlign: 'center',
            fontSize: fontConfig.fontSize,
            lineHeight: fontConfig.lineHeight,
            color: textColor,
            fontWeight: 'bold',
            flexWrap: 'wrap',
            textShadowColor: 'rgba(0, 0, 0, 0.85)',
            textShadowOffset: { width: -1, height: 1 },
            textShadowRadius: 10,
          }}
        >
          {bodyText}
        </Text>
      </View>
    </View>
  );
};

export default function VisualDTBApp() {
  const { width, height } = useWindowDimensions();
  const isLandscape = width > height;
  const isPortrait = height >= width;
  const isCompact = Math.min(width, height) < 600;

  const [activeModule, setActiveModule] = useState<ModuleType>('Bible');
  const [projection, setProjection] = useState<ProjectionData>({ type: 'text', content: 'VISUAL DTB\nListo para proyectar' });
  
  // Toolbar states
  const [isBlackout, setIsBlackout] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [isPresentationMode, setIsPresentationMode] = useState(false);

  // Timer State
  const [timerMinutes, setTimerMinutes] = useState<number>(5);
  const [timeLeft, setTimeLeft] = useState<number>(300);
  const [timerRunning, setTimerRunning] = useState<boolean>(false);

  // Web State
  const [webUrl, setWebUrl] = useState<string>('https://www.google.com');

  // Messages (Marquee) State
  const [messageInput, setMessageInput] = useState<string>('');
  const [messageReps, setMessageReps] = useState<string>('3');
  const [activeMarquee, setActiveMarquee] = useState<string>('');
  const [marqueeSpeed, setMarqueeSpeed] = useState<'muy_lento' | 'lento' | 'normal' | 'rapido'>('normal');
  const [marqueeContainerWidth, setMarqueeContainerWidth] = useState<number>(360);
  const scrollX = useRef(new Animated.Value(360)).current;
  const scrollExtX = useRef(new Animated.Value(1400)).current;
  const marqueeAnimRef = useRef<Animated.CompositeAnimation | null>(null);

  // Songs State
  const [songsList, setSongsList] = useState(mockSongs);
  const [selectedSongId, setSelectedSongId] = useState<string>('');
  const [songSearch, setSongSearch] = useState<string>('');

  // New Song States
  const [isAddingSong, setIsAddingSong] = useState(false);
  const [newSongTitle, setNewSongTitle] = useState('');
  const [newSongLyrics, setNewSongLyrics] = useState('');

  // Bible State
  const [loadedBibles, setLoadedBibles] = useState<any[]>([{ id: 'rv1960', name: 'RV1960', data: fullBible }]);
  const [activeBibleId, setActiveBibleId] = useState<string>('rv1960');
  const [selectedBook, setSelectedBook] = useState<string>('Mateo');
  const [selectedChapter, setSelectedChapter] = useState<number>(8);
  const [bibleSearch, setBibleSearch] = useState<string>('');

  // Media Background State
  const [backgroundMedia, setBackgroundMedia] = useState<{type: 'image' | 'video', uri: string} | null>(null);
  const [mediaPreviewUri, setMediaPreviewUri] = useState<string | null>(null);
  const [mediaPreviewType, setMediaPreviewType] = useState<'image'|'video'|null>(null);
  const [customBackgrounds, setCustomBackgrounds] = useState<any[]>(defaultBackgrounds);

  // Toolbar Slider & Color states
  const [brightness, setBrightness] = useState<number>(100);
  const [textSize, setTextSize] = useState<number>(48);
  const [textColor, setTextColor] = useState<string>('#ffffff');
  const [textHasBackground, setTextHasBackground] = useState<boolean>(false);

  // External Display & Wireless Cast State
  const externalScreens = useExternalDisplay();
  const castSession = useCastSessionSafe();
  const hasHardwareDisplay = Object.keys(externalScreens).length > 0;
  const isCastConnected = !!castSession;
  const hasExternalDisplay = hasHardwareDisplay || isCastConnected;
  const [externalDisplayEnabled, setExternalDisplayEnabled] = useState<boolean>(true);

  // Document State & Picking Lock
  const isPickingDocRef = useRef<boolean>(false);
  const [isReadingDocument, setIsReadingDocument] = useState<boolean>(false);
  const [currentDocName, setCurrentDocName] = useState<string>('');

  // Service Order State
  const [services, setServices] = useState<ServiceOrder[]>(defaultServices);
  const [activeServiceId, setActiveServiceId] = useState<string>('srv-default-1');
  const [activeServiceItemId, setActiveServiceItemId] = useState<string | null>(null);
  const [recentVerses, setRecentVerses] = useState<{ ref: string; text: string; fullContent: string }[]>([]);

  // Load saved services on mount
  useEffect(() => {
    loadSavedServices().then((loaded) => {
      if (loaded && loaded.length > 0) {
        setServices(loaded);
        setActiveServiceId(loaded[0].id);
      }
    });
  }, []);

  const updateServices = (newServices: ServiceOrder[]) => {
    setServices(newServices);
    saveServicesToDisk(newServices);
  };

  const handleCreateService = (name: string, date: string) => {
    const newService: ServiceOrder = {
      id: 'srv-' + Date.now(),
      name,
      date,
      defaultBackgroundUri: backgroundMedia?.uri || defaultBackgrounds[0].uri,
      defaultBackgroundType: (backgroundMedia?.type || defaultBackgrounds[0].type) as any,
      items: [],
    };
    const updated = [newService, ...services];
    updateServices(updated);
    setActiveServiceId(newService.id);
  };

  const handleDeleteService = (serviceId: string) => {
    const updated = services.filter((s) => s.id !== serviceId);
    updateServices(updated);
    if (activeServiceId === serviceId && updated.length > 0) {
      setActiveServiceId(updated[0].id);
    }
  };

  const handleUpdateServiceBackground = (serviceId: string, bg: { uri: string; type: 'image' | 'video' } | null) => {
    const updated = services.map((s) => {
      if (s.id === serviceId) {
        return {
          ...s,
          defaultBackgroundUri: bg?.uri || null,
          defaultBackgroundType: bg?.type || null,
        };
      }
      return s;
    });
    updateServices(updated);
  };

  const handleAddItemToService = (serviceId: string, itemData: Omit<ServiceItem, 'id'>) => {
    const newItem: ServiceItem = {
      id: 'item-' + Date.now() + '-' + Math.floor(Math.random() * 1000),
      ...itemData,
    };
    const updated = services.map((s) => {
      if (s.id === serviceId) {
        return {
          ...s,
          items: [...s.items, newItem],
        };
      }
      return s;
    });
    updateServices(updated);
  };

  const handleRemoveItemFromService = (serviceId: string, itemId: string) => {
    const updated = services.map((s) => {
      if (s.id === serviceId) {
        return {
          ...s,
          items: s.items.filter((item) => item.id !== itemId),
        };
      }
      return s;
    });
    updateServices(updated);
    if (activeServiceItemId === itemId) {
      setActiveServiceItemId(null);
    }
  };

  const handleReorderItemInService = (serviceId: string, itemId: string, direction: 'up' | 'down') => {
    const service = services.find((s) => s.id === serviceId);
    if (!service) return;
    const items = [...service.items];
    const index = items.findIndex((i) => i.id === itemId);
    if (index < 0) return;
    const targetIndex = direction === 'up' ? index - 1 : index + 1;
    if (targetIndex < 0 || targetIndex >= items.length) return;
    const temp = items[index];
    items[index] = items[targetIndex];
    items[targetIndex] = temp;

    const updated = services.map((s) => (s.id === serviceId ? { ...s, items } : s));
    updateServices(updated);
  };

  const handleUpdateItemBackground = (
    serviceId: string,
    itemId: string,
    bg: { uri: string; type: 'image' | 'video' } | null
  ) => {
    const updated = services.map((s) => {
      if (s.id === serviceId) {
        return {
          ...s,
          items: s.items.map((i) =>
            i.id === itemId
              ? { ...i, backgroundUri: bg?.uri || null, backgroundType: bg?.type || null }
              : i
          ),
        };
      }
      return s;
    });
    updateServices(updated);
  };

  const handleProjectServiceItem = (item: ServiceItem) => {
    setActiveServiceItemId(item.id);
    const service = services.find((s) => s.id === activeServiceId);
    const bgUri = item.backgroundUri || service?.defaultBackgroundUri;
    const bgType = item.backgroundType || service?.defaultBackgroundType || 'image';

    if (bgUri) {
      setBackgroundMedia({ type: bgType, uri: bgUri });
    }

    if (item.type === 'song' && item.stanzas && item.stanzas.length > 0) {
      const items = item.stanzas.map((st) => st.text);
      setPlaylist({ items, currentIndex: 0 });
      setProjection({ type: 'text', content: items[0] });
    } else if (item.type === 'verse' || item.type === 'note') {
      setPlaylist({ items: [item.content], currentIndex: 0 });
      setProjection({ type: 'text', content: item.content });
    } else if (item.type === 'media') {
      setProjection({ type: item.backgroundType || 'image', content: item.content });
    }
  };

  const addRecentVerse = (item: { ref: string; text: string; fullContent: string }) => {
    setRecentVerses((prev) => {
      const filtered = prev.filter((v) => v.ref !== item.ref);
      return [item, ...filtered].slice(0, 25);
    });
  };

  const quickAddVerseToActiveService = (ref: string, text: string, fullContent: string) => {
    const service = services.find((s) => s.id === activeServiceId) || services[0];
    if (!service) return;
    handleAddItemToService(service.id, {
      type: 'verse',
      title: ref,
      subtitle: text.length > 55 ? text.substring(0, 55) + '...' : text,
      verseRef: ref,
      content: fullContent,
      backgroundUri: service.defaultBackgroundUri || null,
      backgroundType: service.defaultBackgroundType || null,
    });
    Alert.alert('Añadido al Culto', `${ref} añadido a "${service.name}".`);
  };

  const quickAddSongToActiveService = (song: any) => {
    const service = services.find((s) => s.id === activeServiceId) || services[0];
    if (!service) return;
    const firstText = song.stanzas?.[0]?.text || song.title;
    handleAddItemToService(service.id, {
      type: 'song',
      title: song.title,
      subtitle: `${song.stanzas?.length || 0} estrofas`,
      songId: song.id,
      content: firstText,
      stanzas: song.stanzas,
      backgroundUri: service.defaultBackgroundUri || null,
      backgroundType: service.defaultBackgroundType || null,
    });
    Alert.alert('Añadido al Culto', `"${song.title}" añadida a "${service.name}".`);
  };

  // Playlist Navigation
  const [playlist, setPlaylist] = useState<{ items: string[], currentIndex: number } | null>(null);

  const handleNextSlide = () => {
    if (playlist && playlist.currentIndex < playlist.items.length - 1) {
       const next = playlist.currentIndex + 1;
       setPlaylist({ ...playlist, currentIndex: next });
       setProjection({ type: 'text', content: playlist.items[next] });
    }
  };

  const handlePrevSlide = () => {
    if (playlist && playlist.currentIndex > 0) {
       const prev = playlist.currentIndex - 1;
       setPlaylist({ ...playlist, currentIndex: prev });
       setProjection({ type: 'text', content: playlist.items[prev] });
    }
  };

  useEffect(() => {
    if (Platform.OS === 'web') {
      const handleKeyDown = (e: any) => {
        if (e.key === 'ArrowUp') handlePrevSlide();
        if (e.key === 'ArrowDown') handleNextSlide();
      };
      window.addEventListener('keydown', handleKeyDown);
      return () => window.removeEventListener('keydown', handleKeyDown);
    }
  }, [playlist]);

  // Timer Effect
  useEffect(() => {
    let interval: ReturnType<typeof setInterval>;
    if (timerRunning && timeLeft > 0 && !isPaused) {
      interval = setInterval(() => {
        setTimeLeft(prev => {
          const newTime = prev - 1;
          if (projection.content.includes('\u23F3')) {
             const mins = Math.floor(newTime / 60).toString().padStart(2, '0');
             const secs = (newTime % 60).toString().padStart(2, '0');
             setProjection({ type: 'text', content: '\u23F3 ' + mins + ':' + secs });
          }
          return newTime;
        });
      }, 1000);
    } else if (timeLeft === 0 && timerRunning) {
      setTimerRunning(false);
      if (projection.content.includes('\u23F3')) {
         setProjection({ type: 'text', content: 'Tiempo Finalizado' });
      }
    }
    return () => clearInterval(interval);
  }, [timerRunning, timeLeft, projection, isPaused]);

  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60).toString().padStart(2, '0');
    const s = (seconds % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  };

  const allNavItems: { id: ModuleType, icon: keyof typeof Ionicons.glyphMap, label: string }[] = [
    { id: 'Service', icon: 'layers', label: 'Servicio' },
    { id: 'Bible', icon: 'book', label: 'Biblia' },
    { id: 'Songs', icon: 'musical-notes', label: 'Canciones' },
    { id: 'Media', icon: 'images', label: 'Medios' },
    { id: 'Documents', icon: 'document-text', label: 'Doc.' },
    { id: 'Messages', icon: 'chatbox-ellipses', label: 'Mensajes' },
    { id: 'Timer', icon: 'timer', label: 'Timer' },
    { id: 'Web', icon: 'globe', label: 'Web' },
    { id: 'Settings', icon: 'settings', label: 'Ajustes' },
  ];

  const navItems = allNavItems.filter(item => item.id !== 'Documents' || Platform.OS === 'ios');

  const pickMedia = async () => {
    if (isPickingDocRef.current) return;
    isPickingDocRef.current = true;
    try {
      let result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ['images', 'videos'],
        allowsEditing: false,
        quality: 1,
      });
      if (!result.canceled && result.assets && result.assets.length > 0) {
        setMediaPreviewUri(result.assets[0].uri);
        setMediaPreviewType(result.assets[0].type === 'video' ? 'video' : 'image');
      }
    } catch (err) {
      console.warn('pickMedia error:', err);
    } finally {
      setTimeout(() => {
        isPickingDocRef.current = false;
      }, 500);
    }
  };

  const pickDocument = async () => {
    if (isPickingDocRef.current) return;
    isPickingDocRef.current = true;
    setIsReadingDocument(true);
    try {
      const result = await DocumentPicker.getDocumentAsync({
        type: '*/*',
        copyToCacheDirectory: true
      });
      if (!result.canceled && result.assets && result.assets.length > 0) {
        const asset = result.assets[0];
        const uri = asset.uri;
        const fileName = asset.name || 'Documento';
        setCurrentDocName(fileName);

        setProjection({
          type: 'document',
          content: uri,
          title: fileName,
        });

        // En Android, abrir con la app de visor de PDF / documentos del sistema
        if (Platform.OS === 'android') {
          try {
            await Sharing.shareAsync(uri, {
              dialogTitle: `Abrir ${fileName} con...`,
              mimeType: asset.mimeType || 'application/pdf',
            });
          } catch (shareErr) {
            console.warn('Could not launch external viewer:', shareErr);
          }
        }
      }
    } catch (err: any) {
      const msg = err?.message || String(err);
      if (!msg.includes('Different document picking in progress')) {
        Alert.alert('Aviso', 'No se pudo seleccionar el documento: ' + msg);
      }
    } finally {
      setIsReadingDocument(false);
      setTimeout(() => {
        isPickingDocRef.current = false;
      }, 600);
    }
  };

  const stopMarquee = () => {
    setActiveMarquee('');
    if (marqueeAnimRef.current) {
      marqueeAnimRef.current.stop();
    }
    scrollX.stopAnimation();
    scrollExtX.stopAnimation();
  };

  const playMarquee = () => {
    if (!messageInput.trim()) return;
    
    // Stop any running animations first
    if (marqueeAnimRef.current) {
      marqueeAnimRef.current.stop();
    }
    scrollX.stopAnimation();
    scrollExtX.stopAnimation();

    setActiveMarquee(messageInput.trim());
    const reps = parseInt(messageReps) || 3;
    let count = 0;

    const getDuration = () => {
      if (marqueeSpeed === 'rapido') return 5000;
      if (marqueeSpeed === 'normal') return 9000;
      if (marqueeSpeed === 'lento') return 16000;
      return 26000; // 'muy_lento'
    };
    
    const animate = () => {
      if ((reps < 999 && count >= reps) || isPaused) {
        if (!isPaused) setActiveMarquee('');
        return;
      }
      
      const startX = marqueeContainerWidth > 0 ? marqueeContainerWidth : 360;
      scrollX.setValue(startX);
      scrollExtX.setValue(1400); 

      const anim = Animated.parallel([
        Animated.timing(scrollX, {
          toValue: -650, 
          duration: getDuration(), 
          easing: Easing.linear,
          useNativeDriver: true,
        }),
        Animated.timing(scrollExtX, {
          toValue: -1500, 
          duration: getDuration(), 
          easing: Easing.linear,
          useNativeDriver: true,
        })
      ]);

      marqueeAnimRef.current = anim;
      anim.start(({ finished }) => {
        if (finished && !isPaused) {
          count++;
          animate();
        }
      });
    };
    
    animate();
  };

  useEffect(() => {
    if (isPaused) {
      if (marqueeAnimRef.current) {
        marqueeAnimRef.current.stop();
      }
      scrollX.stopAnimation();
      scrollExtX.stopAnimation();
    }
  }, [isPaused]);


  const handleSaveSong = () => {
    if (!newSongTitle.trim() || !newSongLyrics.trim()) return;
    const stanzasRaw = newSongLyrics.split(/\n\s*\n/);
    const stanzas = stanzasRaw.filter(s => s.trim().length > 0).map((text, index) => ({
       name: `Párrafo ${index + 1}`,
       text: text.trim()
    }));
    const newSongId = 'custom-' + Date.now();
    const newSong = { id: newSongId, title: newSongTitle, stanzas };
    setSongsList([newSong, ...songsList]);
    setIsAddingSong(false);
    setNewSongTitle('');
    setNewSongLyrics('');
    setSelectedSongId(newSong.id);
  };

  const handleEditSong = (id: string) => {
    const song = songsList.find(s => s.id === id);
    if (!song) return;
    setNewSongTitle(song.title);
    setNewSongLyrics(song.stanzas.map((s: any) => s.text).join('\n\n'));
    setSongsList(songsList.filter(s => s.id !== id));
    setIsAddingSong(true);
  };

  const handleDeleteSong = (id: string) => {
    Alert.alert('Eliminar Canción', '¿Estás seguro de que deseas eliminar esta canción?', [
      { text: 'Cancelar', style: 'cancel' },
      { 
        text: 'Eliminar', 
        style: 'destructive', 
        onPress: () => {
          const updated = songsList.filter(s => s.id !== id);
          setSongsList(updated);
          if (selectedSongId === id && updated.length > 0) {
            setSelectedSongId(updated[0].id);
          }
        } 
      }
    ]);
  };

  const renderModuleContent = () => {
    switch(activeModule) {
      case 'Service':
        return (
          <ServiceOrderModule
            services={services}
            activeServiceId={activeServiceId}
            activeServiceItemId={activeServiceItemId}
            onSelectService={setActiveServiceId}
            onCreateService={handleCreateService}
            onDeleteService={handleDeleteService}
            onUpdateServiceBackground={handleUpdateServiceBackground}
            onAddItem={handleAddItemToService}
            onRemoveItem={handleRemoveItemFromService}
            onReorderItem={handleReorderItemInService}
            onUpdateItemBackground={handleUpdateItemBackground}
            onProjectItem={handleProjectServiceItem}
            songsList={songsList}
            recentVerses={recentVerses}
            customBackgrounds={customBackgrounds}
            loadedBibles={loadedBibles}
            isCompact={isCompact}
            isLandscape={isLandscape}
          />
        );

      case 'Bible':
        const activeBibleObj = loadedBibles.find(b => b.id === activeBibleId) || loadedBibles[0];
        const currentBibleData = activeBibleObj.data;
        const filteredBooks = currentBibleData.filter((b: any) => b.name.toLowerCase().includes(bibleSearch.toLowerCase()));
        const activeBookData = selectedBook ? (currentBibleData.find((b: any) => b.name === selectedBook) || null) : null;
        const activeChapterData = activeBookData ? (activeBookData.chapters[selectedChapter - 1] || activeBookData.chapters[0] || []) : [];

        const handleLoadBible = async () => {
           if (isPickingDocRef.current) return;
           isPickingDocRef.current = true;
           try {
             let result = await DocumentPicker.getDocumentAsync({
               type: '*/*',
               copyToCacheDirectory: true
             });
             if (!result.canceled && result.assets && result.assets[0].uri) {
                const fileUri = result.assets[0].uri;
                if (!result.assets[0].name.toLowerCase().endsWith('.json')) {
                   Alert.alert('Error', 'El archivo debe ser un JSON.');
                   return;
                }
                const fileStr = await readFileAsText(fileUri);
                const parsedBible = JSON.parse(fileStr);
                if (Array.isArray(parsedBible) && parsedBible[0] && parsedBible[0].name && Array.isArray(parsedBible[0].chapters)) {
                   const newId = 'bible-' + Date.now();
                   let newName = result.assets[0].name.replace('.json', '');
                   if (newName.length > 12) newName = newName.substring(0, 12) + '...';
                   setLoadedBibles([...loadedBibles, { id: newId, name: newName, data: parsedBible }]);
                   setActiveBibleId(newId);
                   setSelectedBook(parsedBible[0].name);
                   setSelectedChapter(1);
                   Alert.alert('Éxito', 'Biblia cargada correctamente.');
                } else {
                   Alert.alert('Error', 'El formato del archivo JSON no es compatible.');
                }
             }
           } catch(e: any) {
             const msg = e?.message || String(e);
             if (!msg.includes('Different document picking in progress')) {
               Alert.alert('Error', 'No se pudo leer el archivo: ' + msg);
             }
           } finally {
             setTimeout(() => {
               isPickingDocRef.current = false;
             }, 600);
           }
        };

        return (
          <View style={[styles.twoColumnLayout, isPortrait && { flexDirection: 'column' }]}>
             {/* Columna Izquierda: Buscador y Libros */}
             <View style={[styles.columnLeft, isLandscape ? { width: Math.min(240, width * 0.32) } : { height: isCompact ? 160 : 220, borderRightWidth: 0, borderBottomWidth: 1 }]}>
                <View style={{flexDirection: 'row', padding: 10, borderBottomWidth: 1, borderBottomColor: '#1e293b'}}>
                  <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                    {loadedBibles.map(b => (
                      <TouchableOpacity 
                        key={b.id} 
                        style={{padding: 8, paddingHorizontal: 12, marginRight: 8, backgroundColor: activeBibleId === b.id ? '#3b82f6' : '#1e293b', borderRadius: 6}}
                        onPress={() => { setActiveBibleId(b.id); setSelectedBook(b.data[0].name); setSelectedChapter(1); }}
                      >
                        <Text style={{color: 'white', fontWeight: 'bold'}}>{b.name}</Text>
                      </TouchableOpacity>
                    ))}
                    <TouchableOpacity style={{padding: 8, paddingHorizontal: 12, backgroundColor: '#10b981', borderRadius: 6}} onPress={handleLoadBible}>
                      <Text style={{color: 'white', fontWeight: 'bold'}}>+ Añadir JSON</Text>
                    </TouchableOpacity>
                  </ScrollView>
                </View>

                <View style={styles.searchBar}>
                  <Ionicons name="search" size={16} color="#94a3b8" />
                  <TextInput 
                    style={styles.searchInput}
                    placeholder="Buscar libro (ej. Mateo)..."
                    placeholderTextColor="#64748b"
                    value={bibleSearch}
                    onChangeText={setBibleSearch}
                  />
                </View>
                <ScrollView style={{flex: 1}}>
                   {filteredBooks.map((b: any) => {
                     const isExpanded = selectedBook === b.name;
                     return (
                       <View key={b.name} style={{borderBottomWidth: 1, borderBottomColor: '#0f172a'}}>
                         <TouchableOpacity 
                           style={[
                             styles.bookHeader, 
                             isExpanded && { backgroundColor: '#1e293b', borderLeftWidth: 3, borderLeftColor: '#38bdf8' }
                           ]} 
                           onPress={() => {
                             if (isExpanded) {
                               setSelectedBook('');
                             } else {
                               setSelectedBook(b.name);
                               setSelectedChapter(1);
                             }
                           }}
                         >
                           <View style={{flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', width: '100%'}}>
                             <Text style={[styles.bookHeaderText, isExpanded && { color: '#38bdf8', fontWeight: 'bold' }]}>{b.name}</Text>
                             <Ionicons 
                               name={isExpanded ? "chevron-up" : "chevron-down"} 
                               size={16} 
                               color={isExpanded ? "#38bdf8" : "#64748b"} 
                             />
                           </View>
                         </TouchableOpacity>
                         {isExpanded && (
                           <View style={{flexDirection: 'row', flexWrap: 'wrap', padding: 8, backgroundColor: '#0f172a'}}>
                             {b.chapters.map((c: any, index: number) => {
                               const chapterNum = index + 1;
                               return (
                                 <TouchableOpacity 
                                   key={`${b.name}-${chapterNum}`} 
                                   style={isCompact ? { width: 28, height: 28, justifyContent: 'center', alignItems: 'center', margin: 2, borderRadius: 14, backgroundColor: selectedChapter === chapterNum ? '#3b82f6' : '#1e293b' } : { width: 40, height: 40, justifyContent: 'center', alignItems: 'center', margin: 4, borderRadius: 20, backgroundColor: selectedChapter === chapterNum ? '#3b82f6' : '#1e293b' }}
                                   onPress={() => setSelectedChapter(chapterNum)}
                                 >
                                   <Text style={{ color: selectedChapter === chapterNum ? '#ffffff' : '#94a3b8', fontWeight: 'bold' }}>{chapterNum}</Text>
                                 </TouchableOpacity>
                               );
                             })}
                           </View>
                         )}
                       </View>
                     );
                   })}
                </ScrollView>
             </View>

             {/* Columna Derecha: Versículos */}
             <View style={[styles.columnRight, { flex: 1, padding: 12 }]}>
               {selectedBook && activeBookData ? (
                 <>
                   <Text style={[styles.mockTitle, { fontSize: 16, marginBottom: 10 }]}>{selectedBook} {selectedChapter} ({activeBibleObj?.name || 'Biblia'})</Text>
                   <ScrollView style={{flex: 1}}>
                     {activeChapterData.map((verseText: string, index: number) => {
                       const verseNum = index + 1;
                       return (
                         <TouchableOpacity 
                           key={verseNum}
                           style={styles.mockVerse} 
                           onPress={() => {
                             const fullRef = `${selectedBook} ${selectedChapter}:${verseNum}`;
                             const verseContent = `${fullRef}\n${verseText}`;
                             addRecentVerse({ ref: fullRef, text: verseText, fullContent: verseContent });
                             const items = activeChapterData.map((v: string, i: number) => `${selectedBook} ${selectedChapter}:${i+1}\n${v}`);
                             setPlaylist({ items, currentIndex: index });
                             setProjection({ type: 'text', content: items[index] });
                           }}
                         >
                           <Text style={styles.verseNumber}>{verseNum}</Text>
                           <Text style={styles.verseText}>{verseText}</Text>
                           <TouchableOpacity
                             style={{
                               paddingHorizontal: 8,
                               paddingVertical: 4,
                               backgroundColor: '#f59e0b20',
                               borderRadius: 6,
                               borderWidth: 1,
                               borderColor: '#f59e0b50',
                               flexDirection: 'row',
                               alignItems: 'center',
                               gap: 3,
                               marginLeft: 8,
                             }}
                             onPress={(e) => {
                               e.stopPropagation();
                               const fullRef = `${selectedBook} ${selectedChapter}:${verseNum}`;
                               const verseContent = `${fullRef}\n${verseText}`;
                               addRecentVerse({ ref: fullRef, text: verseText, fullContent: verseContent });
                               quickAddVerseToActiveService(fullRef, verseText, verseContent);
                             }}
                           >
                             <Ionicons name="add-circle" size={14} color="#fbbf24" />
                             <Text style={{ color: '#fbbf24', fontSize: 10, fontWeight: 'bold' }}>+ Culto</Text>
                           </TouchableOpacity>
                         </TouchableOpacity>
                       );
                     })}
                   </ScrollView>
                 </>
               ) : (
                 <View style={{flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20}}>
                   <Ionicons name="book-outline" size={48} color="#475569" style={{marginBottom: 12}} />
                   <Text style={{color: '#94a3b8', fontSize: 16, fontWeight: 'bold', textAlign: 'center'}}>Ningún libro seleccionado</Text>
                   <Text style={{color: '#64748b', fontSize: 13, textAlign: 'center', marginTop: 6, lineHeight: 18}}>
                     Toca un libro en la columna izquierda para desplegar sus capítulos y versículos.
                   </Text>
                 </View>
               )}
             </View>
          </View>
        );

      case 'Songs':
        const activeSong = selectedSongId ? (songsList.find(s => s.id === selectedSongId) || null) : null;
        const filteredSongs = songsList.filter(s => s.title.toLowerCase().includes(songSearch.toLowerCase()));

        return (
          <View style={[styles.twoColumnLayout, isPortrait && { flexDirection: 'column' }]}>
             {/* Columna Izquierda: Canciones */}
             <View style={[styles.columnLeft, isLandscape ? { width: Math.min(240, width * 0.32) } : { height: 200, borderRightWidth: 0, borderBottomWidth: 1 }]}>
                <View style={styles.searchBar}>
                  <Ionicons name="search" size={16} color="#94a3b8" />
                  <TextInput 
                    style={styles.searchInput}
                    placeholder="Buscar canción..."
                    placeholderTextColor="#64748b"
                    value={songSearch}
                    onChangeText={setSongSearch}
                  />
                  <TouchableOpacity 
                     style={{backgroundColor: '#10b981', padding: 6, borderRadius: 6, marginLeft: 8, paddingHorizontal: 12}}
                     onPress={() => setIsAddingSong(true)}
                  >
                     <Text style={{color: 'white', fontWeight: 'bold'}}>+ Nueva</Text>
                  </TouchableOpacity>
                </View>
                <ScrollView style={{flex: 1}} keyboardShouldPersistTaps="always">
                   {filteredSongs.map(s => {
                     const isExpanded = selectedSongId === s.id;
                     return (
                       <View key={s.id} style={{borderBottomWidth: 1, borderBottomColor: '#1e293b'}}>
                         <TouchableOpacity 
                           style={[
                             styles.songListItem,
                             isExpanded && styles.songListItemActive,
                             { paddingHorizontal: 12, paddingVertical: 12, justifyContent: 'space-between', borderBottomWidth: 0 }
                           ]}
                           onPress={() => {
                             if (isExpanded) {
                               setSelectedSongId('');
                             } else {
                               setSelectedSongId(s.id);
                               setIsAddingSong(false);
                             }
                           }}
                         >
                           <View style={{flexDirection: 'row', alignItems: 'center', flex: 1, marginRight: 8}}>
                             <Ionicons name="musical-note" size={16} color={isExpanded ? "#38bdf8" : "#94a3b8"} style={{marginRight: 8}}/>
                             <Text style={[styles.songListText, isExpanded && {color: '#38bdf8', fontWeight: 'bold'}]} numberOfLines={1}>{s.title}</Text>
                           </View>
                           
                           <View style={{flexDirection: 'row', alignItems: 'center', gap: 6}}>
                             <TouchableOpacity 
                               style={{paddingHorizontal: 6, paddingVertical: 3, backgroundColor: '#3b82f620', borderRadius: 4, borderWidth: 1, borderColor: '#3b82f640', flexDirection: 'row', alignItems: 'center', gap: 2}} 
                               onPress={(e) => {
                                 e.stopPropagation();
                                 quickAddSongToActiveService(s);
                               }}
                             >
                               <Ionicons name="add" size={13} color="#60a5fa" />
                               <Text style={{color: '#60a5fa', fontSize: 10, fontWeight: 'bold'}}>Culto</Text>
                             </TouchableOpacity>
                             {s.id.startsWith('custom') && (
                               <>
                                 <TouchableOpacity style={{padding: 4}} onPress={() => handleEditSong(s.id)}>
                                   <Ionicons name="pencil" size={16} color="#60a5fa" />
                                 </TouchableOpacity>
                                 <TouchableOpacity style={{padding: 4}} onPress={() => handleDeleteSong(s.id)}>
                                   <Ionicons name="trash" size={16} color="#ef4444" />
                                 </TouchableOpacity>
                               </>
                             )}
                             <Ionicons 
                               name={isExpanded ? "chevron-up" : "chevron-down"} 
                               size={16} 
                               color={isExpanded ? "#38bdf8" : "#64748b"} 
                             />
                           </View>
                         </TouchableOpacity>

                         {isExpanded && (
                           <View style={{backgroundColor: '#0f172a', padding: 8, paddingLeft: 12, borderTopWidth: 1, borderTopColor: '#1e293b'}}>
                             {s.stanzas.map((stanza: any, stIndex: number) => {
                               const isCurrentStanza = playlist?.items?.[playlist.currentIndex] === stanza.text;
                               return (
                                 <TouchableOpacity
                                   key={stIndex}
                                   style={{
                                     flexDirection: 'row',
                                     alignItems: 'center',
                                     paddingVertical: 6,
                                     paddingHorizontal: 8,
                                     marginVertical: 2,
                                     borderRadius: 6,
                                     backgroundColor: isCurrentStanza ? '#1e3a8a' : '#1e293b',
                                   }}
                                   onPress={() => {
                                     const items = s.stanzas.map((st: any) => st.text);
                                     setPlaylist({ items, currentIndex: stIndex });
                                     setProjection({ type: 'text', content: items[stIndex] });
                                   }}
                                 >
                                   <Text style={{color: '#38bdf8', fontSize: 11, fontWeight: 'bold', width: 68}} numberOfLines={1}>{stanza.name}</Text>
                                   <Text style={{color: '#94a3b8', fontSize: 11, flex: 1}} numberOfLines={1}>{stanza.text.replace(/\n/g, ' ')}</Text>
                                 </TouchableOpacity>
                               );
                             })}
                           </View>
                         )}
                       </View>
                     );
                   })}
                </ScrollView>
             </View>

             {/* Columna Derecha: Estrofas o Formulario */}
             <View style={[styles.columnRight, { flex: 1, padding: 12 }]}>
               {isAddingSong ? (
                 <ScrollView style={{flex: 1, padding: 16}} contentContainerStyle={{paddingBottom: 40}}>
                     <Text style={styles.mockTitle}>Crear Nueva Canción</Text>
                    <Text style={{color: '#94a3b8', marginBottom: 10}}>Pega la letra completa. Un doble salto de línea (espacio vacío) creará una estrofa separada automáticamente.</Text>
                    
                    <TextInput 
                      style={[styles.searchInput, {backgroundColor: '#1e293b', padding: 12, marginBottom: 10, color: 'white'}]}
                      placeholder="Título de la canción..."
                      placeholderTextColor="#64748b"
                      value={newSongTitle}
                      onChangeText={setNewSongTitle}
                    />
                    
                    <TextInput 
                      style={[styles.searchInput, {backgroundColor: '#1e293b', padding: 12, marginBottom: 20, color: 'white', textAlignVertical: 'top', minHeight: 250}]}
                      placeholder="Letra de la canción...\n\n(Doble 'Enter' para separar estrofas)"
                      placeholderTextColor="#64748b"
                      value={newSongLyrics}
                      onChangeText={setNewSongLyrics}
                      multiline
                    />
                    
                    <View style={{flexDirection: 'row', gap: 10}}>
                      <TouchableOpacity style={[styles.projectButton, {flex: 1, backgroundColor: '#10b981'}]} onPress={handleSaveSong}>
                         <Text style={styles.projectButtonText}>Guardar Canción</Text>
                      </TouchableOpacity>
                      <TouchableOpacity style={[styles.projectButton, {backgroundColor: '#ef4444'}]} onPress={() => setIsAddingSong(false)}>
                         <Text style={styles.projectButtonText}>Cancelar</Text>
                      </TouchableOpacity>
                    </View>
                 </ScrollView>
               ) : activeSong ? (
                 <>
                   <View style={{flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12}}>
                     <Text style={[styles.mockTitle, {marginBottom: 0, flex: 1}]}>{activeSong.title}</Text>
                     <TouchableOpacity
                       style={{flexDirection: 'row', alignItems: 'center', gap: 4, backgroundColor: '#3b82f620', paddingHorizontal: 10, paddingVertical: 6, borderRadius: 6, borderWidth: 1, borderColor: '#3b82f650'}}
                       onPress={() => quickAddSongToActiveService(activeSong)}
                     >
                       <Ionicons name="add-circle" size={15} color="#60a5fa" />
                       <Text style={{color: '#60a5fa', fontSize: 11, fontWeight: 'bold'}}>Añadir al Culto</Text>
                     </TouchableOpacity>
                   </View>
                   <ScrollView style={{flex: 1}}>
                     {activeSong.stanzas.map((stanza, index) => {
                       const isCurrentStanza = playlist?.items?.[playlist.currentIndex] === stanza.text;
                       return (
                         <TouchableOpacity 
                           key={index}
                           style={[styles.mockVerse, isCurrentStanza && { borderColor: '#3b82f6', borderWidth: 1 }]} 
                           onPress={() => {
                             const items = activeSong.stanzas.map((s: any) => s.text);
                             setPlaylist({ items, currentIndex: index });
                             setProjection({ type: 'text', content: items[index] });
                           }}
                         >
                           <View style={{width: 80}}>
                             <Text style={styles.verseNumber}>{stanza.name}</Text>
                           </View>
                           <Text style={styles.verseText}>{stanza.text}</Text>
                         </TouchableOpacity>
                       );
                     })}
                   </ScrollView>
                 </>
               ) : (
                 <View style={{flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20}}>
                   <Ionicons name="musical-notes-outline" size={48} color="#475569" style={{marginBottom: 12}} />
                   <Text style={{color: '#94a3b8', fontSize: 16, fontWeight: 'bold', textAlign: 'center'}}>Ninguna canción seleccionada</Text>
                   <Text style={{color: '#64748b', fontSize: 13, textAlign: 'center', marginTop: 6, lineHeight: 18}}>
                     Toca una canción en la columna izquierda para desplegarla y proyectar sus estrofas.
                   </Text>
                 </View>
               )}
             </View>
          </View>
        );

      case 'Media':
        return (
          <ScrollView style={styles.moduleContentSingle}>
            <View style={{flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 15, paddingRight: 10}}>
               <Text style={[styles.mockTitle, {marginBottom: 0}]}>Galería Multimedia y Fondos</Text>
               <TouchableOpacity style={{backgroundColor: '#ef4444', padding: 8, borderRadius: 6, flexDirection: 'row', alignItems: 'center'}} onPress={() => setBackgroundMedia(null)}>
                 <Ionicons name="trash-outline" size={16} color="white" style={{marginRight: 4}}/>
                 <Text style={{color: 'white', fontWeight: 'bold'}}>Fondo a Negro</Text>
               </TouchableOpacity>
            </View>
            <View style={styles.gridContainer}>
                 <TouchableOpacity style={[styles.gridBox, {width: isCompact ? 110 : 140, height: isCompact ? 110 : 140, backgroundColor: '#3b82f620', borderColor: '#3b82f6', borderWidth: 2, borderStyle: 'dashed'}]} onPress={pickMedia}>
                   <Ionicons name="cloud-upload" size={28} color="#3b82f6" />
                   <Text style={{color: '#3b82f6', marginTop: 8, fontWeight: 'bold', fontSize: isCompact ? 11 : 13, textAlign: 'center', paddingHorizontal: 6}}>Subir Imagen o Video</Text>
                 </TouchableOpacity>

                 {customBackgrounds.map(bg => {
                    const isCurrentBg = backgroundMedia?.uri === bg.uri;
                    return (
                      <TouchableOpacity 
                        key={bg.id} 
                        style={[
                          styles.gridBox, 
                          {
                            width: isCompact ? 110 : 140, 
                            height: isCompact ? 110 : 140, 
                            overflow: 'hidden', 
                            borderWidth: isCurrentBg ? 2 : 1, 
                            borderColor: isCurrentBg ? '#10b981' : '#334155'
                          }
                        ]} 
                        onPress={() => {
                          // AUTOMÁTICAMENTE AL TOCARLO SE VA COMO FONDO
                          setBackgroundMedia({ type: bg.type as 'image'|'video', uri: bg.uri });
                          setMediaPreviewUri(bg.uri);
                          setMediaPreviewType(bg.type as 'image'|'video');
                        }}>
                        <Image source={{uri: bg.thumbnail}} style={{width: '100%', height: '100%', resizeMode: 'cover'}} />
                        
                        {/* Indicador de Fondo Activo */}
                        {isCurrentBg && (
                          <View style={{position: 'absolute', top: 5, left: 5, backgroundColor: '#10b981', paddingHorizontal: 5, paddingVertical: 2, borderRadius: 4, flexDirection: 'row', alignItems: 'center', gap: 3}}>
                            <Ionicons name="checkmark-circle" size={11} color="white" />
                            <Text style={{color: 'white', fontSize: 9, fontWeight: 'bold'}}>Fondo</Text>
                          </View>
                        )}

                        <View style={{position: 'absolute', bottom: 5, left: 5, right: 5, backgroundColor: 'rgba(0,0,0,0.7)', padding: 4, borderRadius: 4}}>
                           <Text style={{color: 'white', fontSize: 10, textAlign: 'center', fontWeight: 'bold'}} numberOfLines={1}>{bg.name}</Text>
                        </View>
                        <TouchableOpacity 
                          style={{position: 'absolute', top: 5, right: 5, backgroundColor: 'rgba(0,0,0,0.6)', padding: 6, borderRadius: 15, zIndex: 10}}
                          onPress={(e) => {
                             e.stopPropagation();
                             Alert.alert('Eliminar', '¿Deseas quitar este fondo?', [
                               { text: 'Cancelar', style: 'cancel' },
                               { text: 'Eliminar', style: 'destructive', onPress: () => {
                                  if (backgroundMedia?.uri === bg.uri) {
                                    setBackgroundMedia(null);
                                  }
                                  setCustomBackgrounds(prev => prev.filter(item => item.id !== bg.id));
                                  if (mediaPreviewUri === bg.uri) {
                                    setMediaPreviewUri(null);
                                  }
                               }}
                             ]);
                          }}
                        >
                           <Ionicons name="ellipsis-vertical" size={14} color="white" />
                        </TouchableOpacity>
                      </TouchableOpacity>
                    );
                 })}
            </View>
            
            {mediaPreviewUri && (
               <View style={{marginTop: 18, backgroundColor: '#1e293b', padding: 14, borderRadius: 10, borderWidth: 1, borderColor: '#334155'}}>
                  <View style={{flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10}}>
                     <Text style={{color: '#e2e8f0', fontWeight: 'bold', fontSize: 13}}>
                       {mediaPreviewType === 'video' ? 'Video seleccionado' : 'Imagen seleccionada'}
                     </Text>
                     <TouchableOpacity onPress={() => setMediaPreviewUri(null)} style={{padding: 4}}>
                       <Ionicons name="close" size={18} color="#94a3b8" />
                     </TouchableOpacity>
                  </View>
                  
                  {mediaPreviewType === 'image' ? (
                     <Image source={{uri: mediaPreviewUri}} style={{width: '100%', height: 160, resizeMode: 'contain', borderRadius: 8, marginBottom: 12, backgroundColor: 'black'}} />
                  ) : (
                     <View style={{width: '100%', height: 160, backgroundColor: 'black', borderRadius: 8, marginBottom: 12, justifyContent: 'center', alignItems: 'center'}}>
                       <Ionicons name="videocam" size={48} color="#38bdf8" />
                       <Text style={{color: '#38bdf8', marginTop: 8, fontSize: 12, fontWeight: 'bold'}}>Video con sonido listo para proyectar</Text>
                     </View>
                  )}

                  <View style={{flexDirection: 'row', gap: 8, flexWrap: 'wrap'}}>
                     <TouchableOpacity 
                        style={[styles.projectButton, {flex: 1, backgroundColor: '#10b981', flexDirection: 'row', justifyContent: 'center', alignItems: 'center', gap: 6}]} 
                        onPress={() => {
                          setProjection({ type: mediaPreviewType || 'image', content: mediaPreviewUri });
                        }}
                     >
                        <Ionicons name="play" size={16} color="white" />
                        <Text style={styles.projectButtonText}>Proyectar Directo {mediaPreviewType === 'video' ? '(con sonido)' : ''}</Text>
                     </TouchableOpacity>
                     <TouchableOpacity 
                        style={[styles.projectButton, {flex: 1, backgroundColor: '#8b5cf6', flexDirection: 'row', justifyContent: 'center', alignItems: 'center', gap: 6}]} 
                        onPress={() => {
                          if (mediaPreviewUri) {
                            const alreadyExists = customBackgrounds.some(bg => bg.uri === mediaPreviewUri);
                            if (!alreadyExists) {
                               const newBg = { 
                                 id: 'custom-' + Date.now(), 
                                 type: mediaPreviewType, 
                                 thumbnail: mediaPreviewUri, 
                                 uri: mediaPreviewUri, 
                                 name: mediaPreviewType === 'video' ? 'Video Guardado' : 'Fondo Guardado' 
                               };
                               setCustomBackgrounds(prev => [...prev, newBg]);
                            }
                            setBackgroundMedia({ type: mediaPreviewType || 'image', uri: mediaPreviewUri });
                          }
                        }}
                     >
                        <Ionicons name="image" size={16} color="white" />
                        <Text style={styles.projectButtonText}>Poner de Fondo</Text>
                     </TouchableOpacity>
                  </View>
               </View>
            )}
          </ScrollView>
        );

      case 'Documents':
        if (Platform.OS !== 'ios') return null;
        const hasDoc = projection.type === 'document' || projection.type === 'pdf';
        return (
          <ScrollView style={styles.moduleContentSingle}>
            <Text style={styles.mockTitle}>Gestor de Documentos (PDF, PPTX, Word)</Text>
            
            <TouchableOpacity 
              style={[
                styles.gridBox, 
                { 
                  width: '100%', 
                  height: 160, 
                  backgroundColor: '#ef444415', 
                  borderColor: '#ef4444', 
                  borderWidth: 2, 
                  borderStyle: 'dashed',
                  borderRadius: 12,
                  marginBottom: 20
                }
              ]} 
              onPress={pickDocument}
              disabled={isReadingDocument}
            >
              <Ionicons name="document-text" size={44} color="#ef4444" />
              <Text style={{color: '#ef4444', marginTop: 10, fontWeight: 'bold', fontSize: 16}}>
                {isReadingDocument ? 'Abriendo archivo...' : 'Seleccionar Archivo (PDF, PPTX, Word, etc.)'}
              </Text>
              <Text style={{color: '#94a3b8', fontSize: 12, marginTop: 4}}>
                Visualización integrada nativa en iPad
              </Text>
            </TouchableOpacity>

            {hasDoc && (
              <View style={{backgroundColor: '#1e293b', padding: 16, borderRadius: 10, borderWidth: 1, borderColor: '#334155'}}>
                <View style={{flexDirection: 'row', alignItems: 'center', marginBottom: 12}}>
                  <View style={{width: 40, height: 40, borderRadius: 8, backgroundColor: '#ef444420', justifyContent: 'center', alignItems: 'center', marginRight: 12}}>
                    <Ionicons name="document" size={24} color="#ef4444" />
                  </View>
                  <View style={{flex: 1}}>
                    <Text style={{color: '#ffffff', fontWeight: 'bold', fontSize: 15}} numberOfLines={1}>
                      {projection.title || currentDocName || 'Documento Activo'}
                    </Text>
                    <Text style={{color: '#10b981', fontSize: 12, marginTop: 2}}>
                      Listo para proyectar
                    </Text>
                  </View>
                </View>

                <View style={{flexDirection: 'row', gap: 10}}>
                  <TouchableOpacity 
                    style={[styles.projectButton, {flex: 1, backgroundColor: '#3b82f6', flexDirection: 'row', justifyContent: 'center', alignItems: 'center', gap: 6}]}
                    onPress={() => setIsPresentationMode(true)}
                  >
                    <Ionicons name="tv" size={16} color="#ffffff" />
                    <Text style={styles.projectButtonText}>Presentar en Pantalla Completa</Text>
                  </TouchableOpacity>

                  <TouchableOpacity 
                    style={[styles.projectButton, {backgroundColor: '#334155', paddingHorizontal: 16}]}
                    onPress={pickDocument}
                    disabled={isReadingDocument}
                  >
                    <Text style={styles.projectButtonText}>Cambiar</Text>
                  </TouchableOpacity>
                </View>
              </View>
            )}
          </ScrollView>
        );

      case 'Messages':
        return (
          <ScrollView style={styles.moduleContentSingle}>
            <Text style={[styles.mockTitle, isCompact && { fontSize: 18, marginBottom: 12 }]}>Anuncios Tipo Cintillo (Marquee)</Text>
            <TextInput 
              style={[styles.textInput, isCompact && { height: 90, padding: 12, fontSize: 14, marginBottom: 12 }]}
              placeholder="Escribe un anuncio para que aparezca abajo en movimiento..."
              placeholderTextColor="#64748b"
              value={messageInput}
              onChangeText={setMessageInput}
              multiline
            />

            {/* Selector de Velocidad */}
            <View style={{marginBottom: 14}}>
              <Text style={{color: '#94a3b8', fontSize: 12, marginBottom: 6, fontWeight: 'bold'}}>Velocidad del Cintillo:</Text>
              <View style={{flexDirection: 'row', gap: isCompact ? 4 : 6}}>
                {[
                  { id: 'muy_lento', label: 'Muy Lento' },
                  { id: 'lento', label: 'Lento' },
                  { id: 'normal', label: 'Normal' },
                  { id: 'rapido', label: 'Rápido' }
                ].map(s => {
                  const isSelected = marqueeSpeed === s.id;
                  return (
                    <TouchableOpacity
                      key={s.id}
                      style={{
                        flex: 1,
                        paddingVertical: isCompact ? 7 : 10,
                        paddingHorizontal: 2,
                        borderRadius: 8,
                        backgroundColor: isSelected ? '#3b82f6' : '#1e293b',
                        borderWidth: 1,
                        borderColor: isSelected ? '#60a5fa' : '#334155',
                        alignItems: 'center',
                        justifyContent: 'center'
                      }}
                      onPress={() => setMarqueeSpeed(s.id as any)}
                    >
                      <Text style={{
                        color: isSelected ? '#ffffff' : '#94a3b8',
                        fontWeight: 'bold',
                        fontSize: isCompact ? 10 : 12,
                        textAlign: 'center'
                      }}>
                        {s.label}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
            </View>

            {/* Repeticiones */}
            <View style={{flexDirection: 'row', alignItems: 'center', marginBottom: 16, gap: 8, flexWrap: 'wrap'}}>
              <Text style={{color: '#94a3b8', fontSize: 12, fontWeight: 'bold'}}>Repeticiones:</Text>
              <TextInput 
                style={[styles.textInput, {height: 36, marginBottom: 0, width: 55, padding: 6, textAlign: 'center', fontSize: 13}]}
                value={messageReps}
                onChangeText={setMessageReps}
                keyboardType="numeric"
              />
              <View style={{flexDirection: 'row', gap: 4}}>
                {['1', '3', '5', '∞'].map(r => {
                  const isSelected = (messageReps === r || (r === '∞' && messageReps === '999'));
                  return (
                    <TouchableOpacity
                      key={r}
                      onPress={() => setMessageReps(r === '∞' ? '999' : r)}
                      style={{
                        paddingHorizontal: 8,
                        paddingVertical: 6,
                        borderRadius: 6,
                        backgroundColor: isSelected ? '#3b82f6' : '#1e293b',
                        borderWidth: 1,
                        borderColor: isSelected ? '#60a5fa' : '#334155'
                      }}
                    >
                      <Text style={{color: '#ffffff', fontSize: 11, fontWeight: 'bold'}}>{r}</Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
            </View>

            <TouchableOpacity 
              style={[styles.projectButton, {flexDirection: 'row', justifyContent: 'center', alignItems: 'center', gap: 6}]} 
              onPress={playMarquee}
            >
              <Ionicons name="play" size={16} color="#ffffff" />
              <Text style={styles.projectButtonText}>Lanzar Cintillo Animado</Text>
            </TouchableOpacity>
            
            {activeMarquee !== '' && (
              <TouchableOpacity 
                style={[styles.projectButton, {backgroundColor: '#ef4444', marginTop: 10, flexDirection: 'row', justifyContent: 'center', alignItems: 'center', gap: 6}]} 
                onPress={stopMarquee}
              >
                <Ionicons name="stop" size={16} color="#ffffff" />
                <Text style={styles.projectButtonText}>Detener Cintillo</Text>
              </TouchableOpacity>
            )}
          </ScrollView>
        );

      case 'Timer':
        return (
          <ScrollView style={styles.moduleContentSingle}>
            <Text style={styles.mockTitle}>Cuenta Regresiva</Text>
            <View style={styles.timerMock}>
               <Text style={styles.timerTextMock}>{formatTime(timeLeft)}</Text>
            </View>
            <View style={{flexDirection: 'row', gap: 12, marginBottom: 20}}>
               <TouchableOpacity style={[styles.projectButton, {flex: 1, backgroundColor: '#10b981'}]} onPress={() => { setTimerRunning(true); setProjection({ type: 'text', content: '\u23F3 ' + formatTime(timeLeft) }); }}>
                 <Text style={styles.projectButtonText}>{timerRunning ? 'Corriendo...' : 'Iniciar Timer'}</Text>
               </TouchableOpacity>
               <TouchableOpacity style={[styles.projectButton, {flex: 1, backgroundColor: '#ef4444'}]} onPress={() => setTimerRunning(false)}>
                 <Text style={styles.projectButtonText}>Pausar</Text>
               </TouchableOpacity>
               <TouchableOpacity style={[styles.projectButton, {flex: 1, backgroundColor: '#64748b'}]} onPress={() => { setTimerRunning(false); setTimeLeft(timerMinutes * 60); }}>
                 <Text style={styles.projectButtonText}>Reset</Text>
               </TouchableOpacity>
            </View>
          </ScrollView>
        );

      case 'Web':
        // When projecting, show interactive WebView in the controls area
        if (projection.type === 'web') {
          return (
            <View style={{flex: 1}}>
              <View style={{flexDirection: 'row', alignItems: 'center', backgroundColor: '#1e293b', padding: 10, borderBottomWidth: 1, borderBottomColor: '#334155'}}>
                <Ionicons name="globe" size={16} color="#10b981" style={{marginRight: 6}}/>
                <TextInput 
                  style={[styles.urlText, {flex: 1, marginRight: 8}]}
                  value={webUrl}
                  onChangeText={setWebUrl}
                  keyboardType="url"
                  autoCapitalize="none"
                  autoCorrect={false}
                  onSubmitEditing={() => setProjection({ type: 'web', content: webUrl })}
                />
                <TouchableOpacity style={{backgroundColor: '#3b82f6', padding: 8, borderRadius: 6, marginRight: 6}} onPress={() => setProjection({ type: 'web', content: webUrl })}>
                  <Ionicons name="arrow-forward" size={16} color="#fff" />
                </TouchableOpacity>
                <TouchableOpacity style={{backgroundColor: '#ef4444', padding: 8, borderRadius: 6}} onPress={() => setProjection({ type: 'text', content: '' })}>
                  <Ionicons name="close" size={16} color="#fff" />
                </TouchableOpacity>
              </View>
              <WebView 
                source={{ uri: projection.content }} 
                style={{ flex: 1 }} 
                javaScriptEnabled={true} 
                domStorageEnabled={true} 
                originWhitelist={['*']} 
                scalesPageToFit={true}
                onNavigationStateChange={(navState) => {
                  if (navState.url && navState.url !== projection.content && navState.url.startsWith('http')) {
                    setWebUrl(navState.url);
                    setProjection({ type: 'web', content: navState.url });
                  }
                }}
              />
            </View>
          );
        }
        return (
          <ScrollView style={styles.moduleContentSingle}>
             <Text style={styles.mockTitle}>Navegador Integrado</Text>
             <View style={styles.urlBar}>
                <Ionicons name="lock-closed" size={14} color="#10b981" style={{marginRight: 6}}/>
                <TextInput 
                  style={styles.urlText}
                  value={webUrl}
                  onChangeText={setWebUrl}
                  keyboardType="url"
                  autoCapitalize="none"
                  autoCorrect={false}
                />
             </View>
             <TouchableOpacity style={[styles.gridBox, {width: '100%', height: 100, backgroundColor: '#10b981'}]} onPress={() => setProjection({ type: 'web', content: webUrl })}>
                <Text style={{color: '#ffffff', fontWeight: 'bold', fontSize: 18}}>Proyectar y Visualizar Web</Text>
             </TouchableOpacity>
          </ScrollView>
        );

      case 'Settings':
        return (
          <ScrollView style={styles.moduleContentSingle}>
             <Text style={styles.mockTitle}>Configuración del Sistema</Text>
             <View style={styles.settingRow}>
                <Text style={styles.verseText}>Proyectar a TV Externa (Airplay/HDMI)</Text>
                <TouchableOpacity onPress={() => setExternalDisplayEnabled(!externalDisplayEnabled)}>
                  <Ionicons name={externalDisplayEnabled ? "toggle" : "toggle-outline"} size={32} color={externalDisplayEnabled ? "#3b82f6" : "#64748b"} />
                </TouchableOpacity>
             </View>
             {hasHardwareDisplay ? (
                <Text style={{color: '#10b981', marginTop: 10, padding: 10, backgroundColor: '#064e3b', borderRadius: 6}}>Pantalla externa detectada (HDMI / Miracast).</Text>
             ) : isCastConnected ? (
                <Text style={{color: '#38bdf8', marginTop: 10, padding: 10, backgroundColor: '#0c4a6e', borderRadius: 6}}>Chromecast conectado activamente vía Google Cast.</Text>
             ) : (
                <Text style={{color: '#f59e0b', marginTop: 10, padding: 10, backgroundColor: '#78350f', borderRadius: 6}}>No se detecta pantalla externa. Conecta por HDMI, Miracast o Chromecast.</Text>
             )}
          </ScrollView>
        );
    }
  };

  // =============================================
  // PROJECTION CONTENT RENDERER
  // Supports 'miniPreview', 'presentation' (fullscreen) and 'external' (TV)
  // =============================================
  const renderPreviewContent = (mode: 'miniPreview' | 'presentation' | 'external' = 'miniPreview') => {
    if (projection.type === 'text') {
       return (
         <DynamicProjectionText
           content={projection.content}
           mode={mode}
           textColor={textColor}
           textHasBackground={textHasBackground}
           sizeMultiplier={textSize / 48}
           isCompact={isCompact}
         />
       );
    }
    if (projection.type === 'image') {
       return (
         <View style={[styles.previewContentCenter, { padding: 0 }]}>
            <Image source={{ uri: projection.content }} style={{width: '100%', height: '100%', resizeMode: 'contain'}} />
         </View>
       );
    }
    if (projection.type === 'video') {
       const uri = projection.content;
       // Proyección directa de video: SÍ reproduce sonido al proyectar
       // En miniPreview, si hay pantalla externa activa, silenciamos miniPreview para evitar eco doble.
       // De lo contrario (o en modo presentación o TV), sonido activo (muted = false)!
       const shouldMute = mode === 'miniPreview' && (hasExternalDisplay && externalDisplayEnabled);
       return (
         <View style={[styles.previewContentCenter, { padding: 0, backgroundColor: 'black' }]}>
            <SafeVideoView 
              key={uri} 
              uri={uri} 
              contentFit="contain" 
              muted={shouldMute} 
              volume={1.0}
              loop={true}
              nativeControls={mode === 'presentation'}
              isPaused={isPaused}
            />
         </View>
       );
    }
    if (projection.type === 'web') {
       return <WebView source={{ uri: projection.content }} style={{ flex: 1, backgroundColor: 'white' }} javaScriptEnabled={true} domStorageEnabled={true} originWhitelist={['*']} />;
    }
    if (projection.type === 'pdf' || projection.type === 'document') {
       const uri = projection.content;
       
       // Remote HTTP/HTTPS PDF or document
       if (uri.startsWith('http://') || uri.startsWith('https://')) {
         if (Platform.OS === 'android') {
           const googleDocsUrl = `https://docs.google.com/gview?embedded=true&url=${encodeURIComponent(uri)}`;
           return <WebView source={{ uri: googleDocsUrl }} style={{ flex: 1, backgroundColor: 'white' }} javaScriptEnabled={true} domStorageEnabled={true} originWhitelist={['*']} />;
         }
         return <WebView source={{ uri }} style={{ flex: 1, backgroundColor: 'white' }} javaScriptEnabled={true} domStorageEnabled={true} originWhitelist={['*']} />;
       }

       // iOS (iPad) - Native WKWebView handles PDF, PPT, PPTX, Word, audio, video directly!
       if (Platform.OS === 'ios') {
         return (
           <WebView 
             source={{ uri }} 
             style={{ flex: 1, backgroundColor: 'white' }} 
             javaScriptEnabled={true} 
             domStorageEnabled={true} 
             originWhitelist={['*']} 
             allowFileAccessFromFileURLs={true} 
             allowUniversalAccessFromFileURLs={true} 
             allowFileAccess={true} 
           />
         );
       }

       // Android - Local files open via native Android PDF app
       return (
         <View style={[styles.previewContentCenter, mode === 'miniPreview' ? { padding: 4 } : { padding: 24 }]}>
           <Ionicons name="document-text" size={mode === 'miniPreview' ? 24 : 48} color="#38bdf8" />
           <Text style={{color: '#ffffff', marginTop: mode === 'miniPreview' ? 4 : 10, textAlign: 'center', fontWeight: 'bold', fontSize: mode === 'miniPreview' ? 10 : 15}} numberOfLines={1}>
             {projection.title || currentDocName || 'Documento'}
           </Text>
           {mode !== 'miniPreview' && (
             <>
               <Text style={{color: '#94a3b8', fontSize: 11, marginTop: 4, textAlign: 'center', paddingHorizontal: 12}}>
                 Abre con tu app de PDF de Android para proyectar
               </Text>
               <TouchableOpacity
                 style={{marginTop: 10, backgroundColor: '#10b981', paddingVertical: 6, paddingHorizontal: 12, borderRadius: 6, flexDirection: 'row', alignItems: 'center', gap: 6}}
                 onPress={async () => {
                   try {
                     await Sharing.shareAsync(uri, { dialogTitle: 'Abrir con...' });
                   } catch (e) {}
                 }}
               >
                 <Ionicons name="open-outline" size={14} color="#ffffff" />
                 <Text style={{color: '#ffffff', fontWeight: 'bold', fontSize: 12}}>Abrir en App de PDF</Text>
               </TouchableOpacity>
             </>
           )}
         </View>
       );
    }
    return null;
  };

  const renderProjectionScreen = (mode: 'miniPreview' | 'presentation' | 'external' = 'miniPreview') => {
     const isExternal = mode === 'external';
     const isMini = mode === 'miniPreview';
     return (
        <View style={{flex: 1, backgroundColor: 'black'}}>
           {isBlackout ? (
              <View style={{flex: 1, backgroundColor: 'black'}} />
           ) : (
              <>
                {/* Background Media */}
                {backgroundMedia && backgroundMedia.type === 'image' && (
                  <Image source={{ uri: backgroundMedia.uri }} style={[StyleSheet.absoluteFill, {width: '100%', height: '100%', resizeMode: 'cover'}]} />
                )}
                {backgroundMedia && backgroundMedia.type === 'video' && (
                  <View style={[StyleSheet.absoluteFill, { backgroundColor: 'black' }]}>
                    <SafeVideoView 
                      key={backgroundMedia.uri} 
                      uri={backgroundMedia.uri} 
                      contentFit="cover" 
                      muted={true} 
                      volume={0}
                      loop={true} 
                      isPaused={isPaused} 
                    />
                  </View>
                )}

                {/* Brightness Overlay (Simulated Dimming) */}
                {brightness < 100 && (
                  <View style={[StyleSheet.absoluteFill, { backgroundColor: 'black', opacity: 1 - (brightness / 100), pointerEvents: 'none', zIndex: 40 }]} />
                )}
                
                {renderPreviewContent(mode)}
                
                {activeMarquee !== '' && (
                  <View 
                    style={[
                      styles.marqueeContainer, 
                      isMini && isCompact && styles.marqueeContainerCompact,
                      isExternal && { height: 60 }
                    ]}
                    onLayout={(e) => {
                      if (!isExternal) {
                        const w = e.nativeEvent.layout.width;
                        if (w > 0 && w !== marqueeContainerWidth) {
                          setMarqueeContainerWidth(w);
                        }
                      }
                    }}
                  >
                    <Animated.View style={{ transform: [{ translateX: isExternal ? scrollExtX : scrollX }] }}>
                      <Text 
                        style={[
                          styles.marqueeText, 
                          isMini && isCompact && styles.marqueeTextCompact,
                          isExternal && { fontSize: 28, paddingHorizontal: 20 }
                        ]} 
                        numberOfLines={1}
                      >
                        {activeMarquee}
                      </Text>
                    </Animated.View>
                  </View>
                )}
              </>
           )}
        </View>
     );
  };

  // =============================================
  // EXTERNAL DISPLAY - ultra-lightweight to prevent UI freeze
  // =============================================
  const renderExternalScreen = () => {
     return renderProjectionScreen('external');
  };

  // Toolbar auto-hide logic for Presentation Mode
  const [showPresentationControls, setShowPresentationControls] = useState(true);
  const controlsTimeout = useRef<ReturnType<typeof setTimeout> | null>(null);

  const resetControlsTimeout = () => {
    setShowPresentationControls(true);
    if (controlsTimeout.current) clearTimeout(controlsTimeout.current);
    controlsTimeout.current = setTimeout(() => {
      setShowPresentationControls(false);
    }, 3000);
  };

  useEffect(() => {
    if (isPresentationMode) {
      resetControlsTimeout();
    }
    return () => {
      if (controlsTimeout.current) clearTimeout(controlsTimeout.current);
    };
  }, [isPresentationMode]);

  // --- PRESENTATION MODE ---
  // When active, show ONLY the projection fullscreen (for wireless mirroring)
  if (isPresentationMode) {
    return (
      <View style={{flex: 1, backgroundColor: '#000'}} onTouchStart={resetControlsTimeout}>
        {renderProjectionScreen('presentation')}

        {/* Floating toolbar at bottom (Auto-hiding) */}
        {showPresentationControls && (
          <View style={{
            position: 'absolute', bottom: 20, left: 0, right: 0,
            flexDirection: 'row', justifyContent: 'center', alignItems: 'center',
            gap: 8, zIndex: 100,
          }}>
            {/* Playlist nav */}
            {playlist && (
              <>
                <TouchableOpacity
                  style={{backgroundColor: 'rgba(59,130,246,0.8)', padding: 10, borderRadius: 25}}
                  onPress={() => { handlePrevSlide(); resetControlsTimeout(); }}
                >
                  <Ionicons name="chevron-up" size={22} color="#fff" />
                </TouchableOpacity>
                <TouchableOpacity
                  style={{backgroundColor: 'rgba(59,130,246,0.8)', padding: 10, borderRadius: 25}}
                  onPress={() => { handleNextSlide(); resetControlsTimeout(); }}
                >
                  <Ionicons name="chevron-down" size={22} color="#fff" />
                </TouchableOpacity>
              </>
            )}

            {/* Blackout */}
            <TouchableOpacity
              style={{backgroundColor: isBlackout ? 'rgba(239,68,68,0.9)' : 'rgba(100,100,100,0.6)', padding: 10, borderRadius: 25}}
              onPress={() => { setIsBlackout(!isBlackout); resetControlsTimeout(); }}
            >
              <Ionicons name="eye-off" size={22} color="#fff" />
            </TouchableOpacity>

            {/* Exit Presentation Mode */}
            <TouchableOpacity
              style={{backgroundColor: 'rgba(239,68,68,0.9)', paddingVertical: 10, paddingHorizontal: 18, borderRadius: 25, flexDirection: 'row', alignItems: 'center', gap: 6}}
              onPress={() => setIsPresentationMode(false)}
            >
              <Ionicons name="close" size={20} color="#fff" />
              <Text style={{color: '#fff', fontWeight: 'bold', fontSize: 13}}>Salir</Text>
            </TouchableOpacity>
          </View>
        )}
      </View>
    );
  }

  return (
    <>
      <SafeAreaView style={styles.container}>
      {/* SIDEBAR */}
      <View style={[styles.sidebar, isCompact && { width: 42, paddingVertical: 6 }]}>
        <View style={[styles.sidebarHeader, isCompact && { marginBottom: 6, paddingHorizontal: 0, justifyContent: 'center' }]}>
          <Ionicons name="desktop" size={isCompact ? 18 : 28} color="#3b82f6" />
          {!isCompact && <Text style={styles.sidebarTitle}>DTB</Text>}
        </View>

        <ScrollView style={styles.sidebarItems} contentContainerStyle={{paddingBottom: 20}} showsVerticalScrollIndicator={false}>
          {navItems.map((item) => (
            <TouchableOpacity 
              key={item.id} 
              style={[
                styles.navItem, 
                activeModule === item.id && styles.navItemActive, 
                isCompact && { paddingVertical: 5, marginVertical: 1, paddingHorizontal: 0, justifyContent: 'center' }
              ]}
              onPress={() => {
                setActiveModule(item.id);
                if (item.id === 'Songs') {
                  setSelectedSongId('');
                  setIsAddingSong(false);
                }
              }}
            >
              <Ionicons 
                name={item.icon} 
                size={isCompact ? 16 : 24} 
                color={activeModule === item.id ? '#60a5fa' : '#94a3b8'} 
              />
              {!isCompact && (
                <Text style={[styles.navItemText, activeModule === item.id && styles.navItemTextActive]}>
                  {item.label}
                </Text>
              )}
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      {/* MAIN CONTENT AREA */}
      <View style={styles.main}>
        {/* TOP BAR */}
        <View style={[styles.topBar, isCompact && { height: 38, paddingHorizontal: 8 }]}>
          <Text style={[styles.topBarTitle, isCompact && { fontSize: 13 }]} numberOfLines={1}>VisualDTB — {activeModule === 'Service' ? 'Orden de Culto' : activeModule}</Text>
          <View style={[styles.topBarControls, isCompact && { gap: 6 }]}>
            {/* Presentation Mode Button */}
            <TouchableOpacity
              style={[
                {flexDirection: 'row', alignItems: 'center', backgroundColor: '#8b5cf6', paddingHorizontal: 14, paddingVertical: 8, borderRadius: 8, gap: 6},
                isCompact && { paddingHorizontal: 7, paddingVertical: 3, borderRadius: 5, gap: 3 }
              ]}
              onPress={() => setIsPresentationMode(true)}
            >
              <Ionicons name="tv" size={isCompact ? 12 : 16} color="#fff" />
              <Text style={[{color: '#fff', fontWeight: 'bold', fontSize: 13}, isCompact && { fontSize: 10 }]}>Presentar</Text>
            </TouchableOpacity>

            {/* Google Cast Button (Android only) */}
            {Platform.OS === 'android' && (
              <SafeCastButton isCompact={isCompact} tintColor={isCastConnected ? "#38bdf8" : "#ffffff"} />
            )}

            {!isCompact && (
              <View style={styles.tvStatusBadge}>
                <Ionicons 
                  name={hasExternalDisplay ? "tv" : "tv-outline"} 
                  size={16} 
                  color={hasHardwareDisplay ? "#10b981" : isCastConnected ? "#38bdf8" : "#94a3b8"} 
                />
                <Text style={[
                  styles.tvStatusText, 
                  hasHardwareDisplay && { color: '#10b981' },
                  isCastConnected && { color: '#38bdf8' }
                ]}>
                  {hasHardwareDisplay ? "TV Conectada" : isCastConnected ? "Cast Activo" : "Preview Mode"}
                </Text>
              </View>
            )}
          </View>
        </View>

        {/* WORKSPACE & PREVIEW SPLIT */}
        <View style={[styles.workspace, isPortrait && isCompact && { flexDirection: 'column' }]}>
          {/* Module Controls Area */}
          <View style={styles.controlsArea}>
            {renderModuleContent()}
          </View>

          {/* TV Preview Area */}
          <View style={[
            styles.previewArea,
            isCompact ? {
              // En pantallas pequeñas (teléfonos): apartado de proyección aún más pequeño para ganar espacio
              width: isLandscape ? 110 : '100%',
              height: isLandscape ? undefined : 64,
              padding: 3,
              borderTopWidth: isLandscape ? 0 : 1,
              borderTopColor: '#1e293b',
              borderLeftWidth: isLandscape ? 1 : 0,
              borderLeftColor: '#1e293b',
              flex: 0,
            } : {
              // En iPad / pantallas grandes: conserva su tamaño completo original
              width: 280,
              padding: 16,
              flex: 0,
            }
          ]}>
            <View style={[styles.previewHeader, isCompact && { marginBottom: 2, gap: 3 }]}>
              <Ionicons name="tv" size={isCompact ? 10 : 14} color="#94a3b8" />
              <Text style={[styles.previewTitle, isCompact && { fontSize: 8 }]}>PROYECCIÓN</Text>
            </View>
            <View style={[
              styles.previewScreen, 
              isFullscreen && styles.previewScreenFullscreen,
              isCompact && !isFullscreen && { height: isLandscape ? 56 : 44, maxHeight: isLandscape ? 56 : 44 }
            ]}>
              {renderProjectionScreen('miniPreview')}
            </View>
            {!isCompact && (
              <View style={{marginTop: 6}}>
                <Text style={{color: '#64748b', fontSize: 10, textAlign: 'center'}}>
                  {isPaused ? 'PAUSADO' : 'Vista previa de TV'}
                </Text>
              </View>
            )}
          </View>
        </View>

        {/* BOTTOM TOOLBAR */}
        <View style={[styles.bottomToolbar, isCompact && { height: 38, paddingVertical: 2, paddingHorizontal: 3 }]}>
          <ScrollView 
            horizontal 
            showsHorizontalScrollIndicator={true}
            persistentScrollbar={true}
            contentContainerStyle={{ alignItems: 'center', gap: isCompact ? 4 : 10, paddingHorizontal: 4, paddingRight: 20 }}
          >
            {/* BOTONES INTERACTIVOS (Urgentes: Limpiar, Pausa, Blackout, Pantalla Completa) */}
            <View style={[styles.toolbarActions, isCompact && { gap: 3 }]}>
               {/* Limpiar */}
               <TouchableOpacity 
                  style={[
                    styles.actionBtn, 
                    isCompact ? { height: 24, paddingHorizontal: 6, width: undefined, borderRadius: 4 } : { height: 32, paddingHorizontal: 10, width: undefined }, 
                    { backgroundColor: '#f59e0b25', flexDirection: 'row', alignItems: 'center', gap: 3, borderWidth: 1, borderColor: '#f59e0b50' }
                  ]} 
                  onPress={() => setProjection({ type: 'text', content: '' })}>
                 <Ionicons name="trash" size={isCompact ? 11 : 15} color="#f59e0b" />
                 <Text style={{color: '#f59e0b', fontWeight: 'bold', fontSize: isCompact ? 10 : 12}}>Limpiar</Text>
               </TouchableOpacity>

               {/* Pausar */}
               <TouchableOpacity 
                  style={[styles.actionBtn, isCompact && { width: 24, height: 24, borderRadius: 4 }, isPaused && styles.actionBtnActive]} 
                  onPress={() => setIsPaused(!isPaused)}>
                 <Ionicons name="pause" size={isCompact ? 11 : 16} color={isPaused ? "#ffffff" : "#cbd5e1"} />
               </TouchableOpacity>

               {/* Blackout */}
               <TouchableOpacity 
                  style={[styles.actionBtn, isCompact && { width: 24, height: 24, borderRadius: 4 }, isBlackout ? styles.actionBtnDanger : {backgroundColor: '#ef444420'}]} 
                  onPress={() => setIsBlackout(!isBlackout)}>
                 <Ionicons name="eye-off" size={isCompact ? 11 : 16} color={isBlackout ? "#ffffff" : "#ef4444"} />
               </TouchableOpacity>

               {/* Pantalla completa / Expandir */}
               <TouchableOpacity 
                  style={[styles.actionBtn, isCompact && { width: 24, height: 24, borderRadius: 4 }, isFullscreen && styles.actionBtnSuccess]} 
                  onPress={() => setIsFullscreen(!isFullscreen)}>
                 <Ionicons name="expand" size={isCompact ? 11 : 16} color={isFullscreen ? "#ffffff" : "#10b981"} />
               </TouchableOpacity>

               {/* Playlist Controls */}
               {playlist && (
                 <View style={{flexDirection: 'row', borderWidth: 1, borderColor: '#334155', borderRadius: 4}}>
                   <TouchableOpacity style={[styles.actionBtn, isCompact && { width: 22, height: 24 }, {backgroundColor: '#3b82f620', borderRadius: 0, borderRightWidth: 1, borderRightColor: '#334155', borderTopLeftRadius: 4, borderBottomLeftRadius: 4}]} onPress={handlePrevSlide}>
                     <Ionicons name="chevron-up" size={isCompact ? 11 : 16} color="#3b82f6" />
                   </TouchableOpacity>
                   <TouchableOpacity style={[styles.actionBtn, isCompact && { width: 22, height: 24 }, {backgroundColor: '#3b82f620', borderRadius: 0, borderTopRightRadius: 4, borderBottomRightRadius: 4}]} onPress={handleNextSlide}>
                     <Ionicons name="chevron-down" size={isCompact ? 11 : 16} color="#3b82f6" />
                   </TouchableOpacity>
                 </View>
               )}
            </View>

            {/* Separador visual */}
            <View style={{ width: 1, height: isCompact ? 14 : 20, backgroundColor: '#334155', marginHorizontal: 1 }} />

            {/* Brillo */}
            <View style={styles.toolbarGroup}>
              <Ionicons name="sunny" size={isCompact ? 11 : 16} color="#94a3b8" />
              {!isCompact && <Text style={styles.toolbarLabel}>Brillo</Text>}
              <Slider
                style={{width: isCompact ? 48 : 90, height: 24}}
                minimumValue={10}
                maximumValue={100}
                value={brightness}
                onValueChange={setBrightness}
                minimumTrackTintColor="#ffffff"
                maximumTrackTintColor="#334155"
                thumbTintColor="#ffffff"
              />
              <Text style={[styles.toolbarValue, isCompact && { fontSize: 8 }]}>{Math.round(brightness)}%</Text>
            </View>

            {/* Separador visual */}
            <View style={{ width: 1, height: isCompact ? 14 : 20, backgroundColor: '#334155', marginHorizontal: 1 }} />
            
            {/* Selector de Color de Letra (incluye Negro) */}
            <View style={styles.toolbarGroup}>
              <Ionicons name="color-palette" size={isCompact ? 11 : 16} color="#94a3b8" />
              {!isCompact && <Text style={styles.toolbarLabel}>Color</Text>}
              <View style={{flexDirection: 'row', gap: isCompact ? 3 : 6, alignItems: 'center', backgroundColor: '#0f172a', paddingHorizontal: isCompact ? 3 : 6, paddingVertical: 2, borderRadius: 10}}>
                {['#ffffff', '#000000', '#facc15', '#38bdf8', '#4ade80', '#fb923c', '#f472b6'].map(c => (
                  <TouchableOpacity
                    key={c}
                    onPress={() => setTextColor(c)}
                    style={{
                      width: isCompact ? 12 : 18,
                      height: isCompact ? 12 : 18,
                      borderRadius: isCompact ? 6 : 9,
                      backgroundColor: c,
                      borderWidth: textColor === c ? 2 : 1,
                      borderColor: textColor === c ? '#3b82f6' : (c === '#000000' ? '#64748b' : '#334155'),
                      transform: [{ scale: textColor === c ? 1.25 : 1 }]
                    }}
                  />
                ))}
              </View>
            </View>

            {/* Separador visual */}
            <View style={{ width: 1, height: isCompact ? 14 : 20, backgroundColor: '#334155', marginHorizontal: 1 }} />

            {/* Opción de Fondo de Letra (Negro o Transparente) */}
            <TouchableOpacity
              onPress={() => setTextHasBackground(!textHasBackground)}
              style={{
                flexDirection: 'row',
                alignItems: 'center',
                backgroundColor: textHasBackground ? '#3b82f625' : '#0f172a',
                borderColor: textHasBackground ? '#3b82f6' : '#334155',
                borderWidth: 1,
                borderRadius: 4,
                paddingHorizontal: isCompact ? 5 : 8,
                paddingVertical: isCompact ? 2 : 5,
                gap: 3
              }}
            >
              <Ionicons name="square" size={isCompact ? 9 : 13} color={textHasBackground ? '#60a5fa' : '#64748b'} />
              <Text style={{
                color: textHasBackground ? '#60a5fa' : '#94a3b8',
                fontSize: isCompact ? 9 : 11,
                fontWeight: 'bold'
              }}>
                {textHasBackground ? 'Fondo: ON' : 'Fondo'}
              </Text>
            </TouchableOpacity>
          </ScrollView>
        </View>
      </View>
      </SafeAreaView>
      
      {hasExternalDisplay && externalDisplayEnabled && (
        <View style={{ position: 'absolute', top: -1000, left: -1000, width: 1, height: 1, overflow: 'hidden' }} pointerEvents="none">
          <ExternalDisplay
            mainScreenStyle={{ flex: 1 }}
            fallbackInMainScreen={false}
            screen={Object.keys(externalScreens)[0]}
          >
            {renderExternalScreen()}
          </ExternalDisplay>
        </View>
      )}
    </>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, flexDirection: 'row', backgroundColor: '#0f172a' },
  sidebar: { width: 80, backgroundColor: '#1e293b', borderRightWidth: 1, borderRightColor: '#334155', alignItems: 'center', paddingVertical: 20 },
  sidebarHeader: { alignItems: 'center', marginBottom: 30 },
  sidebarTitle: { color: '#e2e8f0', fontSize: 12, fontWeight: 'bold', marginTop: 4 },
  sidebarItems: { flex: 1, width: '100%' },
  navItem: { alignItems: 'center', paddingVertical: 12, marginVertical: 4, borderLeftWidth: 3, borderLeftColor: 'transparent' },
  navItemActive: { borderLeftColor: '#3b82f6', backgroundColor: '#3b82f620' },
  navItemText: { color: '#94a3b8', fontSize: 10, marginTop: 4 },
  navItemTextActive: { color: '#60a5fa', fontWeight: 'bold' },
  sidebarFooter: { alignItems: 'center', marginTop: 'auto' },
  statusDot: { width: 10, height: 10, borderRadius: 5, backgroundColor: '#ef4444', marginBottom: 4 },
  statusText: { color: '#94a3b8', fontSize: 10 },
  main: { flex: 1, flexDirection: 'column' },
  topBar: { height: 60, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, borderBottomWidth: 1, borderBottomColor: '#1e293b' },
  topBarTitle: { color: '#f8fafc', fontSize: 20, fontWeight: 'bold' },
  topBarControls: { flexDirection: 'row', alignItems: 'center', gap: 16 },
  tvStatusBadge: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#1e293b', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 8, gap: 6 },
  tvStatusText: { color: '#94a3b8', fontSize: 14 },
  toggleBtn: { opacity: 0.8 },
  workspace: { flex: 1, flexDirection: 'row' },
  controlsArea: { flex: 1.5, borderRightWidth: 1, borderRightColor: '#1e293b', backgroundColor: '#0f172a' },
  
  // Layout para 2 columnas
  twoColumnLayout: { flex: 1, flexDirection: 'row' },
  columnLeft: { flex: 1, borderRightWidth: 1, borderRightColor: '#1e293b', backgroundColor: '#0f172a' },
  columnRight: { flex: 2, padding: 20 },
  
  searchBar: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#1e293b', padding: 12, borderBottomWidth: 1, borderBottomColor: '#334155' },
  searchInput: { color: '#e2e8f0', marginLeft: 8, flex: 1 },
  
  bookHeader: { padding: 12, backgroundColor: '#1e293b', borderBottomWidth: 1, borderBottomColor: '#0f172a' },
  bookHeaderText: { color: '#e2e8f0', fontWeight: 'bold' },
  chapterItem: { padding: 12, paddingLeft: 24, borderBottomWidth: 1, borderBottomColor: '#1e293b' },
  chapterItemActive: { backgroundColor: '#3b82f620' },
  chapterItemText: { color: '#94a3b8' },

  songListItem: { flexDirection: 'row', alignItems: 'center', padding: 16, borderBottomWidth: 1, borderBottomColor: '#1e293b' },
  songListItemActive: { backgroundColor: '#3b82f620' },
  songListText: { color: '#e2e8f0' },

  moduleContentSingle: { padding: 20, flex: 1 },
  mockTitle: { color: '#e2e8f0', fontSize: 24, fontWeight: 'bold', marginBottom: 20 },
  mockVerse: { flexDirection: 'row', alignItems: 'center', padding: 16, marginVertical: 6, backgroundColor: '#1e293b', borderRadius: 8 },
  verseNumber: { color: '#3b82f6', fontWeight: 'bold', fontSize: 16, marginRight: 12 },
  verseText: { color: '#e2e8f0', fontSize: 16, lineHeight: 24, flex: 1 },
  textInput: { backgroundColor: '#1e293b', color: '#e2e8f0', padding: 16, borderRadius: 8, fontSize: 16, height: 120, textAlignVertical: 'top', marginBottom: 16 },
  projectButton: { backgroundColor: '#3b82f6', padding: 12, borderRadius: 8, alignItems: 'center' },
  projectButtonText: { color: '#ffffff', fontWeight: 'bold', fontSize: 14 },
  gridContainer: { flexDirection: 'row', flexWrap: 'wrap', gap: 16 },
  gridBox: { width: 120, height: 120, backgroundColor: '#1e293b', borderRadius: 8, justifyContent: 'center', alignItems: 'center' },
  timerMock: { alignItems: 'center', justifyContent: 'center', height: 150, backgroundColor: '#1e293b', borderRadius: 8, marginBottom: 20 },
  timerTextMock: { fontSize: 64, color: '#e2e8f0', fontWeight: 'bold' },
  urlBar: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#1e293b', padding: 12, borderRadius: 8, marginBottom: 20 },
  urlText: { color: '#94a3b8', fontSize: 16, flex: 1, height: 30 },
  settingRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#1e293b', padding: 16, borderRadius: 8, marginVertical: 6 },
  previewArea: { flex: 1, backgroundColor: '#0f172a', padding: 20 },
  previewHeader: { flexDirection: 'row', alignItems: 'center', gap: 6, marginBottom: 12 },
  previewTitle: { color: '#94a3b8', fontSize: 12, fontWeight: 'bold', letterSpacing: 1 },
  
  previewScreen: { width: '100%', aspectRatio: 16/9, backgroundColor: '#000000', borderRadius: 8, overflow: 'hidden', display: 'flex', flexDirection: 'column' },
  previewScreenFullscreen: { transform: [{scale: 1.1}], zIndex: 10, shadowColor: '#10b981', shadowOpacity: 0.5, shadowRadius: 20 },
  
  previewContentCenter: { flex: 1, width: '100%', alignSelf: 'stretch', justifyContent: 'center', alignItems: 'center', zIndex: 1 },
  previewText: { color: '#ffffff', fontSize: 28, fontWeight: 'bold', textAlign: 'center', textShadowColor: 'rgba(0, 0, 0, 0.75)', textShadowOffset: {width: -1, height: 1}, textShadowRadius: 10 },
  
  marqueeContainer: { position: 'absolute', bottom: 0, left: 0, right: 0, width: '100%', height: 50, backgroundColor: 'rgba(220, 38, 38, 0.95)', justifyContent: 'center', overflow: 'hidden', zIndex: 50 },
  marqueeContainerCompact: { height: 28 },
  marqueeText: { color: '#ffffff', fontSize: 24, fontWeight: 'bold', paddingHorizontal: 12 },
  marqueeTextCompact: { fontSize: 12, paddingHorizontal: 6 },

  bottomToolbar: { height: 50, backgroundColor: '#1e293b', flexDirection: 'row', alignItems: 'center', paddingHorizontal: 12, gap: 8, justifyContent: 'space-between' },
  toolbarGroup: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  toolbarLabel: { color: '#cbd5e1', fontSize: 12 },
  sliderMock: { width: 90, height: 4, backgroundColor: '#334155', borderRadius: 2, justifyContent: 'center' },
  sliderThumb: { width: 14, height: 14, borderRadius: 7, backgroundColor: '#ffffff', position: 'absolute', left: '80%' },
  toolbarValue: { color: '#94a3b8', fontSize: 10 },
  toolbarActions: { flexDirection: 'row', gap: 6 },
  actionBtn: { width: 32, height: 32, borderRadius: 6, backgroundColor: '#334155', justifyContent: 'center', alignItems: 'center' },
  actionBtnActive: { backgroundColor: '#3b82f6' },
  actionBtnDanger: { backgroundColor: '#ef4444' },
  actionBtnSuccess: { backgroundColor: '#10b981' },
});
