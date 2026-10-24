import Armonia

// MARK: - Textos
//
// Lo que escribe la herramienta por su cuenta, en español, inglés, catalán, gallego y euskera: las
// etiquetas de la salida (`Mensaje`) y los errores de uso (`ErrorDeUso`). Lo musical (notas,
// acordes, escalas…) no está aquí: lo traduce el motor con `Nomenclatura`.
//
// Cada caso da sus textos con una `Traduccion` del motor, que pide los cinco: un caso nuevo no
// compila hasta que los tiene todos. El idioma es el de la notación (`--ingles`, `--idioma eu`…).
// La ayuda (`LineaDeComandos.ayuda(en:)`) también está en los cinco idiomas.

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
    case aCuatroVoces
    case sinArmonizacion
    case sinRealizacion
    case sinDigitaciones
    case dedos(Int)
    case cejilla(Int)
    case pasos(Int)
    case triadas(Int)
    case ciclo(CicloNeorriemanniano)
    case instrumento(Encordado)

    func texto(en notacion: Nomenclatura) -> String {
        traduccion.en(notacion)
    }

    fileprivate var traduccion: Traduccion {
        switch self {
        case .notas: return Traduccion("notas", "notes", ca: "notes", gl: "notas", eu: "notak")
        case .acordes: return Traduccion("acordes", "chords", ca: "acords", gl: "acordes", eu: "akordeak")
        case .armadura: return Traduccion("armadura", "key signature", ca: "armadura", gl: "armadura", eu: "armadura")
        case .relativa: return Traduccion("relativa", "relative", ca: "relativa", gl: "relativa", eu: "erlatiboa")
        case .homonima: return Traduccion("homónima", "parallel", ca: "homònima", gl: "homónima", eu: "homonimoa")
        case .bajo(let nota):
            return Traduccion("bajo \(nota)", "bass \(nota)", ca: "baix \(nota)", gl: "baixo \(nota)", eu: "baxua \(nota)")
        case .inversion(let n):
            let ordinales = [
                Traduccion("primera", "first", ca: "primera", gl: "primeira", eu: "lehen"),
                Traduccion("segunda", "second", ca: "segona", gl: "segunda", eu: "bigarren"),
                Traduccion("tercera", "third", ca: "tercera", gl: "terceira", eu: "hirugarren"),
                Traduccion("cuarta", "fourth", ca: "quarta", gl: "cuarta", eu: "laugarren"),
                Traduccion("quinta", "fifth", ca: "cinquena", gl: "quinta", eu: "bosgarren"),
                Traduccion("sexta", "sixth", ca: "sisena", gl: "sexta", eu: "seigarren"),
            ]
            guard (1...ordinales.count).contains(n) else {
                return Traduccion("inversión \(n)", "inversion \(n)", ca: "inversió \(n)", gl: "inversión \(n)",
                                  eu: "\(n). inbertsioa")
            }
            let o = ordinales[n - 1]
            return Traduccion("\(o.espanol) inversión", "\(o.ingles) inversion", ca: "\(o.catalan) inversió",
                              gl: "\(o.gallego) inversión", eu: "\(o.euskera) inbertsioa")
        case .bajoAjeno:
            return Traduccion("bajo ajeno al acorde", "bass not in the chord", ca: "baix aliè a l'acord",
                              gl: "baixo alleo ao acorde", eu: "akordetik kanpoko baxua")
        case .sinAcordes:
            return Traduccion("No forman ningún acorde conocido.", "No chord found.", ca: "No formen cap acord conegut.",
                              gl: "Non forman ningún acorde coñecido.", eu: "Ez dute akorde ezagunik osatzen.")
        case .sin(let notas):
            return Traduccion("sin \(notas)", "omits \(notas)", ca: "sense \(notas)", gl: "sen \(notas)", eu: "\(notas) gabe")
        case .semitonos(let n):
            return Traduccion("\(n) semitonos", "\(n) semitones", ca: "\(n) semitons", gl: "\(n) semitons", eu: "\(n) tonuerdi")
        case .sinAlteraciones:
            return Traduccion("sin alteraciones", "no sharps or flats", ca: "sense alteracions", gl: "sen alteracións",
                              eu: "alteraziorik gabe")
        case .alteraciones(let n, let sostenidos):
            if sostenidos {
                return Traduccion(n == 1 ? "1 sostenido" : "\(n) sostenidos", n == 1 ? "1 sharp" : "\(n) sharps",
                                  ca: n == 1 ? "1 sostingut" : "\(n) sostinguts", gl: n == 1 ? "1 sostido" : "\(n) sostidos",
                                  eu: "\(n) diesa")
            }
            return Traduccion(n == 1 ? "1 bemol" : "\(n) bemoles", n == 1 ? "1 flat" : "\(n) flats",
                              ca: n == 1 ? "1 bemoll" : "\(n) bemolls", gl: n == 1 ? "1 bemol" : "\(n) bemois",
                              eu: "\(n) bemol")
        case .sinFaltasDeConduccion:
            return Traduccion("Sin faltas de conducción.", "No voice-leading errors.", ca: "Sense errors de conducció.",
                              gl: "Sen erros de condución.", eu: "Ez dago ahots-eramate akatsik.")
        case .aCuatroVoces:
            return Traduccion("A cuatro voces (bajo, tenor, contralto, soprano):", "In four parts (bass, tenor, alto, soprano):",
                              ca: "A quatre veus (baix, tenor, contralt, soprano):",
                              gl: "A catro voces (baixo, tenor, contralto, soprano):",
                              eu: "Lau ahotsetara (baxua, tenorra, altua, sopranoa):")
        case .sinArmonizacion:
            return Traduccion("Alguna nota no está en ningún acorde de la tonalidad.", "Some note is not in any chord of the key.",
                              ca: "Alguna nota no és a cap acord de la tonalitat.",
                              gl: "Algunha nota non está en ningún acorde da tonalidade.",
                              eu: "Notaren bat ez dago tonalitateko inongo akordetan.")
        case .sinRealizacion:
            return Traduccion("No hay ninguna realización sin faltas de conducción.",
                              "There is no realization without voice-leading errors.",
                              ca: "No hi ha cap realització sense errors de conducció.",
                              gl: "Non hai ningunha realización sen erros de condución.",
                              eu: "Ez dago ahots-eramate akatsik gabeko errealizaziorik.")
        case .sinDigitaciones:
            return Traduccion("no hay digitaciones cómodas", "no comfortable fingerings found",
                              ca: "no hi ha digitacions còmodes", gl: "non hai dixitacións cómodas",
                              eu: "ez dago hatz-jarrera erosorik")
        case .dedos(let n):
            return Traduccion(n == 1 ? "1 dedo" : "\(n) dedos", n == 1 ? "1 finger" : "\(n) fingers",
                              ca: n == 1 ? "1 dit" : "\(n) dits", gl: n == 1 ? "1 dedo" : "\(n) dedos", eu: "\(n) hatz")
        case .cejilla(let traste):
            return Traduccion("cejilla en el traste \(traste)", "barre at fret \(traste)", ca: "celleta al trast \(traste)",
                              gl: "pestana no traste \(traste)", eu: "zeja \(traste). trastean")
        case .pasos(let n):
            switch n {
            case 0: return Traduccion("ningún paso", "no steps", ca: "cap pas", gl: "ningún paso", eu: "urratsik ez")
            case 1: return Traduccion("1 paso", "1 step", ca: "1 pas", gl: "1 paso", eu: "urrats 1")
            default: return Traduccion("\(n) pasos", "\(n) steps", ca: "\(n) passos", gl: "\(n) pasos", eu: "\(n) urrats")
            }
        case .triadas(let n):
            return Traduccion(n == 1 ? "1 tríada" : "\(n) tríadas", n == 1 ? "1 triad" : "\(n) triads",
                              ca: n == 1 ? "1 tríada" : "\(n) tríades", gl: n == 1 ? "1 tríade" : "\(n) tríades",
                              eu: "\(n) triade")
        case .ciclo(let ciclo):
            return Traduccion(ciclo.nombre(en: .espanol), ciclo.nombre(en: .ingles), ca: ciclo.nombre(en: .catalan),
                              gl: ciclo.nombre(en: .gallego), eu: ciclo.nombre(en: .euskera))
        case .instrumento(let encordado):
            // El catálogo del motor solo tiene el nombre en español, que es también el que se escribe en
            // `--instrumento`: en catalán, gallego y euskera se deja así para que se pueda copiar.
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
            return Traduccion(encordado.nombre, ingles, ca: encordado.nombre, gl: encordado.nombre, eu: encordado.nombre)
        }
    }
}

