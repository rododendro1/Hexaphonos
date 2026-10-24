import Foundation

/// Altura: una nota con su octava (Do4, Fa♯3), codificada como un punto del plano
/// (quintas, octavas) con origen en el Do central (Do4, MIDI 60). Es lo que la teoría llama
/// también sonido; la nota sin octava es `Nota`.
///
/// La altura con coordenadas (q, o) es la que se alcanza desde Do4 subiendo
/// `q` quintas justas y `o` octavas justas (valores negativos = bajar):
///
///  * MIDI            = 60 + 7·q + 12·o
///  * pasos desde Do4 = 4·q + 7·o
///
/// Ejemplos: Do4 = (0, 0), Sol4 = (1, 0), Re4 = (2, −1), La4 = (3, −1), Fa4 = (−1, 1).
/// La coordenada `pasosDeQuinta` coincide con la de su `Nota`, así que la ortografía
/// se conserva: Fa♯4 y Sol♭4 tienen el mismo MIDI pero son alturas distintas.

public struct Altura: Hashable, Sendable {
    public let pasosDeQuinta: Int
    public let pasosDeOctava: Int

    public init(pasosDeQuinta: Int, pasosDeOctava: Int) {
        self.pasosDeQuinta = pasosDeQuinta
        self.pasosDeOctava = pasosDeOctava
    }

    /// `Altura(.do, octava: 4)` es el Do central. Octava en notación científica:
    /// la octava cambia en Do, y Do♭4 está un semitono por debajo de Do4.
    public init(_ nombre: Nota, octava: Int) {
        let pasos = (octava - 4) * 7 + nombre.natural.indiceDiatonico
        self.init(pasosDeQuinta: nombre.pasosDeQuinta, pasosDeOctava: (pasos - 4 * nombre.pasosDeQuinta) / 7)
    }

    /// Lee textos como "Do4", "Fa#3", "Sib-1", "C#5".
    /// Si no se puede leer, el error indica dónde y por qué.
    /// También acepta los nombres en catalán, gallego, euskera, portugués, occitano, ruso y griego:
    /// "re bemoll 4", "fa sostido 3", "fá sustenido 3", "фа-диез 3", "σι ύφεση 4".
    public init(leyendo texto: String) throws {
        var lector = Lector(texto)
        try lector.exigirContenido()
        let leida: Altura
        do {
            guard let nombre = lector.leerNombreNota() else { throw lector.error(.notaNoReconocida) }
            lector.saltarEspacios()
            let textoOctava = lector.restoSinEspacios
            guard let octava = Int(textoOctava) else { throw lector.error(.octavaNoValida(textoOctava)) }
            leida = Altura(nombre, octava: octava)
        } catch {
            let peninsulares = Nomenclatura.deLecturaGenerica.lazy.compactMap { try? Altura(leyendo: texto, en: $0) }
            guard let nota = peninsulares.first else { throw error }
            leida = nota
        }
        self = leida
    }

    /// Lee una nota escrita en una notación concreta: `Altura(leyendo: "Fis4", en: .aleman)`,
    /// `Altura(leyendo: "ré bémol 3", en: .frances)`. La octava es la científica (Do4 = do central).
    public init(leyendo texto: String, en notacion: Nomenclatura) throws {
        let notacion = notacion.notas
        switch notacion.escritura {
        case .aleman, .frances, .italiano, .catalan, .gallego, .euskera, .portugues, .occitano, .ruso, .griego:
            let limpio = texto.trimmingEspacios()
            let cifras = limpio.reversed().prefix(while: { $0.isNumber || $0 == "-" })
            let textoOctava = String(cifras.reversed())
            let parteNombre = String(limpio.dropLast(cifras.count)).trimmingEspacios()
            guard let octava = Int(textoOctava) else {
                throw ErrorDeLectura(texto: texto, posicion: nil, motivo: .octavaNoValida(textoOctava))
            }
            do {
                self.init(try Nota(leyendo: parteNombre, en: notacion), octava: octava)
            } catch let error as ErrorDeLectura {
                throw ErrorDeLectura(texto: texto, posicion: 0, motivo: error.motivo)
            }
        case .espanol, .espanolASCII, .ingles, .inglesUnicode:
            try self.init(leyendo: texto)
        }
    }

