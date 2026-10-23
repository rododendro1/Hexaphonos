import ArmoniaNucleo
import ArmoniaTeoria
// MARK: - Representación en base 40 (y sus generalizaciones)
//
// Walter B. Hewlett (1992) numera las alturas de forma que la ortografía se conserva y los
// intervalos son diferencias de números: cada letra ocupa un bloque de valores consecutivos
// (de doble bemol a doble sostenido) y entre dos letras a distancia de tono queda un hueco sin
// usar. Con dobles alteraciones salen 7·5 + 5 = 40 valores por octava; con `m` alteraciones
// como máximo, 7·(2m + 1) + 5. Así, m = 3 da la base 54 (triples alteraciones) y m = 42, la
// base 600.
//
// En el modelo de quintas la conversión es lineal: una quinta justa vale 8m + 7 y una octava,
// 14m + 12 (la base). Do natural es m dentro de su octava, así que Do4 = 4·base + m (162 en
// base 40, como en Humdrum).

/// Una numeración de Hewlett: base 40, 54, 600… Los números de nota, de nombre de nota y de
/// intervalo usan la misma escala, de modo que `numero(Re4) − numero(Do4) == numero(2ª mayor)`.
///
///     Altura("Do4").numero(en: .base40)          // 162
///     Altura("Fa#4").numero(en: .base40)         // 180
///     Altura("Solb4").numero(en: .base40)        // 184 (distinto de Fa♯4)
///     Intervalo.quintaJusta.numero(en: .base40) // 23
///     Altura(numero: 185, en: .base40)            // Sol4
///     let faTripleSostenido = Altura(Nota(.fa, 3), octava: 4)
///     faTripleSostenido.numero(en: .base40)     // nil: base 40 solo llega a doble sostenido
///     faTripleSostenido.numero(en: .base54)     // 245
public struct BaseDeHewlett: Hashable, Sendable, CustomStringConvertible {
    /// Número máximo de alteraciones en cada sentido (2 en base 40: 𝄫 a 𝄪).
    public let alteracionMaxima: Int

    /// Numeración que admite hasta `alteracionMaxima` sostenidos o bemoles. Un número negativo se toma como 0
    /// (solo las notas naturales).
    public init(alteracionMaxima: Int) {
        self.alteracionMaxima = max(0, alteracionMaxima)
    }

    /// Numeración con la base dada, si existe: 12, 26, 40, 54… (14m + 12). `nil` en otro caso.
    public init?(base: Int) {
        guard base >= 12, (base - 12) % 14 == 0 else { return nil }
        self.init(alteracionMaxima: (base - 12) / 14)
    }

    /// Base 40 de Hewlett: hasta dobles sostenidos y dobles bemoles.
    public static let base40 = BaseDeHewlett(alteracionMaxima: 2)
    /// Base 54: hasta triples sostenidos y triples bemoles.
    public static let base54 = BaseDeHewlett(alteracionMaxima: 3)
    /// Base 600: hasta 42 sostenidos o bemoles.
    public static let base600 = BaseDeHewlett(alteracionMaxima: 42)

    /// Valores por octava: 7·(2m + 1) + 5.
    public var base: Int { 14 * alteracionMaxima + 12 }

    /// Valor de una quinta justa: 8m + 7 (23 en base 40).
    public var quinta: Int { 8 * alteracionMaxima + 7 }

    public var description: String { "base \(base)" }

    // MARK: Bloques de letras

    /// Primer valor del bloque de cada letra dentro de la octava (el del bemol más grave):
    /// en base 40, Do 0, Re 6, Mi 12, Fa 17, Sol 23, La 29, Si 35.
    package func inicio(de letra: NotaNatural) -> Int {
        let huecosAntes = [0, 1, 2, 2, 3, 4, 5][letra.rawValue]
        return letra.rawValue * (2 * alteracionMaxima + 1) + huecosAntes
    }

