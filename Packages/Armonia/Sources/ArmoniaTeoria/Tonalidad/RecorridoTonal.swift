import ArmoniaNucleo
// Modulaciones: una progresión partida en tramos, cada uno en su tonalidad, con el acorde pivote
// que lleva de uno a otro.

// MARK: - TramoTonal

/// Un trozo de la progresión que está en una sola tonalidad.
public struct TramoTonal: Hashable, Sendable, CustomStringConvertible {
    /// Índice del primer acorde del tramo en la progresión entera, contado desde 0.
    public let inicio: Int
    /// Los acordes del tramo leídos en su tonalidad.
    public let analisis: AnalisisArmonico

    public var tonalidad: Tonalidad { analisis.tonalidad }
    /// Índices de los acordes del tramo en la progresión entera.
    public var indices: Range<Int> { inicio..<(inicio + analisis.acordes.count) }

    /// "ii–V7–I en Sol mayor".
    public var description: String { analisis.description }
}

// MARK: - AcordePivote

/// El acorde que pertenece a las dos tonalidades de una modulación y se oye primero en la de
/// partida y luego en la de llegada: Lam es vi en Do mayor y ii en Sol mayor.
public struct AcordePivote: Hashable, Sendable, CustomStringConvertible {
    /// Índice del acorde en la progresión, contado desde 0.
    public let indice: Int
    /// El acorde leído en la tonalidad de partida.
    public let antes: AcordeAnalizado
    public let tonalidadDePartida: Tonalidad
    /// El acorde leído en la tonalidad de llegada.
    public let despues: AcordeAnalizado
    public let tonalidadDeLlegada: Tonalidad

    public var acorde: Acorde { antes.acorde }

    /// "Lam = vi en Do mayor = ii en Sol mayor".
    public var description: String { descripcion(en: .espanol) }

    public func descripcion(en notacion: Nomenclatura) -> String {
        let en = notacion.vocabulario == .ingles ? "in" : "en"
        return acorde.cifrado(en: notacion)
            + " = \(antes.cifrado) \(en) " + tonalidadDePartida.nombre(en: notacion)
            + " = \(despues.cifrado) \(en) " + tonalidadDeLlegada.nombre(en: notacion)
    }
}

// MARK: - Modulacion

/// El paso de una tonalidad a otra.
public struct Modulacion: Hashable, Sendable, CustomStringConvertible {
    public let desde: Tonalidad
    public let hasta: Tonalidad
    /// Índice del primer acorde que se lee en la tonalidad nueva (el pivote, si lo hay).
    public let acorde: Int
    /// El acorde común a las dos tonalidades que hace de puente, o `nil` si se cambia de
    /// tonalidad directamente (sin acorde común justo antes del primero que solo es de la nueva).
    public let pivote: AcordePivote?

    /// "De Do mayor a Sol mayor en el acorde 5 (pivote: Lam = vi en Do mayor = ii en Sol mayor)".
    public var description: String { descripcion(en: .espanol) }

    public func descripcion(en notacion: Nomenclatura) -> String {
        let ingles = notacion.vocabulario == .ingles
        var texto = ingles
            ? "From \(desde.nombre(en: notacion)) to \(hasta.nombre(en: notacion)) at chord \(acorde + 1)"
            : "De \(desde.nombre(en: notacion)) a \(hasta.nombre(en: notacion)) en el acorde \(acorde + 1)"
        if let pivote {
            texto += " (" + (ingles ? "pivot" : "pivote") + ": " + pivote.descripcion(en: notacion) + ")"
        } else {
            texto += ingles ? " (direct)" : " (directa)"
        }
        return texto
    }
}

// MARK: - RecorridoTonal

