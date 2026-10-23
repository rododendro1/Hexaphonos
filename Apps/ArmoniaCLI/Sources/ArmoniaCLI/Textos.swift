import Armonia

// MARK: - Textos
//
// Lo que escribe la herramienta por su cuenta, en español y en inglés: las etiquetas de la salida
// (`Mensaje`) y los errores de uso (`ErrorDeUso`). Lo musical (notas, acordes, escalas…) no está
// aquí: lo traduce el motor con `Nomenclatura`.
//
// Cada caso da sus dos textos en un `switch` sin `default`, como los `X+Idiomas.swift` del motor:
// un caso nuevo no compila hasta que tiene los dos. El idioma es el del vocabulario de la
// notación (`--ingles` → inglés).

/// Elige el texto en español o en inglés según el vocabulario de la notación.
func elegir(_ textos: (espanol: String, ingles: String), _ notacion: Nomenclatura) -> String {
    notacion.vocabulario == .ingles ? textos.ingles : textos.espanol
}

/// Las piezas de texto de la salida de las órdenes.
enum Mensaje {
    case notas
    case acordes
    case armadura
    case relativa
    case homonima
    case bajo(String)
    case inversion(Int)
    case bajoAjeno
    case sinAcordes
    case sin(String)
    case semitonos(Int)
    case sinAlteraciones
    case alteraciones(Int, sostenidos: Bool)
    case sinFaltasDeConduccion
    case sinDigitaciones
    case dedos(Int)
    case cejilla(Int)
    case pasos(Int)
    case triadas(Int)
    case ciclo(CicloNeorriemanniano)
    case instrumento(Encordado)

    func texto(en notacion: Nomenclatura) -> String {
        elegir(traducciones, notacion)
    }

    fileprivate var traducciones: (espanol: String, ingles: String) {
        switch self {
        case .notas: return ("notas", "notes")
        case .acordes: return ("acordes", "chords")
        case .armadura: return ("armadura", "key signature")
        case .relativa: return ("relativa", "relative")
        case .homonima: return ("homónima", "parallel")
        case .bajo(let nota): return ("bajo \(nota)", "bass \(nota)")
        case .inversion(let n): return ("inversión \(n)", "inversion \(n)")
        case .bajoAjeno: return ("bajo ajeno al acorde", "bass not in the chord")
        case .sinAcordes: return ("No forman ningún acorde conocido.", "No chord found.")
        case .sin(let notas): return ("sin \(notas)", "omits \(notas)")
        case .semitonos(let n): return ("\(n) semitonos", "\(n) semitones")
        case .sinAlteraciones: return ("sin alteraciones", "no sharps or flats")
        case .alteraciones(let n, let sostenidos):
            if sostenidos { return (n == 1 ? "1 sostenido" : "\(n) sostenidos", n == 1 ? "1 sharp" : "\(n) sharps") }
            return (n == 1 ? "1 bemol" : "\(n) bemoles", n == 1 ? "1 flat" : "\(n) flats")
        case .sinFaltasDeConduccion: return ("Sin faltas de conducción.", "No voice-leading errors.")
        case .sinDigitaciones: return ("no hay digitaciones cómodas", "no comfortable fingerings found")
        case .dedos(let n): return (n == 1 ? "1 dedo" : "\(n) dedos", n == 1 ? "1 finger" : "\(n) fingers")
        case .cejilla(let traste): return ("cejilla en el traste \(traste)", "barre at fret \(traste)")
        case .pasos(let n):
            switch n {
            case 0: return ("ningún paso", "no steps")
            case 1: return ("1 paso", "1 step")
            default: return ("\(n) pasos", "\(n) steps")
            }
        case .triadas(let n): return (n == 1 ? "1 tríada" : "\(n) tríadas", n == 1 ? "1 triad" : "\(n) triads")
        case .ciclo(let ciclo): return (ciclo.nombre, ciclo.nombreEnIngles)
        case .instrumento(let encordado):
            // El catálogo del motor solo tiene el nombre en español.
            let ingles: String
            switch encordado.nombre {
            case "guitarra": ingles = "guitar"
            case "guitarra de siete cuerdas": ingles = "seven-string guitar"
            case "guitarra en re grave": ingles = "drop D guitar"
            case "bajo": ingles = "bass"
            case "bajo de cinco cuerdas": ingles = "five-string bass"
            case "ukelele": ingles = "ukulele"
            case "mandolina": ingles = "mandolin"
            default: ingles = encordado.nombre
            }
            return (encordado.nombre, ingles)
        }
    }
}

