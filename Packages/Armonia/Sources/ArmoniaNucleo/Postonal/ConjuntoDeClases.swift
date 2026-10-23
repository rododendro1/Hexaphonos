// Teoría de conjuntos de clases de altura (análisis postonal).
//
// Un conjunto de clases de altura ignora la ortografía, la octava y el orden: Do–Mi–Sol es
// {0, 4, 7}. Dos conjuntos son de la misma clase si uno es transposición o inversión del otro;
// la clase se representa por su forma prima y su número de Forte (3-11 para cualquier tríada
// mayor o menor).

public struct ConjuntoDeClases: Hashable, Sendable, CustomStringConvertible {
    /// Clases de altura (0 = Do … 11 = Si), sin repetir y ordenadas.
    public let clases: [Int]

    public init<S: Sequence>(_ clases: S) where S.Element == Int {
        self.clases = Set(clases.map { modulo($0, 12) }).sorted()
    }

    public init(notas: [Nota]) { self.init(notas.map(\.claseDeAltura)) }
    public init(alturas: [Altura]) { self.init(alturas.map(\.nota.claseDeAltura)) }

    public var cardinalidad: Int { clases.count }
    public func contiene(_ clase: Int) -> Bool { clases.contains(modulo(clase, 12)) }

    public var description: String { "[" + clases.map(String.init).joined(separator: ", ") + "]" }

    // MARK: Operaciones

    /// Tn: suma `n` semitonos a cada clase.
    public func transponer(_ n: Int) -> ConjuntoDeClases { ConjuntoDeClases(clases.map { $0 + n }) }

    /// TnI: invierte (x → −x) y después transpone `n` semitonos.
    public func invertir(_ n: Int = 0) -> ConjuntoDeClases { ConjuntoDeClases(clases.map { n - $0 }) }

    /// Las clases que faltan para completar las doce.
    public var complemento: ConjuntoDeClases {
        ConjuntoDeClases((0..<12).filter { !clases.contains($0) })
    }

    /// Unión: las clases que están en alguno de los dos.
    public func unir(con otro: ConjuntoDeClases) -> ConjuntoDeClases { ConjuntoDeClases(clases + otro.clases) }
    /// Intersección: las clases que están en los dos.
    public func intersecar(con otro: ConjuntoDeClases) -> ConjuntoDeClases {
        ConjuntoDeClases(clases.filter(otro.contiene))
    }

    public func esSubconjunto(de otro: ConjuntoDeClases) -> Bool { clases.allSatisfy(otro.contiene) }

    // MARK: Vector interválico

    /// Cuántas veces aparece cada clase interválica 1…6 entre los pares de notas.
    /// Tríada mayor → [0, 0, 1, 1, 1, 0].
    public var vectorIntervalico: [Int] {
        var vector = [Int](repeating: 0, count: 6)
        for (i, a) in clases.enumerated() {
            for b in clases[(i + 1)...] {
                let d = b - a
                vector[min(d, 12 - d) - 1] += 1
            }
        }
        return vector
    }

    // MARK: Forma normal y forma prima

    package enum Criterio { case forte, rahn }

    /// Clave de comparación de una rotación (transportada a 0):
    /// - Rahn: se compara del último elemento hacia el primero.
    /// - Forte: primero el más compacto (último elemento) y luego de izquierda a derecha.
    package static func clave(_ r: [Int], _ criterio: Criterio) -> [Int] {
        switch criterio {
        case .rahn: return Array(r.reversed())
        case .forte: return [r.last ?? 0] + (r.count > 2 ? Array(r[1..<(r.count - 1)]) : [])
        }
    }

    /// Rotación más compacta según el criterio, devuelta con sus clases reales.
    package static func ordenNormal(_ c: [Int], _ criterio: Criterio) -> [Int] {
        guard !c.isEmpty else { return [] }
        let rotaciones = c.indices.map { i in Array(c[i...] + c[..<i]) }
        func transportada(_ r: [Int]) -> [Int] { r.map { modulo($0 - r[0], 12) } }
        return rotaciones.min {
            clave(transportada($0), criterio).lexicographicallyPrecedes(clave(transportada($1), criterio))
        } ?? c
    }