/// El recorrido tonal de una progresión: los tramos en que se queda en una tonalidad, las
/// modulaciones entre ellos (con su acorde pivote) y las cadencias.
///
///     let r = try RecorridoTonal(leyendo: "Do Fa Sol7 Do Lam Re7 Sol")
///     r.tramos.map(\.tonalidad)        // [Do mayor, Sol mayor]
///     r.modulaciones[0].pivote?.description   // "Lam = vi en Do mayor = ii en Sol mayor"
///     r.cifrados                       // ["I", "IV", "V7", "I", "ii", "V7", "I"]
///
/// Una tonalidad nueva tiene que confirmarse con una cadencia auténtica a su tónica; si no, los
/// acordes ajenos se leen como dominantes secundarias o préstamos de la tonalidad en la que se
/// está (una tonicalización, no una modulación). Entre las particiones posibles se elige la que
/// explica los acordes con menos coste, como en ``AnalisisArmonico``, y cada modulación cuesta
/// lo suyo, para no partir la progresión sin necesidad.
public struct RecorridoTonal: Hashable, Sendable, CustomStringConvertible {
    public let tramos: [TramoTonal]
    public let modulaciones: [Modulacion]

    /// Cada acorde leído en la tonalidad de su tramo.
    public var acordes: [AcordeAnalizado] { tramos.flatMap(\.analisis.acordes) }
    public var cifrados: [String] { acordes.map(\.cifrado) }
    public var tonalidadInicial: Tonalidad { tramos[0].tonalidad }
    public var tonalidadFinal: Tonalidad { tramos[tramos.count - 1].tonalidad }

    /// Las cadencias de toda la progresión, cada una en la tonalidad de su segundo acorde.
    public var cadencias: [Cadencia] {
        var resultado: [Cadencia] = []
        let todos = acordes
        for (n, tramo) in tramos.enumerated() {
            var leidos = tramo.analisis.acordes
            var inicio = tramo.inicio
            // La pareja que cruza la frontera se lee en la tonalidad nueva.
            if n > 0 {
                let siguiente = tramo.analisis.acordes.first?.acorde
                leidos.insert(tramo.tonalidad.analizar(todos[inicio - 1].acorde, siguiente: siguiente), at: 0)
                inicio -= 1
            }
            resultado += Cadencia.buscar(en: leidos, tonalidad: tramo.tonalidad, desde: inicio,
                                         esFinal: n == tramos.count - 1)
        }
        return resultado
    }

    /// "I–IV–V7–I en Do mayor → ii–V7–I en Sol mayor".
    public var description: String { nombre(en: .espanol) }

    public func nombre(en notacion: Nomenclatura) -> String {
        tramos.map { $0.analisis.nombre(en: notacion) }.joined(separator: " → ")
    }

    /// Lee una progresión como ``AnalisisArmonico/analizar(leyendo:en:)`` y busca sus modulaciones.
    public init(leyendo texto: String) throws {
        self = RecorridoTonal(try AnalisisArmonico.leerAcordes(texto))!
    }

    /// `nil` si no hay acordes.
    public init?(_ acordes: [Acorde]) {
        guard let unico = AnalisisArmonico.analizar(acordes) else { return nil }
        let particion = RecorridoTonal.particion(acordes)
        guard particion.count > 1 else {
            self.init(tramos: [TramoTonal(inicio: 0, analisis: unico)], modulaciones: [])
            return
        }
        // Se ajusta cada frontera al acorde pivote, si lo hay.
        var fronteras: [(inicio: Int, tonalidad: Tonalidad)] = []
        var pivotes: [AcordePivote?] = []
        for (n, tramo) in particion.enumerated() {
            guard n > 0 else { fronteras.append(tramo); continue }
            let anterior = fronteras[n - 1]
            let fin = n + 1 < particion.count ? particion[n + 1].inicio : acordes.count
            let ajuste = RecorridoTonal.pivote(acordes, desde: anterior.tonalidad, hasta: tramo.tonalidad,
                                               frontera: tramo.inicio, minimo: anterior.inicio + 1, fin: fin)
            fronteras.append((ajuste.inicio, tramo.tonalidad))
            pivotes.append(ajuste.pivote)
        }
        var tramos: [TramoTonal] = []
        for (n, frontera) in fronteras.enumerated() {
            let fin = n + 1 < fronteras.count ? fronteras[n + 1].inicio : acordes.count
            let trozo = Array(acordes[frontera.inicio..<fin])
            let siguiente = fin < acordes.count ? acordes[fin] : nil
            let analizados = trozo.indices.map { i in
                frontera.tonalidad.analizar(trozo[i], siguiente: i + 1 < trozo.count ? trozo[i + 1] : siguiente)
            }
            tramos.append(TramoTonal(inicio: frontera.inicio,
                                     analisis: AnalisisArmonico(tonalidad: frontera.tonalidad, acordes: analizados)))
        }
        let modulaciones = (1..<tramos.count).map { n in
            Modulacion(desde: tramos[n - 1].tonalidad, hasta: tramos[n].tonalidad, acorde: tramos[n].inicio,
                       pivote: pivotes[n - 1])
        }
        self.init(tramos: tramos, modulaciones: modulaciones)
    }

