import ArmoniaNucleo
import ArmoniaTeoria
import Foundation

// Afinaciones y temperamentos.
//
// Las coordenadas (quintas, octavas) encajan de forma natural con los temperamentos
// regulares: en todos ellos la octava es pura y todas las quintas miden lo mismo, así que
// una nota queda afinada con un solo número, el tamaño de la quinta:
//
//     cents(nota) = quintas · quinta + octavas · 1200      (desde Do4)
//
// Con quinta = 700 sale el temperamento igual; con 701,955, el pitagórico; con
// 696,578 (¼ de coma), el mesotónico, cuyas terceras mayores son puras.

/// Una forma de dar frecuencia a cada nota.
public protocol Afinacion: Sendable {
    func frecuencia(de nota: Altura) -> Double
}

extension Afinacion {
    /// Distancia en cents entre dos notas en esta afinación.
    public func cents(desde a: Altura, hasta b: Altura) -> Double {
        1200 * log2(frecuencia(de: b) / frecuencia(de: a))
    }

    /// Cuánto se aparta una nota (en cents) de la misma nota en temperamento igual con La4 = 440.
    public func desviacion(de nota: Altura) -> Double {
        1200 * log2(frecuencia(de: nota) / nota.frecuencia())
    }
}

extension Altura {
    /// Frecuencia en una afinación cualquiera: `nota.frecuencia(en: .mesotonicoCuartoDeComa)`.
    public func frecuencia(en afinacion: some Afinacion) -> Double {
        afinacion.frecuencia(de: self)
    }
}

// MARK: - Temperamentos regulares

/// Temperamento regular: octava pura y todas las quintas del mismo tamaño.
public struct TemperamentoRegular: Afinacion, Hashable {
    public let nombre: String
    /// Tamaño de la quinta en cents.
    public let quinta: Double
    /// Frecuencia del La4 de referencia.
    public let la4: Double

    public init(nombre: String, quinta: Double, la4: Double = 440) {
        self.nombre = nombre
        self.quinta = quinta
        self.la4 = la4
    }

    /// Cents desde Do4.
    public func cents(de nota: Altura) -> Double {
        Double(nota.pasosDeQuinta) * quinta + Double(nota.pasosDeOctava) * 1200
    }

    /// Tamaño de un intervalo en cents (con signo).
    public func cents(de intervalo: Intervalo) -> Double {
        Double(intervalo.pasosDeQuintaConSigno) * quinta + Double(intervalo.pasosDeOctavaConSigno) * 1200
    }

    public func frecuencia(de nota: Altura) -> Double {
        // La4 está en (3, −1).
        la4 * pow(2, (cents(de: nota) - cents(de: .la440)) / 1200)
    }

    /// El mismo temperamento con otra frecuencia de referencia: `.igual.afinar(la4: 415)`.
    public func afinar(la4 frecuencia: Double) -> TemperamentoRegular {
        TemperamentoRegular(nombre: nombre, quinta: quinta, la4: frecuencia)
    }

    /// Temperamento igual de `divisiones` partes por octava, con la quinta en el paso más cercano
    /// a la quinta pura: `.igual(divisiones: 12)` es `.igual`; 19, 31 (casi mesotónico),
    /// 53 (casi pitagórico).
    public static func igual(divisiones: Int, la4: Double = 440) -> TemperamentoRegular {
        let pasos = (Double(divisiones) * log2(1.5)).rounded()
        return TemperamentoRegular(nombre: "\(divisiones) divisiones iguales",
                                   quinta: 1200 * pasos / Double(divisiones), la4: la4)
    }

    /// Mesotónico de 1/`fraccion` de coma sintónica: cada quinta se estrecha esa parte de la coma.
    public static func mesotonico(fraccionDeComa fraccion: Double, la4: Double = 440) -> TemperamentoRegular {
        let pura = 1200 * log2(1.5)
        let coma = 1200 * log2(81.0 / 80.0)
        return TemperamentoRegular(nombre: "mesotónico de 1/\(Int(fraccion)) de coma",
                                   quinta: pura - coma / fraccion, la4: la4)
    }

