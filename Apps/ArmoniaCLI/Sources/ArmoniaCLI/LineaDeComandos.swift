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
    /// La ayuda en español (`armonia ayuda`). Todas salen de la tabla de `Ayuda.swift`.
    public static let ayuda = textoDeAyuda(en: .espanol)
    /// La ayuda en inglés (`armonia help --ingles`).
    public static let help = textoDeAyuda(en: .ingles)
    /// La ayuda en catalán (`armonia ayuda --idioma ca`).
    public static let ajuda = textoDeAyuda(en: .catalan)
    /// La ayuda en gallego (`armonia ayuda --idioma gl`).
    public static let axuda = textoDeAyuda(en: .gallego)
    /// La ayuda en euskera (`armonia ayuda --idioma eu`).
    public static let laguntza = textoDeAyuda(en: .euskera)
    /// La ayuda en portugués (`armonia ayuda --idioma pt`).
    public static let ajudaEmPortugues = textoDeAyuda(en: .portugues)
    /// La ayuda en francés (`armonia ayuda --idioma fr`).
    public static let aide = textoDeAyuda(en: .frances)
    /// La ayuda en italiano (`armonia ayuda --idioma it`).
    public static let aiuto = textoDeAyuda(en: .italiano)

    /// Ejecuta una orden con sus argumentos (sin el nombre del programa).
    public static func ejecutar(_ argumentos: [String]) -> ResultadoDeOrden {
        var opciones = Argumentos(argumentos)
        var notacion: Notacion = opciones.quitarMarca("--ingles", "--english") ? .ingles : .espanol
        switch opciones.quitarOpcion("--idioma", "--language") {
        case .ausente:
            break
        case .sinValor(let nombre):
            return uso(.faltaValor(nombre), notacion)
        case .valor(let texto):
            guard let elegida = notacionDelIdioma(texto) else { return uso(.idiomaDesconocido(texto), notacion) }
            notacion = elegida
        }
        switch opciones.quitarOpcion("--textos", "--texts") {
        case .ausente:
            break
        case .sinValor(let nombre):
            return uso(.faltaValor(nombre), notacion)
        case .valor(let texto):
            guard let textos = notacionDelIdioma(texto)?.idiomaDeLasNotas else { return uso(.idiomaDesconocido(texto), notacion) }
            notacion = notacion.conTextos(en: textos)
        }
        let argumentos = opciones.restantes

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
            case "revisar", "check":
                return try revisar(resto, notacion)
            case "tonnetz":
                return try tonnetz(resto, notacion)
            case "tabla", "harmonic-table":
                return try tablaArmonica(resto, notacion)
            case "vecinos", "neighbors":
                return try vecinos(resto, notacion)
            case "conduccion-parsimoniosa", "conducción-parsimoniosa", "smooth-path":
                return try caminoParsimonioso(resto, notacion)
            case "conduccion-minima", "conducción-mínima", "minimal-voice-leading":
                guard resto.count == 2 else { return uso(.dosAcordesDeConduccion, notacion) }
                let conduccion = try Acorde(leyendo: resto[0]).conduccionMinima(hasta: try Acorde(leyendo: resto[1]))
                return bien(conduccion.texto(en: notacion))
            case "digitaciones", "digitacion", "digitación", "fingerings":
                return try digitaciones(resto, notacion)
            case "plr", "neoriemannian":
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

    static func uso(_ error: ErrorDeUso, _ notacion: Notacion) -> ResultadoDeOrden {
        ResultadoDeOrden(salida: "", error: error.texto(en: notacion), codigo: 2)
    }

    /// La ayuda en el idioma de los textos de la notación (`Notacion.textos`).
    public static func ayuda(en notacion: Notacion) -> String {
        switch notacion.textos {
        case .ingles, .aleman, .occitano, .ruso, .griego: return help
        case .catalan: return ajuda
        case .gallego: return axuda
        case .euskera: return laguntza
        case .portugues: return ajudaEmPortugues
        case .frances: return aide
        case .italiano: return aiuto
        case .espanol: return ayuda
        }
    }

    /// La notación de `--idioma`: es, en, ca, gl, eu, pt, fr o it, o el nombre del idioma.
    static func notacionDelIdioma(_ texto: String) -> Notacion? {
        switch texto.lowercased() {
        case "es", "espanol", "español", "castellano": return .espanol
        case "en", "ingles", "inglés", "english": return .ingles
        case "ca", "catalan", "catalán", "català": return .catalan
        case "gl", "gallego", "galego": return .gallego
        case "eu", "euskera", "euskara": return .euskera
        case "pt", "portugues", "portugués", "português": return .portugues
        case "fr", "frances", "francés", "français", "francais": return .frances
        case "it", "italiano": return .italiano
        default: return nil
        }
    }
}