/// Una orden mal escrita: lo que falta o sobra, con un ejemplo de cómo se escribe.
enum ErrorDeUso {
    // Órdenes sencillas
    case ordenDesconocida(String)
    case opcionDesconocida(String)
    case faltaCifrado
    case faltanNotas
    case dosNotas
    case faltaEscala
    case faltaTonalidad
    case faltanAcordesDeLasVoces
    case dosAcordesDeConduccion
    case faltaTonalidadTrasEn
    case faltanAcordesDelAnalisis

    // Digitaciones
    case faltaInstrumento
    case instrumentoDesconocido(String)
    case faltaLimite
    case limiteFueraDeRango
    case faltanDedos
    case dedosFueraDeRango
    case faltaTraste
    case trasteFueraDeRango
    case faltaCifradoDeDigitaciones

    // Neorriemanniano
    case vocesFueraDeRango
    case unAcordeDeVecinos
    case vecinosSinFamilia
    case dosAcordesDeCamino
    case caminoSinConexion
    case faltanPasosDePLR
    case plrSoloTriadas(camino: Bool)

    // Partituras (`orden` es «musicxml» o «midi»)
    case faltaTipoDePartitura(orden: String)
    case instrumentoMIDI
    case marcasSoloMusicXML
    case faltaValor(String)
    case tempoMalEscrito
    case faltanNotasDeLaMelodia(orden: String)
    case marcasSoloCoral
    case duracionSoloCoral
    case claveDesconocida(String)
    case faltanAcordesDelCoral(orden: String)
    case soloParaMelodia(String)
    case faltanAcordesDeLaProgresion(orden: String)
    case acordesConCifradosYAnalisis
    case tipoDePartituraDesconocido(String)

    // Dibujos (`orden` es «tonnetz» o «tabla»)
    case margenFueraDeRango
    case faltanNotasDelDibujo(orden: String)
    case faltaAcordeDelDibujo(orden: String)
    case faltaEscalaDelDibujo(orden: String)
    case clasesFueraDeRango(orden: String)
    case faltanTriadasDelRecorrido(orden: String)
    case cicloMalEscrito(orden: String)
    case recorridoSoloTriadas(orden: String)
    case caminoSoloTriadas(orden: String)
    case cicloSoloTriadas(orden: String)

    /// El mensaje completo, con la línea que remite a la ayuda.
    func texto(en notacion: Nomenclatura) -> String {
        "armonia: " + elegir(traducciones, notacion) + "\n"
            + elegir(("Prueba «armonia ayuda».", "Try \"armonia help\"."), notacion) + "\n"
    }

