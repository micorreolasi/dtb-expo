import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, TextInput, ScrollView, Image, Animated, Easing, Platform, useWindowDimensions, Alert, NativeModules } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import * as DocumentPicker from 'expo-document-picker';
import * as FileSystemLegacy from 'expo-file-system/legacy';
import { File as ExpoFile } from 'expo-file-system';
import { WebView } from 'react-native-webview';
import Slider from '@react-native-community/slider';
import ExternalDisplay, { useExternalDisplay } from '../utils/safeExternalDisplay';
import fullBible from '../bible.json';

let NativeVideoView: any = null;
let useNativeVideoPlayer: any = null;
try {
  const expoVideo = require('expo-video');
  NativeVideoView = expoVideo.VideoView;
  useNativeVideoPlayer = expoVideo.useVideoPlayer;
} catch (e) {
  // Not available in standard Expo Go without native build
}

const RealVideoPlayer = ({ uri, contentFit, style }: { uri: string; contentFit: 'contain' | 'cover'; style?: any }) => {
  const player = useNativeVideoPlayer(uri, (p: any) => {
    p.loop = true;
    p.muted = true;
    p.play();
  });

  return (
    <NativeVideoView
      style={style || { width: '100%', height: '100%' }}
      player={player}
      contentFit={contentFit}
      nativeControls={false}
    />
  );
};

const SafeVideoView = ({ 
  uri, 
  contentFit = 'contain', 
  style 
}: { 
  uri: string; 
  contentFit?: 'contain' | 'cover'; 
  style?: any; 
}) => {
  if (NativeVideoView && useNativeVideoPlayer) {
    return <RealVideoPlayer uri={uri} contentFit={contentFit} style={style} />;
  }

  return (
    <View style={[style || { width: '100%', height: '100%' }, { backgroundColor: 'black', justifyContent: 'center', alignItems: 'center' }]}>
      <Ionicons name="videocam" size={48} color="#94a3b8" />
      <Text style={{ color: '#94a3b8', marginTop: 8, fontSize: 12 }}>Video activo en Development Build</Text>
    </View>
  );
};

type ModuleType = 'Bible' | 'Songs' | 'Media' | 'Documents' | 'Messages' | 'Timer' | 'Web' | 'Settings';

type ProjectionData = {
  type: 'text' | 'image' | 'video' | 'web' | 'pdf' | 'document';
  content: string; 
  base64?: string;
  title?: string;
};

const getPdfHtml = (base64: string) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=4.0, user-scalable=yes">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.min.js"></script>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body {
      width: 100%;
      background-color: #0b0f19;
      color: #e2e8f0;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }
    body {
      padding: 12px;
      display: flex;
      flex-direction: column;
      align-items: center;
      min-height: 100vh;
    }
    .page-card {
      margin-bottom: 20px;
      display: flex;
      flex-direction: column;
      align-items: center;
      width: 100%;
      max-width: 900px;
    }
    canvas {
      max-width: 100%;
      height: auto !important;
      border-radius: 6px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.7);
      background-color: #ffffff;
    }
    .page-footer {
      font-size: 12px;
      color: #94a3b8;
      margin-top: 8px;
      font-weight: 600;
      background: rgba(30, 41, 59, 0.8);
      padding: 4px 12px;
      border-radius: 12px;
    }
    #loading {
      padding: 40px 20px;
      text-align: center;
      color: #38bdf8;
      font-size: 16px;
      font-weight: bold;
    }
    .spinner {
      border: 3px solid rgba(56, 189, 248, 0.2);
      border-top: 3px solid #38bdf8;
      border-radius: 50%;
      width: 28px;
      height: 28px;
      animation: spin 1s linear infinite;
      margin: 0 auto 12px auto;
    }
    @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div id="loading">
    <div class="spinner"></div>
    Cargando PDF...
  </div>
  <div id="pdf-container" style="width: 100%; display: flex; flex-direction: column; align-items: center;"></div>
  
  <script>
    if (typeof pdfjsLib !== 'undefined') {
      pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js';
      
      try {
        const raw = atob("${base64}");
        const bytes = new Uint8Array(raw.length);
        for (let i = 0; i < raw.length; i++) {
          bytes[i] = raw.charCodeAt(i);
        }
        
        pdfjsLib.getDocument({ data: bytes }).promise.then(async function(pdf) {
          const loadingEl = document.getElementById('loading');
          if (loadingEl) loadingEl.style.display = 'none';
          const container = document.getElementById('pdf-container');
          
          for (let pageNum = 1; pageNum <= pdf.numPages; pageNum++) {
            const page = await pdf.getPage(pageNum);
            const viewport = page.getViewport({ scale: 1.5 });
            
            const card = document.createElement('div');
            card.className = 'page-card';
            
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            canvas.height = viewport.height;
            canvas.width = viewport.width;
            
            const footer = document.createElement('div');
            footer.className = 'page-footer';
            footer.textContent = 'Página ' + pageNum + ' de ' + pdf.numPages;
            
            card.appendChild(canvas);
            card.appendChild(footer);
            container.appendChild(card);
            
            await page.render({ canvasContext: ctx, viewport: viewport }).promise;
          }
        }).catch(function(err) {
          document.getElementById('loading').innerHTML = '<span style="color:#ef4444">Error al procesar PDF: ' + err.message + '</span>';
        });
      } catch(e) {
        document.getElementById('loading').innerHTML = '<span style="color:#ef4444">Error de datos: ' + e.message + '</span>';
      }
    } else {
      document.getElementById('loading').innerHTML = '<span style="color:#ef4444">No se pudo cargar el visor de PDF.</span>';
    }
  </script>
