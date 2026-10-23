import ArmoniaNucleo
import ArmoniaTeoria
// MARK: - Color

/// Un color en RGB, de 0 a 255 por componente.
///
///     ColorRGB(hexadecimal: "#FF8000")!.verde   // 128
///     ColorRGB(rojo: 255, verde: 0, azul: 0).hexadecimal   // "#FF0000"
///     ColorRGB(tono: 120, saturacion: 1, brillo: 1)        // verde puro
public struct ColorRGB: Hashable, Sendable, CustomStringConvertible {
    public let rojo: Int
    public let verde: Int
    public let azul: Int

    /// Componentes de 0 a 255 (los valores fuera de rango se recortan).
    public init(rojo: Int, verde: Int, azul: Int) {
        func recortar(_ x: Int) -> Int { min(255, max(0, x)) }
        self.rojo = recortar(rojo)
        self.verde = recortar(verde)
        self.azul = recortar(azul)
    }

    /// Lee "#RRGGBB" o "RRGGBB". `nil` si no son seis cifras hexadecimales.
    public init?(hexadecimal texto: String) {
        let cifras = texto.hasPrefix("#") ? String(texto.dropFirst()) : texto
        guard cifras.count == 6, cifras.allSatisfy(\.isHexDigit), let valor = Int(cifras, radix: 16) else { return nil }
        self.init(rojo: (valor >> 16) & 0xFF, verde: (valor >> 8) & 0xFF, azul: valor & 0xFF)
    }

    /// Color a partir de tono (en grados: 0 rojo, 120 verde, 240 azul), saturación y brillo (0…1).
    public init(tono: Double, saturacion: Double, brillo: Double) {
        let h = (tono.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) / 60
        let c = brillo * saturacion
        let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))
        let (r, g, b): (Double, Double, Double)
        switch Int(h) {
        case 0: (r, g, b) = (c, x, 0)
        case 1: (r, g, b) = (x, c, 0)
        case 2: (r, g, b) = (0, c, x)
        case 3: (r, g, b) = (0, x, c)
        case 4: (r, g, b) = (x, 0, c)
        default: (r, g, b) = (c, 0, x)
        }
        let m = brillo - c
        func componente(_ v: Double) -> Int { Int(((v + m) * 255).rounded()) }
        self.init(rojo: componente(r), verde: componente(g), azul: componente(b))
    }

    /// "#RRGGBB" en mayúsculas.
    public var hexadecimal: String {
        let cifras = Array("0123456789ABCDEF")
        func par(_ v: Int) -> String { String([cifras[v / 16], cifras[v % 16]]) }
        return "#" + par(rojo) + par(verde) + par(azul)
    }

    public var description: String { hexadecimal }
}

// MARK: - CorrespondenciaDeColores

/// Correspondencias históricas entre notas y colores. No son sinestesia, que es un fenómeno de
/// la percepción, sino sistemas propuestos para asociar sonido y color.
///
/// - `newton`: los siete colores del espectro sobre las siete notas naturales (*Opticks*, 1704),
///   en la lectura habitual Do rojo … Si violeta. Las alteraciones no cambian el color.
/// - `castel`: el «clave ocular» de Louis-Bertrand Castel (1734), doce colores por clase de
///   altura empezando por Do azul.
/// - `scriabin`: el *clavier à lumières* de Prometeo (1911), ordenado por el círculo de quintas.
/// - `circuloDeQuintas`: el círculo cromático sobre el círculo de quintas, 30° por quinta,
///   con Do en rojo (0°), Sol en naranja, Re en amarillo…
///
/// Las fuentes históricas dan nombres de colores, no valores exactos; los colores RGB son una
/// interpretación de esos nombres, que se pueden consultar con `nombreDelColor(de:)`.
///
///     Nota.re.color(segun: .scriabin)          // #FFFF00 (amarillo)
///     CorrespondenciaDeColores.scriabin.nombreDelColor(de: .mi)      // "azul cielo (luz de luna o escarcha)"
///     Acorde("Do").colores(segun: .circuloDeQuintas)  // [#FF0000, #00FF00, #FF8000]
public enum CorrespondenciaDeColores: Hashable, Sendable, CaseIterable, CustomStringConvertible {
    case newton, castel, scriabin, circuloDeQuintas

