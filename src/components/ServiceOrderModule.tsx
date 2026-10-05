import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  TextInput,
  Modal,
  Image,
  Alert,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { ServiceOrder, ServiceItem } from '../utils/serviceStorage';

interface ServiceOrderModuleProps {
  services: ServiceOrder[];
  activeServiceId: string;
  activeServiceItemId?: string | null;
  onSelectService: (serviceId: string) => void;
  onCreateService: (name: string, date: string) => void;
  onDeleteService: (serviceId: string) => void;
  onUpdateServiceBackground: (serviceId: string, bg: { uri: string; type: 'image' | 'video' } | null) => void;
  onAddItem: (serviceId: string, item: Omit<ServiceItem, 'id'>) => void;
  onRemoveItem: (serviceId: string, itemId: string) => void;
  onReorderItem: (serviceId: string, itemId: string, direction: 'up' | 'down') => void;
  onUpdateItemBackground: (serviceId: string, itemId: string, bg: { uri: string; type: 'image' | 'video' } | null) => void;
  onProjectItem: (item: ServiceItem) => void;
  songsList: any[];
  recentVerses: { ref: string; text: string; fullContent: string }[];
  customBackgrounds: any[];
  loadedBibles: any[];
  isCompact: boolean;
  isLandscape: boolean;
}

