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

    Uso: armonia <orden> <argumentos> [--ingles]

    Órdenes:
      acorde <cifrado>…            notas, tipo y papel de cada nota      armonia acorde Sol7/Si
      identificar <notas>          acordes que forman unas notas         armonia identificar Do Mi Sol Sib
      intervalo <nota> <nota>      intervalo entre dos notas o alturas   armonia intervalo Do4 Mi5
      escala <escala>              notas y acordes de una escala         armonia escala Re dórico
      tonalidad <tonalidad>        armadura, relativas y grados          armonia tonalidad La menor
      analizar <acordes> [--en <tonalidad>]
                                   cifrado romano y funciones            armonia analizar Do Lam Re7 Sol7 Do
      voces <acordes>              conducción de voces; acordes de
                                   grave a agudo, separados por comas    armonia voces Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4
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
                                   --instrumento 0…127, General MIDI)    armonia midi acordes Do Lam Re7 Sol7 Do > progresion.mid
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
      camino <acorde> <acorde> [--voces 2] [--ampliada]
                                   el camino más corto moviendo voces    armonia camino Sol7 Rem7
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
                                   por defecto la quinta puede faltar), --tab (con una tablatura)
                                                                         armonia digitaciones Sol7/Si --instrumento ukelele
      ayuda                        esta ayuda

    Se aceptan nombres en español o en inglés (Do, C, Sib, Bb). Con --ingles, la respuesta
    usa la notación inglesa.
    """

    /// Ejecuta una orden con sus argumentos (sin el nombre del programa).
    public static func ejecutar(_ argumentos: [String]) -> ResultadoDeOrden {
        var argumentos = argumentos
        let ingles = argumentos.contains("--ingles") || argumentos.contains("--english")
        argumentos.removeAll { $0 == "--ingles" || $0 == "--english" }
        let notacion: Nomenclatura = ingles ? .ingles : .espanol

        guard let orden = argumentos.first?.lowercased() else { return bien(ayuda) }
        let resto = Array(argumentos.dropFirst())
        do {
            switch orden {
            case "ayuda", "help", "-h", "--help", "--ayuda":
                return bien(ayuda)
            case "acorde", "chord":
                guard !resto.isEmpty else { return uso("falta el cifrado: armonia acorde Sol7") }
                return bien(try resto.map { try describir(acorde: Acorde(leyendo: $0), notacion) }.joined(separator: "\n\n"))
            case "identificar", "identify":
                guard !resto.isEmpty else { return uso("faltan las notas: armonia identificar Do Mi Sol") }
                return bien(try identificar(resto, notacion))
            case "intervalo", "interval":
                guard resto.count == 2 else { return uso("hacen falta dos notas: armonia intervalo Do Mi") }
                return bien(try intervalo(resto[0], resto[1], notacion))
            case "escala", "scale":
                guard !resto.isEmpty else { return uso("falta la escala: armonia escala Re dórico") }
                return bien(describir(escala: try Escala(leyendo: resto.joined(separator: " ")), notacion))
            case "tonalidad", "key":
                guard !resto.isEmpty else { return uso("falta la tonalidad: armonia tonalidad La menor") }
                return bien(describir(tonalidad: try Tonalidad(leyendo: resto.joined(separator: " ")), notacion))
            case "analizar", "analyze", "analyse":
                return try analizar(resto, notacion)
            case "voces", "voices":
                guard !resto.isEmpty else { return uso("faltan los acordes: armonia voces Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4") }
                return bien(describir(conduccion: try ConduccionDeVoces(leyendo: resto.joined(separator: " ")), notacion))
            case "tonnetz":
                return try tonnetz(resto, notacion)
            case "tabla", "tabla-armonica", "harmonic-table":
                return try tablaArmonica(resto, notacion)
            case "vecinos", "neighbors":
                return try vecinos(resto, notacion)
            case "camino", "path":
                return try caminoParsimonioso(resto, notacion)
            case "conduccion", "conducción", "voice-leading":
                guard resto.count == 2 else { return uso("hacen falta dos acordes: armonia conduccion Sol7 Do") }
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
                return uso("orden desconocida: «\(orden)»")
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

    static func uso(_ mensaje: String) -> ResultadoDeOrden {
        ResultadoDeOrden(salida: "", error: "armonia: \(mensaje)\nPrueba «armonia ayuda».\n", codigo: 2)
    }
}