    /// Altura a partir de un número MIDI, eligiendo la ortografía más habitual:
    /// con sostenidos de Fa a La♯, o con bemoles de Sol♭ a Si.
    public init(midi: Int, preferirBemoles: Bool = false) {
        let pc = modulo(midi, 12)
        let q0 = modulo(pc * 7, 12)            // 7 es su propio inverso módulo 12
        let inicio = preferirBemoles ? -6 : -1
        let q = inicio + modulo(q0 - inicio, 12)
        self.init(pasosDeQuinta: q, pasosDeOctava: (midi - 60 - 7 * q) / 12)
    }

    // MARK: Propiedades

    /// La nota sin octava: Fa♯4 → Fa♯.
    public var nota: Nota { Nota(pasosDeQuinta: pasosDeQuinta) }

    /// Pasos diatónicos desde Do4 (Re4 = 1, Si3 = −1).
    public var pasos: Int { 4 * pasosDeQuinta + 7 * pasosDeOctava }

    /// Octava en notación científica (Do4 = Do central), la misma de `Altura(_:octava:)`.
    /// No confundir con la coordenada `pasosDeOctava`: La4 está en la octava 4 y tiene
    /// coordenadas (3, −1).
    public var octava: Int { 4 + divisionEntera(pasos, 7) }

    public var midi: Int { 60 + 7 * pasosDeQuinta + 12 * pasosDeOctava }

    /// Frecuencia en temperamento igual.
    public func frecuencia(la4: Double = 440) -> Double {
        la4 * pow(2, Double(midi - 69) / 12)
    }

    /// "Fa♯4".
    public var nombreCompleto: String { nombre(en: .espanol) }

    /// Nombre con octava en la notación indicada: "Fa♯4", "F#4", `.inglesUnicode` → "F♯4".
    /// Nombre en español: "Fa♯4".
    public var nombre: String { nombre(en: .espanol) }

    /// Nombre con octava (científica en todas las notaciones): "Fa♯4", "F#4", "Fis4",
    /// "fa dièse 4" (con espacio cuando el nombre tiene varias palabras).
    public func nombre(en notacion: Nomenclatura) -> String {
        let nombre = nota.nombre(en: notacion)
        return nombre + (nombre.contains(" ") ? " " : "") + "\(octava)"
    }

    // MARK: Operaciones

    public func transponer(_ intervalo: Intervalo) -> Altura {
        Altura(pasosDeQuinta: pasosDeQuinta + intervalo.pasosDeQuintaConSigno,
             pasosDeOctava: pasosDeOctava + intervalo.pasosDeOctavaConSigno)
    }

    /// Intervalo (con dirección) desde esta nota hasta `otra`.
    public func intervalo(hasta otra: Altura) -> Intervalo {
        Intervalo(pasosDeQuinta: otra.pasosDeQuinta - pasosDeQuinta, pasosDeOctava: otra.pasosDeOctava - pasosDeOctava)
    }

    public func esEnarmonica(de otra: Altura) -> Bool { midi == otra.midi }

    /// `b - a` es el intervalo que va de `a` a `b`.
    public static func - (b: Altura, a: Altura) -> Intervalo { a.intervalo(hasta: b) }

    public static let doCentral = Altura(pasosDeQuinta: 0, pasosDeOctava: 0)
    public static let la440 = Altura(pasosDeQuinta: 3, pasosDeOctava: -1)
}

extension Altura: Comparable {
    /// Ordena por altura; a igual altura, por posición diatónica (Si♯3 < Do4).
    public static func < (a: Altura, b: Altura) -> Bool {
        a.midi != b.midi ? a.midi < b.midi : a.pasos < b.pasos
    }
}

extension Altura: CustomStringConvertible {
    public var description: String { nombreCompleto }
}

extension Altura {
    /// Altura con un nombre dado y un número MIDI dado, si son compatibles:
    /// `Altura(Nota("Sol#"), midi: 68)` → Sol♯4; `Altura(.la, midi: 68)` → `nil`.
    public init?(_ nombre: Nota, midi: Int) {
        guard nombre.claseDeAltura == modulo(midi, 12) else { return nil }
        self.init(pasosDeQuinta: nombre.pasosDeQuinta, pasosDeOctava: (midi - 60 - 7 * nombre.pasosDeQuinta) / 12)
    }
}

extension Altura {
    /// Altura con un nombre dado a una distancia diatónica de Do4 (debe coincidir la letra).
    package init(_ nombre: Nota, pasos: Int) {
        self.init(pasosDeQuinta: nombre.pasosDeQuinta, pasosDeOctava: (pasos - 4 * nombre.pasosDeQuinta) / 7)
    }
}

extension Altura: RepresentableComoTexto, Nombrable, Transponible {
    public func texto(_ notacion: Nomenclatura) -> String { nombre(en: notacion) }
}