export default function ServiceOrderModule({
  services,
  activeServiceId,
  activeServiceItemId,
  onSelectService,
  onCreateService,
  onDeleteService,
  onUpdateServiceBackground,
  onAddItem,
  onRemoveItem,
  onReorderItem,
  onUpdateItemBackground,
  onProjectItem,
  songsList,
  recentVerses,
  customBackgrounds,
  loadedBibles,
  isCompact,
  isLandscape,
}: ServiceOrderModuleProps) {
  const currentService = services.find((s) => s.id === activeServiceId) || services[0];

  // Modals state
  const [showNewServiceModal, setShowNewServiceModal] = useState(false);
  const [newServiceName, setNewServiceName] = useState('');
  const [newServiceDate, setNewServiceDate] = useState('Domingo');

  const [showSongModal, setShowSongModal] = useState(false);
  const [songSearch, setSongSearch] = useState('');

  const [showVerseModal, setShowVerseModal] = useState(false);
  const [verseModalTab, setVerseModalTab] = useState<'recent' | 'manual'>('recent');
  const [selectedBook, setSelectedBook] = useState(loadedBibles[0]?.data[0]?.name || 'Mateo');
  const [selectedChapter, setSelectedChapter] = useState(1);
  const [selectedVerseNum, setSelectedVerseNum] = useState(1);

  const [showMediaModal, setShowMediaModal] = useState(false);
  const [showNoteModal, setShowNoteModal] = useState(false);
  const [noteTitle, setNoteTitle] = useState('Bienvenida');
  const [noteContent, setNoteContent] = useState('');

  const [bgTarget, setBgTarget] = useState<{ mode: 'service' | 'item'; itemId?: string } | null>(null);

  // Helper to submit new service
  const handleCreateService = () => {
    if (!newServiceName.trim()) {
      Alert.alert('Nombre requerido', 'Por favor ingresa un nombre para el orden de culto.');
      return;
    }
    onCreateService(newServiceName.trim(), newServiceDate.trim() || 'Culto');
    setNewServiceName('');
    setNewServiceDate('Domingo');
    setShowNewServiceModal(false);
  };

  // Helper to add a song to the active service
  const handleAddSong = (song: any) => {
    if (!currentService) return;
    const firstText = song.stanzas?.[0]?.text || song.title;
    onAddItem(currentService.id, {
      type: 'song',
      title: song.title,
      subtitle: `${song.stanzas?.length || 0} estrofas`,
      songId: song.id,
      content: firstText,
      stanzas: song.stanzas,
      backgroundUri: currentService.defaultBackgroundUri || null,
      backgroundType: currentService.defaultBackgroundType || null,
    });
    setShowSongModal(false);
  };

  // Helper to add verse
  const handleAddRecentVerse = (item: { ref: string; text: string; fullContent: string }) => {
    if (!currentService) return;
    onAddItem(currentService.id, {
      type: 'verse',
      title: item.ref,
      subtitle: item.text.length > 55 ? item.text.substring(0, 55) + '...' : item.text,
      verseRef: item.ref,
      content: item.fullContent,
      backgroundUri: currentService.defaultBackgroundUri || null,
      backgroundType: currentService.defaultBackgroundType || null,
    });
    setShowVerseModal(false);
  };

  const handleAddManualVerse = () => {
    if (!currentService) return;
    const bibleData = loadedBibles[0]?.data || [];
    const book = bibleData.find((b: any) => b.name === selectedBook);
    const chapter = book?.chapters?.[selectedChapter - 1] || [];
    const verseText = chapter[selectedVerseNum - 1] || '';
    const ref = `${selectedBook} ${selectedChapter}:${selectedVerseNum}`;
    const fullContent = `${ref}\n${verseText}`;

    onAddItem(currentService.id, {
      type: 'verse',
      title: ref,
      subtitle: verseText.length > 55 ? verseText.substring(0, 55) + '...' : verseText,
      verseRef: ref,
      content: fullContent,
      backgroundUri: currentService.defaultBackgroundUri || null,
      backgroundType: currentService.defaultBackgroundType || null,
    });
    setShowVerseModal(false);
  };

  // Helper to add media
  const handleAddMedia = (bg: any) => {
    if (!currentService) return;
    onAddItem(currentService.id, {
      type: 'media',
      title: bg.name || 'Multimedia',
      subtitle: bg.type === 'video' ? 'Video animado' : 'Imagen fija',
      content: bg.uri,
      backgroundUri: bg.uri,
      backgroundType: bg.type as any,
    });
    setShowMediaModal(false);
  };

  // Helper to add note/block
  const handleAddNote = () => {
    if (!currentService) return;
    onAddItem(currentService.id, {
      type: 'note',
      title: noteTitle.trim() || 'Momento del Servicio',
      subtitle: 'Momento de Culto',
      content: noteContent.trim() || noteTitle.toUpperCase(),
      backgroundUri: currentService.defaultBackgroundUri || null,
      backgroundType: currentService.defaultBackgroundType || null,
    });
    setNoteTitle('');
    setNoteContent('');
    setShowNoteModal(false);
  };

  // Quick preset notes
  const presetNotes = [
    { title: 'Bienvenida y Oración', content: 'BIENVENIDOS\nA LA CASA DE DIOS' },
    { title: 'Alabanza y Adoración', content: 'TIEMPO DE ALABANZA\nY ADORACIÓN' },
    { title: 'Diezmos y Ofrendas', content: 'DIEZMOS Y OFRENDAS\n«Dios ama al dador alegre»' },
    { title: 'Mensaje de la Palabra', content: 'TIEMPO DE LA PALABRA\nPredicación Pastoral' },
    { title: 'Santa Cena', content: 'SANTA CENA DEL SEÑOR' },
    { title: 'Anuncios y Avisos', content: 'ANUNCIOS GENERALES' },
    { title: 'Oración Final', content: 'BENDICIÓN Y DESPEDIDA' },
  ];

  const filteredSongs = songsList.filter((s) =>
    s.title.toLowerCase().includes(songSearch.toLowerCase())
  );

  return (
    <View style={styles.container}>
      {/* 1. SELECTOR DE CULTOS / SERVICIOS (PILLS) */}
      <View style={styles.servicesHeader}>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ alignItems: 'center', gap: 8, paddingHorizontal: 4 }}
        >
          {services.map((srv) => {
            const isSelected = srv.id === currentService?.id;
            return (
              <TouchableOpacity
                key={srv.id}
                style={[styles.servicePill, isSelected && styles.servicePillActive]}
                onPress={() => onSelectService(srv.id)}
              >
                <Ionicons
                  name="calendar-outline"
                  size={14}
                  color={isSelected ? '#ffffff' : '#94a3b8'}
                  style={{ marginRight: 6 }}
                />
                <Text
                  style={[styles.servicePillText, isSelected && styles.servicePillTextActive]}
                  numberOfLines={1}
                >
                  {srv.name}
                </Text>
                <Text style={{ color: isSelected ? '#93c5fd' : '#64748b', fontSize: 10, marginLeft: 6 }}>
                  ({srv.items.length})
                </Text>
              </TouchableOpacity>
            );
          })}

          {/* Botón Añadir Nuevo Servicio */}
          <TouchableOpacity
            style={styles.newServiceBtn}
            onPress={() => {
              setNewServiceName(`Culto ${new Date().toLocaleDateString('es-ES', { weekday: 'short', day: 'numeric', month: 'short' })}`);
              setShowNewServiceModal(true);
            }}
          >
            <Ionicons name="add-circle" size={16} color="#ffffff" style={{ marginRight: 4 }} />
            <Text style={styles.newServiceBtnText}>+ Nuevo Culto</Text>
          </TouchableOpacity>
        </ScrollView>
      </View>

      {/* 2. BARRA DE DETALLES DEL SERVICIO ACTIVO Y FONDO GENERAL */}
      {currentService && (
        <View style={[styles.serviceBar, isCompact && { paddingVertical: 8, paddingHorizontal: 10 }]}>
          <View style={{ flex: 1, marginRight: 8 }}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
              <Text style={styles.serviceTitleText} numberOfLines={1}>
                {currentService.name}
              </Text>
              <Text style={styles.serviceDateBadge}>{currentService.date}</Text>
            </View>
            <Text style={{ color: '#64748b', fontSize: 11, marginTop: 2 }}>
              {currentService.items.length === 0
                ? 'Sin elementos agregados aún'
                : `${currentService.items.length} momentos planificados en el culto`}
            </Text>
          </View>

          {/* Selector de Fondo Predeterminado del Culto */}
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
            <TouchableOpacity
              style={styles.bgThumbnailBtn}
              onPress={() => setBgTarget({ mode: 'service' })}
            >
              {currentService.defaultBackgroundUri ? (
                <Image
                  source={{ uri: currentService.defaultBackgroundUri }}
                  style={styles.bgThumbnailImage}
                />
              ) : (
                <View style={[styles.bgThumbnailImage, { backgroundColor: '#090d16', justifyContent: 'center', alignItems: 'center' }]}>
                  <Ionicons name="color-palette-outline" size={14} color="#64748b" />
                </View>
              )}
              <View style={{ marginLeft: 6 }}>
                <Text style={{ color: '#cbd5e1', fontSize: 10, fontWeight: 'bold' }}>Fondo Culto</Text>
                <Text style={{ color: '#38bdf8', fontSize: 9 }}>
                  {currentService.defaultBackgroundUri ? 'Asignado' : 'A Negro'}
                </Text>
              </View>
            </TouchableOpacity>

            {/* Eliminar Servicio */}
            {services.length > 1 && (
              <TouchableOpacity
                style={styles.deleteServiceBtn}
                onPress={() => {
                  Alert.alert('Eliminar Orden de Culto', `¿Deseas eliminar "${currentService.name}"?`, [
                    { text: 'Cancelar', style: 'cancel' },
                    { text: 'Eliminar', style: 'destructive', onPress: () => onDeleteService(currentService.id) },
                  ]);
                }}
              >
                <Ionicons name="trash-outline" size={16} color="#ef4444" />
              </TouchableOpacity>
            )}
          </View>
        </View>
      )}

      {/* 3. BOTONERA DE ACCIÓN: AÑADIR A ORDEN DE CULTO */}
      <View style={[styles.addButtonsBar, isCompact && { paddingHorizontal: 6, paddingVertical: 4, gap: 4 }]}>
        <TouchableOpacity
          style={[styles.addBtn, isCompact && { paddingHorizontal: 6, paddingVertical: 3, borderRadius: 5, gap: 2 }, { backgroundColor: '#3b82f620', borderColor: '#3b82f650' }]}
          onPress={() => setShowSongModal(true)}
        >
          <Ionicons name="musical-notes" size={isCompact ? 12 : 15} color="#3b82f6" />
          <Text style={[styles.addBtnText, isCompact && { fontSize: 10 }, { color: '#60a5fa' }]}>+ Canción</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.addBtn, isCompact && { paddingHorizontal: 6, paddingVertical: 3, borderRadius: 5, gap: 2 }, { backgroundColor: '#f59e0b20', borderColor: '#f59e0b50' }]}
          onPress={() => {
            setVerseModalTab(recentVerses.length > 0 ? 'recent' : 'manual');
            setShowVerseModal(true);
          }}
        >
          <Ionicons name="book" size={isCompact ? 12 : 15} color="#f59e0b" />
          <Text style={[styles.addBtnText, isCompact && { fontSize: 10 }, { color: '#fbbf24' }]}>+ Versículo</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.addBtn, isCompact && { paddingHorizontal: 6, paddingVertical: 3, borderRadius: 5, gap: 2 }, { backgroundColor: '#8b5cf620', borderColor: '#8b5cf650' }]}
          onPress={() => setShowMediaModal(true)}
        >
          <Ionicons name="images" size={isCompact ? 12 : 15} color="#a78bfa" />
          <Text style={[styles.addBtnText, isCompact && { fontSize: 10 }, { color: '#c4b5fd' }]}>+ Multimedia</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.addBtn, isCompact && { paddingHorizontal: 6, paddingVertical: 3, borderRadius: 5, gap: 2 }, { backgroundColor: '#10b98120', borderColor: '#10b98150' }]}
          onPress={() => setShowNoteModal(true)}
        >
          <Ionicons name="document-text" size={isCompact ? 12 : 15} color="#10b981" />
          <Text style={[styles.addBtnText, isCompact && { fontSize: 10 }, { color: '#34d399' }]}>+ Bloque</Text>
        </TouchableOpacity>
      </View>

      {/* 4. LISTA CRONOLÓGICA DE ORDEN DE CULTO */}
      {currentService && currentService.items.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Ionicons name="layers-outline" size={54} color="#334155" style={{ marginBottom: 12 }} />
          <Text style={styles.emptyTitle}>El orden de este culto está vacío</Text>
          <Text style={styles.emptySubtitle}>
            Usa los botones de arriba para planificar canciones, versículos bíblicos y momentos del servicio.
          </Text>
        </View>
      ) : (
        <ScrollView style={styles.itemsList} contentContainerStyle={{ paddingBottom: 60 }}>
          {currentService?.items.map((item, index) => {
            const isProjecting = activeServiceItemId === item.id;
            const bgUri = item.backgroundUri || currentService.defaultBackgroundUri;

            return (
              <TouchableOpacity
                key={item.id}
                activeOpacity={0.8}
                style={[
                  styles.serviceItemCard,
                  isProjecting && styles.serviceItemCardActive,
                  isCompact && { padding: 6, marginVertical: 2 },
                ]}
                onPress={() => onProjectItem(item)}
              >
                {/* 1. Número y orden */}
                <View style={styles.itemIndexCol}>
                  <View style={[styles.itemIndexCircle, isProjecting && { backgroundColor: '#3b82f6' }]}>
                    <Text style={[styles.itemIndexText, isProjecting && { color: '#ffffff' }]}>
                      {index + 1}
                    </Text>
                  </View>
                  {isProjecting && (
                    <View style={styles.liveBadge}>
                      <Text style={styles.liveBadgeText}>EN VIVO</Text>
                    </View>
                  )}
                </View>

                {/* 2. Ícono de tipo */}
                <View
                  style={[
                    styles.itemTypeIconWrap,
                    item.type === 'song' && { backgroundColor: '#3b82f625' },
                    item.type === 'verse' && { backgroundColor: '#f59e0b25' },
                    item.type === 'media' && { backgroundColor: '#8b5cf625' },
                    item.type === 'note' && { backgroundColor: '#10b98125' },
                  ]}
                >
                  <Ionicons
                    name={
                      item.type === 'song'
                        ? 'musical-notes'
                        : item.type === 'verse'
                        ? 'book'
                        : item.type === 'media'
                        ? 'images'
                        : 'document-text'
                    }
                    size={18}
                    color={
                      item.type === 'song'
                        ? '#60a5fa'
                        : item.type === 'verse'
                        ? '#fbbf24'
                        : item.type === 'media'
                        ? '#c4b5fd'
                        : '#34d399'
                    }
                  />
                </View>

                {/* 3. Contenido principal */}
                <View style={{ flex: 1, marginHorizontal: 8 }}>
                  <Text style={[styles.itemTitle, isProjecting && { color: '#60a5fa' }]} numberOfLines={1}>
                    {item.title}
                  </Text>
                  <Text style={styles.itemSubtitle} numberOfLines={1}>
                    {item.subtitle || item.content.replace(/\n/g, ' ')}
                  </Text>
                </View>

                {/* 4. Miniatura de fondo asignado */}
                <TouchableOpacity
                  style={styles.itemBgPreview}
                  onPress={(e) => {
                    e.stopPropagation();
                    setBgTarget({ mode: 'item', itemId: item.id });
                  }}
                >
                  {bgUri ? (
                    <Image source={{ uri: bgUri }} style={styles.itemBgImage} />
                  ) : (
                    <View style={[styles.itemBgImage, { backgroundColor: '#090d16', justifyContent: 'center', alignItems: 'center' }]}>
                      <Ionicons name="moon" size={10} color="#64748b" />
                    </View>
                  )}
                  <Text style={styles.itemBgLabel} numberOfLines={1}>
                    {item.backgroundUri ? 'Propio' : bgUri ? 'Culto' : 'Negro'}
                  </Text>
                </TouchableOpacity>

                {/* 5. Controles: Reordenar y Eliminar */}
                <View style={styles.itemControls}>
                  <TouchableOpacity
                    style={[styles.reorderBtn, index === 0 && { opacity: 0.3 }]}
                    disabled={index === 0}
                    onPress={(e) => {
                      e.stopPropagation();
                      onReorderItem(currentService.id, item.id, 'up');
                    }}
                  >
                    <Ionicons name="chevron-up" size={14} color="#94a3b8" />
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={[
                      styles.reorderBtn,
                      index === currentService.items.length - 1 && { opacity: 0.3 },
                    ]}
                    disabled={index === currentService.items.length - 1}
                    onPress={(e) => {
                      e.stopPropagation();
                      onReorderItem(currentService.id, item.id, 'down');
                    }}
                  >
                    <Ionicons name="chevron-down" size={14} color="#94a3b8" />
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={styles.removeBtn}
                    onPress={(e) => {
                      e.stopPropagation();
                      onRemoveItem(currentService.id, item.id);
                    }}
                  >
                    <Ionicons name="trash-outline" size={15} color="#ef4444" />
                  </TouchableOpacity>
                </View>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      )}

      {/* ========================================================= */}
      {/* MODAL: NUEVO SERVICIO                                     */}
      {/* ========================================================= */}
      <Modal visible={showNewServiceModal} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Crear Nuevo Orden de Culto</Text>
              <TouchableOpacity onPress={() => setShowNewServiceModal(false)}>
                <Ionicons name="close" size={22} color="#94a3b8" />
              </TouchableOpacity>
            </View>

            <Text style={styles.inputLabel}>Nombre del Culto / Reunión:</Text>
            <TextInput
              style={styles.textInput}
              placeholder="Ej. Culto Dominical Mañana"
              placeholderTextColor="#64748b"
              value={newServiceName}
              onChangeText={setNewServiceName}
            />

            <Text style={styles.inputLabel}>Fecha o Día:</Text>
            <TextInput
              style={styles.textInput}
              placeholder="Ej. Domingo 10:00 AM"
              placeholderTextColor="#64748b"
              value={newServiceDate}
              onChangeText={setNewServiceDate}
            />

            <View style={{ flexDirection: 'row', gap: 10, marginTop: 16 }}>
              <TouchableOpacity
                style={[styles.modalActionBtn, { backgroundColor: '#3b82f6', flex: 1 }]}
                onPress={handleCreateService}
              >
                <Text style={styles.modalActionBtnText}>Crear Servicio</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalActionBtn, { backgroundColor: '#334155' }]}
                onPress={() => setShowNewServiceModal(false)}
              >
                <Text style={{ color: '#cbd5e1', fontWeight: 'bold' }}>Cancelar</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* ========================================================= */}
      {/* MODAL: SELECCIONAR CANCIÓN                                 */}
      {/* ========================================================= */}
      <Modal visible={showSongModal} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { maxHeight: '80%', height: 500 }]}>
            <View style={styles.modalHeader}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                <Ionicons name="musical-notes" size={20} color="#3b82f6" />
                <Text style={styles.modalTitle}>Añadir Canción al Culto</Text>
              </View>
              <TouchableOpacity onPress={() => setShowSongModal(false)}>
                <Ionicons name="close" size={22} color="#94a3b8" />
              </TouchableOpacity>
            </View>

            <View style={styles.modalSearchBar}>
              <Ionicons name="search" size={16} color="#94a3b8" style={{ marginRight: 6 }} />
              <TextInput
                style={{ flex: 1, color: '#ffffff', fontSize: 14 }}
                placeholder="Buscar por título..."
                placeholderTextColor="#64748b"
                value={songSearch}
                onChangeText={setSongSearch}
              />
            </View>

            <ScrollView style={{ flex: 1, marginTop: 10 }}>
              {filteredSongs.map((song) => (
                <TouchableOpacity
                  key={song.id}
                  style={styles.modalListItem}
                  onPress={() => handleAddSong(song)}
                >
                  <View style={{ flex: 1 }}>
                    <Text style={{ color: '#ffffff', fontWeight: 'bold', fontSize: 14 }}>
                      {song.title}
                    </Text>
                    <Text style={{ color: '#94a3b8', fontSize: 11, marginTop: 2 }}>
                      {song.stanzas?.length || 0} estrofas disponibles
                    </Text>
                  </View>
                  <View style={styles.addMiniBadge}>
                    <Ionicons name="add" size={14} color="#38bdf8" />
                    <Text style={{ color: '#38bdf8', fontSize: 11, fontWeight: 'bold' }}>Añadir</Text>
                  </View>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>
        </View>
      </Modal>

      {/* ========================================================= */}
      {/* MODAL: SELECCIONAR VERSÍCULO (VISTOS RECIENTES O BUSCAR)  */}
      {/* ========================================================= */}
      <Modal visible={showVerseModal} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { maxHeight: '85%', height: 550 }]}>
            <View style={styles.modalHeader}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                <Ionicons name="book" size={20} color="#f59e0b" />
                <Text style={styles.modalTitle}>Añadir Versículo al Culto</Text>
              </View>
              <TouchableOpacity onPress={() => setShowVerseModal(false)}>
                <Ionicons name="close" size={22} color="#94a3b8" />
              </TouchableOpacity>
            </View>

            {/* Pestañas de Versículos */}
            <View style={styles.tabHeader}>
              <TouchableOpacity
                style={[styles.tabBtn, verseModalTab === 'recent' && styles.tabBtnActive]}
                onPress={() => setVerseModalTab('recent')}
              >
                <Text
                  style={[
                    styles.tabBtnText,
                    verseModalTab === 'recent' && styles.tabBtnTextActive,
                  ]}
                >
                  Vistos Recientes ({recentVerses.length})
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.tabBtn, verseModalTab === 'manual' && styles.tabBtnActive]}
                onPress={() => setVerseModalTab('manual')}
              >
                <Text
                  style={[
                    styles.tabBtnText,
                    verseModalTab === 'manual' && styles.tabBtnTextActive,
                  ]}
                >
                  Buscar en Biblia
                </Text>
              </TouchableOpacity>
            </View>

            {verseModalTab === 'recent' ? (
              <ScrollView style={{ flex: 1, marginTop: 10 }}>
                {recentVerses.length === 0 ? (
                  <View style={{ padding: 24, alignItems: 'center' }}>
                    <Ionicons name="time-outline" size={36} color="#475569" style={{ marginBottom: 8 }} />
                    <Text style={{ color: '#94a3b8', textAlign: 'center', fontSize: 13 }}>
                      Aún no has explorado versículos en la Biblia. Ve a la pestaña Biblia y toca versículos para verlos aquí al instante.
                    </Text>
                  </View>
                ) : (
                  recentVerses.map((item, idx) => (
                    <TouchableOpacity
                      key={`${item.ref}-${idx}`}
                      style={styles.modalListItem}
                      onPress={() => handleAddRecentVerse(item)}
                    >
                      <View style={{ flex: 1, marginRight: 8 }}>
                        <Text style={{ color: '#fbbf24', fontWeight: 'bold', fontSize: 13 }}>
                          {item.ref}
                        </Text>
                        <Text style={{ color: '#cbd5e1', fontSize: 12, marginTop: 2 }} numberOfLines={2}>
                          {item.text}
                        </Text>
                      </View>
                      <View style={[styles.addMiniBadge, { borderColor: '#f59e0b50', backgroundColor: '#f59e0b20' }]}>
                        <Ionicons name="add" size={14} color="#fbbf24" />
                        <Text style={{ color: '#fbbf24', fontSize: 11, fontWeight: 'bold' }}>Añadir</Text>
                      </View>
                    </TouchableOpacity>
                  ))
                )}
              </ScrollView>
            ) : (
              <ScrollView style={{ flex: 1, marginTop: 10 }}>
                <Text style={styles.inputLabel}>1. Selecciona Libro:</Text>
                <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 12 }}>
                  {loadedBibles[0]?.data.map((b: any) => (
                    <TouchableOpacity
                      key={b.name}
                      style={[
                        styles.selectorPill,
                        selectedBook === b.name && styles.selectorPillActive,
                      ]}
                      onPress={() => {
                        setSelectedBook(b.name);
                        setSelectedChapter(1);
                        setSelectedVerseNum(1);
                      }}
                    >
                      <Text
                        style={[
                          styles.selectorPillText,
                          selectedBook === b.name && { color: '#ffffff', fontWeight: 'bold' },
                        ]}
                      >
                        {b.name}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>

                <Text style={styles.inputLabel}>2. Capítulo {selectedChapter}:</Text>
                <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 12 }}>
                  {Array.from(
                    {
                      length:
                        loadedBibles[0]?.data.find((b: any) => b.name === selectedBook)?.chapters?.length || 1,
                    },
                    (_, i) => i + 1
                  ).map((ch) => (
                    <TouchableOpacity
                      key={ch}
                      style={[
                        styles.numberPill,
                        selectedChapter === ch && styles.numberPillActive,
                      ]}
                      onPress={() => {
                        setSelectedChapter(ch);
                        setSelectedVerseNum(1);
                      }}
                    >
                      <Text style={{ color: selectedChapter === ch ? '#fff' : '#94a3b8', fontWeight: 'bold' }}>
                        {ch}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>

                <Text style={styles.inputLabel}>3. Versículo {selectedVerseNum}:</Text>
                <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 16 }}>
                  {Array.from(
                    {
                      length:
                        loadedBibles[0]?.data.find((b: any) => b.name === selectedBook)?.chapters?.[
                          selectedChapter - 1
                        ]?.length || 1,
                    },
                    (_, i) => i + 1
                  ).map((v) => (
                    <TouchableOpacity
                      key={v}
                      style={[
                        styles.numberPill,
                        selectedVerseNum === v && styles.numberPillActive,
                      ]}
                      onPress={() => setSelectedVerseNum(v)}
                    >
                      <Text style={{ color: selectedVerseNum === v ? '#fff' : '#94a3b8', fontWeight: 'bold' }}>
                        {v}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>

                <TouchableOpacity
                  style={[styles.modalActionBtn, { backgroundColor: '#f59e0b' }]}
                  onPress={handleAddManualVerse}
                >
                  <Text style={styles.modalActionBtnText}>
                    Añadir {selectedBook} {selectedChapter}:{selectedVerseNum}
                  </Text>
                </TouchableOpacity>
              </ScrollView>
            )}
          </View>
        </View>
      </Modal>

      {/* ========================================================= */}
      {/* MODAL: SELECCIONAR MULTIMEDIA                             */}
      {/* ========================================================= */}
      <Modal visible={showMediaModal} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { maxHeight: '80%', height: 480 }]}>
            <View style={styles.modalHeader}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                <Ionicons name="images" size={20} color="#8b5cf6" />
                <Text style={styles.modalTitle}>Añadir Fondo o Video al Culto</Text>
              </View>
              <TouchableOpacity onPress={() => setShowMediaModal(false)}>
                <Ionicons name="close" size={22} color="#94a3b8" />
              </TouchableOpacity>
            </View>

            <ScrollView style={{ flex: 1, marginTop: 10 }}>
              <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 10, justifyContent: 'center' }}>
                {customBackgrounds.map((bg) => (
                  <TouchableOpacity
                    key={bg.id}
                    style={styles.mediaGridItem}
                    onPress={() => handleAddMedia(bg)}
                  >
                    <Image source={{ uri: bg.thumbnail }} style={{ width: '100%', height: 90, borderRadius: 6 }} />
                    <Text style={styles.mediaGridTitle} numberOfLines={1}>
                      {bg.name}
                    </Text>
                    <View style={styles.mediaTypeBadge}>
                      <Text style={{ color: '#fff', fontSize: 8, fontWeight: 'bold' }}>
                        {bg.type === 'video' ? 'VIDEO' : 'IMAGEN'}
                      </Text>
                    </View>
                  </TouchableOpacity>
                ))}
              </View>
            </ScrollView>
          </View>
        </View>
      </Modal>

      {/* ========================================================= */}
      {/* MODAL: AÑADIR BLOQUE / NOTA DEL CULTO                     */}
      {/* ========================================================= */}
      <Modal visible={showNoteModal} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { maxHeight: '85%', height: 520 }]}>
            <View style={styles.modalHeader}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                <Ionicons name="document-text" size={20} color="#10b981" />
                <Text style={styles.modalTitle}>Añadir Bloque de Servicio</Text>
              </View>
              <TouchableOpacity onPress={() => setShowNoteModal(false)}>
                <Ionicons name="close" size={22} color="#94a3b8" />
              </TouchableOpacity>
            </View>

            <Text style={styles.inputLabel}>Plantillas Rápidas:</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 12 }}>
              {presetNotes.map((p, idx) => (
                <TouchableOpacity
                  key={idx}
                  style={styles.presetPill}
                  onPress={() => {
                    setNoteTitle(p.title);
                    setNoteContent(p.content);
                  }}
                >
                  <Text style={{ color: '#34d399', fontSize: 11, fontWeight: 'bold' }}>{p.title}</Text>
                </TouchableOpacity>
              ))}
            </ScrollView>

            <Text style={styles.inputLabel}>Título del Bloque:</Text>
            <TextInput
              style={styles.textInput}
              placeholder="Ej. Anuncios y Avisos"
              placeholderTextColor="#64748b"
              value={noteTitle}
              onChangeText={setNoteTitle}
            />

            <Text style={styles.inputLabel}>Texto a Proyectar (Opcional):</Text>
            <TextInput
              style={[styles.textInput, { height: 90, textAlignVertical: 'top' }]}
              placeholder="Texto o mensaje que aparecerá en pantalla..."
              placeholderTextColor="#64748b"
              value={noteContent}
              onChangeText={setNoteContent}
              multiline
            />

            <View style={{ flexDirection: 'row', gap: 10, marginTop: 14 }}>
              <TouchableOpacity
                style={[styles.modalActionBtn, { backgroundColor: '#10b981', flex: 1 }]}
                onPress={handleAddNote}
              >
                <Text style={styles.modalActionBtnText}>Añadir al Culto</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalActionBtn, { backgroundColor: '#334155' }]}
                onPress={() => setShowNoteModal(false)}
              >
                <Text style={{ color: '#cbd5e1', fontWeight: 'bold' }}>Cancelar</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* ========================================================= */}
      {/* MODAL: CAMBIAR FONDO (DEL CULTO O DE UN ELEMENTO)         */}
      {/* ========================================================= */}
      <Modal visible={bgTarget !== null} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { maxHeight: '80%', height: 480 }]}>
            <View style={styles.modalHeader}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                <Ionicons name="color-palette" size={20} color="#38bdf8" />
                <Text style={styles.modalTitle}>
                  {bgTarget?.mode === 'service'
                    ? 'Fondo General del Culto'
                    : 'Fondo de este Elemento'}
                </Text>
              </View>
              <TouchableOpacity onPress={() => setBgTarget(null)}>
                <Ionicons name="close" size={22} color="#94a3b8" />
              </TouchableOpacity>
            </View>

            {/* Opción Fondo Negro */}
            <TouchableOpacity
              style={[styles.modalListItem, { borderColor: '#ef444450', backgroundColor: '#ef444415', marginBottom: 12 }]}
              onPress={() => {
                if (bgTarget?.mode === 'service' && currentService) {
                  onUpdateServiceBackground(currentService.id, null);
                } else if (bgTarget?.mode === 'item' && currentService && bgTarget.itemId) {
                  onUpdateItemBackground(currentService.id, bgTarget.itemId, null);
                }
                setBgTarget(null);
              }}
            >
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                <Ionicons name="moon" size={18} color="#ef4444" />
                <Text style={{ color: '#ef4444', fontWeight: 'bold' }}>Sin Fondo (Fondo a Negro)</Text>
              </View>
              <Ionicons name="checkmark" size={18} color="#ef4444" />
            </TouchableOpacity>

            <ScrollView style={{ flex: 1 }}>
              <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 10, justifyContent: 'center' }}>
                {customBackgrounds.map((bg) => (
                  <TouchableOpacity
                    key={bg.id}
                    style={styles.mediaGridItem}
                    onPress={() => {
                      const newBg = { uri: bg.uri, type: bg.type as 'image' | 'video' };
                      if (bgTarget?.mode === 'service' && currentService) {
                        onUpdateServiceBackground(currentService.id, newBg);
                      } else if (bgTarget?.mode === 'item' && currentService && bgTarget.itemId) {
                        onUpdateItemBackground(currentService.id, bgTarget.itemId, newBg);
                      }
                      setBgTarget(null);
                    }}
                  >
                    <Image source={{ uri: bg.thumbnail }} style={{ width: '100%', height: 80, borderRadius: 6 }} />
                    <Text style={styles.mediaGridTitle} numberOfLines={1}>
                      {bg.name}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </ScrollView>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#090d16',
    flexDirection: 'column',
  },
  servicesHeader: {
    paddingVertical: 10,
    paddingHorizontal: 10,
    backgroundColor: '#0f172a',
    borderBottomWidth: 1,
    borderBottomColor: '#1e293b',
  },
  servicePill: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 7,
    backgroundColor: '#1e293b',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#334155',
  },
  servicePillActive: {
    backgroundColor: '#1e40af',
    borderColor: '#3b82f6',
  },
  servicePillText: {
    color: '#94a3b8',
    fontSize: 12,
    fontWeight: 'bold',
  },
  servicePillTextActive: {
    color: '#ffffff',
  },
  newServiceBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 7,
    backgroundColor: '#10b981',
    borderRadius: 8,
  },
  newServiceBtnText: {
    color: '#ffffff',
    fontSize: 12,
    fontWeight: 'bold',
  },
  serviceBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 10,
    backgroundColor: '#0b1120',
    borderBottomWidth: 1,
    borderBottomColor: '#1e293b',
  },
  serviceTitleText: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: 'bold',
  },
  serviceDateBadge: {
    color: '#60a5fa',
    backgroundColor: '#1e3a8a40',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    fontSize: 10,
    fontWeight: 'bold',
  },
  bgThumbnailBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1e293b',
    padding: 4,
    paddingRight: 8,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#334155',
  },
  bgThumbnailImage: {
    width: 28,
    height: 28,
    borderRadius: 4,
  },
  deleteServiceBtn: {
    padding: 7,
    backgroundColor: '#ef444420',
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#ef444440',
  },
  addButtonsBar: {
    flexDirection: 'row',
    paddingHorizontal: 10,
    paddingVertical: 8,
    backgroundColor: '#0f172a',
    gap: 6,
    flexWrap: 'wrap',
    borderBottomWidth: 1,
    borderBottomColor: '#1e293b',
  },
  addBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
    borderWidth: 1,
  },
  addBtnText: {
    fontSize: 11,
    fontWeight: 'bold',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 30,
  },
  emptyTitle: {
    color: '#cbd5e1',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 6,
    textAlign: 'center',
  },
  emptySubtitle: {
    color: '#64748b',
    fontSize: 12,
    textAlign: 'center',
    lineHeight: 18,
    maxWidth: 320,
  },
  itemsList: {
    flex: 1,
    padding: 10,
  },
  serviceItemCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#0f172a',
    borderRadius: 8,
    padding: 12,
    marginVertical: 4,
    borderWidth: 1,
    borderColor: '#1e293b',
  },
  serviceItemCardActive: {
    borderColor: '#3b82f6',
    backgroundColor: '#1e293b',
    shadowColor: '#3b82f6',
    shadowOpacity: 0.3,
    shadowRadius: 8,
  },
  itemIndexCol: {
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 6,
  },
  itemIndexCircle: {
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: '#1e293b',
    justifyContent: 'center',
    alignItems: 'center',
  },
  itemIndexText: {
    color: '#94a3b8',
    fontSize: 10,
    fontWeight: 'bold',
  },
  liveBadge: {
    marginTop: 2,
    backgroundColor: '#ef4444',
    paddingHorizontal: 3,
    paddingVertical: 1,
    borderRadius: 3,
  },
  liveBadgeText: {
    color: '#ffffff',
    fontSize: 7,
    fontWeight: 'bold',
  },
  itemTypeIconWrap: {
    width: 32,
    height: 32,
    borderRadius: 6,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 4,
  },
  itemTitle: {
    color: '#f8fafc',
    fontSize: 13,
    fontWeight: 'bold',
  },
  itemSubtitle: {
    color: '#94a3b8',
    fontSize: 11,
    marginTop: 2,
  },
  itemBgPreview: {
    alignItems: 'center',
    marginRight: 6,
  },
  itemBgImage: {
    width: 26,
    height: 26,
    borderRadius: 4,
  },
  itemBgLabel: {
    color: '#64748b',
    fontSize: 8,
    marginTop: 2,
  },
  itemControls: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  reorderBtn: {
    padding: 4,
    backgroundColor: '#1e293b',
    borderRadius: 4,
  },
  removeBtn: {
    padding: 5,
    backgroundColor: '#ef444415',
    borderRadius: 4,
    marginLeft: 2,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.75)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  modalContent: {
    width: '100%',
    maxWidth: 480,
    backgroundColor: '#0f172a',
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: '#334155',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#1e293b',
    paddingBottom: 10,
  },
  modalTitle: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: 'bold',
  },
  inputLabel: {
    color: '#cbd5e1',
    fontSize: 12,
    fontWeight: 'bold',
    marginBottom: 6,
    marginTop: 8,
  },
  textInput: {
    backgroundColor: '#1e293b',
    color: '#ffffff',
    padding: 10,
    borderRadius: 8,
    fontSize: 13,
    borderWidth: 1,
    borderColor: '#334155',
  },
  modalActionBtn: {
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalActionBtnText: {
    color: '#ffffff',
    fontSize: 13,
    fontWeight: 'bold',
  },
  modalSearchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1e293b',
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#334155',
  },
  modalListItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 10,
    backgroundColor: '#1e293b',
    borderRadius: 8,
    marginVertical: 4,
    borderWidth: 1,
    borderColor: '#334155',
  },
  addMiniBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    backgroundColor: '#3b82f620',
    borderWidth: 1,
    borderColor: '#3b82f650',
    gap: 3,
  },
  tabHeader: {
    flexDirection: 'row',
    backgroundColor: '#1e293b',
    borderRadius: 8,
    padding: 3,
    marginBottom: 8,
  },
  tabBtn: {
    flex: 1,
    paddingVertical: 8,
    alignItems: 'center',
    borderRadius: 6,
  },
  tabBtnActive: {
    backgroundColor: '#3b82f6',
  },
  tabBtnText: {
    color: '#94a3b8',
    fontSize: 12,
    fontWeight: 'bold',
  },
  tabBtnTextActive: {
    color: '#ffffff',
  },
  selectorPill: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: '#1e293b',
    borderRadius: 6,
    marginRight: 6,
    borderWidth: 1,
    borderColor: '#334155',
  },
  selectorPillActive: {
    backgroundColor: '#f59e0b',
    borderColor: '#f59e0b',
  },
  selectorPillText: {
    color: '#94a3b8',
    fontSize: 11,
  },
  numberPill: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: '#1e293b',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 6,
    borderWidth: 1,
    borderColor: '#334155',
  },
  numberPillActive: {
    backgroundColor: '#f59e0b',
    borderColor: '#f59e0b',
  },
  mediaGridItem: {
    width: 105,
    backgroundColor: '#1e293b',
    borderRadius: 8,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#334155',
    padding: 4,
  },
  mediaGridTitle: {
    color: '#cbd5e1',
    fontSize: 10,
    fontWeight: 'bold',
    textAlign: 'center',
    marginTop: 4,
  },
  mediaTypeBadge: {
    position: 'absolute',
    top: 6,
    left: 6,
    backgroundColor: 'rgba(0,0,0,0.7)',
    paddingHorizontal: 4,
    paddingVertical: 1,
    borderRadius: 3,
  },
  presetPill: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: '#10b98120',
    borderRadius: 6,
    marginRight: 6,
    borderWidth: 1,
    borderColor: '#10b98140',
  },
});