    public var description: String { nombre }

    /// Color de un nombre de nota.
    public func color(de nota: Nota) -> ColorRGB {
        switch self {
        case .newton:
            return ColorRGB(hexadecimal: CorrespondenciaDeColores.tablaNewton[nota.natural.rawValue].hex)!
        case .castel:
            return ColorRGB(hexadecimal: CorrespondenciaDeColores.tablaCastel[nota.claseDeAltura].hex)!
        case .scriabin:
            return ColorRGB(hexadecimal: CorrespondenciaDeColores.tablaScriabin[nota.claseDeAltura].hex)!
        case .circuloDeQuintas:
            return ColorRGB(tono: Double(modulo(nota.pasosDeQuinta, 12) * 30), saturacion: 1, brillo: 1)
        }
    }

    /// Nombre del color según la fuente: "rojo intenso", "añil"… `nil` en `circuloDeQuintas`,
    /// que no procede de ninguna fuente histórica.
    public func nombreDelColor(de nota: Nota) -> String? {
        switch self {
        case .newton: return CorrespondenciaDeColores.tablaNewton[nota.natural.rawValue].nombre
        case .castel: return CorrespondenciaDeColores.tablaCastel[nota.claseDeAltura].nombre
        case .scriabin: return CorrespondenciaDeColores.tablaScriabin[nota.claseDeAltura].nombre
        case .circuloDeQuintas: return nil
        }
    }

    /// Do, Re, Mi, Fa, Sol, La, Si.
    package static let tablaNewton: [(nombre: String, hex: String)] = [
        ("rojo", "#FF0000"), ("naranja", "#FF7F00"), ("amarillo", "#FFFF00"), ("verde", "#00FF00"),
        ("azul", "#0000FF"), ("añil", "#4B0082"), ("violeta", "#8B00FF"),
    ]

    /// Clases de altura 0…11 (Do, Do♯, Re…).
    package static let tablaCastel: [(nombre: String, hex: String)] = [
        ("azul", "#0000FF"), ("azul verdoso", "#0D98BA"), ("verde", "#00A651"), ("verde oliva", "#808000"),
        ("amarillo", "#FFFF00"), ("amarillo anaranjado", "#FFBF00"), ("naranja", "#FF7F00"), ("rojo", "#FF0000"),
        ("carmesí", "#DC143C"), ("violeta", "#8F00FF"), ("ágata", "#A0785A"), ("añil", "#4B0082"),
    ]

    /// Clases de altura 0…11 (Do, Do♯, Re…).
    package static let tablaScriabin: [(nombre: String, hex: String)] = [
        ("rojo intenso", "#FF0000"), ("violeta o púrpura", "#8F00FF"), ("amarillo", "#FFFF00"),
        ("carne (con brillo de acero)", "#D8B4A0"), ("azul cielo (luz de luna o escarcha)", "#87CEEB"),
        ("rojo oscuro", "#8B0000"), ("azul brillante o violeta", "#0080FF"), ("naranja", "#FF8000"),
        ("violeta o lila", "#C8A2C8"), ("verde", "#00C000"), ("rosa o acero", "#C08090"),
        ("azul nacarado", "#8EB8E5"),
    ]
}

extension CorrespondenciaDeColores: Nombrable {}

// MARK: - Colores de notas, acordes y escalas

extension Nota {
    /// Color de la nota según una correspondencia: `Nota.do.color(segun: .newton)` → rojo.
    public func color(segun correspondencia: CorrespondenciaDeColores) -> ColorRGB { correspondencia.color(de: self) }
}

extension Altura {
    /// Color de la nota (no depende de la octava).
    public func color(segun correspondencia: CorrespondenciaDeColores) -> ColorRGB { correspondencia.color(de: nota) }
}

extension Acorde {
    /// Colores de las notas del acorde, en orden de disposición (desde la fundamental).
    public func colores(segun correspondencia: CorrespondenciaDeColores) -> [ColorRGB] { notas.map(correspondencia.color(de:)) }
}

extension Escala {
    /// Colores de las notas de la escala, desde la tónica.
    public func colores(segun correspondencia: CorrespondenciaDeColores) -> [ColorRGB] { notas.map(correspondencia.color(de:)) }
}
