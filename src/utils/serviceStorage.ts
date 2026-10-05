import { Platform } from 'react-native';
import * as FileSystemLegacy from 'expo-file-system/legacy';

export interface ServiceItem {
  id: string;
  type: 'song' | 'verse' | 'media' | 'note';
  title: string;
  subtitle?: string;
  content: string; // The primary content to project
  backgroundUri?: string | null;
  backgroundType?: 'image' | 'video' | null;
  songId?: string;
  stanzas?: { name: string; text: string }[];
  verseRef?: string;
}

export interface ServiceOrder {
  id: string;
  name: string;
  date: string;
  defaultBackgroundUri?: string | null;
  defaultBackgroundType?: 'image' | 'video' | null;
  items: ServiceItem[];
}

const STORAGE_KEY = 'dtb_service_orders_v1';
const FILE_PATH = (FileSystemLegacy.documentDirectory || '') + 'dtb_service_orders_v1.json';

export const defaultServices: ServiceOrder[] = [
  {
    id: 'srv-default-1',
    name: 'Culto Dominical General',
    date: 'Domingo',
    defaultBackgroundUri: 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=300&q=80',
    defaultBackgroundType: 'video',
    items: [
      {
        id: 'item-1',
        type: 'note',
        title: 'Bienvenida y Oración',
        subtitle: 'Apertura de la reunión',
        content: 'BIENVENIDOS\nA LA CASA DE DIOS',
      },
      {
        id: 'item-2',
        type: 'song',
        title: 'Cuan Grande Es Él',
        subtitle: '3 estrofas',
        songId: 's1',
        content: 'Señor mi Dios\nAl contemplar los cielos\nEl firmamento y las estrellas mil',
        stanzas: [
          { name: 'Estrofa 1', text: 'Señor mi Dios\nAl contemplar los cielos\nEl firmamento y las estrellas mil' },
          { name: 'Coro', text: 'Mi corazón entona la canción\nCuan grande es Él\nCuan grande es Él' },
          { name: 'Estrofa 2', text: 'Al recorrer los montes y los valles\nY ver las bellas flores al pasar' }
        ],
        backgroundUri: 'https://vjs.zencdn.net/v/oceans.mp4',
        backgroundType: 'video',
      },
      {
        id: 'item-3',
        type: 'verse',
        title: 'Salmos 23:1',
        subtitle: 'Lectura Bíblica Congregacional',
        verseRef: 'Salmos 23:1',
        content: 'Salmos 23:1\nJehová es mi pastor; nada me faltará.',
      },
      {
        id: 'item-4',
        type: 'song',
        title: 'Way Maker',
        subtitle: '3 estrofas',
        songId: 's2',
        content: 'Aquí estás\nTe vemos mover\nTe adoraré\nTe adoraré',
        stanzas: [
          { name: 'Estrofa 1', text: 'Aquí estás\nTe vemos mover\nTe adoraré\nTe adoraré' },
          { name: 'Coro', text: 'Milagroso, abres camino\nCumples promesas\nLuz en tinieblas\nMi Dios, así eres Tú' },
          { name: 'Puente', text: 'Aunque no pueda ver, estás obrando\nAunque no pueda ver, estás obrando\nSiempre estás, siempre estás obrando' }
        ],
        backgroundUri: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=1920&auto=format&fit=crop',
        backgroundType: 'image',
      },
      {
        id: 'item-5',
        type: 'note',
        title: 'Mensaje de la Palabra',
        subtitle: 'Predicación pastoral',
        content: 'TIEMPO DE LA PALABRA\nPredicación',
      }
    ]
  }
];

export async function loadSavedServices(): Promise<ServiceOrder[]> {
  try {
    if (Platform.OS === 'web') {
      if (typeof window !== 'undefined' && window.localStorage) {
        const data = window.localStorage.getItem(STORAGE_KEY);
        if (data) {
          const parsed = JSON.parse(data);
          if (Array.isArray(parsed) && parsed.length > 0) return parsed;
        }
      }
    } else {
      const fileInfo = await FileSystemLegacy.getInfoAsync(FILE_PATH);
      if (fileInfo.exists) {
        const fileContent = await FileSystemLegacy.readAsStringAsync(FILE_PATH);
        if (fileContent) {
          const parsed = JSON.parse(fileContent);
          if (Array.isArray(parsed) && parsed.length > 0) return parsed;
        }
      }
    }
  } catch (error) {
    console.warn('loadSavedServices error:', error);
  }
  return defaultServices;
}

export async function saveServicesToDisk(services: ServiceOrder[]): Promise<void> {
  try {
    const jsonStr = JSON.stringify(services);
    if (Platform.OS === 'web') {
      if (typeof window !== 'undefined' && window.localStorage) {
        window.localStorage.setItem(STORAGE_KEY, jsonStr);
      }
    } else {
      await FileSystemLegacy.writeAsStringAsync(FILE_PATH, jsonStr);
    }
  } catch (error) {
    console.warn('saveServicesToDisk error:', error);
  }
}