</body>
</html>
`;

const readFileAsBase64 = async (uri: string): Promise<string> => {
  try {
    const file = new ExpoFile(uri);
    if (typeof (file as any).base64 === 'function') {
      const b64 = await (file as any).base64();
      if (b64) return b64;
    }
  } catch (e) {
    // Fallback to legacy API
  }

  return await FileSystemLegacy.readAsStringAsync(uri, {
    encoding: FileSystemLegacy.EncodingType.Base64,
  });
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


export default function VisualDTBApp() {
  const { width, height } = useWindowDimensions();
  const isLandscape = width > height;
  const isPortrait = height >= width;
  const isCompact = width < 768;

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
  const scrollX = useRef(new Animated.Value(1000)).current;

  // Songs State
  const [songsList, setSongsList] = useState(mockSongs);
  const [selectedSongId, setSelectedSongId] = useState<string>('s1');
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

  // External Display State
  const externalScreens = useExternalDisplay();
  const hasExternalDisplay = Object.keys(externalScreens).length > 0;
  const [externalDisplayEnabled, setExternalDisplayEnabled] = useState<boolean>(true);

  // Document State & Picking Lock
  const isPickingDocRef = useRef<boolean>(false);
  const [isReadingDocument, setIsReadingDocument] = useState<boolean>(false);
  const [currentDocName, setCurrentDocName] = useState<string>('');

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

  const navItems: { id: ModuleType, icon: keyof typeof Ionicons.glyphMap, label: string }[] = [
    { id: 'Bible', icon: 'book', label: 'Biblia' },
    { id: 'Songs', icon: 'musical-notes', label: 'Canciones' },
    { id: 'Media', icon: 'images', label: 'Medios' },
    { id: 'Documents', icon: 'document-text', label: 'Doc.' },
    { id: 'Messages', icon: 'chatbox-ellipses', label: 'Mensajes' },
    { id: 'Timer', icon: 'timer', label: 'Timer' },
    { id: 'Web', icon: 'globe', label: 'Web' },
    { id: 'Settings', icon: 'settings', label: 'Ajustes' },
  ];

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
        type: ['application/pdf', 'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation', '*/*'],
        copyToCacheDirectory: true
      });
      if (!result.canceled && result.assets && result.assets.length > 0) {
        const asset = result.assets[0];
        const uri = asset.uri;
        const fileName = asset.name || 'documento.pdf';
        setCurrentDocName(fileName);

        // Read file as base64 for Android PDF.js rendering
        let base64Data: string | undefined = undefined;
        try {
          base64Data = await readFileAsBase64(uri);
        } catch (readErr) {
          console.warn('Could not read file as base64:', readErr);
        }

        setProjection({
          type: 'document',
          content: uri,
          base64: base64Data,
          title: fileName,
        });
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

  const playMarquee = () => {
    if (!messageInput.trim()) return;
    setActiveMarquee(messageInput);
    const reps = parseInt(messageReps) || 3;
    let count = 0;
    
    const animate = () => {
      if (count >= reps || isPaused) {
        if (!isPaused) setActiveMarquee('');
        return;
      }
      scrollX.setValue(1000); 
      Animated.timing(scrollX, {
        toValue: -1500, 
        duration: 12000, 
        easing: Easing.linear,
        useNativeDriver: true,
      }).start(({ finished }) => {
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
      scrollX.stopAnimation();
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
             <View style={[styles.columnLeft, isLandscape ? { width: Math.min(240, width * 0.32) } : { height: 220, borderRightWidth: 0, borderBottomWidth: 1 }]}>
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
                                   style={{ width: 40, height: 40, justifyContent: 'center', alignItems: 'center', margin: 4, borderRadius: 20, backgroundColor: selectedChapter === chapterNum ? '#3b82f6' : '#1e293b' }}
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
                             const items = activeChapterData.map((v: string, i: number) => `${selectedBook} ${selectedChapter}:${i+1}\n${v}`);
                             setPlaylist({ items, currentIndex: index });
                             setProjection({ type: 'text', content: items[index] });
                           }}
                         >
                           <Text style={styles.verseNumber}>{verseNum}</Text>
                           <Text style={styles.verseText}>{verseText}</Text>
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
                   <Text style={styles.mockTitle}>{activeSong.title}</Text>
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
                 <TouchableOpacity style={[styles.gridBox, {width: 140, height: 140, backgroundColor: '#3b82f620', borderColor: '#3b82f6', borderWidth: 2, borderStyle: 'dashed'}]} onPress={pickMedia}>
                   <Ionicons name="cloud-upload" size={32} color="#3b82f6" />
                   <Text style={{color: '#3b82f6', marginTop: 10, fontWeight: 'bold', textAlign: 'center', paddingHorizontal: 10}}>Archivo Local del iPad</Text>
                 </TouchableOpacity>

                 {customBackgrounds.map(bg => (
                    <TouchableOpacity 
                      key={bg.id} 
                      style={[styles.gridBox, {width: 140, height: 140, overflow: 'hidden', borderWidth: 1, borderColor: '#334155'}]} 
                      onPress={() => {
                        setMediaPreviewUri(bg.uri);
                        setMediaPreviewType(bg.type as 'image'|'video');
                      }}>
                      <Image source={{uri: bg.thumbnail}} style={{width: '100%', height: '100%', resizeMode: 'cover'}} />
                      <View style={{position: 'absolute', bottom: 5, left: 5, right: 5, backgroundColor: 'rgba(0,0,0,0.7)', padding: 4, borderRadius: 4}}>
                         <Text style={{color: 'white', fontSize: 10, textAlign: 'center', fontWeight: 'bold'}}>{bg.name}</Text>
                      </View>
                      <TouchableOpacity 
                        style={{position: 'absolute', top: 5, right: 5, backgroundColor: 'rgba(0,0,0,0.6)', padding: 6, borderRadius: 15, zIndex: 10}}
                        onPress={(e) => {
                           e.stopPropagation();
                           Alert.alert('Eliminar', '¿Deseas quitar este fondo?', [
                             { text: 'Cancelar', style: 'cancel' },
                             { text: 'Eliminar', style: 'destructive', onPress: () => {
                                setCustomBackgrounds(prev => prev.filter(item => item.id !== bg.id));
                             }}
                           ]);
                        }}
                      >
                         <Ionicons name="ellipsis-vertical" size={14} color="white" />
                      </TouchableOpacity>
                    </TouchableOpacity>
                 ))}
            </View>
            
            {mediaPreviewUri && (
               <View style={{marginTop: 20}}>
                  <Text style={{color: '#e2e8f0', marginBottom: 10}}>Archivo seleccionado listo:</Text>
                  
                  {mediaPreviewType === 'image' ? (
                     <Image source={{uri: mediaPreviewUri}} style={{width: '100%', height: 200, resizeMode: 'cover', borderRadius: 8, marginBottom: 10}} />
                  ) : (
                     <View style={{width: '100%', height: 200, backgroundColor: 'black', borderRadius: 8, marginBottom: 10, justifyContent: 'center', alignItems: 'center'}}>
                       <Ionicons name="videocam" size={48} color="#94a3b8" />
                       <Text style={{color: '#94a3b8', marginTop: 10}}>Video cargado</Text>
                     </View>
                  )}

                  <View style={{flexDirection: 'row', gap: 10}}>
                     <TouchableOpacity style={[styles.projectButton, {flex: 1, backgroundColor: '#10b981'}]} onPress={() => {
                        setProjection({ type: mediaPreviewType || 'image', content: mediaPreviewUri });
                     }}>
                        <Text style={styles.projectButtonText}>Proyectar Directo</Text>
                     </TouchableOpacity>
                     <TouchableOpacity style={[styles.projectButton, {flex: 1, backgroundColor: '#8b5cf6'}]} onPress={() => {
                        if (mediaPreviewUri) {
                          const alreadyExists = customBackgrounds.some(bg => bg.uri === mediaPreviewUri);
                          if (!alreadyExists) {
                             const newBg = { id: 'custom-'+Date.now(), type: mediaPreviewType, thumbnail: mediaPreviewUri, uri: mediaPreviewUri, name: 'Guardado' };
                             setCustomBackgrounds([...customBackgrounds, newBg]);
                          }
                          setBackgroundMedia({ type: mediaPreviewType || 'image', uri: mediaPreviewUri });
                          setMediaPreviewUri(null);
                        }
                     }}>
                        <Text style={styles.projectButtonText}>Fondo y Guardar</Text>
                     </TouchableOpacity>
                     <TouchableOpacity style={[styles.projectButton, {backgroundColor: '#ef4444'}]} onPress={() => {setMediaPreviewUri(null);}}>
                        <Text style={styles.projectButtonText}>X</Text>
                     </TouchableOpacity>
                  </View>
               </View>
            )}
          </ScrollView>
        );

      case 'Documents':
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
                {isReadingDocument ? 'Procesando archivo...' : 'Seleccionar Archivo PDF / Documento'}
              </Text>
              <Text style={{color: '#94a3b8', fontSize: 12, marginTop: 4}}>
                Compatible con Android y iPad / iOS
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
                      Listo en Vista Previa y Proyección
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
            <Text style={styles.mockTitle}>Anuncios Tipo Cintillo (Marquee)</Text>
            <TextInput 
              style={styles.textInput}
              placeholder="Escribe un anuncio para que aparezca abajo en movimiento..."
              placeholderTextColor="#64748b"
              value={messageInput}
              onChangeText={setMessageInput}
              multiline
            />
            <View style={{flexDirection: 'row', alignItems: 'center', marginBottom: 16, gap: 10}}>
              <Text style={{color: '#94a3b8'}}>Repeticiones:</Text>
              <TextInput 
                style={[styles.textInput, {height: 40, marginBottom: 0, width: 80, padding: 10}]}
                value={messageReps}
                onChangeText={setMessageReps}
                keyboardType="numeric"
              />
            </View>
            <TouchableOpacity style={styles.projectButton} onPress={playMarquee}>
              <Text style={styles.projectButtonText}>Lanzar Cintillo Animado</Text>
            </TouchableOpacity>
            
            {activeMarquee !== '' && (
              <TouchableOpacity style={[styles.projectButton, {backgroundColor: '#ef4444', marginTop: 12}]} onPress={() => setActiveMarquee('')}>
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
             {hasExternalDisplay ? (
                <Text style={{color: '#10b981', marginTop: 10, padding: 10, backgroundColor: '#064e3b', borderRadius: 6}}>Pantalla externa detectada.</Text>
             ) : (
                <Text style={{color: '#f59e0b', marginTop: 10, padding: 10, backgroundColor: '#78350f', borderRadius: 6}}>No se detecta pantalla externa. Conecta por HDMI o AirPlay.</Text>
             )}
             <Text style={{color: '#94a3b8', marginTop: 10, fontSize: 12}}>Nota: Requiere App Nativa (EAS Build). En Expo Go, esta función no está soportada.</Text>
          </ScrollView>
        );
    }
  };

  // =============================================
  // LOCAL PREVIEW - full features, runs on device screen
  // =============================================
  const renderPreviewContent = () => {
    if (projection.type === 'text') {
       return (
         <View style={styles.previewContentCenter}>
            <Text style={[styles.previewText, { fontSize: Math.max(textSize, 60), color: textColor, flexShrink: 1, width: '100%' }]} adjustsFontSizeToFit minimumFontScale={0.1} numberOfLines={25}>{projection.content}</Text>
         </View>
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
       return (
         <View style={[styles.previewContentCenter, { padding: 0, backgroundColor: 'black' }]}>
            <SafeVideoView key={uri} uri={uri} contentFit="contain" />
         </View>
       );
    }
    if (projection.type === 'web') {
       return <WebView source={{ uri: projection.content }} style={{ flex: 1, backgroundColor: 'white' }} javaScriptEnabled={true} domStorageEnabled={true} originWhitelist={['*']} />;
    }
    if (projection.type === 'pdf' || projection.type === 'document') {
       const uri = projection.content;
       
       // Android (or any platform) with base64 data: render via Mozilla PDF.js in WebView
       if (projection.base64) {
         return (
           <WebView 
             key={uri}
             source={{ html: getPdfHtml(projection.base64) }} 
             style={{ flex: 1, backgroundColor: '#0b0f19' }} 
             javaScriptEnabled={true} 
             domStorageEnabled={true} 
             originWhitelist={['*']} 
             scalesPageToFit={true}
           />
         );
       }

       // Remote HTTP/HTTPS PDF
       if (uri.startsWith('http://') || uri.startsWith('https://')) {
         if (Platform.OS === 'android') {
           const googleDocsUrl = `https://docs.google.com/gview?embedded=true&url=${encodeURIComponent(uri)}`;
           return <WebView source={{ uri: googleDocsUrl }} style={{ flex: 1, backgroundColor: 'white' }} javaScriptEnabled={true} domStorageEnabled={true} originWhitelist={['*']} />;
         }
         return <WebView source={{ uri }} style={{ flex: 1, backgroundColor: 'white' }} javaScriptEnabled={true} domStorageEnabled={true} originWhitelist={['*']} />;
       }

       // iOS native file URI rendering
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

       // Android fallback if base64 is missing
       return (
         <View style={styles.previewContentCenter}>
           <Ionicons name="document-text" size={48} color="#94a3b8" />
           <Text style={{color: '#e2e8f0', marginTop: 10, textAlign: 'center', fontWeight: 'bold'}}>
             {projection.title || 'Documento cargado'}
           </Text>
           <Text style={{color: '#94a3b8', fontSize: 12, marginTop: 4, textAlign: 'center'}}>
             Selecciona el archivo nuevamente para visualizarlo en pantalla.
           </Text>
         </View>
       );
    }
    return null;
  };

  const renderProjectionScreen = () => {
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
                    <SafeVideoView key={backgroundMedia.uri} uri={backgroundMedia.uri} contentFit="cover" />
                  </View>
                )}

                {/* Brightness Overlay (Simulated Dimming) */}
                {brightness < 100 && (
                  <View style={[StyleSheet.absoluteFill, { backgroundColor: 'black', opacity: 1 - (brightness / 100), pointerEvents: 'none', zIndex: 40 }]} />
                )}
                
                {renderPreviewContent()}
                
                {activeMarquee !== '' && (
                  <View style={styles.marqueeContainer}>
                    <Animated.View style={{ transform: [{ translateX: scrollX }] }}>
                      <Text style={styles.marqueeText} numberOfLines={1}>{activeMarquee}</Text>
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
  // NO adjustsFontSizeToFit, NO WebView backgrounds, NO animations
  // =============================================
  const renderExternalScreen = () => {
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
                    <SafeVideoView key={backgroundMedia.uri} uri={backgroundMedia.uri} contentFit="cover" />
                  </View>
                )}

                {/* Brightness Overlay */}
                {brightness < 100 && (
                  <View style={[StyleSheet.absoluteFill, { backgroundColor: 'black', opacity: 1 - (brightness / 100), pointerEvents: 'none', zIndex: 40 }]} />
                )}
                
                {/* Content - lightweight text rendering for text, standard for others */}
                {projection.type === 'text' ? (
                  <View style={styles.previewContentCenter}>
                    <Text style={[styles.previewText, { fontSize: textSize, color: textColor, width: '100%' }]} numberOfLines={25}>{projection.content}</Text>
                  </View>
                ) : renderPreviewContent()}

                {/* Marquee - simple, no animation on external (static banner) */}
                {activeMarquee !== '' && (
                  <View style={styles.marqueeContainer}>
                    <Text style={styles.marqueeText} numberOfLines={1}>{activeMarquee}</Text>
                  </View>
                )}
              </>
           )}
        </View>
     );
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
        {renderProjectionScreen()}

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
      <View style={[styles.sidebar, isCompact && { width: 60 }]}>
        <View style={[styles.sidebarHeader, isCompact && { paddingHorizontal: 10, justifyContent: 'center' }]}>
          <Ionicons name="desktop" size={28} color="#3b82f6" />
          {!isCompact && <Text style={styles.sidebarTitle}>DTB</Text>}
        </View>

        <ScrollView style={styles.sidebarItems} contentContainerStyle={{paddingBottom: 20}} showsVerticalScrollIndicator={false}>
          {navItems.map((item) => (
            <TouchableOpacity 
              key={item.id} 
              style={[styles.navItem, activeModule === item.id && styles.navItemActive, isCompact && { paddingHorizontal: 0, justifyContent: 'center' }]}
              onPress={() => setActiveModule(item.id)}
            >
              <Ionicons 
                name={item.icon} 
                size={24} 
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
        <View style={styles.topBar}>
          <Text style={styles.topBarTitle}>VisualDTB — {activeModule}</Text>
          <View style={styles.topBarControls}>
            {/* Presentation Mode Button */}
            <TouchableOpacity
              style={{flexDirection: 'row', alignItems: 'center', backgroundColor: '#8b5cf6', paddingHorizontal: 14, paddingVertical: 8, borderRadius: 8, gap: 6}}
              onPress={() => setIsPresentationMode(true)}
            >
              <Ionicons name="tv" size={16} color="#fff" />
              <Text style={{color: '#fff', fontWeight: 'bold', fontSize: 13}}>Presentar</Text>
            </TouchableOpacity>
            <View style={styles.tvStatusBadge}>
              <Ionicons name="tv-outline" size={16} color="#94a3b8" />
              <Text style={styles.tvStatusText}>Preview Mode</Text>
            </View>
          </View>
        </View>

        {/* WORKSPACE & PREVIEW SPLIT */}
        <View style={styles.workspace}>
          {/* Module Controls Area */}
          <View style={styles.controlsArea}>
            {renderModuleContent()}
          </View>

          {/* TV Preview Area */}
          <View style={[styles.previewArea, isLandscape && isCompact ? { width: 170, padding: 8 } : isCompact ? { width: '100%', height: 180, padding: 8 } : { width: 280, padding: 16 }]}>
            <View style={styles.previewHeader}>
              <Ionicons name="tv" size={14} color="#94a3b8" />
              <Text style={styles.previewTitle}>PROYECCIÓN</Text>
            </View>
            <View style={[styles.previewScreen, isFullscreen && styles.previewScreenFullscreen]}>
              {renderProjectionScreen()}
            </View>
            <View style={{marginTop: 6}}>
                <Text style={{color: '#64748b', fontSize: 10, textAlign: 'center'}}>
                  {isPaused ? 'PAUSADO' : 'Vista previa de TV'}
                </Text>
            </View>
          </View>
        </View>

        {/* BOTTOM TOOLBAR */}
        <View style={[styles.bottomToolbar, isCompact && { height: 48, paddingVertical: 4, paddingHorizontal: 8 }]}>
          <View style={styles.toolbarGroup}>
            <Ionicons name="sunny" size={16} color="#94a3b8" />
            <Text style={[styles.toolbarLabel, isCompact && { display: 'none' }]}>Brillo</Text>
            <Slider
              style={{width: isCompact ? 65 : 90, height: 30}}
              minimumValue={10}
              maximumValue={100}
              value={brightness}
              onValueChange={setBrightness}
              minimumTrackTintColor="#ffffff"
              maximumTrackTintColor="#334155"
              thumbTintColor="#ffffff"
            />
            <Text style={styles.toolbarValue}>{Math.round(brightness)}%</Text>
          </View>
          
          {/* Selector de Color de Letra */}
          <View style={styles.toolbarGroup}>
            <Ionicons name="color-palette" size={16} color="#94a3b8" />
            <Text style={[styles.toolbarLabel, isCompact && { display: 'none' }]}>Color</Text>
            <View style={{flexDirection: 'row', gap: 6, alignItems: 'center', backgroundColor: '#0f172a', paddingHorizontal: 6, paddingVertical: 4, borderRadius: 16}}>
              {['#ffffff', '#facc15', '#38bdf8', '#4ade80', '#fb923c', '#f472b6'].map(c => (
                <TouchableOpacity
                  key={c}
                  onPress={() => setTextColor(c)}
                  style={{
                    width: 18,
                    height: 18,
                    borderRadius: 9,
                    backgroundColor: c,
                    borderWidth: textColor === c ? 2 : 1,
                    borderColor: textColor === c ? '#3b82f6' : '#475569',
                    transform: [{ scale: textColor === c ? 1.25 : 1 }]
                  }}
                />
              ))}
            </View>
          </View>

          <View style={{flex: 1}} />

          {/* BOTONES INTERACTIVOS */}
          <View style={styles.toolbarActions}>
             {/* Playlist Controls */}
             {playlist && (
               <View style={{flexDirection: 'row', marginRight: 6, borderWidth: 1, borderColor: '#334155', borderRadius: 6}}>
                 <TouchableOpacity style={[styles.actionBtn, {backgroundColor: '#3b82f620', borderRadius: 0, borderRightWidth: 1, borderRightColor: '#334155', borderTopLeftRadius: 6, borderBottomLeftRadius: 6}]} onPress={handlePrevSlide}>
                   <Ionicons name="chevron-up" size={16} color="#3b82f6" />
                 </TouchableOpacity>
                 <TouchableOpacity style={[styles.actionBtn, {backgroundColor: '#3b82f620', borderRadius: 0, borderTopRightRadius: 6, borderBottomRightRadius: 6}]} onPress={handleNextSlide}>
                   <Ionicons name="chevron-down" size={16} color="#3b82f6" />
                 </TouchableOpacity>
               </View>
             )}

             <TouchableOpacity 
                style={[styles.actionBtn, {backgroundColor: '#f59e0b20', flexDirection: 'row', paddingHorizontal: 8, marginRight: 6}]} 
                onPress={() => setProjection({ type: 'text', content: '' })}>
               <Ionicons name="trash" size={14} color="#f59e0b" style={{marginRight: 4}}/>
               <Text style={{color: '#f59e0b', fontWeight: 'bold', fontSize: 10}}>Limpiar</Text>
             </TouchableOpacity>

             <TouchableOpacity 
                style={[styles.actionBtn, isPaused && styles.actionBtnActive]} 
                onPress={() => setIsPaused(!isPaused)}>
               <Ionicons name="pause" size={16} color={isPaused ? "#ffffff" : "#cbd5e1"} />
             </TouchableOpacity>

             <TouchableOpacity 
                style={[styles.actionBtn, isBlackout ? styles.actionBtnDanger : {backgroundColor: '#ef444420'}]} 
                onPress={() => setIsBlackout(!isBlackout)}>
               <Ionicons name="eye-off" size={16} color={isBlackout ? "#ffffff" : "#ef4444"} />
             </TouchableOpacity>

             <TouchableOpacity 
                style={[styles.actionBtn, isFullscreen && styles.actionBtnSuccess]} 
                onPress={() => setIsFullscreen(!isFullscreen)}>
               <Ionicons name="expand" size={16} color={isFullscreen ? "#ffffff" : "#10b981"} />
             </TouchableOpacity>
          </View>
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
  
  previewContentCenter: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24, zIndex: 1 },
  previewText: { color: '#ffffff', fontSize: 28, fontWeight: 'bold', textAlign: 'center', textShadowColor: 'rgba(0, 0, 0, 0.75)', textShadowOffset: {width: -1, height: 1}, textShadowRadius: 10 },
  
  marqueeContainer: { position: 'absolute', bottom: 0, width: '100%', height: 60, backgroundColor: 'rgba(220, 38, 38, 0.9)', justifyContent: 'center', zIndex: 50 },
  marqueeText: { color: '#ffffff', fontSize: 28, fontWeight: 'bold', paddingHorizontal: 20 },

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
