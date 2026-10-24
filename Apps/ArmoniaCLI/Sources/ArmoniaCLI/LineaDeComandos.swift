// La herramienta de línea de comandos `armonia`: el motor sin escribir código.
//
//     armonia acorde Sol7/Si
//     armonia identificar Do Mi Sol Sib
//     armonia analizar Do Lam Re7 Sol7 Do
//
// Toda la lógica está aquí, separada del ejecutable, para poder probarla.

import Armonia
import Foundation

/// Lo que produce una orden: el texto de la salida estándar, el de la salida de errores y el
/// código de salida (0 bien, 1 texto que no se puede leer, 2 orden mal escrita). Una orden que
/// produce un fichero binario (MIDI) lo deja en `datos`, que va a la salida estándar en lugar
/// del texto.
public struct ResultadoDeOrden: Equatable, Sendable {
    public var salida: String
    public var error: String
    public var codigo: Int32
    public var datos: Data? = nil
}

public enum LineaDeComandos {
    public static let ayuda = """
    armonia: teoría musical desde la línea de comandos.

    Uso: armonia <orden> <argumentos> [--ingles | --idioma es|en|ca|gl|eu]

    Órdenes:
      acorde <cifrado>…            notas, tipo y papel de cada nota      armonia acorde Sol7/Si
      identificar <notas>          acordes que forman unas notas         armonia identificar Do Mi Sol Sib
      intervalo <nota> <nota>      intervalo entre dos notas o alturas   armonia intervalo Do4 Mi5
      escala <escala>              notas y acordes de una escala         armonia escala Re dórico
      tonalidad <tonalidad>        armadura, relativas y grados          armonia tonalidad La menor
      analizar <acordes> [--en <tonalidad>]
                                   cifrado romano, funciones, cadencias
                                   y modulaciones (con su acorde
                                   pivote; sin --en)                     armonia analizar Do Fa Sol7 Do Lam Re7 Sol
      armonizar <melodía> [--en <tonalidad>] [--propuestas 3]
                                   acordes para una melodía, de mejor a
                                   peor; con octavas (Mi4), también el
                                   coral a cuatro voces                  armonia armonizar Mi4 Fa4 Re4 Do4
      realizar <acordes> [--en <tonalidad>]
                                   los acordes a cuatro voces, sin
                                   faltas de conducción                  armonia realizar Do Fa Sol7 Do
      revisar <acordes>            faltas de conducción (quintas
                                   paralelas…); acordes de grave a
                                   agudo, separados por comas            armonia revisar Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4
      musicxml melodia <eventos> [opciones]
                                   partitura MusicXML de una melodía     armonia musicxml melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4 > melodia.musicxml
      musicxml coral <acordes> [opciones]
                                   coral a cuatro voces en MusicXML      armonia musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 > coral.musicxml
      musicxml acordes <cifrados> [opciones]
                                   progresión con cifrados y análisis    armonia musicxml acordes Do Lam Re7 Sol7 Do > progresion.musicxml
                                   opciones: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,
                                   --clave fa, --tempo 90 (o --tempo 60 4.), --titulo Mi coral,
                                   --duracion 2 (lo que dura cada acorde; negra en el coral y
                                   blanca en los acordes si no), --cifrados y --analisis (en el
                                   coral: cifrado americano encima, romano y función debajo)
      midi melodia|coral|acordes <…> [opciones]
                                   lo mismo como fichero MIDI, para oírlo
                                   (sin --clave ni --cifrados; con
                                   --programa 0…127, General MIDI)       armonia midi acordes Do Lam Re7 Sol7 Do > progresion.mid
      tonnetz <notas>              Tonnetz en SVG de unas notas          armonia tonnetz Do Mi Sol Si > tonnetz.svg
      tonnetz --acorde <cifrado> | --escala <escala> | --clases <números>
                                   de un acorde, una escala o un
                                   conjunto de clases de altura          armonia tonnetz --escala Re dórico > dorico.svg
      tonnetz --recorrido <tríadas> | --camino <tríada> <tríada>
                                   un recorrido de tríadas, con flechas,
                                   o el camino más corto por P, L y R    armonia tonnetz --recorrido Do Lam Fa Rem > recorrido.svg
      tonnetz --ciclo <ciclo> <tríada>
                                   un ciclo hexatónico, octatónico o LR  armonia tonnetz --ciclo hexatonico Do > ciclo.svg
                                   (--margen 2: más red alrededor)
      tabla <notas o alturas>      tabla armónica en SVG (hexágonos)     armonia tabla Do3 Sol3 Mi4 > tabla.svg
      tabla --acorde <cifrado> | --escala <escala> | --clases <números>
      tabla --recorrido <tríadas> | --camino <tríada> <tríada>
      tabla --ciclo <ciclo> <tríada>
                                   (--margen 2: más tabla alrededor)     armonia tabla --acorde Domaj7 > domaj7.svg
      vecinos <acorde> [--voces 2] acordes a un semitono (séptimas: dominante, menor, semidisminuida
                                   y disminuida; tríadas: mayor, menor y aumentada; un maj7, entre
                                   las séptimas y los maj7; --ampliada: con los maj7 también)
                                                                         armonia vecinos Sol7
      conduccion-parsimoniosa <acorde> <acorde> [--voces 2] [--ampliada]
                                   de un acorde a otro moviendo una voz
                                   (o dos) un semitono en cada paso      armonia conduccion-parsimoniosa Sol7 Rem7
      conduccion <acorde> <acorde> la conducción con menos semitonos     armonia conduccion Sol7 Do
      plr <tríada> <P, L, R…>      transformaciones neorriemannianas     armonia plr Do PLR
      plr <tríada> <tríada>        el camino más corto por P, L y R      armonia plr Do Mibm
      plr <tríada> <ciclo>         un ciclo: hexatonico (P, L),
                                   octatonico (P, R) o "ciclo LR"        armonia plr Do hexatonico
      digitaciones <cifrado>… [opciones]
                                   formas de tocar un acorde, de la más cómoda a la menos, en un
                                   instrumento de cuerda con trastes (cuerdas de grave a agudo)
                                   opciones: --instrumento guitarra|bajo|ukelele|mandolina|…
                                   (también «guitarra de siete cuerdas», «bajo de 5 cuerdas»,
                                   «drop D»), --limite 5, --traste 12 (el más alto que se usa),
                                   --dedos 4 (los que se pueden usar), --completo (con todas las notas:
                                   por defecto la quinta puede faltar), --diagrama (una línea por cuerda)
                                                                         armonia digitaciones Sol7/Si --instrumento ukelele
      ayuda                        esta ayuda

    Se aceptan nombres en español o en inglés (Do, C, Sib, Bb). Con --ingles, la respuesta
    usa la notación inglesa. Con --idioma ca, gl o eu, las notas y los mensajes salen en catalán,
    gallego o euskera (los nombres de acordes y escalas, en español, y esta ayuda también).
    """

