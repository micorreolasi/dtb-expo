# VisualDTB — Versión Nativa Swift / SwiftUI (iOS & iPadOS)

Esta es la migración 100% nativa en **Swift y SwiftUI** del proyecto `visualdtb-expo`, manteniendo con exactitud **todas las funcionalidades, diseño visual, paleta de colores, comportamientos y flujos de trabajo**.

---

## 📱 Módulos y Funcionalidades Migradas 1:1

### 1. Orden de Culto (`ServiceOrderView.swift`)
- **Gestión de Cultos:** Selector horizontal con selector de cultos creados y botón **"+ Nuevo Culto"** (con asignación de nombre y fecha).
- **Fondo Global y Fondo por Elemento:** Selector modal para asignar fondo general del culto o fondo personalizado por elemento (con soporte para fondos animados en video, fondos en imagen fija o opción **"Fondo a Negro"**).
- **Adición de Momentos:**
  - **+ Canción:** Selector con buscador en tiempo real.
  - **+ Versículo:** Pestañas de **Vistos Recientes** y explorador manual por libro, capítulo y versículo.
  - **+ Multimedia:** Galería de fondos e imágenes.
  - **+ Bloque:** Plantillas predefinidas (Bienvenida, Alabanza, Ofrendas, Mensaje pastoral, etc.) con texto proyectable opcional.
- **Control en Vivo:** Reordenamiento con flechas arriba/abajo, eliminación, indicador **"EN VIVO"** y proyección directa.
- **Persistencia en Disco:** Guarda y carga automáticamente en `dtb_service_orders_v1.json` con exactamente la misma estructura de datos JSON.

### 2. Biblia (`BibleView.swift`)
- **Libros y Capítulos:** Despliegue interactivo de libros con cuadrícula táctil de números de capítulo.
- **Versículos y Culto Rápido:** Lista de versículos con su número, botón directo **"+ Culto"** para planificar al instante en el culto activo, y tap para proyectar con playlist automática de todo el capítulo.
- **Cargador de Biblias JSON:** Botón **"+ Añadir JSON"** con selector nativo de archivos (`.json`) para cargar cualquier versión bíblica de forma dinámica.

### 3. Canciones (`SongsView.swift`)
- **Lista y Desglose:** Búsqueda en tiempo real por título, botón **"+ Nueva"**, botón **"Culto"**, desglose de estrofas y edición/eliminación para canciones personalizadas.
- **Editor Completo:** Título y letra multilínea (los dobles saltos de línea generan estrofas automáticamente).
- **Proyección de Estrofas:** Navegación diapositiva por diapositiva con resaltado activo.

### 4. Medios y Fondos (`MediaView.swift`)
- **Galería de Fondos:** Miniaturas de imágenes y videos animados en bucle.
- **Fondo a Negro:** Botón de un toque para limpiar la pantalla a negro.
- **Subida Nativa:** Integración con `PhotosPicker` para importar fotos y videos desde la fototeca del dispositivo.
- **Proyección Directa con Sonido:** Opción de proyectar el video o imagen directamente a pantalla completa (con audio habilitado para videos/alabanzas).

### 5. Documentos (`DocumentsView.swift`)
- **Soporte iPad Nativo:** Carga y proyección de archivos PDF, PPTX y Word mediante `PDFKit` y `WKWebView`.
- **Modo Presentación:** Botón directo para proyectar el documento en pantalla completa.

### 6. Mensajes / Cintillo (`MessagesView.swift`)
- **Anuncios Animados:** Entrada de texto multilínea con animación horizontal continua tipo *marquee*.
- **Velocidades:** Muy Lento (26s), Lento (16s), Normal (9s), Rápido (5s).
- **Repeticiones:** Presets de 1, 3, 5 o infinito (`∞`), con botón de parada de emergencia.

### 7. Cuenta Regresiva / Timer (`TimerView.swift`)
- Visualización de números grandes (`MM:SS`).
- Botones de **Iniciar Timer**, **Pausar** y **Reset**.
- Sincronización automática de `⏳ MM:SS` en la proyección y mensaje de "Tiempo Finalizado".

### 8. Navegador Web (`WebViewModule.swift`)
- Barra de direcciones con botón de proyección.
- Vista interactiva de `WKWebView` integrada con navegación sincronizada.