    package static func prima(_ c: [Int], _ criterio: Criterio) -> [Int] {
        guard !c.isEmpty else { return [] }
        func transportada(_ r: [Int]) -> [Int] { r.map { modulo($0 - r[0], 12) } }
        let directa = transportada(ordenNormal(c, criterio))
        let invertida = transportada(ordenNormal(Set(c.map { modulo(-$0, 12) }).sorted(), criterio))
        return clave(invertida, criterio).lexicographicallyPrecedes(clave(directa, criterio)) ? invertida : directa
    }

    /// Forma normal (orden más compacto, criterio de Rahn): {7, 0, 4} → [0, 4, 7]; {11, 2, 7} → [7, 11, 2].
    public var formaNormal: [Int] { ConjuntoDeClases.ordenNormal(clases, .rahn) }

    /// Forma prima según Forte (la que usan los números de Forte): Do–Mi–Sol → [0, 3, 7].
    public var formaPrima: [Int] { ConjuntoDeClases.prima(clases, .forte) }

    /// Forma prima según Rahn (la de Straus y la mayoría de manuales actuales). Sólo difiere de la
    /// de Forte en seis clases: 5-20, 6-Z29, 6-31, 7-Z18, 7-20 y 8-26.
    public var formaPrimaRahn: [Int] { ConjuntoDeClases.prima(clases, .rahn) }

    /// Número de Forte: "3-11", "4-Z15", "7-35". `nil` para el conjunto vacío.
    public var numeroDeForte: String? { ConjuntoDeClases.tablaForte[formaPrima] }

    /// Relación Z: mismo vector interválico sin ser de la misma clase (4-Z15 y 4-Z29).
    public func estaEnRelacionZ(con otro: ConjuntoDeClases) -> Bool {
        cardinalidad == otro.cardinalidad && vectorIntervalico == otro.vectorIntervalico
            && !esDeLaMismaClase(que: otro)
    }

    /// Cuántas transposiciones Tn (n = 0…11) dejan el conjunto igual. 1 = sin simetría;
    /// la tríada aumentada da 3 y la escala de tonos enteros, 6.
    public var simetriasPorTransposicion: Int { (0..<12).filter { transponer($0) == self }.count }

    /// Cuántas operaciones TnI dejan el conjunto igual (0 si no es simétrico por inversión).
    public var simetriasPorInversion: Int { (0..<12).filter { invertir($0) == self }.count }

    /// Nombre habitual de algunas clases conocidas: "tríada mayor o menor", "escala diatónica"…
    public var nombreComun: String? {
        numeroDeForte.flatMap { ConjuntoDeClases.nombresComunes[$0] }
    }

    package static let nombresComunes: [String: String] = [
        "3-10": "tríada disminuida",
        "3-11": "tríada mayor o menor",
        "3-12": "tríada aumentada",
        "4-19": "menor con séptima mayor o aumentado con séptima mayor",
        "4-20": "séptima mayor",
        "4-26": "menor séptima o sexta mayor",
        "4-27": "séptima de dominante o semidisminuido",
        "4-28": "séptima disminuida",
        "4-Z15": "tetracordo de todos los intervalos",
        "4-Z29": "tetracordo de todos los intervalos",
        "5-35": "escala pentatónica",
        "6-20": "escala hexatónica (aumentada)",
        "6-35": "escala de tonos enteros",
        "6-Z17": "hexacordo de todos los tricordos",
        "7-32": "escala menor armónica o mayor armónica",
        "7-34": "escala menor melódica (acústica)",
        "7-35": "escala diatónica",
        "8-28": "escala octatónica (disminuida)",
        "12-1": "agregado cromático",
    ]
}

extension ConjuntoDeClases: ExpressibleByArrayLiteral {
    /// `let c: ConjuntoDeClases = [0, 4, 7]`.
    public init(arrayLiteral clases: Int...) { self.init(clases) }
}

extension ConjuntoDeClases: Codable {
    public init(from decoder: Decoder) throws {
        let clases = try decoder.singleValueContainer().decode([Int].self)
        self.init(clases)
    }

    public func encode(to encoder: Encoder) throws {
        var contenedor = encoder.singleValueContainer()
        try contenedor.encode(clases)
    }
}

extension ConjuntoDeClases: Transponible, ConClasesDeAltura {
    public var conjuntoDeClases: ConjuntoDeClases { self }

    /// Transpone por los semitonos del intervalo (la ortografía no cuenta en un conjunto de clases).
    public func transponer(_ intervalo: Intervalo) -> ConjuntoDeClases { transponer(intervalo.semitonosConSigno) }
}