    /// La ayuda en inglés (`armonia help --ingles`).
    public static let help = """
    armonia: music theory from the command line.

    Usage: armonia <command> <arguments> [--ingles | --language es|en|ca|gl|eu]

    Commands:
      chord <symbol>…              notes, type and role of each note     armonia chord G7/B
      identify <notes>             chords formed by some notes           armonia identify C E G Bb
      interval <note> <note>       interval between two notes or pitches armonia interval C4 E5
      scale <scale>                notes and chords of a scale           armonia scale D dorian
      key <key>                    key signature, relatives and degrees  armonia key A minor
      analyze <chords> [--in <key>]
                                   roman numerals, functions, cadences
                                   and modulations (with their pivot
                                   chord; without --in)                  armonia analyze C F G7 C Am D7 G
      harmonize <melody> [--in <key>] [--proposals 3]
                                   chords for a melody, best first; with
                                   octaves (E4), also the four-part
                                   chorale                               armonia harmonize E4 F4 D4 C4
      realize <chords> [--in <key>]
                                   the chords in four parts, without
                                   voice-leading errors                  armonia realize C F G7 C
      check <chords>               voice-leading errors (parallel
                                   fifths…); chords from low to high,
                                   separated by commas                   armonia check C3 E4 G4 C5, G2 D4 G4 B4
      musicxml melody <events> [options]
                                   MusicXML score of a melody            armonia musicxml melody C4:4 D4:8 E4:8 F4:2 --compas 3/4 > melody.musicxml
      musicxml chorale <chords> [options]
                                   four-part chorale in MusicXML         armonia musicxml chorale C3 E4 G4 C5, G2 D4 G4 B4 > chorale.musicxml
      musicxml chords <symbols> [options]
                                   progression with symbols and analysis armonia musicxml chords C Am D7 G7 C > progression.musicxml
                                   options: --compas 6/8 (time signature), --anacrusa 8 (pickup),
                                   --tonalidad G major (key), --clave fa (clef), --tempo 90 (or
                                   --tempo 60 4.), --titulo My chorale (title), --duracion 2 (how
                                   long each chord lasts; a quarter note in the chorale and a half
                                   note in the chords by default), --cifrados and --analisis (in
                                   the chorale: chord symbols above, roman numerals and function below)
      midi melody|chorale|chords <…> [options]
                                   the same as a MIDI file, to listen to
                                   (without --clave or --cifrados; with
                                   --program 0…127, General MIDI)        armonia midi chords C Am D7 G7 C > progression.mid
      tonnetz <notes>              SVG Tonnetz of some notes             armonia tonnetz C E G B > tonnetz.svg
      tonnetz --chord <symbol> | --scale <scale> | --pcs <numbers>
                                   of a chord, a scale or a
                                   pitch-class set                       armonia tonnetz --scale D dorian > dorian.svg
      tonnetz --sequence <triads> | --shortest <triad> <triad>
                                   a sequence of triads, with arrows, or
                                   the shortest path through P, L and R  armonia tonnetz --sequence C Am F Dm > sequence.svg
      tonnetz --cycle <cycle> <triad>
                                   a hexatonic, octatonic or LR cycle    armonia tonnetz --cycle hexatonic C > cycle.svg
                                   (--margen 2: more grid around it)
      tabla <notes or pitches>     SVG harmonic table (hexagons)         armonia tabla C3 G3 E4 > table.svg
      tabla --chord <symbol> | --scale <scale> | --pcs <numbers>
      tabla --sequence <triads> | --shortest <triad> <triad>
      tabla --cycle <cycle> <triad>
                                   (--margen 2: more table around it)    armonia tabla --chord Cmaj7 > cmaj7.svg
      neighbors <chord> [--voices 2]
                                   chords a semitone away (sevenths: dominant, minor, half-diminished
                                   and diminished; triads: major, minor and augmented; a maj7, among
                                   the sevenths and the maj7s; --extended: with the maj7s too)
                                                                         armonia neighbors G7
      smooth-path <chord> <chord> [--voices 2] [--extended]
                                   from one chord to another moving one
                                   voice (or two) a semitone at a time   armonia smooth-path G7 Dm7
      voice-leading <chord> <chord>
                                   the voice leading with fewest semitones
                                                                         armonia voice-leading G7 C
      plr <triad> <P, L, R…>       neo-Riemannian transformations        armonia plr C PLR
      plr <triad> <triad>          the shortest path through P, L and R  armonia plr C Ebm
      plr <triad> <cycle>          a cycle: hexatonic (P, L),
                                   octatonic (P, R) or "LR cycle"        armonia plr C hexatonic
      fingerings <symbol>… [options]
                                   ways to play a chord, from the most comfortable to the least, on a
                                   fretted string instrument (strings from low to high)
                                   options: --instrument guitar|bass|ukulele|mandolin|…
                                   (also "seven-string guitar", "five-string bass",
                                   "drop D"), --limit 5, --fret 12 (the highest one used),
                                   --fingers 4 (how many can be used), --complete (with every note:
                                   by default the fifth may be left out), --diagram (one line per string)
                                                                         armonia fingerings G7/B --instrument ukulele
      help                         this help

    Note names are accepted in Spanish or English (Do, C, Sib, Bb). With --ingles, the answer
    uses English notation, and so do messages and this help. With --language ca, gl or eu, notes
    and messages are in Catalan, Galician or Basque (chord and scale names, and this help, in Spanish).
    """