### 9. Pantalla Externa y AirPlay / HDMI (`ExternalDisplayManager.swift`)
- Detección automática de monitores externos, proyectores o Apple TV conectados por cable HDMI, USB-C o inalámbrico por AirPlay.
- Crea un `UIWindow` independiente a pantalla completa sobre la pantalla secundaria, proyectando el contenido sin controles, mientras el iPad/iPhone conserva todos los paneles y controles de mando.
- Control (switch) en Ajustes para activar o desactivar la salida externa.

### 10. Motor de Ajuste Tipográfico Automático (`FontFitting.swift`)
- Algoritmo matemático idéntico que calcula el tamaño óptimo de fuente (`fontSize`, `lineHeight`, márgenes) según las dimensiones de la pantalla.
- Detección por expresión regular de referencias bíblicas en la primera línea.
- Garantiza cero desbordamientos (*no text overflow*) en teléfonos móviles, iPads y televisores 4K.

### 11. Barra de Herramientas Inferior (`BottomToolbarView.swift`)
- Botón **Limpiar** (resetea el texto proyectado).
- Botón **Pausa** (pausa videos y animaciones).
- Botón **Blackout** (apaga la proyección instantáneamente a negro).
- Botón **Expandir** (pantalla completa).
- Controles de Diapositiva (flechas arriba/abajo si hay playlist activa).
- Control deslizante de **Brillo** (10% a 100%).
- Paleta de colores de letra (Blanco, Negro, Amarillo, Celeste, Verde, Naranja, Rosa).
- Interruptor de **Fondo de Letra** (caja negra detrás del texto).

---

## 🗂️ Estructura del Proyecto

```
VisualDTB/
├── Package.swift                          # Manifiesto de Swift Package Manager
├── README.md
└── VisualDTB/
    ├── VisualDTBApp.swift                 # Punto de entrada @main de la aplicación
    ├── Models/
    │   ├── Models.swift                   # Modelos de datos (Codable, Identifiable)
    │   └── DefaultData.swift              # Canciones, fondos y cultos iniciales
    ├── Services/
    │   ├── AppState.swift                 # Estado reactivo central (ObservableObject)
    │   ├── Storage.swift                  # Persistencia en disco de cultos y archivos
    │   └── ExternalDisplayManager.swift   # Soporte nativo de doble pantalla (AirPlay/HDMI)
    ├── Utils/
    │   ├── Theme.swift                    # Paleta de colores hex, tipografías y helpers
    │   └── FontFitting.swift              # Motor auto-fit de texto para pantallas
    ├── Views/
    │   ├── MainContentView.swift         # Vista principal (Sidebar + Módulo + Mini-TV + Toolbar)
    │   ├── Components/
    │   │   ├── SidebarView.swift          # Barra lateral responsiva
    │   │   ├── BottomToolbarView.swift    # Barra inferior con controles y sliders
    │   │   ├── ProjectionView.swift       # Lienzo de proyección (TV, Mini-Preview y Fullscreen)
    │   │   ├── DynamicProjectionTextView.swift # Texto con ajuste dinámico
    │   │   ├── SafeVideoPlayerView.swift  # Reproductor AVPlayer nativo
    │   │   ├── WebViewRepresentable.swift # Visor WebKit nativo
    │   │   ├── PDFDocumentView.swift      # Visor PDFKit / Office
    │   │   ├── MarqueeBannerView.swift    # Cintillo animado horizontal
    │   │   └── PresentationModeView.swift # Modo presentación con controles flotantes
    │   └── Modules/
    │       ├── ServiceOrderView.swift     # Módulo Orden de Culto
    │       ├── BibleView.swift            # Módulo Biblia
    │       ├── SongsView.swift            # Módulo Canciones
    │       ├── MediaView.swift            # Módulo Multimedia
    │       ├── DocumentsView.swift        # Módulo Documentos
    │       ├── MessagesView.swift         # Módulo Mensajes
    │       ├── TimerView.swift            # Módulo Cuenta Regresiva
    │       ├── WebViewModule.swift        # Módulo Navegador Web
    │       └── SettingsView.swift         # Módulo Ajustes
    └── Resources/
        ├── Info.plist                     # Permisos y configuración de iOS
        ├── bible.json                     # Biblia completa RV1960 en JSON
        └── Assets/                        # Iconos y fondos
```

---

## 🚀 Cómo abrir y compilar en Xcode

1. Abre **Xcode** en tu Mac.
2. Selecciona **File > Open...** y elige la carpeta `VisualDTB` (o arrastra `Package.swift` a Xcode).
3. Selecciona tu dispositivo de destino (iPad, iPhone o simulador) y presiona **Cmd + R** para compilar y ejecutar.