    private init(tramos: [TramoTonal], modulaciones: [Modulacion]) {
        self.tramos = tramos
        self.modulaciones = modulaciones
    }

    // MARK: Partición

    /// Lo que cuesta cada modulación, en las mismas unidades que ``AnalisisArmonico``: algo menos
    /// que lo que rebaja terminar en la tónica, para que una tonalidad nueva confirmada con una
    /// cadencia y en la que termina la progresión gane a seguir en la de partida.
    static let costeDeModular = 0.75
    /// Lo que rebaja el coste de un tramo cada cadencia auténtica a su tónica: lo que confirma una tonalidad.
    static let bonificacionPorCadencia = 0.5

    /// Las tonalidades que se prueban: las más probables por las notas de toda la progresión y las
    /// que tienen por tónica una tríada mayor o menor de la progresión.
    private static func tonalidadesPosibles(_ acordes: [Acorde]) -> [Tonalidad] {
        let notas = acordes.flatMap { $0.notas + [$0.fundamental] }
        var posibles = Tonalidad.candidatos(notas: notas).prefix(6).map(\.valor)
        for acorde in acordes where acorde.tipo == .mayor || acorde.tipo == .menor {
            let tonalidad = Tonalidad(acorde.fundamental, acorde.tipo == .mayor ? .mayor : .menor)
            if !posibles.contains(tonalidad) { posibles.append(tonalidad) }
        }
        return posibles
    }