    /// Ejecuta una orden con sus argumentos (sin el nombre del programa).
    public static func ejecutar(_ argumentos: [String]) -> ResultadoDeOrden {
        var argumentos = argumentos
        let ingles = argumentos.contains("--ingles") || argumentos.contains("--english")
        argumentos.removeAll { $0 == "--ingles" || $0 == "--english" }
        var notacion: Nomenclatura = ingles ? .ingles : .espanol
        if let i = argumentos.firstIndex(where: { $0 == "--idioma" || $0 == "--language" }) {
            guard i + 1 < argumentos.count else { return uso(.faltaValor(String(argumentos[i].dropFirst(2))), notacion) }
            guard let elegida = notacionDelIdioma(argumentos[i + 1]) else {
                return uso(.idiomaDesconocido(argumentos[i + 1]), notacion)
            }
            notacion = elegida
            argumentos.removeSubrange(i...(i + 1))
        }

        guard let orden = argumentos.first?.lowercased() else { return bien(ayuda(en: notacion)) }
        let resto = Array(argumentos.dropFirst())
        do {
            switch orden {
            case "ayuda", "help", "-h", "--help", "--ayuda":
                return bien(ayuda(en: notacion))
            case "acorde", "chord":
                guard !resto.isEmpty else { return uso(.faltaCifrado, notacion) }
                return bien(try resto.map { try describir(acorde: Acorde(leyendo: $0), notacion) }.joined(separator: "\n\n"))
            case "identificar", "identify":
                guard !resto.isEmpty else { return uso(.faltanNotas, notacion) }
                return bien(try identificar(resto, notacion))
            case "intervalo", "interval":
                guard resto.count == 2 else { return uso(.dosNotas, notacion) }
                return bien(try intervalo(resto[0], resto[1], notacion))
            case "escala", "scale":
                guard !resto.isEmpty else { return uso(.faltaEscala, notacion) }
                return bien(describir(escala: try Escala(leyendo: resto.joined(separator: " ")), notacion))
            case "tonalidad", "key":
                guard !resto.isEmpty else { return uso(.faltaTonalidad, notacion) }
                return bien(describir(tonalidad: try Tonalidad(leyendo: resto.joined(separator: " ")), notacion))
            case "analizar", "analyze", "analyse":
                return try analizar(resto, notacion)
            case "armonizar", "harmonize", "harmonise":
                return try armonizar(resto, notacion)
            case "realizar", "realize", "realise":
                return try realizar(resto, notacion)
            case "revisar", "check", "voces", "voices":
                guard !resto.isEmpty else { return uso(.faltanAcordesDeLasVoces, notacion) }
                return bien(describir(conduccion: try ConduccionDeVoces(leyendo: resto.joined(separator: " ")), notacion))
            case "tonnetz":
                return try tonnetz(resto, notacion)
            case "tabla", "tabla-armonica", "harmonic-table":
                return try tablaArmonica(resto, notacion)
            case "vecinos", "neighbors":
                return try vecinos(resto, notacion)
            case "conduccion-parsimoniosa", "conducción-parsimoniosa", "smooth-path", "camino", "path":
                return try caminoParsimonioso(resto, notacion)
            case "conduccion", "conducción", "voice-leading":
                guard resto.count == 2 else { return uso(.dosAcordesDeConduccion, notacion) }
                let conduccion = try Acorde(leyendo: resto[0]).conduccionMinima(hasta: try Acorde(leyendo: resto[1]))
                return bien(conduccion.texto(notacion))
            case "digitaciones", "digitacion", "digitación", "fingerings":
                return try digitaciones(resto, notacion)
            case "plr", "neorriemanniano", "neoriemannian":
                return try plr(resto, notacion)
            case "musicxml":
                return try partitura(resto, notacion, formato: .musicXML)
            case "midi":
                return try partitura(resto, notacion, formato: .midi)
            default:
                return uso(.ordenDesconocida(orden), notacion)
            }
        } catch let error as ErrorDeLectura {
            return ResultadoDeOrden(salida: "", error: error.descripcion(en: notacion) + "\n", codigo: 1)
        } catch {
            return ResultadoDeOrden(salida: "", error: "\(error)\n", codigo: 1)
        }
    }