    private var traducciones: (espanol: String, ingles: String) {
        let digitaciones = ("armonia digitaciones Sol7/Si --instrumento ukelele", "armonia fingerings G7/B --instrument ukulele")
        switch self {
        case .ordenDesconocida(let orden):
            return ("orden desconocida: «\(orden)»", "unknown command: \"\(orden)\"")
        case .opcionDesconocida(let opcion):
            return ("opción desconocida: «\(opcion)»", "unknown option: \"\(opcion)\"")
        case .faltaCifrado:
            return ("falta el cifrado: armonia acorde Sol7", "missing the chord symbol: armonia chord G7")
        case .faltanNotas:
            return ("faltan las notas: armonia identificar Do Mi Sol", "missing the notes: armonia identify C E G")
        case .dosNotas:
            return ("hacen falta dos notas: armonia intervalo Do Mi", "two notes are needed: armonia interval C E")
        case .faltaEscala:
            return ("falta la escala: armonia escala Re dórico", "missing the scale: armonia scale D dorian")
        case .faltaTonalidad:
            return ("falta la tonalidad: armonia tonalidad La menor", "missing the key: armonia key A minor")
        case .faltanAcordesDeLasVoces:
            return ("faltan los acordes: armonia voces Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4",
                    "missing the chords: armonia voices C3 E4 G4 C5, G2 D4 G4 B4")
        case .dosAcordesDeConduccion:
            return ("hacen falta dos acordes: armonia conduccion Sol7 Do", "two chords are needed: armonia voice-leading G7 C")
        case .faltaTonalidadTrasEn:
            return ("falta la tonalidad tras --en", "missing the key after --in")
        case .faltanAcordesDelAnalisis:
            return ("faltan los acordes: armonia analizar Do Fa Sol7 Do", "missing the chords: armonia analyze C F G7 C")

        case .faltaInstrumento:
            return ("falta el instrumento: \(digitaciones.0)", "missing the instrument: \(digitaciones.1)")
        case .instrumentoDesconocido(let nombre):
            let conocidos = Encordado.todos.map { Mensaje.instrumento($0).traducciones }
            return ("instrumento desconocido: «\(nombre)» (\(conocidos.map { $0.espanol }.joined(separator: ", ")))",
                    "unknown instrument: \"\(nombre)\" (\(conocidos.map { $0.ingles }.joined(separator: ", ")))")
        case .faltaLimite:
            return ("falta el número de digitaciones: --limite 5", "missing the number of fingerings: --limit 5")
        case .limiteFueraDeRango:
            return ("el límite es un número de 1 a 200: --limite 5", "the limit is a number from 1 to 200: --limit 5")
        case .faltanDedos:
            return ("falta el número de dedos: --dedos 3", "missing the number of fingers: --fingers 3")
        case .dedosFueraDeRango:
            return ("los dedos son un número de 1 a 4: --dedos 3", "the fingers are a number from 1 to 4: --fingers 3")
        case .faltaTraste:
            return ("falta el traste más alto: --traste 12", "missing the highest fret: --fret 12")
        case .trasteFueraDeRango:
            return ("el traste más alto es un número de 0 a 24: --traste 12", "the highest fret is a number from 0 to 24: --fret 12")
        case .faltaCifradoDeDigitaciones:
            return ("falta el cifrado: \(digitaciones.0)", "missing the chord symbol: \(digitaciones.1)")

        case .vocesFueraDeRango:
            return ("las voces que se mueven son 1 o 2: --voces 2", "the moving voices are 1 or 2: --voices 2")
        case .unAcordeDeVecinos:
            return ("hace falta un acorde: armonia vecinos Sol7", "one chord is needed: armonia neighbors G7")
        case .vecinosSinFamilia:
            return ("los vecinos se buscan entre séptimas de dominante, menores, semidisminuidas, disminuidas y maj7, o entre tríadas mayores, menores y aumentadas",
                    "neighbors are searched among dominant, minor, half-diminished, diminished and maj7 sevenths, or among major, minor and augmented triads")
        case .dosAcordesDeCamino:
            return ("hacen falta dos acordes: armonia camino Sol7 Rem7", "two chords are needed: armonia path G7 Dm7")
        case .caminoSinConexion:
            return ("los dos acordes han de ser de la misma familia (séptimas, con o sin maj7, o tríadas) y estar conectados",
                    "both chords must be of the same family (sevenths, with or without maj7, or triads) and be connected")
        case .faltanPasosDePLR:
            return ("hacen falta una tríada y unos pasos u otra tríada: armonia plr Do PLR",
                    "a triad and some steps or another triad are needed: armonia plr C PLR")
        case .plrSoloTriadas(let camino):
            return ("P, L y R se aplican a tríadas mayores y menores: armonia plr " + (camino ? "Do Mibm" : "Do PLR"),
                    "P, L and R apply to major and minor triads: armonia plr " + (camino ? "C Ebm" : "C PLR"))

        case .faltaTipoDePartitura(let orden):
            return ("falta «melodia», «coral» o «acordes»: armonia \(orden) melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4",
                    "missing \"melody\", \"chorale\" or \"chords\": armonia \(orden) melody C4:4 D4:8 E4:8 F4:2 --compas 3/4")
        case .instrumentoMIDI:
            return ("el instrumento es un programa General MIDI de 0 a 127: --instrumento 52",
                    "the instrument is a General MIDI program from 0 to 127: --instrumento 52")
        case .marcasSoloMusicXML:
            return ("--cifrados y --analisis son para MusicXML", "--cifrados and --analisis are for MusicXML")
        case .faltaValor(let opcion):
            return ("falta el valor de --\(opcion)", "missing the value of --\(opcion)")
        case .tempoMalEscrito:
            return ("el tempo se escribe «--tempo 90» o «--tempo 60 4.»", "the tempo is written \"--tempo 90\" or \"--tempo 60 4.\"")
        case .faltanNotasDeLaMelodia(let orden):
            return ("faltan las notas: armonia \(orden) melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4",
                    "missing the notes: armonia \(orden) melody C4:4 D4:8 E4:8 F4:2 --compas 3/4")
        case .marcasSoloCoral:
            return ("--cifrados y --analisis son para «coral»", "--cifrados and --analisis are for \"chorale\"")
        case .duracionSoloCoral:
            return ("--duracion es solo para «coral»", "--duracion is only for \"chorale\"")
        case .claveDesconocida(let clave):
            return ("clave desconocida: «\(clave)» (sol, fa, do1, do2, do3, do4, sol8b, sol8a, fa3)",
                    "unknown clef: \"\(clave)\" (treble, bass, alto, tenor, sol, fa, do1, do2, do3, do4, sol8b, sol8a, fa3)")
        case .faltanAcordesDelCoral(let orden):
            return ("faltan los acordes: armonia \(orden) coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4",
                    "missing the chords: armonia \(orden) chorale C3 E4 G4 C5, G2 D4 G4 B4")
        case .soloParaMelodia(let opcion):
            return ("--\(opcion) es solo para «melodia»", "--\(opcion) is only for \"melody\"")
        case .faltanAcordesDeLaProgresion(let orden):
            return ("faltan los acordes: armonia \(orden) acordes Do Lam Re7 Sol7 Do",
                    "missing the chords: armonia \(orden) chords C Am D7 G7 C")
        case .acordesConCifradosYAnalisis:
            return ("los acordes llevan siempre cifrados y análisis", "chords always come with chord symbols and analysis")
        case .tipoDePartituraDesconocido(let tipo):
            return ("«\(tipo)»: se exporta una «melodia», un «coral» o unos «acordes»",
                    "\"\(tipo)\": the export is a \"melody\", a \"chorale\" or \"chords\"")

        case .margenFueraDeRango:
            return ("el margen es un número de 0 a 6: --margen 2", "the margin is a number from 0 to 6: --margen 2")
        case .faltanNotasDelDibujo(let orden):
            return ("faltan las notas: armonia \(orden) Do Mi Sol", "missing the notes: armonia \(orden) C E G")
        case .faltaAcordeDelDibujo(let orden):
            return ("falta el acorde: armonia \(orden) --acorde Sol7", "missing the chord: armonia \(orden) --chord G7")
        case .faltaEscalaDelDibujo(let orden):
            return ("falta la escala: armonia \(orden) --escala Re dórico", "missing the scale: armonia \(orden) --scale D dorian")
        case .clasesFueraDeRango(let orden):
            return ("las clases de altura son números de 0 a 11: armonia \(orden) --clases 0 4 7",
                    "pitch classes are numbers from 0 to 11: armonia \(orden) --pcs 0 4 7")
        case .faltanTriadasDelRecorrido(let orden):
            return ("faltan las tríadas: armonia \(orden) --recorrido Do Lam Fa Rem",
                    "missing the triads: armonia \(orden) --path C Am F Dm")
        case .cicloMalEscrito(let orden):
            return ("el ciclo es hexatónico, octatónico o LR, desde una tríada: armonia \(orden) --ciclo hexatonico Do",
                    "the cycle is hexatonic, octatonic or LR, from a triad: armonia \(orden) --cycle hexatonic C")
        case .recorridoSoloTriadas(let orden):
            return ("el recorrido es de tríadas mayores y menores: armonia \(orden) --recorrido Do Lam Fa Rem",
                    "the path is made of major and minor triads: armonia \(orden) --path C Am F Dm")
        case .caminoSoloTriadas(let orden):
            return ("el camino va de una tríada mayor o menor a otra: armonia \(orden) --camino Do Mibm",
                    "the shortest path goes from one major or minor triad to another: armonia \(orden) --shortest C Ebm")
        case .cicloSoloTriadas(let orden):
            return ("el ciclo empieza en una tríada mayor o menor: armonia \(orden) --ciclo hexatonico Do",
                    "the cycle starts on a major or minor triad: armonia \(orden) --cycle hexatonic C")
        }
    }
}
