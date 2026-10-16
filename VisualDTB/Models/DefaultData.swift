import Foundation

enum DefaultData {

    static let backgrounds: [MediaBackground] = [
        MediaBackground(
            id: "bg1", type: .video,
            thumbnail: "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=300&q=80",
            uri: "https://vjs.zencdn.net/v/oceans.mp4",
            name: "Océano (Video)"
        ),
        MediaBackground(
            id: "bg2", type: .video,
            thumbnail: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=300&q=80",
            uri: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4",
            name: "Naturaleza (Video)"
        ),
        MediaBackground(
            id: "bg3", type: .image,
            thumbnail: "https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=300&q=80",
            uri: "https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=1920&auto=format&fit=crop",
            name: "Abstracto (Imagen)"
        ),
        MediaBackground(
            id: "bg4", type: .image,
            thumbnail: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=300&q=80",
            uri: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1920&auto=format&fit=crop",
            name: "Montañas (Imagen)"
        ),
    ]

    static let songs: [Song] = [
        Song(id: "s1", title: "Cuan Grande Es Él", stanzas: [
            Stanza(name: "Estrofa 1", text: "Señor mi Dios\nAl contemplar los cielos\nEl firmamento y las estrellas mil"),
            Stanza(name: "Coro", text: "Mi corazón entona la canción\nCuan grande es Él\nCuan grande es Él"),
            Stanza(name: "Estrofa 2", text: "Al recorrer los montes y los valles\nY ver las bellas flores al pasar"),
        ]),
        Song(id: "s2", title: "Way Maker", stanzas: [
            Stanza(name: "Estrofa 1", text: "Aquí estás\nTe vemos mover\nTe adoraré\nTe adoraré"),
            Stanza(name: "Coro", text: "Milagroso, abres camino\nCumples promesas\nLuz en tinieblas\nMi Dios, así eres Tú"),
            Stanza(name: "Puente", text: "Aunque no pueda ver, estás obrando\nAunque no pueda ver, estás obrando\nSiempre estás, siempre estás obrando"),
        ]),
        Song(id: "s3", title: "Hermoso Nombre", stanzas: [
            Stanza(name: "Estrofa 1", text: "Tú fuiste el Verbo en el principio\nUnigénito de Dios\nEl misterio de Tu gloria revelado en Tu amor"),
            Stanza(name: "Coro", text: "Cuan hermoso Su nombre es\nCuan hermoso Su nombre es\nEl nombre de Jesús mi Rey"),
        ]),
    ]

    static let services: [ServiceOrder] = [
        ServiceOrder(
            id: "srv-default-1",
            name: "Culto Dominical General",
            date: "Domingo",
            defaultBackgroundUri: "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=300&q=80",
            defaultBackgroundType: .video,
            items: [
                ServiceItem(
                    id: "item-1", type: .note,
                    title: "Bienvenida y Oración",
                    subtitle: "Apertura de la reunión",
                    content: "BIENVENIDOS\nA LA CASA DE DIOS"
                ),
                ServiceItem(
                    id: "item-2", type: .song,
                    title: "Cuan Grande Es Él",
                    subtitle: "3 estrofas",
                    content: "Señor mi Dios\nAl contemplar los cielos\nEl firmamento y las estrellas mil",
                    backgroundUri: "https://vjs.zencdn.net/v/oceans.mp4",
                    backgroundType: .video,
                    songId: "s1",
                    stanzas: songs[0].stanzas
                ),
                ServiceItem(
                    id: "item-3", type: .verse,
                    title: "Salmos 23:1",
                    subtitle: "Lectura Bíblica Congregacional",
                    content: "Salmos 23:1\nJehová es mi pastor; nada me faltará.",
                    verseRef: "Salmos 23:1"
                ),
                ServiceItem(
                    id: "item-4", type: .song,
                    title: "Way Maker",
                    subtitle: "3 estrofas",
                    content: "Aquí estás\nTe vemos mover\nTe adoraré\nTe adoraré",
                    backgroundUri: "https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=1920&auto=format&fit=crop",
                    backgroundType: .image,
                    songId: "s2",
                    stanzas: songs[1].stanzas
                ),
                ServiceItem(
                    id: "item-5", type: .note,
                    title: "Mensaje de la Palabra",
                    subtitle: "Predicación pastoral",
                    content: "TIEMPO DE LA PALABRA\nPredicación"
                ),
            ]
        ),
    ]

    static let presetNotes: [(title: String, content: String)] = [
        ("Bienvenida y Oración", "BIENVENIDOS\nA LA CASA DE DIOS"),
        ("Alabanza y Adoración", "TIEMPO DE ALABANZA\nY ADORACIÓN"),
        ("Diezmos y Ofrendas", "DIEZMOS Y OFRENDAS\n«Dios ama al dador alegre»"),
        ("Mensaje de la Palabra", "TIEMPO DE LA PALABRA\nPredicación Pastoral"),
        ("Santa Cena", "SANTA CENA DEL SEÑOR"),
        ("Anuncios y Avisos", "ANUNCIOS GENERALES"),
        ("Oración Final", "BENDICIÓN Y DESPEDIDA"),
    ]
}
