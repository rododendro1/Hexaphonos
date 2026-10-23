import Foundation

// Protocolos comunes del motor.
//
// Lo que antes se repetía tipo por tipo (lectura de texto, literales, Codable, nombres en
// dos idiomas, transposición, clases de altura) se declara aquí una sola vez:
//
//  · RepresentableComoTexto: se lee con `init(leyendo:)` y se escribe con `texto(_:)`.
//    A cambio recibe `init?(_:)`, el literal de texto y Codable.
//  · Nombrable: nombre para personas en español o inglés (`nombre(en:)`).
//  · Transponible: `transponer(_:)`, y con ello los operadores + y − y las secuencias.
//  · ConClasesDeAltura: `conjuntoDeClases`, y con ello número de Forte y vector interválico.

// MARK: - RepresentableComoTexto

/// Un valor que se lee y se escribe como texto, sin pérdida: `T(leyendo: x.texto(n)) == x`
/// para cualquier notación `n`.
public protocol RepresentableComoTexto: Codable, ExpressibleByStringLiteral where StringLiteralType == String {
    /// Lee un texto. Si no se puede, lanza `ErrorDeLectura` con la posición y el motivo.
    init(leyendo texto: String) throws
    /// Escribe el valor en una notación; `init(leyendo:)` lo vuelve a leer igual.
    func texto(_ notacion: Nomenclatura) -> String
}

extension RepresentableComoTexto {
    /// Texto en la notación española (la que se usa al codificar).
    public var texto: String { texto(.espanol) }

    /// Como `init(leyendo:)`, devolviendo `nil` en lugar de un error: `Acorde(texto: entrada)`.
    ///
    /// Lleva etiqueta a propósito. Swift convierte `Acorde("Sol7")` en el literal de texto
    /// (SE-0213), que no es opcional; sin etiqueta, `Acorde("…")` sería opcional con una
    /// variable y no con un literal.
    public init?(texto: String) {
        guard let valor = try? Self(leyendo: texto) else { return nil }
        self = valor
    }

    /// Literal de texto: `let a: Acorde = "Sol7/Si"`. Un literal no válido es un error de
    /// programación y detiene la ejecución con el mensaje de `ErrorDeLectura`.
    public init(stringLiteral texto: String) {
        do { self = try Self(leyendo: texto) } catch { preconditionFailure("\(error)") }
    }

    /// Se decodifica desde su texto; el error de lectura acompaña al de decodificación.
    public init(from decoder: Decoder) throws {
        let contenedor = try decoder.singleValueContainer()
        let texto = try contenedor.decode(String.self)
        do {
            self = try Self(leyendo: texto)
        } catch let error as ErrorDeLectura {
            throw DecodingError.dataCorruptedError(in: contenedor, debugDescription: error.description)
        }
    }

    /// Se codifica como su texto en notación española ("Fa♯4", "-5d", "Sol7(♭9)/Si").
    public func encode(to encoder: Encoder) throws {
        var contenedor = encoder.singleValueContainer()
        try contenedor.encode(texto(.espanol))
    }
}

// MARK: - Nombrable

/// Un valor con nombre para personas, en la notación que se pida:
/// `nombre(en: .espanol)` → "Re dórico", `nombre(en: .ingles)` → "D dorian".
public protocol Nombrable {
    func nombre(en notacion: Nomenclatura) -> String
}

// MARK: - Transponible

/// Un valor que se puede transponer por un intervalo.
public protocol Transponible {
    func transponer(_ intervalo: Intervalo) -> Self
}

extension Transponible {
    public static func + (valor: Self, intervalo: Intervalo) -> Self { valor.transponer(intervalo) }
    public static func - (valor: Self, intervalo: Intervalo) -> Self { valor.transponer(-intervalo) }

    /// Transpone `veces` veces el mismo intervalo: Do, 12 quintas → Si♯.
    public func transponer(_ intervalo: Intervalo, veces: Int) -> Self { transponer(veces * intervalo) }

    /// El valor y sus transposiciones sucesivas: `Nota.do.secuencia(.quintaJusta, veces: 3)`
    /// → [Do, Sol, Re, La].
    public func secuencia(_ intervalo: Intervalo, veces: Int) -> [Self] {
        (0...max(0, veces)).map { transponer(intervalo, veces: $0) }
    }
}

// MARK: - ConClasesDeAltura

/// Un valor que ocupa un conjunto de clases de altura (acordes, escalas, melodías…).
public protocol ConClasesDeAltura {
    var conjuntoDeClases: ConjuntoDeClases { get }
}

extension ConClasesDeAltura {
    /// Número de Forte de sus clases de altura: Sol7 → "4-27", cualquier escala mayor → "7-35".
    public var numeroDeForte: String? { conjuntoDeClases.numeroDeForte }

    public var vectorIntervalico: [Int] { conjuntoDeClases.vectorIntervalico }

    /// Mismo número de Forte (uno es transposición o inversión del otro), aunque sean de tipos
    /// distintos: `Acorde("Do").esDeLaMismaClase(que: Acorde("Lam"))` → `true` (3-11).
    public func esDeLaMismaClase(que otro: some ConClasesDeAltura) -> Bool {
        conjuntoDeClases.formaPrima == otro.conjuntoDeClases.formaPrima
    }
}