    public static let igual = TemperamentoRegular(nombre: "temperamento igual", quinta: 700)
    public static let pitagorico = TemperamentoRegular(nombre: "pitagórico", quinta: 1200 * log2(1.5))
    /// Terceras mayores puras (5/4).
    public static let mesotonicoCuartoDeComa = mesotonico(fraccionDeComa: 4)
    /// Terceras menores puras (6/5).
    public static let mesotonicoTercioDeComa = mesotonico(fraccionDeComa: 3)
    public static let mesotonicoSextoDeComa = mesotonico(fraccionDeComa: 6)
}

// MARK: - Afinación justa

/// Afinación justa de 5 límites relativa a una tónica: las notas se afinan con razones de
/// los números 2, 3 y 5 (5/4, 6/5, 3/2…).
///
/// Una nota escrita no determina por sí sola su razón justa (Mi puede ser 81/64 o 5/4 sobre
/// Do). Aquí, cada nota a `q` quintas de la tónica sustituye ⌊(q + 1) / 4⌋ grupos de cuatro
/// quintas por terceras puras, que es la afinación de Ptolomeo de la escala mayor:
/// 1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8.
public struct EntonacionJusta: Afinacion, Hashable {
    public let tonica: Nota
    /// Frecuencia de la tónica en la octava 4.
    public let frecuenciaTonica: Double

    /// La tónica en la octava 4 toma su frecuencia en temperamento igual con el La4 dado.
    public init(tonica: Nota, la4: Double = 440) {
        self.tonica = tonica
        self.frecuenciaTonica = Altura(tonica, octava: 4).frecuencia(la4: la4)
    }

    public init(tonica: Nota, frecuenciaTonica: Double) {
        self.tonica = tonica
        self.frecuenciaTonica = frecuenciaTonica
    }

    public func frecuencia(de nota: Altura) -> Double {
        let referencia = Altura(tonica, octava: 4)
        return frecuenciaTonica * Intervalo(pasosDeQuinta: nota.pasosDeQuinta - referencia.pasosDeQuinta,
                                            pasosDeOctava: nota.pasosDeOctava - referencia.pasosDeOctava).razonJusta.valor
    }
}

/// Razón de frecuencias como fracción (5/4, 3/2, 45/32…).
public struct RazonDeFrecuencias: Hashable, Sendable, CustomStringConvertible {
    public let numerador: Double
    public let denominador: Double

    public init(_ numerador: Double, _ denominador: Double) {
        self.numerador = numerador
        self.denominador = denominador
    }

    public var valor: Double { numerador / denominador }
    public var cents: Double { 1200 * log2(valor) }

    public var description: String {
        func entero(_ x: Double) -> String {
            x.rounded() == x && abs(x) < 1e15 ? String(Int64(x)) : String(x)
        }
        return "\(entero(numerador))/\(entero(denominador))"
    }

    /// Coma sintónica (81/80): la diferencia entre cuatro quintas puras y una tercera pura.
    public static let comaSintonica = RazonDeFrecuencias(81, 80)
    /// Coma pitagórica (531441/524288): doce quintas puras frente a siete octavas.
    public static let comaPitagorica = RazonDeFrecuencias(531_441, 524_288)
}

extension Intervalo {
    /// Razón justa de 5 límites del intervalo, con el mismo criterio que `EntonacionJusta`
    /// (como si la nota grave fuera la tónica): 3ª mayor → 5/4, 3ª menor → 6/5,
    /// 7ª mayor → 15/8, 4ª aumentada → 45/32. Si el intervalo desciende, la razón es menor que 1.
    public var razonJusta: RazonDeFrecuencias {
        let q = pasosDeQuintaConSigno
        let o = pasosDeOctavaConSigno
        let terceras = divisionEntera(q + 1, 4)
        let exponentes = [(3.0, q - 4 * terceras), (5.0, terceras), (2.0, o - q + 4 * terceras)]
        var numerador = 1.0, denominador = 1.0
        for (base, exponente) in exponentes {
            if exponente >= 0 { numerador *= pow(base, Double(exponente)) }
            else { denominador *= pow(base, Double(-exponente)) }
        }
        return RazonDeFrecuencias(numerador, denominador)
    }

    /// Tamaño en cents en un temperamento (temperamento igual por defecto).
    public func cents(en temperamento: TemperamentoRegular = .igual) -> Double {
        temperamento.cents(de: self)
    }
}
