import ArmoniaNucleo
import ArmoniaTeoria

/// Un sitio del mástil: una cuerda y un traste (0 = cuerda al aire).
public struct PosicionEnElMastil: Hashable, Sendable, Comparable, CustomStringConvertible {
    /// Índice de la cuerda en el `Encordado`: 0 es la primera.
    public let cuerda: Int
    public let traste: Int

    public init(cuerda: Int, traste: Int) {
        self.cuerda = cuerda
        self.traste = traste
    }

    public static func < (a: PosicionEnElMastil, b: PosicionEnElMastil) -> Bool {
        (a.traste, a.cuerda) < (b.traste, b.cuerda)
    }

    public var description: String { "cuerda \(cuerda + 1), traste \(traste)" }
}

/// El mástil de un instrumento: un `Encordado` y su número de trastes.
///
///     let mastil = Mastil(.guitarra)
///     mastil.altura(en: PosicionEnElMastil(cuerda: 1, traste: 3))     // Do3
///     mastil.posiciones(de: .mi).count                      // dónde suena Mi, en cualquier octava
public struct Mastil: Hashable, Sendable {
    public let encordado: Encordado
    /// Cuántos trastes tiene (sin contar la cuerda al aire).
    public let trastes: Int

    /// - Parameter trastes: cuántos trastes tiene. Un número negativo se toma como 0 (solo cuerdas al aire).
    public init(_ encordado: Encordado = .guitarra, trastes: Int = 24) {
        self.encordado = encordado
        self.trastes = max(0, trastes)
    }

    /// ¿Existe esta posición en el mástil?
    public func contiene(_ posicion: PosicionEnElMastil) -> Bool {
        encordado.cuerdas.indices.contains(posicion.cuerda) && (0...trastes).contains(posicion.traste)
    }

    /// Número MIDI de una posición, o `nil` si no está en el mástil.
    public func midiSiExiste(en posicion: PosicionEnElMastil) -> Int? {
        contiene(posicion) ? encordado.cuerdas[posicion.cuerda].midi + posicion.traste : nil
    }

    /// Número MIDI de una posición. Detiene el programa si la posición no está en el mástil (un error de
    /// quien llama, como salirse de un array): si viene de fuera, usa `midiSiExiste(en:)` o `contiene(_:)`.
    public func midi(en posicion: PosicionEnElMastil) -> Int {
        guard let midi = midiSiExiste(en: posicion) else {
            preconditionFailure("Posición fuera del mástil: \(posicion)")
        }
        return midi
    }

    /// La altura de una posición, o `nil` si no está en el mástil. La ortografía es la habitual de
    /// `Altura(midi:)`, con sostenidos o, con `preferirBemoles`, con bemoles.
    public func alturaSiExiste(en posicion: PosicionEnElMastil, preferirBemoles: Bool = false) -> Altura? {
        midiSiExiste(en: posicion).map { Altura(midi: $0, preferirBemoles: preferirBemoles) }
    }

    /// La altura de una posición (con la misma ortografía que `alturaSiExiste(en:)`). Detiene el programa si
    /// la posición no está en el mástil: si viene de fuera, usa `alturaSiExiste(en:)`.
    public func altura(en posicion: PosicionEnElMastil, preferirBemoles: Bool = false) -> Altura {
        Altura(midi: midi(en: posicion), preferirBemoles: preferirBemoles)
    }

    /// Todas las posiciones donde suena exactamente esa altura (misma octava).
    public func posiciones(de altura: Altura) -> [PosicionEnElMastil] {
        var resultado: [PosicionEnElMastil] = []
        for (cuerda, alAire) in encordado.cuerdas.enumerated() {
            let traste = altura.midi - alAire.midi
            if (0...trastes).contains(traste) { resultado.append(PosicionEnElMastil(cuerda: cuerda, traste: traste)) }
        }
        return resultado.sorted()
    }

    /// Todas las posiciones donde suena esa nota en cualquier octava. Los enarmónicos suenan igual:
    /// Fa♯ y Sol♭ dan las mismas posiciones.
    public func posiciones(de nota: Nota) -> [PosicionEnElMastil] {
        posiciones(deClases: [nota.claseDeAltura])
    }

    /// Las posiciones de todas las notas de una escala, en un rango de trastes si se indica.
    public func posiciones(de escala: Escala, trastes rango: ClosedRange<Int>? = nil) -> [PosicionEnElMastil] {
        let todas = posiciones(deClases: Set(escala.notas.map(\.claseDeAltura)))
        guard let rango else { return todas }
        return todas.filter { rango.contains($0.traste) }
    }

    /// Las posiciones cuya clase de altura (0…11) está en el conjunto.
    public func posiciones(deClases clases: Set<Int>) -> [PosicionEnElMastil] {
        var resultado: [PosicionEnElMastil] = []
        for (cuerda, alAire) in encordado.cuerdas.enumerated() {
            for traste in 0...trastes where clases.contains(Mastil.clase(alAire.midi + traste)) {
                resultado.append(PosicionEnElMastil(cuerda: cuerda, traste: traste))
            }
        }
        return resultado.sorted()
    }

    /// Clase de altura 0…11 de un número MIDI (también para negativos).
    static func clase(_ midi: Int) -> Int { ((midi % 12) + 12) % 12 }
}
