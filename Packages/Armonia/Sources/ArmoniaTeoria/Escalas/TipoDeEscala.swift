import ArmoniaNucleo
import Foundation

// MARK: - TipoDeEscala

/// Estructura interválica de una escala, medida desde la tónica.
///
/// Dos tipos son iguales cuando tienen el mismo contenido (los mismos intervalos al subir y al
/// bajar), sin importar el nombre: `TipoDeEscala.mayor == TipoDeEscala(nombre: "jónico", intervalos: …)`.
/// Para comparar también el nombre, `esIdentico(a:)`; para ver con qué otros nombres se conoce
/// una escala, `equivalentes`.
///
/// Algunas escalas suben y bajan con notas distintas (la menor melódica, el dromos Rast, muchos
/// ragas): `intervalos` es la forma ascendente y `descenso`, la descendente.
public struct TipoDeEscala: Sendable, Codable {
    public let nombre: String
    /// Intervalos ascendentes simples desde la tónica, ordenados (empieza por el unísono).
    public let intervalos: [Intervalo]
    /// Intervalos de la forma descendente, si es distinta de la ascendente (también ordenados
    /// de grave a agudo); `nil` si la escala baja con las mismas notas con que sube.
    public let descenso: [Intervalo]?
    public let alias: [String]

    /// Los intervalos se reducen a la octava, se pasan a ascendentes y se ordenan,
    /// de modo que el mismo contenido da siempre el mismo tipo. `descenso` solo se guarda si
    /// es distinto de `intervalos`.
    public init(nombre: String, intervalos: [Intervalo], descenso: [Intervalo]? = nil, alias: [String] = []) {
        self.nombre = nombre
        let subida = TipoDeEscala.ordenar(intervalos)
        let bajada = descenso.map(TipoDeEscala.ordenar)
        self.intervalos = subida
        self.descenso = bajada == subida ? nil : bajada
        self.alias = alias
    }

    package static func ordenar(_ intervalos: [Intervalo]) -> [Intervalo] {
        var unicos: [Intervalo] = []
        for i in intervalos.map({ Intervalo.simpleAscendente(pasosDeQuinta: $0.pasosDeQuintaConSigno) })
        where !unicos.contains(i) {
            unicos.append(i)
        }
        if !unicos.contains(.unisono) { unicos.append(.unisono) }
        return unicos.sorted { ($0.pasos, $0.semitonos) < ($1.pasos, $1.semitonos) }
    }

    // MARK: Dirección

    /// ¿Baja con notas distintas de las que sube?
    public var esDireccional: Bool { descenso != nil }

    /// Forma que se usa al descender (la menor melódica baja como menor natural). Si la escala
    /// no es direccional, ella misma.
    public var formaDescendente: TipoDeEscala {
        guard let descenso else { return self }
        return TipoDeEscala(nombre: "\(nombre) (descendente)", intervalos: descenso)
    }

    /// Forma que se usa al ascender, como escala no direccional.
    public var formaAscendente: TipoDeEscala {
        guard esDireccional else { return self }
        return TipoDeEscala(nombre: "\(nombre) (ascendente)", intervalos: intervalos)
    }

    /// Intervalos que aparecen al subir o al bajar: en la menor melódica, la 6ª y la 7ª mayores
    /// y menores.
    public var intervalosEnAmbasDirecciones: [Intervalo] {
        TipoDeEscala.ordenar(intervalos + (descenso ?? []))
    }

    // MARK: Identidad

    /// Mismo contenido y mismo nombre: Kāfī y dórico son iguales (`==`), pero no idénticos.
    public func esIdentico(a otro: TipoDeEscala) -> Bool { self == otro && nombre == otro.nombre }

    /// Otras escalas del catálogo (`todos` y `tradicionales`) con el mismo contenido y otro
    /// nombre: para la mayor, Bilāval, Dhīraśaṅkarābharaṇam y Qīngyuè.
    public var equivalentes: [TipoDeEscala] {
        (TipoDeEscala.todos + TipoDeEscala.tradicionales).filter { $0 == self && $0.nombre != nombre }
    }

    /// Rotación de la escala empezando en el grado `grado` (1 = la propia escala).
    /// Si la rotación coincide con un tipo conocido, devuelve ese tipo.
    public func rotacion(_ grado: Int) -> TipoDeEscala {
        let n = intervalos.count
        let desde = modulo(grado - 1, n)
        let nuevos = (0..<n).map { i in
            Intervalo.simpleAscendente(
                pasosDeQuinta: intervalos[(desde + i) % n].pasosDeQuinta - intervalos[desde].pasosDeQuinta)
        }
        if desde == 0 { return self }
        let candidato = TipoDeEscala(nombre: "\(nombre), modo \(desde + 1)", intervalos: nuevos)
        return TipoDeEscala.todos.first { $0 == candidato }
            ?? TipoDeEscala.todos.first { $0.intervalos == candidato.intervalos } ?? candidato
    }
}

extension TipoDeEscala: Hashable {
    public static func == (a: TipoDeEscala, b: TipoDeEscala) -> Bool {
        a.intervalos == b.intervalos && a.descenso == b.descenso
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(intervalos)
        hasher.combine(descenso)
    }
}

extension TipoDeEscala: Nombrable {}

extension TipoDeEscala: CustomStringConvertible {
    public var description: String { nombre }
}

// Más escalas, búsqueda de escalas, armaduras, círculo de quintas y funciones de grado.

// Las escalas adicionales (modos derivados, exóticas, hexatónicas, Messiaen, jazz…) están en
// `Occidentales/TipoDeEscala+*.swift`, y las de otras tradiciones, en `Tradiciones/`.

extension Escala {
    /// El hexacordo natural, sobre Do (Do Re Mi Fa Sol La).
    public static let hexacordoNatural = Escala(.do, .hexacordo)
    /// El hexacordo duro, sobre Sol (Sol La Si Do Re Mi), con el si «cuadrado».
    public static let hexacordoDuro = Escala(.sol, .hexacordo)
    /// El hexacordo blando, sobre Fa (Fa Sol La Si♭ Do Re), con el si «redondo».
    public static let hexacordoBlando = Escala(.fa, .hexacordo)
}
