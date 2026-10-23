// MARK: - MapaHexagonal

/// Un mapa: un valor (un terreno, una altura, una nota) en cada una de sus casillas.
///
/// Por dentro es un diccionario `[CoordenadaAxial: Valor]`, así que el mapa puede tener cualquier
/// forma, con huecos, y crecer por cualquier lado. Una casilla que no está en el mapa no tiene valor
/// (`nil`), y los caminos y las búsquedas no pasan por ella.
///
/// ```swift
/// var mapa = MapaHexagonal(repitiendo: "hierba", en: FormasDeMapa.hexagono(radio: 2))
/// mapa[CoordenadaAxial(q: 1, r: 0)] = "agua"
/// mapa.count                                  // 19
/// mapa[CoordenadaAxial(q: 5, r: 0)]           // nil
/// mapa.vecinas(de: .origen).count             // 6
/// ```
///
/// Se recorre como una colección de pares `(casilla, valor)`, en un orden sin especificar (el del
/// diccionario).
public struct MapaHexagonal<Valor> {
    /// Los valores, por casilla.
    public private(set) var valores: [CoordenadaAxial: Valor]

    /// Un mapa vacío.
    public init() {
        valores = [:]
    }

    /// El mapa con esos valores.
    public init(_ valores: [CoordenadaAxial: Valor]) {
        self.valores = valores
    }

    /// Un mapa con las `casillas` y el valor que da `valor` para cada una.
    public init(_ casillas: some Sequence<CoordenadaAxial>,
                valor: (CoordenadaAxial) throws -> Valor) rethrows {
        var valores: [CoordenadaAxial: Valor] = [:]
        for casilla in casillas {
            valores[casilla] = try valor(casilla)
        }
        self.valores = valores
    }

    /// Un mapa con las `casillas` y el mismo valor en todas.
    public init(repitiendo valor: Valor, en casillas: some Sequence<CoordenadaAxial>) {
        self.init(casillas) { _ in valor }
    }

    /// El valor de una casilla, o `nil` si no está en el mapa. Al asignar `nil`, la casilla sale del mapa.
    public subscript(casilla: CoordenadaAxial) -> Valor? {
        get { valores[casilla] }
        set { valores[casilla] = newValue }
    }

    /// El valor de una casilla o, si no está en el mapa, `porDefecto` (al modificarlo, la casilla entra
    /// en el mapa): `mapa[casilla, porDefecto: 0] += 1`.
    public subscript(casilla: CoordenadaAxial, porDefecto valor: @autoclosure () -> Valor) -> Valor {
        get { valores[casilla, default: valor()] }
        set { valores[casilla] = newValue }
    }

    /// Las casillas del mapa.
    public var casillas: Dictionary<CoordenadaAxial, Valor>.Keys { valores.keys }

    /// Si la casilla está en el mapa.
    public func contiene(_ casilla: CoordenadaAxial) -> Bool {
        valores[casilla] != nil
    }

    /// Saca una casilla del mapa y devuelve su valor (`nil` si no estaba).
    @discardableResult
    public mutating func quitar(_ casilla: CoordenadaAxial) -> Valor? {
        valores.removeValue(forKey: casilla)
    }

    /// Las vecinas de una casilla que están en el mapa, con su valor, en el orden de
    /// ``CoordenadaAxial/direcciones``. La casilla no tiene por qué estar en el mapa.
    public func vecinas(de casilla: CoordenadaAxial) -> [(casilla: CoordenadaAxial, valor: Valor)] {
        casilla.vecinos.compactMap { vecina in valores[vecina].map { (vecina, $0) } }
    }

    /// El mismo mapa con cada valor transformado.
    public func transformado<Otro>(_ transformacion: (Valor) throws -> Otro) rethrows -> MapaHexagonal<Otro> {
        MapaHexagonal<Otro>(try valores.mapValues(transformacion))
    }

    /// Solo las casillas que cumplen `incluir`.
    public func filtrado(_ incluir: (CoordenadaAxial, Valor) throws -> Bool) rethrows -> MapaHexagonal {
        MapaHexagonal(try valores.filter { try incluir($0.key, $0.value) })
    }

    /// Las casillas cuyo valor cumple `condicion`.
    public func casillas(donde condicion: (Valor) throws -> Bool) rethrows -> [CoordenadaAxial] {
        try valores.compactMap { try condicion($0.value) ? $0.key : nil }
    }

    /// El rectángulo que ocupan sus hexágonos al dibujarlos con `disposicion`, o `nil` si está vacío.
    public func limites(con disposicion: Disposicion) -> (minimo: Punto, maximo: Punto)? {
        disposicion.limites(de: casillas)
    }
}

// MARK: - Simetrías

extension MapaHexagonal {
    /// El mapa movido: cada valor pasa de `casilla` a `casilla + vector`.
    public func desplazado(por vector: CoordenadaAxial) -> MapaHexagonal {
        recolocado { $0 + vector }
    }

    /// El mapa girado `sextos` veces 60° alrededor de `centro` (ver ``CoordenadaAxial/rotada(sextos:alrededorDe:)``).
    public func girado(sextos: Int, alrededorDe centro: CoordenadaAxial = .origen) -> MapaHexagonal {
        recolocado { $0.rotada(sextos: sextos, alrededorDe: centro) }
    }

    /// El mapa reflejado sobre un eje (ver ``CoordenadaAxial/reflejada(sobre:alrededorDe:)``).
    public func reflejado(sobre eje: Eje, alrededorDe centro: CoordenadaAxial = .origen) -> MapaHexagonal {
        recolocado { $0.reflejada(sobre: eje, alrededorDe: centro) }
    }