    // MARK: Auxiliares

    static func binario(_ datos: Data) -> ResultadoDeOrden {
        ResultadoDeOrden(salida: "", error: "", codigo: 0, datos: datos)
    }

    static func bien(_ texto: String) -> ResultadoDeOrden {
        ResultadoDeOrden(salida: texto + "\n", error: "", codigo: 0)
    }

    static func uso(_ error: ErrorDeUso, _ notacion: Nomenclatura) -> ResultadoDeOrden {
        ResultadoDeOrden(salida: "", error: error.texto(en: notacion), codigo: 2)
    }

    /// La ayuda en el idioma de la notación: en inglés si los textos salen en inglés; si no, en español.
    public static func ayuda(en notacion: Nomenclatura) -> String {
        notacion.idiomaDeLosTextos == .ingles ? help : ayuda
    }

    /// La notación de `--idioma`: es, en, ca, gl o eu, o el nombre del idioma.
    static func notacionDelIdioma(_ texto: String) -> Nomenclatura? {
        switch texto.lowercased() {
        case "es", "espanol", "español", "castellano": return .espanol
        case "en", "ingles", "inglés", "english": return .ingles
        case "ca", "catalan", "catalán", "català": return .catalan
        case "gl", "gallego", "galego": return .gallego
        case "eu", "euskera", "euskara": return .euskera
        default: return nil
        }
    }
}