    /// La partición de menor coste: dónde empieza cada tramo y en qué tonalidad está. Cada tramo
    /// tiene al menos dos acordes, y los que no son el primero, una cadencia auténtica a su tónica.
    private static func particion(_ acordes: [Acorde]) -> [(inicio: Int, tonalidad: Tonalidad)] {
        let n = acordes.count
        guard n >= 4 else { return [] }
        let tonalidades = tonalidadesPosibles(acordes)
        let k = tonalidades.count
        // Para cada tonalidad: el coste acumulado de los acordes y cuántas cadencias auténticas
        // acaban antes de cada posición (para saber en O(1) si un tramo tiene alguna).
        var costes = [[Double]](repeating: [Double](repeating: 0, count: n + 1), count: k)
        var cadencias = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: k)
        var lecturas = [[AcordeAnalizado]](repeating: [], count: k)
        for (t, tonalidad) in tonalidades.enumerated() {
            let leidos = tonalidad.analizar(acordes).acordes
            lecturas[t] = leidos
            for i in 0..<n {
                costes[t][i + 1] = costes[t][i] + AnalisisArmonico.coste(de: leidos[i], siguiente: i + 1 < n ? leidos[i + 1] : nil)
                let cierra = i > 0 && Cadencia.esDominante(leidos[i - 1]) && Cadencia.esTonica(leidos[i])
                cadencias[t][i + 1] = cadencias[t][i] + (cierra ? 1 : 0)
            }
        }
        // Coste del tramo [i, j) en la tonalidad t, o nada si no puede ser un tramo.
        func coste(_ t: Int, _ i: Int, _ j: Int) -> Double? {
            guard j - i >= 2 else { return nil }
            // Una cadencia cuyo primer acorde está dentro del tramo: termina en i + 2 … j.
            if i > 0 && cadencias[t][j] - cadencias[t][i + 1] == 0 { return nil }
            var total = costes[t][j] - costes[t][i] + 0.01 * Double(t)
                - bonificacionPorCadencia * Double(cadencias[t][j] - cadencias[t][i + 1])
            if i == 0 { total -= AnalisisArmonico.rebaja(lecturas[t][0], 0.5) } else { total += costeDeModular }
            if j == n { total -= AnalisisArmonico.rebaja(lecturas[t][n - 1], 1) }
            return total
        }
        // mejor[j][t]: el menor coste de partir los j primeros acordes con el último tramo en t.
        var mejor = [[Double]](repeating: [Double](repeating: .infinity, count: k), count: n + 1)
        var previo = [[(i: Int, t: Int)?]](repeating: [(i: Int, t: Int)?](repeating: nil, count: k), count: n + 1)
        for j in 2...n {
            for t in 0..<k {
                if let c = coste(t, 0, j), c < mejor[j][t] { mejor[j][t] = c }
                for i in stride(from: 2, through: j - 2, by: 1) {
                    guard let c = coste(t, i, j) else { continue }
                    for u in 0..<k where u != t && mejor[i][u] + c < mejor[j][t] {
                        mejor[j][t] = mejor[i][u] + c
                        previo[j][t] = (i, u)
                    }
                }
            }
        }
        guard let ultima = (0..<k).min(by: { mejor[n][$0] < mejor[n][$1] }), mejor[n][ultima] < .infinity else { return [] }
        var resultado: [(inicio: Int, tonalidad: Tonalidad)] = []
        var posicion = (j: n, t: ultima)
        while let anterior = previo[posicion.j][posicion.t] {
            resultado.insert((anterior.i, tonalidades[posicion.t]), at: 0)
            posicion = (anterior.i, anterior.t)
        }
        resultado.insert((0, tonalidades[posicion.t]), at: 0)
        return resultado
    }

    /// Ajusta la frontera entre dos tramos: el primer acorde que ya no es diatónico en la tonalidad
    /// de partida (o la dominante de la primera cadencia de la nueva, si llega antes) marca el
    /// cambio, y el acorde justo anterior, si es diatónico en las dos, es el pivote y abre el tramo nuevo.
    private static func pivote(_ acordes: [Acorde], desde antigua: Tonalidad, hasta nueva: Tonalidad,
                               frontera: Int, minimo: Int, fin: Int) -> (inicio: Int, pivote: AcordePivote?) {
        func leer(_ tonalidad: Tonalidad, _ i: Int) -> AcordeAnalizado {
            tonalidad.analizar(acordes[i], siguiente: i + 1 < acordes.count ? acordes[i + 1] : nil)
        }
        var cambio = frontera
        while cambio < fin, leer(antigua, cambio).categoria == .diatonico,
              !(cambio + 1 < fin && Cadencia.esDominante(leer(nueva, cambio)) && Cadencia.esTonica(leer(nueva, cambio + 1))) {
            cambio += 1
        }
        if cambio == fin { cambio = frontera }
        let candidato = cambio - 1
        guard candidato >= minimo else { return (max(cambio, minimo), nil) }
        let antes = leer(antigua, candidato), despues = leer(nueva, candidato)
        guard antes.categoria == .diatonico, despues.categoria == .diatonico else { return (cambio, nil) }
        return (candidato, AcordePivote(indice: candidato, antes: antes, tonalidadDePartida: antigua,
                                        despues: despues, tonalidadDeLlegada: nueva))
    }
}