    /// Mueve cada valor a otra casilla; `mover` tiene que llevar casillas distintas a casillas distintas.
    private func recolocado(_ mover: (CoordenadaAxial) -> CoordenadaAxial) -> MapaHexagonal {
        MapaHexagonal(Dictionary(uniqueKeysWithValues: valores.map { (mover($0.key), $0.value) }))
    }
}

// MARK: - Caminos y visibilidad

extension MapaHexagonal {
    /// El camino más barato de `origen` a `destino` por las casillas del mapa (ver
    /// ``CoordenadaAxial/caminoMasBarato(hasta:costeMinimo:presupuesto:coste:)``).
    ///
    /// `coste` dice lo que cuesta entrar en una casilla según su valor, o `nil` si no se puede. Las
    /// casillas que no están en el mapa no se pueden pisar; `origen` no tiene por qué estar.
    ///
    /// ```swift
    /// var terreno = MapaHexagonal(repitiendo: 1.0, en: FormasDeMapa.hexagono(radio: 3))
    /// terreno[CoordenadaAxial(q: 1, r: 0)] = 10
    /// terreno.caminoMasBarato(desde: .origen, hasta: CoordenadaAxial(q: 2, r: 0)) { $0 }?.coste   // 3.0
    /// ```
    public func caminoMasBarato(desde origen: CoordenadaAxial, hasta destino: CoordenadaAxial,
                                costeMinimo: Double = 0, presupuesto: Double = .infinity,
                                coste: (Valor) -> Double?) -> CaminoHexagonal? {
        origen.caminoMasBarato(hasta: destino, costeMinimo: costeMinimo, presupuesto: presupuesto) { _, hacia in
            valores[hacia].flatMap(coste)
        }
    }

    /// Las casillas del mapa a las que se llega desde `origen` gastando `presupuesto` o menos, con lo
    /// que cuesta llegar a cada una (ver ``CoordenadaAxial/alcanzables(presupuesto:coste:)``).
    /// `coste` es lo que cuesta entrar en una casilla según su valor, o `nil` si no se puede.
    public func alcanzables(desde origen: CoordenadaAxial, presupuesto: Double,
                            coste: (Valor) -> Double?) -> [CoordenadaAxial: Double] {
        origen.alcanzables(presupuesto: presupuesto) { _, hacia in valores[hacia].flatMap(coste) }
    }

    /// Las casillas del mapa que se ven desde `origen`, si las de valor `tapa` tapan la vista (las
    /// tapadas no se ven; las que no están en el mapa no tapan). Ver ``CoordenadaAxial/ve(_:tapada:)``.
    public func visibles(desde origen: CoordenadaAxial, tapa: (Valor) -> Bool) -> [CoordenadaAxial] {
        origen.visibles(en: casillas) { valores[$0].map(tapa) ?? false }
    }
}

// MARK: - Colección

extension MapaHexagonal: Collection {
    public typealias Index = Dictionary<CoordenadaAxial, Valor>.Index
    public typealias Element = (casilla: CoordenadaAxial, valor: Valor)

    public var startIndex: Index { valores.startIndex }
    public var endIndex: Index { valores.endIndex }
    public func index(after i: Index) -> Index { valores.index(after: i) }

    public subscript(posicion: Index) -> Element {
        let (casilla, valor) = valores[posicion]
        return (casilla, valor)
    }

    // Más rápidos que los de `Collection`, que recorren el mapa.
    public var count: Int { valores.count }
    public var isEmpty: Bool { valores.isEmpty }
}

extension MapaHexagonal: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elementos: (CoordenadaAxial, Valor)...) {
        self.init(Dictionary(elementos, uniquingKeysWith: { _, ultimo in ultimo }))
    }
}

extension MapaHexagonal: Equatable where Valor: Equatable {
    public static func == (a: MapaHexagonal, b: MapaHexagonal) -> Bool { a.valores == b.valores }
}

extension MapaHexagonal: Hashable where Valor: Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(valores) }
}

extension MapaHexagonal: Sendable where Valor: Sendable {}

extension MapaHexagonal: Codable where Valor: Codable {
    // Se guarda como una lista de casillas con su valor: `[{"q": 1, "r": 0, "valor": …}, …]`, en el
    // orden de las columnas y las filas para que dos mapas iguales se guarden igual.

    public init(from decoder: Decoder) throws {
        let entradas = try decoder.singleValueContainer().decode([EntradaDeMapa<Valor>].self)
        var valores: [CoordenadaAxial: Valor] = [:]
        for entrada in entradas {
            let casilla = CoordenadaAxial(q: entrada.q, r: entrada.r)
            guard valores.updateValue(entrada.valor, forKey: casilla) == nil else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                        debugDescription: "La casilla \(casilla) está repetida"))
            }
        }
        self.valores = valores
    }

    public func encode(to encoder: Encoder) throws {
        let entradas = valores
            .sorted { ($0.key.q, $0.key.r) < ($1.key.q, $1.key.r) }
            .map { EntradaDeMapa(q: $0.key.q, r: $0.key.r, valor: $0.value) }
        var contenedor = encoder.singleValueContainer()
        try contenedor.encode(entradas)
    }
}

extension MapaHexagonal: CustomStringConvertible {
    public var description: String {
        count == 1 ? "MapaHexagonal (1 casilla)" : "MapaHexagonal (\(count) casillas)"
    }
}

/// Una casilla de un mapa guardado, con su valor.
private struct EntradaDeMapa<Valor: Codable>: Codable {
    var q: Int
    var r: Int
    var valor: Valor
}
