import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, TextInput, ScrollView, Image, Animated, Easing, Platform } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import * as DocumentPicker from 'expo-document-picker';
import { WebView } from 'react-native-webview';
import Slider from '@react-native-community/slider';
import fullBible from '../bible.json';

type ModuleType = 'Bible' | 'Songs' | 'Media' | 'Documents' | 'Messages' | 'Timer' | 'Web' | 'Settings';

type ProjectionData = {
  type: 'text' | 'image' | 'video' | 'web' | 'pdf';
  content: string; 
};

const defaultBackgrounds = [
  {
    id: 'bg1',
    type: 'video',
    thumbnail: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=300&q=80',
    uri: 'https://assets.mixkit.co/videos/preview/mixkit-stars-in-space-1610-large.mp4',
    name: 'Espacio (Video)'
  },
  {
    id: 'bg2',
    type: 'video',
    thumbnail: 'https://images.unsplash.com/photo-1534081333815-ae5019106622?w=300&q=80',
    uri: 'https://assets.mixkit.co/videos/preview/mixkit-clouds-and-blue-sky-2408-large.mp4',
    name: 'Nubes (Video)'
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
  const [activeModule, setActiveModule] = useState<ModuleType>('Bible');
  const [projection, setProjection] = useState<ProjectionData>({ type: 'text', content: 'VISUAL DTB\nListo para proyectar' });
  
  // Toolbar states
  const [isBlackout, setIsBlackout] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);

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
  const [selectedBook, setSelectedBook] = useState<string>('Mateo');
  const [selectedChapter, setSelectedChapter] = useState<number>(8);
  const [bibleSearch, setBibleSearch] = useState<string>('');

  // Media Background State
  const [backgroundMedia, setBackgroundMedia] = useState<{type: 'image' | 'video', uri: string} | null>(null);
  const [mediaPreviewUri, setMediaPreviewUri] = useState<string | null>(null);
  const [mediaPreviewType, setMediaPreviewType] = useState<'image'|'video'|null>(null);
  const [customBackgrounds, setCustomBackgrounds] = useState<any[]>([]);

  // Toolbar Slider states
  const [brightness, setBrightness] = useState<number>(100);
  const [textSize, setTextSize] = useState<number>(48);

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
    let interval: NodeJS.Timeout;
    if (timerRunning && timeLeft > 0 && !isPaused) {
      interval = setInterval(() => {
        setTimeLeft(prev => {
          const newTime = prev - 1;
          if (projection.content.includes('⏳')) {
             const mins = Math.floor(newTime / 60).toString().padStart(2, '0');
             const secs = (newTime % 60).toString().padStart(2, '0');
             setProjection({ type: 'text', content: `⏳ ${mins}:${secs}` });
          }
          return newTime;
        });
      }, 1000);
    } else if (timeLeft === 0 && timerRunning) {
      setTimerRunning(false);
      if (projection.content.includes('⏳')) {
         setProjection({ type: 'text', content: `¡Tiempo Finalizado!` });
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
    let result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images', 'videos'],
      allowsEditing: false,
      quality: 1,
    });
    if (!result.canceled) {
      setMediaPreviewUri(result.assets[0].uri);
      setMediaPreviewType(result.assets[0].type === 'video' ? 'video' : 'image');
    }
  };

  const pickDocument = async () => {
    let result = await DocumentPicker.getDocumentAsync({
      type: '*/*',
      copyToCacheDirectory: true
    });
    if (!result.canceled) {
       // WebView en iOS puede renderizar PDF, PPT, PPTX, DOC, DOCX
       setProjection({ type: 'document', content: result.assets[0].uri });
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

  const renderModuleContent = () => {
    switch(activeModule) {
      case 'Bible':
        const filteredBooks = fullBible.filter((b: any) => b.name.toLowerCase().includes(bibleSearch.toLowerCase()));
        const activeBookData = fullBible.find((b: any) => b.name === selectedBook) || fullBible[0];
        const activeChapterData = activeBookData.chapters[selectedChapter - 1] || activeBookData.chapters[0];

        return (
          <View style={styles.twoColumnLayout}>
             {/* Columna Izquierda: Buscador y Libros */}
             <View style={styles.columnLeft}>
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
                   {filteredBooks.map((b: any) => (
                     <View key={b.name}>
                       <TouchableOpacity style={styles.bookHeader} onPress={() => { setSelectedBook(b.name); setSelectedChapter(1); }}>
                         <Text style={styles.bookHeaderText}>{b.name}</Text>
                       </TouchableOpacity>
                       {selectedBook === b.name && b.chapters.map((c: any, index: number) => {
                         const chapterNum = index + 1;
                         return (
                         <TouchableOpacity 
                           key={`${b.name}-${chapterNum}`} 
                           style={[styles.chapterItem, selectedChapter === chapterNum && styles.chapterItemActive]}
                           onPress={() => setSelectedChapter(chapterNum)}
                         >
                           <Text style={[styles.chapterItemText, selectedChapter === chapterNum && {color: '#60a5fa'}]}>Capítulo {chapterNum}</Text>
                         </TouchableOpacity>
                         )
                       })}
                     </View>
                   ))}
                </ScrollView>
             </View>

             {/* Columna Derecha: Versículos */}
             <View style={styles.columnRight}>
               <Text style={styles.mockTitle}>{selectedBook} {selectedChapter} (RV1960)</Text>
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
                   )
                 })}
               </ScrollView>
             </View>
          </View>
        );

      case 'Songs':
        const activeSong = songsList.find(s => s.id === selectedSongId) || songsList[0];
        const filteredSongs = songsList.filter(s => s.title.toLowerCase().includes(songSearch.toLowerCase()));

        return (
          <View style={styles.twoColumnLayout}>
             {/* Columna Izquierda: Canciones */}
             <View style={styles.columnLeft}>
                <View style={styles.searchBar}>
                  <Ionicons name="search" size={16} color="#94a3b8" />
                  <TextInput 
                    style={styles.searchInput}
                    placeholder="Buscar canción..."
                    placeholderTextColor="#64748b"
                    value={songSearch}
                    onChangeText={setSongSearch}
                  />
                </View>
                <TouchableOpacity 
                   style={[styles.projectButton, {backgroundColor: '#3b82f6', marginBottom: 10, marginHorizontal: 16, paddingVertical: 8}]}
                   onPress={() => setIsAddingSong(true)}
                >
                   <Text style={[styles.projectButtonText, {fontSize: 14}]}>+ Agregar Canción</Text>
                </TouchableOpacity>
                <ScrollView style={{flex: 1}}>
                   {filteredSongs.map(s => (
                     <ScrollView key={s.id} horizontal showsHorizontalScrollIndicator={false} snapToInterval={350} decelerationRate="fast">
                       <View style={{flexDirection: 'row'}}>
                         <TouchableOpacity 
                           style={[styles.songListItem, {width: 250}, selectedSongId === s.id && styles.songListItemActive]}
                           onPress={() => { setSelectedSongId(s.id); setIsAddingSong(false); }}
                         >
                           <Ionicons name="musical-note" size={16} color={selectedSongId === s.id ? "#3b82f6" : "#94a3b8"} style={{marginRight: 8}}/>
                           <Text style={[styles.songListText, selectedSongId === s.id && {color: '#60a5fa', fontWeight: 'bold'}]} numberOfLines={1}>{s.title}</Text>
                         </TouchableOpacity>
                         
                         {s.id.startsWith('custom') && (
                           <>
                             <TouchableOpacity style={{width: 50, backgroundColor: '#3b82f6', justifyContent: 'center', alignItems: 'center'}} onPress={() => handleEditSong(s.id)}>
                               <Ionicons name="pencil" size={20} color="white" />
                             </TouchableOpacity>
                             <TouchableOpacity style={{width: 50, backgroundColor: '#ef4444', justifyContent: 'center', alignItems: 'center'}} onPress={() => handleDeleteSong(s.id)}>
                               <Ionicons name="trash" size={20} color="white" />
                             </TouchableOpacity>
                           </>
                         )}
                       </View>
                     </ScrollView>
                   ))}
                </ScrollView>
             </View>

             {/* Columna Derecha: Estrofas o Formulario */}
             <View style={styles.columnRight}>
               {isAddingSong ? (
                 <View style={{flex: 1, padding: 16}}>
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
                      style={[styles.searchInput, {flex: 1, backgroundColor: '#1e293b', padding: 12, marginBottom: 10, color: 'white', textAlignVertical: 'top'}]}
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
                 </View>
               ) : (
                 <>
                   <Text style={styles.mockTitle}>{activeSong.title}</Text>
                   <ScrollView style={{flex: 1}}>
                     {activeSong.stanzas.map((stanza, index) => (
                       <TouchableOpacity 
                         key={index}
                         style={styles.mockVerse} 
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
                     ))}
                   </ScrollView>
                 </>
               )}
             </View>
          </View>
        );

      case 'Media':
        return (
          <ScrollView style={styles.moduleContentSingle}>
            <Text style={styles.mockTitle}>Galería Multimedia y Fondos</Text>
            <View style={styles.gridContainer}>
                 <TouchableOpacity style={[styles.gridBox, {width: 140, height: 140, backgroundColor: '#3b82f620', borderColor: '#3b82f6', borderWidth: 2, borderStyle: 'dashed'}]} onPress={pickMedia}>
                   <Ionicons name="cloud-upload" size={32} color="#3b82f6" />
                   <Text style={{color: '#3b82f6', marginTop: 10, fontWeight: 'bold', textAlign: 'center', paddingHorizontal: 10}}>Archivo Local del iPad</Text>
                 </TouchableOpacity>

                 {[...defaultBackgrounds, ...customBackgrounds].map(bg => (
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
                        const newBg = { id: 'custom-'+Date.now(), type: mediaPreviewType, thumbnail: mediaPreviewUri, uri: mediaPreviewUri, name: 'Guardado' };
                        setCustomBackgrounds([...customBackgrounds, newBg]);
                        setBackgroundMedia({ type: mediaPreviewType || 'image', uri: mediaPreviewUri });
                        setMediaPreviewUri(null);
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
        return (
          <View style={styles.moduleContentSingle}>
            <Text style={styles.mockTitle}>Gestor de Archivos (PDF, PPTX, DOCX)</Text>
            <View style={styles.gridContainer}>
                 <TouchableOpacity style={[styles.gridBox, {width: '100%', height: 200, backgroundColor: '#ef444420', borderColor: '#ef4444', borderWidth: 2, borderStyle: 'dashed'}]} onPress={pickDocument}>
                   <Ionicons name="document-text" size={48} color="#ef4444" />
                   <Text style={{color: '#ef4444', marginTop: 10, fontWeight: 'bold'}}>Seleccionar y Visualizar Archivo (PDF, PPT, Word)</Text>
                 </TouchableOpacity>
            </View>
          </View>
        );

      case 'Messages':
        return (
          <View style={styles.moduleContentSingle}>
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
          </View>
        );

      case 'Timer':
        return (
          <View style={styles.moduleContentSingle}>
            <Text style={styles.mockTitle}>Cuenta Regresiva</Text>
            <View style={styles.timerMock}>
               <Text style={styles.timerTextMock}>{formatTime(timeLeft)}</Text>
            </View>
            <View style={{flexDirection: 'row', gap: 12, marginBottom: 20}}>
               <TouchableOpacity style={[styles.projectButton, {flex: 1, backgroundColor: '#10b981'}]} onPress={() => { setTimerRunning(true); setProjection({ type: 'text', content: `⏳ ${formatTime(timeLeft)}` }); }}>
                 <Text style={styles.projectButtonText}>{timerRunning ? 'Corriendo...' : 'Iniciar Timer'}</Text>
               </TouchableOpacity>
               <TouchableOpacity style={[styles.projectButton, {flex: 1, backgroundColor: '#ef4444'}]} onPress={() => setTimerRunning(false)}>
                 <Text style={styles.projectButtonText}>Pausar</Text>
               </TouchableOpacity>
               <TouchableOpacity style={[styles.projectButton, {flex: 1, backgroundColor: '#64748b'}]} onPress={() => { setTimerRunning(false); setTimeLeft(timerMinutes * 60); }}>
                 <Text style={styles.projectButtonText}>Reset</Text>
               </TouchableOpacity>
            </View>
          </View>
        );

      case 'Web':
        return (
          <View style={styles.moduleContentSingle}>
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
          </View>
        );

      case 'Settings':
        return (
          <View style={styles.moduleContentSingle}>
             <Text style={styles.mockTitle}>Configuración del Sistema</Text>
             <View style={styles.settingRow}>
                <Text style={styles.verseText}>Auto-conectar a TV Externa HDMI</Text>
                <Ionicons name="toggle" size={32} color="#3b82f6" />
             </View>
          </View>
        );
    }
  };

  const renderPreviewContent = () => {
    if (projection.type === 'text') {
       return (
         <View style={styles.previewContentCenter}>
            <Text style={[styles.previewText, { fontSize: Math.max(textSize, 60), flexShrink: 1, width: '100%' }]} adjustsFontSizeToFit minimumFontScale={0.1} numberOfLines={25}>{projection.content}</Text>
         </View>
       );
    }
    if (projection.type === 'image') {
       return (
         <View style={styles.previewContentCenter}>
            <Image source={{ uri: projection.content }} style={{width: '100%', height: '100%', resizeMode: 'contain'}} />
         </View>
       );
    }
    if (projection.type === 'video') {
       const videoHtml = `
        <style>body { margin: 0; background: black; overflow: hidden; display: flex; justify-content: center; align-items: center; height: 100vh; }</style>
        <video autoplay loop muted playsinline style="width: 100%; height: 100%; object-fit: contain;" src="${projection.content}"></video>
       `;
       return (
         <View style={styles.previewContentCenter}>
            <WebView 
              originWhitelist={['*']} 
              source={{ html: videoHtml, baseUrl: projection.content }} 
              allowsInlineMediaPlayback={true} 
              mediaPlaybackRequiresUserAction={false} 
              allowFileAccessFromFileURLs={true} 
              allowUniversalAccessFromFileURLs={true} 
              style={{width: '100%', height: '100%', backgroundColor: 'black'}} 
              scrollEnabled={false} 
            />
         </View>
       );
    }
    if (projection.type === 'web' || projection.type === 'pdf' || projection.type === 'document') {
       // Allow webview to render PDFs and Office documents natively on iOS and Web URLs.
       return <WebView source={{ uri: projection.content }} style={{ flex: 1, backgroundColor: 'white' }} javaScriptEnabled={true} domStorageEnabled={true} originWhitelist={['*']} allowFileAccessFromFileURLs={true} allowUniversalAccessFromFileURLs={true} />;
    }
    return null;
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* SIDEBAR */}
      <View style={styles.sidebar}>
        <View style={styles.sidebarHeader}>
          <Ionicons name="desktop" size={28} color="#3b82f6" />
          <Text style={styles.sidebarTitle}>DTB</Text>
        </View>

        <View style={styles.sidebarItems}>
          {navItems.map((item) => (
            <TouchableOpacity 
              key={item.id} 
              style={[styles.navItem, activeModule === item.id && styles.navItemActive]}
              onPress={() => setActiveModule(item.id)}
            >
              <Ionicons 
                name={item.icon} 
                size={24} 
                color={activeModule === item.id ? '#60a5fa' : '#94a3b8'} 
              />
              <Text style={[styles.navItemText, activeModule === item.id && styles.navItemTextActive]}>
                {item.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
        
      </View>

      {/* MAIN CONTENT AREA */}
      <View style={styles.main}>
        {/* TOP BAR */}
        <View style={styles.topBar}>
          <Text style={styles.topBarTitle}>VisualDTB — {activeModule}</Text>
          <View style={styles.topBarControls}>
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
          <View style={styles.previewArea}>
            <View style={styles.previewHeader}>
              <Ionicons name="tv" size={14} color="#94a3b8" />
              <Text style={styles.previewTitle}>PANTALLA DE PROYECCIÓN {isFullscreen ? '(PANTALLA COMPLETA)' : ''}</Text>
            </View>
            <View style={[styles.previewScreen, isFullscreen && styles.previewScreenFullscreen]}>
              
              {isBlackout ? (
                 <View style={{flex: 1, backgroundColor: 'black'}} />
              ) : (
                 <>
                   {/* Background Media */}
                   {backgroundMedia && backgroundMedia.type === 'image' && (
                     <Image source={{ uri: backgroundMedia.uri }} style={[StyleSheet.absoluteFill, {width: '100%', height: '100%', resizeMode: 'cover', zIndex: -1}]} />
                   )}
                   {backgroundMedia && backgroundMedia.type === 'video' && (
                     <View style={[StyleSheet.absoluteFill, {zIndex: -1}]}>
                       <WebView 
                         originWhitelist={['*']} 
                         scrollEnabled={false}
                         source={{ html: `
                            <style>body { margin: 0; background: black; overflow: hidden; }</style>
                            <video autoplay loop muted playsinline style="width: 100vw; height: 100vh; object-fit: cover;">
                              <source src="${backgroundMedia.uri}" type="video/mp4">
                            </video>
                         ` }} 
                         style={{flex: 1, backgroundColor: 'black'}} 
                       />
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
            <View style={{marginTop: 10}}>
                <Text style={{color: '#64748b', fontSize: 12, textAlign: 'center'}}>
                  {isPaused ? '⏸️ LA PROYECCIÓN ESTÁ PAUSADA' : 'Lo que ves aquí es lo que verá la audiencia.'}
                </Text>
            </View>
          </View>
        </View>

        {/* BOTTOM TOOLBAR */}
        <View style={styles.bottomToolbar}>
          <View style={styles.toolbarGroup}>
            <Ionicons name="sunny" size={20} color="#94a3b8" />
            <Text style={styles.toolbarLabel}>Brillo</Text>
            <Slider
              style={{width: 150, height: 40}}
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
          
          <View style={styles.toolbarGroup}>
            <Text style={{color: '#94a3b8', fontWeight: 'bold', fontSize: 16}}>AA</Text>
            <Text style={styles.toolbarLabel}>Tamaño</Text>
            <Slider
              style={{width: 150, height: 40}}
              minimumValue={24}
              maximumValue={96}
              value={textSize}
              onValueChange={setTextSize}
              minimumTrackTintColor="#ffffff"
              maximumTrackTintColor="#334155"
              thumbTintColor="#ffffff"
            />
            <Text style={styles.toolbarValue}>{Math.round(textSize)}</Text>
          </View>

          <View style={{flex: 1}} />

          {/* BOTONES INTERACTIVOS */}
          <View style={styles.toolbarActions}>
             {/* Playlist Controls */}
             {playlist && (
               <View style={{flexDirection: 'row', marginRight: 10, borderWidth: 1, borderColor: '#334155', borderRadius: 8}}>
                 <TouchableOpacity style={[styles.actionBtn, {backgroundColor: '#3b82f620', borderRadius: 0, borderRightWidth: 1, borderRightColor: '#334155', borderTopLeftRadius: 8, borderBottomLeftRadius: 8}]} onPress={handlePrevSlide}>
                   <Ionicons name="chevron-up" size={20} color="#3b82f6" />
                 </TouchableOpacity>
                 <TouchableOpacity style={[styles.actionBtn, {backgroundColor: '#3b82f620', borderRadius: 0, borderTopRightRadius: 8, borderBottomRightRadius: 8}]} onPress={handleNextSlide}>
                   <Ionicons name="chevron-down" size={20} color="#3b82f6" />
                 </TouchableOpacity>
               </View>
             )}

             <TouchableOpacity 
                style={[styles.actionBtn, {backgroundColor: '#f59e0b20', flexDirection: 'row', paddingHorizontal: 12, marginRight: 10}]} 
                onPress={() => setProjection({ type: 'text', content: '' })}>
               <Ionicons name="trash" size={18} color="#f59e0b" style={{marginRight: 6}}/>
               <Text style={{color: '#f59e0b', fontWeight: 'bold', fontSize: 12}}>Limpiar Texto</Text>
             </TouchableOpacity>

             <TouchableOpacity 
                style={[styles.actionBtn, isPaused && styles.actionBtnActive]} 
                onPress={() => setIsPaused(!isPaused)}>
               <Ionicons name="pause" size={20} color={isPaused ? "#ffffff" : "#cbd5e1"} />
             </TouchableOpacity>

             <TouchableOpacity 
                style={[styles.actionBtn, isBlackout ? styles.actionBtnDanger : {backgroundColor: '#ef444420'}]} 
                onPress={() => setIsBlackout(!isBlackout)}>
               <Ionicons name="eye-off" size={20} color={isBlackout ? "#ffffff" : "#ef4444"} />
             </TouchableOpacity>

             <TouchableOpacity 
                style={[styles.actionBtn, isFullscreen && styles.actionBtnSuccess]} 
                onPress={() => setIsFullscreen(!isFullscreen)}>
               <Ionicons name="expand" size={20} color={isFullscreen ? "#ffffff" : "#10b981"} />
             </TouchableOpacity>
          </View>
        </View>
      </View>
    </SafeAreaView>
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
  projectButton: { backgroundColor: '#3b82f6', padding: 16, borderRadius: 8, alignItems: 'center' },
  projectButtonText: { color: '#ffffff', fontWeight: 'bold', fontSize: 16 },
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

  bottomToolbar: { height: 60, backgroundColor: '#1e293b', flexDirection: 'row', alignItems: 'center', paddingHorizontal: 20, gap: 24 },
  toolbarGroup: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  toolbarLabel: { color: '#cbd5e1', fontSize: 14 },
  sliderMock: { width: 150, height: 4, backgroundColor: '#334155', borderRadius: 2, justifyContent: 'center' },
  sliderThumb: { width: 16, height: 16, borderRadius: 8, backgroundColor: '#ffffff', position: 'absolute', left: '80%' },
  toolbarValue: { color: '#94a3b8', fontSize: 12 },
  toolbarActions: { flexDirection: 'row', gap: 12 },
  actionBtn: { width: 40, height: 40, borderRadius: 8, backgroundColor: '#334155', justifyContent: 'center', alignItems: 'center' },
  actionBtnActive: { backgroundColor: '#3b82f6' },
  actionBtnDanger: { backgroundColor: '#ef4444' },
  actionBtnSuccess: { backgroundColor: '#10b981' },
});
