# Registro de Modificaciones - VisualDTB

Este documento detalla todas las modificaciones y mejoras implementadas en la aplicación para mantener un contexto claro del desarrollo.

## 1. Adaptación a Pantallas Pequeñas y Responsividad
- Se implementó `useWindowDimensions` para detectar el tamaño de la pantalla.
- Se mantuvieron los iPad en modo horizontal (Landscape) como el objetivo principal de diseño, pero se aseguró que la aplicación colapse ordenadamente en dispositivos más pequeños (como móviles).
- Se cambiaron múltiples `<View>` estáticos por `<ScrollView>` en módulos clave (Mensajes, Temporizador, Web, Configuración) para que todos los botones y opciones sigan siendo accesibles deslizando hacia abajo.

## 2. Mejoras en el Módulo de Biblias
- Inicialmente solo se mostraba el libro de Mateo. Se implementó la capacidad de leer archivos `.json` dinámicamente.
- Se integró `expo-document-picker` y `expo-file-system` para permitir al usuario **subir sus propias versiones de biblias en formato JSON**.

## 3. Optimizaciones en el Módulo de Canciones
- Se redujo drásticamente el tamaño del botón "+ Agregar Canción" y se integró visualmente dentro de la barra de búsqueda como un botón verde ("+ Nueva"), ahorrando espacio vertical valioso.
- Se solucionó el problema en el formulario de creación de nuevas canciones (que no permitía ver los botones de guardar al abrir el teclado) envolviéndolo en un `ScrollView` y dándole una altura mínima adaptativa.

## 4. Gestión del Módulo de Medios y Errores Corregidos
- Se agregó el botón **"Fondo a Negro"** para limpiar instantáneamente el proyector sin necesidad de buscar una imagen negra.
- Se incorporó un botón de tres puntos (menú) sobre cada miniatura de imagen/video que despliega la opción de **Eliminar** ese medio de la galería.
- **Corrección en Android:** Se resolvió el error `net::ERR_ACCESS_DENIED` al intentar cargar PDFs locales y videos ajustando los permisos del componente `<WebView>` (`allowFileAccessFromFileURLs`, `allowUniversalAccessFromFileURLs` y configurando `baseUrl`).

## 5. Soporte para Pantallas Externas (AirPlay y HDMI)
- Se integró la librería nativa `react-native-external-display` para manejar el control de doble pantalla.
- **Funcionamiento Dual:** Ahora el iPad retiene todos los controles de la aplicación, mientras que la pantalla secundaria (vía HDMI o AirPlay) proyecta únicamente el contenido en pantalla completa.
- Se añadió un control (switch) en la pestaña **"Configuración"** para activar o desactivar la proyección en la TV externa.
- **Fallback para Expo Go:** Dado que Expo Go estándar no soporta librerías nativas de doble pantalla, se implementó un mecanismo de protección dinámico (try/catch) al importar el módulo. Esto previene que la app colapse al correrse en Expo Go, aunque para que funcione la pantalla externa se requiere compilar un *EAS Build* o ejecutar localmente con `npx expo run:ios`.

---
*Última actualización: Septiembre 2026*