/// Una orden mal escrita: lo que falta o sobra, con un ejemplo de cómo se escribe.
enum ErrorDeUso {
    // Órdenes sencillas
    case ordenDesconocida(String)
    case opcionDesconocida(String)
    case idiomaDesconocido(String)
    case faltaCifrado
    case faltanNotas
    case dosNotas
    case faltaEscala
    case faltaTonalidad
    case faltanAcordesDeLasVoces
    case dosAcordesDeConduccion
    case faltaTonalidadTrasEn
    case faltanAcordesDelAnalisis
    case faltanNotasDeLaArmonizacion
    case propuestasFueraDeRango
    case faltanAcordesDeLaRealizacion

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
        "armonia: " + traduccion.en(notacion) + "\n"
            + Traduccion("Prueba «armonia ayuda».", "Try \"armonia help\".", ca: "Prova «armonia ayuda».",
                         gl: "Proba «armonia ayuda».", eu: "Probatu «armonia ayuda».").en(notacion) + "\n"
    }

    private var traduccion: Traduccion {
        let digitaciones = ("armonia digitaciones Sol7/Si --instrumento ukelele", "armonia fingerings G7/B --instrument ukulele")
        let d = digitaciones.0
        switch self {
        case .ordenDesconocida(let orden):
            return Traduccion("orden desconocida: «\(orden)»", "unknown command: \"\(orden)\"",
                              ca: "ordre desconeguda: «\(orden)»", gl: "orde descoñecida: «\(orden)»",
                              eu: "agindu ezezaguna: «\(orden)»")
        case .opcionDesconocida(let opcion):
            return Traduccion("opción desconocida: «\(opcion)»", "unknown option: \"\(opcion)\"",
                              ca: "opció desconeguda: «\(opcion)»", gl: "opción descoñecida: «\(opcion)»",
                              eu: "aukera ezezaguna: «\(opcion)»")
        case .idiomaDesconocido(let idioma):
            return Traduccion("idioma desconocido: «\(idioma)» (es, en, ca, gl o eu)",
                              "unknown language: \"\(idioma)\" (es, en, ca, gl or eu)",
                              ca: "idioma desconegut: «\(idioma)» (es, en, ca, gl o eu)",
                              gl: "idioma descoñecido: «\(idioma)» (es, en, ca, gl ou eu)",
                              eu: "hizkuntza ezezaguna: «\(idioma)» (es, en, ca, gl edo eu)")
        case .faltaCifrado:
            return Traduccion("falta el cifrado: armonia acorde Sol7", "missing the chord symbol: armonia chord G7",
                              ca: "falta el xifrat: armonia acorde Sol7", gl: "falta o cifrado: armonia acorde Sol7",
                              eu: "zifratua falta da: armonia acorde Sol7")
        case .faltanNotas:
            return Traduccion("faltan las notas: armonia identificar Do Mi Sol", "missing the notes: armonia identify C E G",
                              ca: "falten les notes: armonia identificar Do Mi Sol",
                              gl: "faltan as notas: armonia identificar Do Mi Sol",
                              eu: "notak falta dira: armonia identificar Do Mi Sol")
        case .dosNotas:
            return Traduccion("hacen falta dos notas: armonia intervalo Do Mi", "two notes are needed: armonia interval C E",
                              ca: "calen dues notes: armonia intervalo Do Mi", gl: "fan falta dúas notas: armonia intervalo Do Mi",
                              eu: "bi nota behar dira: armonia intervalo Do Mi")
        case .faltaEscala:
            return Traduccion("falta la escala: armonia escala Re dórico", "missing the scale: armonia scale D dorian",
                              ca: "falta l'escala: armonia escala Re dórico", gl: "falta a escala: armonia escala Re dórico",
                              eu: "eskala falta da: armonia escala Re dórico")
        case .faltaTonalidad:
            return Traduccion("falta la tonalidad: armonia tonalidad La menor", "missing the key: armonia key A minor",
                              ca: "falta la tonalitat: armonia tonalidad La menor",
                              gl: "falta a tonalidade: armonia tonalidad La menor",
                              eu: "tonalitatea falta da: armonia tonalidad La menor")
        case .faltanAcordesDeLasVoces:
            let ejemplo = "armonia revisar Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4"
            return Traduccion("faltan los acordes: " + ejemplo, "missing the chords: armonia check C3 E4 G4 C5, G2 D4 G4 B4",
                              ca: "falten els acords: " + ejemplo, gl: "faltan os acordes: " + ejemplo,
                              eu: "akordeak falta dira: " + ejemplo)
        case .dosAcordesDeConduccion:
            let ejemplo = "armonia conduccion Sol7 Do"
            return Traduccion("hacen falta dos acordes: " + ejemplo, "two chords are needed: armonia voice-leading G7 C",
                              ca: "calen dos acords: " + ejemplo, gl: "fan falta dous acordes: " + ejemplo,
                              eu: "bi akorde behar dira: " + ejemplo)
        case .faltaTonalidadTrasEn:
            return Traduccion("falta la tonalidad tras --en", "missing the key after --in",
                              ca: "falta la tonalitat després de --en", gl: "falta a tonalidade despois de --en",
                              eu: "tonalitatea falta da --en ondoren")
        case .faltanAcordesDelAnalisis:
            let ejemplo = "armonia analizar Do Fa Sol7 Do"
            return Traduccion("faltan los acordes: " + ejemplo, "missing the chords: armonia analyze C F G7 C",
                              ca: "falten els acords: " + ejemplo, gl: "faltan os acordes: " + ejemplo,
                              eu: "akordeak falta dira: " + ejemplo)
        case .faltanNotasDeLaArmonizacion:
            let ejemplo = "armonia armonizar Mi4 Re4 Do4"
            return Traduccion("faltan las notas de la melodía: " + ejemplo,
                              "missing the notes of the melody: armonia harmonize E4 D4 C4",
                              ca: "falten les notes de la melodia: " + ejemplo, gl: "faltan as notas da melodía: " + ejemplo,
                              eu: "melodiaren notak falta dira: " + ejemplo)
        case .propuestasFueraDeRango:
            return Traduccion("--propuestas va de 1 a 20", "--proposals goes from 1 to 20", ca: "--propuestas va d'1 a 20",
                              gl: "--propuestas vai de 1 a 20", eu: "--propuestas 1etik 20ra doa")
        case .faltanAcordesDeLaRealizacion:
            let ejemplo = "armonia realizar Do Fa Sol7 Do"
            return Traduccion("faltan los acordes: " + ejemplo, "missing the chords: armonia realize C F G7 C",
                              ca: "falten els acords: " + ejemplo, gl: "faltan os acordes: " + ejemplo,
                              eu: "akordeak falta dira: " + ejemplo)

        case .faltaInstrumento:
            return Traduccion("falta el instrumento: \(d)", "missing the instrument: \(digitaciones.1)",
                              ca: "falta l'instrument: \(d)", gl: "falta o instrumento: \(d)", eu: "instrumentua falta da: \(d)")
        case .instrumentoDesconocido(let nombre):
            let conocidos = Encordado.todos.map { Mensaje.instrumento($0).traduccion }
            let espanol = conocidos.map(\.espanol).joined(separator: ", ")
            return Traduccion("instrumento desconocido: «\(nombre)» (\(espanol))",
                              "unknown instrument: \"\(nombre)\" (\(conocidos.map(\.ingles).joined(separator: ", ")))",
                              ca: "instrument desconegut: «\(nombre)» (\(espanol))",
                              gl: "instrumento descoñecido: «\(nombre)» (\(espanol))",
                              eu: "instrumentu ezezaguna: «\(nombre)» (\(espanol))")
        case .faltaLimite:
            return Traduccion("falta el número de digitaciones: --limite 5", "missing the number of fingerings: --limit 5",
                              ca: "falta el nombre de digitacions: --limite 5", gl: "falta o número de dixitacións: --limite 5",
                              eu: "hatz-jarrera kopurua falta da: --limite 5")
        case .limiteFueraDeRango:
            return Traduccion("el límite es un número de 1 a 200: --limite 5", "the limit is a number from 1 to 200: --limit 5",
                              ca: "el límit és un nombre d'1 a 200: --limite 5", gl: "o límite é un número de 1 a 200: --limite 5",
                              eu: "muga 1etik 200era bitarteko zenbaki bat da: --limite 5")
        case .faltanDedos:
            return Traduccion("falta el número de dedos: --dedos 3", "missing the number of fingers: --fingers 3",
                              ca: "falta el nombre de dits: --dedos 3", gl: "falta o número de dedos: --dedos 3",
                              eu: "hatz kopurua falta da: --dedos 3")
        case .dedosFueraDeRango:
            return Traduccion("los dedos son un número de 1 a 4: --dedos 3", "the fingers are a number from 1 to 4: --fingers 3",
                              ca: "els dits són un nombre d'1 a 4: --dedos 3", gl: "os dedos son un número de 1 a 4: --dedos 3",
                              eu: "hatzak 1etik 4ra bitarteko zenbaki bat dira: --dedos 3")
        case .faltaTraste:
            return Traduccion("falta el traste más alto: --traste 12", "missing the highest fret: --fret 12",
                              ca: "falta el trast més alt: --traste 12", gl: "falta o traste máis alto: --traste 12",
                              eu: "traste altuena falta da: --traste 12")
        case .trasteFueraDeRango:
            return Traduccion("el traste más alto es un número de 0 a 24: --traste 12",
                              "the highest fret is a number from 0 to 24: --fret 12",
                              ca: "el trast més alt és un nombre de 0 a 24: --traste 12",
                              gl: "o traste máis alto é un número de 0 a 24: --traste 12",
                              eu: "traste altuena 0tik 24ra bitarteko zenbaki bat da: --traste 12")
        case .faltaCifradoDeDigitaciones:
            return Traduccion("falta el cifrado: \(d)", "missing the chord symbol: \(digitaciones.1)",
                              ca: "falta el xifrat: \(d)", gl: "falta o cifrado: \(d)", eu: "zifratua falta da: \(d)")

        case .vocesFueraDeRango:
            return Traduccion("las voces que se mueven son 1 o 2: --voces 2", "the moving voices are 1 or 2: --voices 2",
                              ca: "les veus que es mouen són 1 o 2: --voces 2", gl: "as voces que se moven son 1 ou 2: --voces 2",
                              eu: "mugitzen diren ahotsak 1 edo 2 dira: --voces 2")
        case .unAcordeDeVecinos:
            let ejemplo = "armonia vecinos Sol7"
            return Traduccion("hace falta un acorde: " + ejemplo, "one chord is needed: armonia neighbors G7",
                              ca: "cal un acord: " + ejemplo, gl: "fai falta un acorde: " + ejemplo,
                              eu: "akorde bat behar da: " + ejemplo)
        case .vecinosSinFamilia:
            return Traduccion("los vecinos se buscan entre séptimas de dominante, menores, semidisminuidas, disminuidas y maj7, o entre tríadas mayores, menores y aumentadas",
                              "neighbors are searched among dominant, minor, half-diminished, diminished and maj7 sevenths, or among major, minor and augmented triads",
                              ca: "els veïns es busquen entre sèptimes de dominant, menors, semidisminuïdes, disminuïdes i maj7, o entre tríades majors, menors i augmentades",
                              gl: "os veciños búscanse entre sétimas de dominante, menores, semidiminuídas, diminuídas e maj7, ou entre tríades maiores, menores e aumentadas",
                              eu: "auzokideak dominanteko zazpigarrenen, txikien, erdi-gutxituen, gutxituen eta maj7en artean bilatzen dira, edo triade handi, txiki eta gehituen artean")
        case .dosAcordesDeCamino:
            let ejemplo = "armonia conduccion-parsimoniosa Sol7 Rem7"
            return Traduccion("hacen falta dos acordes: " + ejemplo, "two chords are needed: armonia smooth-path G7 Dm7",
                              ca: "calen dos acords: " + ejemplo, gl: "fan falta dous acordes: " + ejemplo,
                              eu: "bi akorde behar dira: " + ejemplo)
        case .caminoSinConexion:
            return Traduccion("los dos acordes han de ser de la misma familia (séptimas, con o sin maj7, o tríadas) y estar conectados",
                              "both chords must be of the same family (sevenths, with or without maj7, or triads) and be connected",
                              ca: "els dos acords han de ser de la mateixa família (sèptimes, amb maj7 o sense, o tríades) i estar connectats",
                              gl: "os dous acordes teñen que ser da mesma familia (sétimas, con ou sen maj7, ou tríades) e estar conectados",
                              eu: "bi akordeek familia berekoak izan behar dute (zazpigarrenak, maj7rekin edo gabe, edo triadeak) eta lotuta egon")
        case .faltanPasosDePLR:
            let ejemplo = "armonia plr Do PLR"
            return Traduccion("hacen falta una tríada y unos pasos u otra tríada: " + ejemplo,
                              "a triad and some steps or another triad are needed: armonia plr C PLR",
                              ca: "calen una tríada i uns passos o una altra tríada: " + ejemplo,
                              gl: "fan falta unha tríade e uns pasos ou outra tríade: " + ejemplo,
                              eu: "triade bat eta urrats batzuk edo beste triade bat behar dira: " + ejemplo)
        case .plrSoloTriadas(let camino):
            let ejemplo = "armonia plr " + (camino ? "Do Mibm" : "Do PLR")
            return Traduccion("P, L y R se aplican a tríadas mayores y menores: " + ejemplo,
                              "P, L and R apply to major and minor triads: armonia plr " + (camino ? "C Ebm" : "C PLR"),
                              ca: "P, L i R s'apliquen a tríades majors i menors: " + ejemplo,
                              gl: "P, L e R aplícanse a tríades maiores e menores: " + ejemplo,
                              eu: "P, L eta R triade handi eta txikiei aplikatzen zaizkie: " + ejemplo)

        case .faltaTipoDePartitura(let orden):
            let ejemplo = "armonia \(orden) melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4"
            return Traduccion("falta «melodia», «coral» o «acordes»: " + ejemplo,
                              "missing \"melody\", \"chorale\" or \"chords\": armonia \(orden) melody C4:4 D4:8 E4:8 F4:2 --compas 3/4",
                              ca: "falta «melodia», «coral» o «acordes»: " + ejemplo,
                              gl: "falta «melodia», «coral» ou «acordes»: " + ejemplo,
                              eu: "«melodia», «coral» edo «acordes» falta da: " + ejemplo)
        case .instrumentoMIDI:
            return Traduccion("el programa es un número General MIDI de 0 a 127: --programa 52",
                              "the program is a General MIDI number from 0 to 127: --program 52",
                              ca: "el programa és un nombre General MIDI de 0 a 127: --programa 52",
                              gl: "o programa é un número General MIDI de 0 a 127: --programa 52",
                              eu: "programa 0tik 127ra bitarteko General MIDI zenbaki bat da: --programa 52")
        case .marcasSoloMusicXML:
            return Traduccion("--cifrados y --analisis son para MusicXML", "--cifrados and --analisis are for MusicXML",
                              ca: "--cifrados i --analisis són per a MusicXML", gl: "--cifrados e --analisis son para MusicXML",
                              eu: "--cifrados eta --analisis MusicXMLrako dira")
        case .faltaValor(let opcion):
            return Traduccion("falta el valor de --\(opcion)", "missing the value of --\(opcion)",
                              ca: "falta el valor de --\(opcion)", gl: "falta o valor de --\(opcion)",
                              eu: "--\(opcion) aukeraren balioa falta da")
        case .tempoMalEscrito:
            return Traduccion("el tempo se escribe «--tempo 90» o «--tempo 60 4.»",
                              "the tempo is written \"--tempo 90\" or \"--tempo 60 4.\"",
                              ca: "el tempo s'escriu «--tempo 90» o «--tempo 60 4.»",
                              gl: "o tempo escríbese «--tempo 90» ou «--tempo 60 4.»",
                              eu: "tempoa «--tempo 90» edo «--tempo 60 4.» idazten da")
        case .faltanNotasDeLaMelodia(let orden):
            let ejemplo = "armonia \(orden) melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4"
            return Traduccion("faltan las notas: " + ejemplo,
                              "missing the notes: armonia \(orden) melody C4:4 D4:8 E4:8 F4:2 --compas 3/4",
                              ca: "falten les notes: " + ejemplo, gl: "faltan as notas: " + ejemplo,
                              eu: "notak falta dira: " + ejemplo)
        case .marcasSoloCoral:
            return Traduccion("--cifrados y --analisis son para «coral»", "--cifrados and --analisis are for \"chorale\"",
                              ca: "--cifrados i --analisis són per a «coral»", gl: "--cifrados e --analisis son para «coral»",
                              eu: "--cifrados eta --analisis «coral»erako dira")
        case .duracionSoloCoral:
            return Traduccion("--duracion es solo para «coral»", "--duracion is only for \"chorale\"",
                              ca: "--duracion només és per a «coral»", gl: "--duracion só é para «coral»",
                              eu: "--duracion «coral»erako bakarrik da")
        case .claveDesconocida(let clave):
            let claves = "(sol, fa, do1, do2, do3, do4, sol8b, sol8a, fa3)"
            return Traduccion("clave desconocida: «\(clave)» " + claves,
                              "unknown clef: \"\(clave)\" (treble, bass, alto, tenor, sol, fa, do1, do2, do3, do4, sol8b, sol8a, fa3)",
                              ca: "clau desconeguda: «\(clave)» " + claves, gl: "clave descoñecida: «\(clave)» " + claves,
                              eu: "giltza ezezaguna: «\(clave)» " + claves)
        case .faltanAcordesDelCoral(let orden):
            let ejemplo = "armonia \(orden) coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4"
            return Traduccion("faltan los acordes: " + ejemplo,
                              "missing the chords: armonia \(orden) chorale C3 E4 G4 C5, G2 D4 G4 B4",
                              ca: "falten els acords: " + ejemplo, gl: "faltan os acordes: " + ejemplo,
                              eu: "akordeak falta dira: " + ejemplo)
        case .soloParaMelodia(let opcion):
            return Traduccion("--\(opcion) es solo para «melodia»", "--\(opcion) is only for \"melody\"",
                              ca: "--\(opcion) només és per a «melodia»", gl: "--\(opcion) só é para «melodia»",
                              eu: "--\(opcion) «melodia»rako bakarrik da")
        case .faltanAcordesDeLaProgresion(let orden):
            let ejemplo = "armonia \(orden) acordes Do Lam Re7 Sol7 Do"
            return Traduccion("faltan los acordes: " + ejemplo, "missing the chords: armonia \(orden) chords C Am D7 G7 C",
                              ca: "falten els acords: " + ejemplo, gl: "faltan os acordes: " + ejemplo,
                              eu: "akordeak falta dira: " + ejemplo)
        case .acordesConCifradosYAnalisis:
            return Traduccion("los acordes llevan siempre cifrados y análisis", "chords always come with chord symbols and analysis",
                              ca: "els acords porten sempre xifrats i anàlisi", gl: "os acordes levan sempre cifrados e análise",
                              eu: "akordeek beti daramatzate zifratuak eta analisia")
        case .tipoDePartituraDesconocido(let tipo):
            return Traduccion("«\(tipo)»: se exporta una «melodia», un «coral» o unos «acordes»",
                              "\"\(tipo)\": the export is a \"melody\", a \"chorale\" or \"chords\"",
                              ca: "«\(tipo)»: s'exporta una «melodia», un «coral» o uns «acordes»",
                              gl: "«\(tipo)»: expórtase unha «melodia», un «coral» ou uns «acordes»",
                              eu: "«\(tipo)»: «melodia», «coral» edo «acordes» bat esportatzen da")

        case .margenFueraDeRango:
            return Traduccion("el margen es un número de 0 a 6: --margen 2", "the margin is a number from 0 to 6: --margen 2",
                              ca: "el marge és un nombre de 0 a 6: --margen 2", gl: "a marxe é un número de 0 a 6: --margen 2",
                              eu: "marjina 0tik 6ra bitarteko zenbaki bat da: --margen 2")
        case .faltanNotasDelDibujo(let orden):
            let ejemplo = "armonia \(orden) Do Mi Sol"
            return Traduccion("faltan las notas: " + ejemplo, "missing the notes: armonia \(orden) C E G",
                              ca: "falten les notes: " + ejemplo, gl: "faltan as notas: " + ejemplo,
                              eu: "notak falta dira: " + ejemplo)
        case .faltaAcordeDelDibujo(let orden):
            let ejemplo = "armonia \(orden) --acorde Sol7"
            return Traduccion("falta el acorde: " + ejemplo, "missing the chord: armonia \(orden) --chord G7",
                              ca: "falta l'acord: " + ejemplo, gl: "falta o acorde: " + ejemplo,
                              eu: "akordea falta da: " + ejemplo)
        case .faltaEscalaDelDibujo(let orden):
            let ejemplo = "armonia \(orden) --escala Re dórico"
            return Traduccion("falta la escala: " + ejemplo, "missing the scale: armonia \(orden) --scale D dorian",
                              ca: "falta l'escala: " + ejemplo, gl: "falta a escala: " + ejemplo,
                              eu: "eskala falta da: " + ejemplo)
        case .clasesFueraDeRango(let orden):
            let ejemplo = "armonia \(orden) --clases 0 4 7"
            return Traduccion("las clases de altura son números de 0 a 11: " + ejemplo,
                              "pitch classes are numbers from 0 to 11: armonia \(orden) --pcs 0 4 7",
                              ca: "les classes d'altura són nombres de 0 a 11: " + ejemplo,
                              gl: "as clases de altura son números de 0 a 11: " + ejemplo,
                              eu: "altuera-klaseak 0tik 11ra bitarteko zenbakiak dira: " + ejemplo)
        case .faltanTriadasDelRecorrido(let orden):
            let ejemplo = "armonia \(orden) --recorrido Do Lam Fa Rem"
            return Traduccion("faltan las tríadas: " + ejemplo, "missing the triads: armonia \(orden) --sequence C Am F Dm",
                              ca: "falten les tríades: " + ejemplo, gl: "faltan as tríades: " + ejemplo,
                              eu: "triadeak falta dira: " + ejemplo)
        case .cicloMalEscrito(let orden):
            let ejemplo = "armonia \(orden) --ciclo hexatonico Do"
            return Traduccion("el ciclo es hexatónico, octatónico o LR, desde una tríada: " + ejemplo,
                              "the cycle is hexatonic, octatonic or LR, from a triad: armonia \(orden) --cycle hexatonic C",
                              ca: "el cicle és hexatònic, octatònic o LR, des d'una tríada: " + ejemplo,
                              gl: "o ciclo é hexatónico, octatónico ou LR, desde unha tríade: " + ejemplo,
                              eu: "zikloa hexatonikoa, oktatonikoa edo LR da, triade batetik abiatuta: " + ejemplo)
        case .recorridoSoloTriadas(let orden):
            let ejemplo = "armonia \(orden) --recorrido Do Lam Fa Rem"
            return Traduccion("el recorrido es de tríadas mayores y menores: " + ejemplo,
                              "the sequence is made of major and minor triads: armonia \(orden) --sequence C Am F Dm",
                              ca: "el recorregut és de tríades majors i menors: " + ejemplo,
                              gl: "o percorrido é de tríades maiores e menores: " + ejemplo,
                              eu: "ibilbidea triade handi eta txikiz osatzen da: " + ejemplo)
        case .caminoSoloTriadas(let orden):
            let ejemplo = "armonia \(orden) --camino Do Mibm"
            return Traduccion("el camino va de una tríada mayor o menor a otra: " + ejemplo,
                              "the shortest path goes from one major or minor triad to another: armonia \(orden) --shortest C Ebm",
                              ca: "el camí va d'una tríada major o menor a una altra: " + ejemplo,
                              gl: "o camiño vai dunha tríade maior ou menor a outra: " + ejemplo,
                              eu: "bidea triade handi edo txiki batetik beste batera doa: " + ejemplo)
        case .cicloSoloTriadas(let orden):
            let ejemplo = "armonia \(orden) --ciclo hexatonico Do"
            return Traduccion("el ciclo empieza en una tríada mayor o menor: " + ejemplo,
                              "the cycle starts on a major or minor triad: armonia \(orden) --cycle hexatonic C",
                              ca: "el cicle comença en una tríada major o menor: " + ejemplo,
                              gl: "o ciclo comeza nunha tríade maior ou menor: " + ejemplo,
                              eu: "zikloa triade handi edo txiki batean hasten da: " + ejemplo)
        }
    }
}