    /// Nombre de nota que ocupa un valor dentro de la octava (0..<base); `nil` en los huecos.
    package func nota(posicion: Int) -> Nota? {
        for letra in NotaNatural.allCases {
            let desplazamiento = posicion - inicio(de: letra)
            if (0...(2 * alteracionMaxima)).contains(desplazamiento) {
                return Nota(letra, Alteracion(desplazamiento - alteracionMaxima))
            }
        }
        return nil
    }

    package func admite(_ nombre: Nota) -> Bool { nombre.alteracion.cantidad <= alteracionMaxima }

    // MARK: Conversiones

    /// Número de una nota: octava · base + posición. `nil` si tiene más alteraciones de las que
    /// admite la base.
    public func numero(de nota: Altura) -> Int? {
        guard admite(nota.nota) else { return nil }
        return 4 * base + alteracionMaxima + nota.pasosDeQuinta * quinta + nota.pasosDeOctava * base
    }

    /// Altura con un número dado; `nil` si cae en un hueco.
    public func altura(_ numero: Int) -> Altura? {
        let octava = divisionEntera(numero, base)
        guard let nombre = nota(posicion: numero - octava * base) else { return nil }
        return Altura(nombre, octava: octava)
    }

    /// Número de un nombre de nota dentro de la octava (0..<base): Do = m, Do♯ = m + 1…
    public func numero(de nombre: Nota) -> Int? {
        guard admite(nombre) else { return nil }
        return modulo(alteracionMaxima + nombre.pasosDeQuinta * quinta, base)
    }

    /// Nombre de nota con un número (se toma módulo la base); `nil` si cae en un hueco.
    public func nota(_ numero: Int) -> Nota? {
        nota(posicion: modulo(numero, base))
    }

    /// Número de un intervalo, con signo según la dirección: 3ª mayor = 12 y 5ª justa = 23 en
    /// base 40. `nil` si la nota a la que llega desde Do tiene más alteraciones de las admitidas.
    public func numero(de intervalo: Intervalo) -> Int? {
        guard admite(Nota(pasosDeQuinta: intervalo.pasosDeQuintaConSigno)) else { return nil }
        return intervalo.pasosDeQuintaConSigno * quinta + intervalo.pasosDeOctavaConSigno * base
    }

    /// Intervalo con un número (negativo = descendente); `nil` si cae en un hueco
    /// (en base 40, el 20, entre la 4ª doble aumentada y la 5ª doble disminuida).
    public func intervalo(_ numero: Int) -> Intervalo? {
        let do4 = Altura(pasosDeQuinta: 0, pasosDeOctava: 0)
        guard let destino = altura(4 * base + alteracionMaxima + numero) else { return nil }
        return destino - do4
    }
}

// MARK: - Accesos desde cada tipo

extension Altura {
    /// Número en una numeración de Hewlett: `Altura("Do4").numero(en: .base40)` → 162.
    public func numero(en base: BaseDeHewlett) -> Int? { base.numero(de: self) }

    /// Altura con un número de Hewlett: `Altura(numero: 185, en: .base40)` → Sol4.
    public init?(numero: Int, en base: BaseDeHewlett) {
        guard let nota = base.altura(numero) else { return nil }
        self = nota
    }
}

extension Nota {
    /// Posición dentro de la octava en una numeración de Hewlett: Do = 2, Fa♯ = 20 en base 40.
    public func numero(en base: BaseDeHewlett) -> Int? { base.numero(de: self) }

    /// Nombre de nota con un número de Hewlett (módulo la base).
    public init?(numero: Int, en base: BaseDeHewlett) {
        guard let nombre = base.nota(numero) else { return nil }
        self = nombre
    }
}

extension Intervalo {
    /// Número en una numeración de Hewlett, con signo: `Intervalo.quintaJusta.numero(en: .base40)` → 23.
    public func numero(en base: BaseDeHewlett) -> Int? { base.numero(de: self) }

    /// Intervalo con un número de Hewlett: `Intervalo(numero: 12, en: .base40)` → 3ª mayor.
    public init?(numero: Int, en base: BaseDeHewlett) {
        guard let intervalo = base.intervalo(numero) else { return nil }
        self = intervalo
    }
}
