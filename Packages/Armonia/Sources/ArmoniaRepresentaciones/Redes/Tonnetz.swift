import ArmoniaNucleo
import ArmoniaTeoria
import Hexagonos
// El Tonnetz: la red de notas unidas por quintas justas y terceras mayores y menores, en la
// que cada triángulo es una tríada (hacia arriba, mayor; hacia abajo, menor).
//
// Es el plano quintas × terceras mayores, así que encaja con la línea de quintas del motor: el
// punto (a, b) es la nota a quintas y b terceras mayores por encima de Do, que está a
// a + 4b pasos de quinta. La ortografía se conserva (Fa♯ y Sol♭ están en sitios distintos),
// pero una misma nota aparece en muchos puntos: Mi es (4, 0), cuatro quintas, y (0, 1), una
// tercera mayor (en entonación justa difieren en una coma sintónica). Al colocar unas notas se
// elige, entre todas las disposiciones, la más compacta.
//
// Para un conjunto de clases de altura, sin ortografía, el Tonnetz es el de doce notas: el
// punto (a, b) es la clase 7a + 4b (mod 12), y la red se repite como un toro.
//
// La red es una rejilla hexagonal (cada nota, el centro de un hexágono): las distancias y las
// posiciones del dibujo salen del paquete `Hexagonos` (Tonnetz+Hexagonos.swift).

import Foundation

// MARK: - PuntoDelTonnetz

/// Un punto del Tonnetz: `quintas` pasos de quinta justa (eje horizontal) y `terceras` de
/// tercera mayor (eje diagonal) desde Do.
public struct PuntoDelTonnetz: Hashable, Sendable, CustomStringConvertible {
    public let quintas: Int
    public let terceras: Int

    public init(quintas: Int, terceras: Int) {
        self.quintas = quintas
        self.terceras = terceras
    }

    /// Posición en la línea de quintas: (0, 1) → 4, Mi.
    public var pasosDeQuinta: Int { quintas + 4 * terceras }
    /// La nota, con su ortografía: (−1, 1) → La; (2, 1) → Fa♯.
    public var nota: Nota { Nota(pasosDeQuinta: pasosDeQuinta) }
    /// La clase de altura (0 = Do … 11 = Si).
    public var claseDeAltura: Int { modulo(7 * quintas + 4 * terceras, 12) }

    /// Los seis vecinos: una quinta justa, una tercera mayor o una tercera menor arriba o abajo.
    public var vecinos: [PuntoDelTonnetz] {
        PuntoDelTonnetz.pasos.map { PuntoDelTonnetz(quintas: quintas + $0.0, terceras: terceras + $0.1) }
    }

    /// Pasos mínimos por la red hasta otro punto.
    public func distancia(hasta otro: PuntoDelTonnetz) -> Int {
        // La de la rejilla hexagonal: un paso de tercera menor, (1, −1), avanza en los dos ejes a la vez.
        coordenada.distancia(hasta: otro.coordenada)
    }

    public var description: String { "(\(quintas), \(terceras))" }

    /// Quinta justa, tercera mayor y tercera menor (y sus contrarios).
    package static let pasos = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, -1), (-1, 1)]
}

// MARK: - Tonnetz

/// Unas notas colocadas en el Tonnetz, con las tríadas y los intervalos que forman.
///
///     let t = Tonnetz(Acorde("Do"))
///     t.puntos          // [(0, 0), (0, 1), (1, 0)]: Do, Mi y Sol, un triángulo
///     t.triadas         // [Do mayor]
///     t.svg()           // el dibujo
///
/// Se puede construir con notas (`Tonnetz([.do, .mi, .sol])`), un acorde, una escala o un
/// `ConjuntoDeClases`; este último, sin ortografía, en el Tonnetz de doce notas.
public struct Tonnetz: Hashable, Sendable {
    /// Una tríada completa: los tres vértices de un triángulo.
    public struct Triada: Hashable, Sendable, CustomStringConvertible {
        /// El punto de la fundamental.
        public let fundamental: PuntoDelTonnetz
        /// Triángulo hacia arriba (mayor) o hacia abajo (menor).
        public let mayor: Bool

        public init(fundamental: PuntoDelTonnetz, mayor: Bool) {
            self.fundamental = fundamental
            self.mayor = mayor
        }

        /// Fundamental, quinta y tercera.
        public var vertices: [PuntoDelTonnetz] {
            let quinta = PuntoDelTonnetz(quintas: fundamental.quintas + 1, terceras: fundamental.terceras)
            let tercera = mayor ? PuntoDelTonnetz(quintas: fundamental.quintas, terceras: fundamental.terceras + 1)
                                : PuntoDelTonnetz(quintas: fundamental.quintas + 1, terceras: fundamental.terceras - 1)
            return [fundamental, tercera, quinta]
        }

        /// El acorde (con la ortografía del punto de la fundamental).
        public var acorde: Acorde { Acorde(fundamental.nota, mayor ? .mayor : .menor) }
        public var description: String { acorde.cifrado }
    }

    /// Dos puntos vecinos de la red.
    public struct Arista: Hashable, Sendable {
        /// El eje de la red que sigue la arista: quinta justa, tercera mayor o tercera menor.
        public enum Eje: Hashable, Sendable { case quintaJusta, terceraMayor, terceraMenor }
        public let desde: PuntoDelTonnetz
        public let hasta: PuntoDelTonnetz
        public let eje: Eje

        @available(*, deprecated, renamed: "Eje")
        public typealias Intervalo = Eje
        @available(*, deprecated, renamed: "eje")
        public var intervalo: Eje { eje }
    }

    /// Los puntos de las notas, en el orden en que se dieron (sin repetir).
    public let puntos: [PuntoDelTonnetz]
    /// `true` si se colocaron notas con su ortografía; `false` para clases de altura.
    public let tieneOrtografia: Bool
    @available(*, deprecated, renamed: "tieneOrtografia")
    public var conOrtografia: Bool { tieneOrtografia }
    /// Las tríadas de un recorrido, en orden (`init(recorrido:)`); vacío si no lo es.
    public private(set) var recorrido: [Triada] = []
    /// De dónde salen las notas, para el título del dibujo.
    package var origen: OrigenDelDibujo?
    /// En un ciclo, el nombre de cada punto, que no siempre es el de su posición (`init(ciclo:desde:)`).
    package var nombres: [PuntoDelTonnetz: Nota] = [:]
    /// En un ciclo, las tríadas con la ortografía con que se escriben.
    package var acordesDelRecorrido: [Acorde] = []

    package init(puntos: [PuntoDelTonnetz], tieneOrtografia: Bool, recorrido: [Triada]) {
        self.puntos = puntos
        self.tieneOrtografia = tieneOrtografia
        self.recorrido = recorrido
    }

    /// Coloca las notas con su ortografía, en la disposición más compacta, con la primera en (a, 0).
    public init(_ notas: [Nota]) {
        var vistas: [Nota] = []
        for nota in notas where !vistas.contains(nota) { vistas.append(nota) }
        puntos = Tonnetz.colocar(vistas.map(\.pasosDeQuinta)) { pasos, cerca in
            // Los puntos con a + 4b = pasos, con b cerca de los ya colocados.
            cerca.map { b in PuntoDelTonnetz(quintas: pasos - 4 * b, terceras: b) }
        }
        tieneOrtografia = true
        origen = .notas(vistas)
    }

    /// Coloca las clases de altura en el Tonnetz de doce notas, de la forma más compacta.
    public init(_ conjunto: ConjuntoDeClases) {
        puntos = Tonnetz.colocar(conjunto.clases) { clase, cerca in
            // Los puntos con 7a + 4b ≡ clase (mod 12): para cada b, los a de 12 en 12 cerca de 0.
            cerca.flatMap { b -> [PuntoDelTonnetz] in
                (-12...12).compactMap { a in
                    modulo(7 * a + 4 * b, 12) == clase ? PuntoDelTonnetz(quintas: a, terceras: b) : nil
                }
            }
        }
        tieneOrtografia = false
        origen = .conjunto(conjunto)
    }

    public init(_ acorde: Acorde) { self.init(acorde.notas); origen = .acorde(acorde) }
    public init(_ escala: Escala) { self.init(escala.notas); origen = .escala(escala) }

    /// Las notas de los puntos (con ortografía) o, para clases de altura, su nombre con sostenidos.
    public var notas: [Nota] { puntos.map(nombre(de:)) }

    /// ¿Están todas las notas unidas por la red?
    public var esConexo: Bool {
        guard let primero = puntos.first else { return true }
        var alcanzados: Set<PuntoDelTonnetz> = [primero]
        var pendientes = [primero]
        while let punto = pendientes.popLast() {
            for vecino in punto.vecinos where puntos.contains(vecino) && !alcanzados.contains(vecino) {
                alcanzados.insert(vecino)
                pendientes.append(vecino)
            }
        }
        return alcanzados.count == puntos.count
    }

    /// Las tríadas mayores y menores completas, de izquierda a derecha.
    public var triadas: [Triada] {
        let conjunto = Set(puntos)
        var triadas: [Triada] = []
        for punto in puntos {
            for mayor in [true, false] {
                let triada = Triada(fundamental: punto, mayor: mayor)
                if triada.vertices.allSatisfy(conjunto.contains) { triadas.append(triada) }
            }
        }
        return triadas.sorted { ($0.fundamental.quintas, $0.fundamental.terceras, $0.mayor ? 0 : 1)
            < ($1.fundamental.quintas, $1.fundamental.terceras, $1.mayor ? 0 : 1) }
    }

    /// Los pares de notas vecinas en la red: los intervalos de quinta y de tercera que hay.
    public var aristas: [Arista] {
        let conjunto = Set(puntos)
        var aristas: [Arista] = []
        for punto in puntos {
            for (paso, eje) in [((1, 0), Arista.Eje.quintaJusta), ((0, 1), .terceraMayor), ((1, -1), .terceraMenor)] {
                let otro = PuntoDelTonnetz(quintas: punto.quintas + paso.0, terceras: punto.terceras + paso.1)
                if conjunto.contains(otro) { aristas.append(Arista(desde: punto, hasta: otro, eje: eje)) }
            }
        }
        return aristas
    }

    // MARK: Colocación

    /// Coloca los elementos (pasos de quinta, clases de altura o números MIDI) de la forma más
    /// compacta: la de menos grupos sueltos y, entre ellas, la de menor suma de distancias entre
    /// cada par de notas (a igualdad, la de menor diámetro). El primero queda en la fila 0 (o lo
    /// más cerca posible del origen) y los demás, donde mejor encajen.
    ///
    /// Se buscan todas las disposiciones con ramificación y poda, partiendo de la colocación
    /// voraz como cota; si un conjunto grande agota el presupuesto de búsqueda, se queda la mejor
    /// encontrada. `candidatos` da, para un elemento y unas filas `b`, los puntos posibles en ellas.
    package static func colocar(_ elementos: [Int], candidatos: (Int, ClosedRange<Int>) -> [PuntoDelTonnetz]) -> [PuntoDelTonnetz] {
        let voraz = colocarVoraz(elementos, candidatos: candidatos)
        guard elementos.count > 2 else { return voraz }
        let primero = voraz[0]
        // Para cada uno de los demás, los puntos cercanos al primero: hasta dos pasos más lejos
        // que el más cercano, que es donde puede estar la disposición más compacta.
        let filas = (primero.terceras - 4)...(primero.terceras + 4)
        let opciones: [[PuntoDelTonnetz]] = elementos.dropFirst().map { elemento in
            let puntos = candidatos(elemento, filas)
            let minimo = puntos.map { $0.distancia(hasta: primero) }.min() ?? 0
            return puntos.filter { $0.distancia(hasta: primero) <= minimo + 2 }
                .sorted { ($0.distancia(hasta: primero), $0.terceras, $0.quintas) < ($1.distancia(hasta: primero), $1.terceras, $1.quintas) }
        }
        // Se recorren primero los elementos con menos opciones, para podar antes.
        let orden = opciones.indices.sorted { (opciones[$0].count, $0) < (opciones[$1].count, $1) }

        func coste(_ puntos: [PuntoDelTonnetz]) -> (Int, Int, Int) {
            var suma = 0, diametro = 0
            for i in puntos.indices {
                for j in puntos.indices where j > i {
                    let d = puntos[i].distancia(hasta: puntos[j])
                    suma += d
                    diametro = max(diametro, d)
                }
            }
            return (Tonnetz.grupos(puntos), suma, diametro)
        }
        var mejor = voraz
        var mejorCoste = coste(voraz)
        var elegidos: [PuntoDelTonnetz] = [primero]
        var asignacion = [PuntoDelTonnetz?](repeating: nil, count: opciones.count)
        var presupuesto = 200_000

        func buscar(_ k: Int, _ parcial: Int) {
            presupuesto -= 1
            guard presupuesto > 0 else { return }
            if k == orden.count {
                let puntos = [primero] + asignacion.map { $0! }
                let c = coste(puntos)
                if c < mejorCoste { mejor = puntos; mejorCoste = c }
                return
            }
            // Cota: lo que suman ya los colocados y, para cada uno de los que faltan, lo mínimo
            // que puede sumar con ellos. Los grupos sueltos no se pueden acotar (pueden unirse).
            var cota = parcial
            for resto in orden[k...] {
                cota += opciones[resto].map { o in elegidos.reduce(0) { $0 + $1.distancia(hasta: o) } }.min() ?? 0
            }
            if mejorCoste.0 == 1 && cota > mejorCoste.1 { return }
            let indice = orden[k]
            for opcion in opciones[indice] where !elegidos.contains(opcion) {
                let suma = elegidos.reduce(0) { $0 + $1.distancia(hasta: opcion) }
                if mejorCoste.0 == 1 && parcial + suma > mejorCoste.1 { continue }
                elegidos.append(opcion)
                asignacion[indice] = opcion
                buscar(k + 1, parcial + suma)
                elegidos.removeLast()
                asignacion[indice] = nil
            }
        }
        buscar(0, 0)
        return mejor
    }

    /// Cuántos grupos de notas unidas por la red forman unos puntos.
    package static func grupos(_ puntos: [PuntoDelTonnetz]) -> Int {
        var pendientes = Set(puntos)
        var grupos = 0
        while let inicio = pendientes.first {
            grupos += 1
            pendientes.remove(inicio)
            var cola = [inicio]
            while let punto = cola.popLast() {
                for vecino in punto.vecinos where pendientes.contains(vecino) {
                    pendientes.remove(vecino)
                    cola.append(vecino)
                }
            }
        }
        return grupos
    }

    /// La colocación voraz: en cada vuelta, el elemento que puede quedar más cerca de los ya
    /// colocados, en el punto que menos se aleja de todos.
    package static func colocarVoraz(_ elementos: [Int], candidatos: (Int, ClosedRange<Int>) -> [PuntoDelTonnetz]) -> [PuntoDelTonnetz] {
        guard let primero = elementos.first else { return [] }
        let origen = PuntoDelTonnetz(quintas: 0, terceras: 0)
        // El primero, en la fila 0 (con ortografía) o lo más cerca posible del origen.
        let inicial = candidatos(primero, 0...0).min { $0.distancia(hasta: origen) < $1.distancia(hasta: origen) }
            ?? candidatos(primero, -2...2).min { $0.distancia(hasta: origen) < $1.distancia(hasta: origen) }!
        var colocados: [Int: PuntoDelTonnetz] = [primero: inicial]
        var pendientes = Array(elementos.dropFirst())
        while !pendientes.isEmpty {
            let filas = colocados.values.map(\.terceras)
            let cerca = (filas.min()! - 3)...(filas.max()! + 3)
            var mejor: (indice: Int, punto: PuntoDelTonnetz, coste: (Int, Int, Int))?
            for (i, elemento) in pendientes.enumerated() {
                for punto in candidatos(elemento, cerca) {
                    let distancias = colocados.values.map { $0.distancia(hasta: punto) }
                    // Lo más cerca del vecino más próximo, después del conjunto y, a igualdad, del origen.
                    let coste = (distancias.min()!, distancias.reduce(0, +), punto.distancia(hasta: origen))
                    if mejor == nil || coste < mejor!.coste { mejor = (i, punto, coste) }
                }
            }
            colocados[pendientes[mejor!.indice]] = mejor!.punto
            pendientes.remove(at: mejor!.indice)
        }
        return elementos.map { colocados[$0]! }
    }

    // MARK: Dibujo

    /// El Tonnetz como imagen SVG: la red alrededor de las notas, con las notas marcadas, sus
    /// intervalos de quinta y tercera resaltados y las tríadas completas rellenas (mayores en
    /// naranja, menores en azul). Con clases de altura se marcan todas las repeticiones de cada
    /// clase en la red, que es un toro. En un recorrido, unas flechas rojas unen los centros de
    /// sus triángulos y debajo se escriben los acordes con la transformación de cada paso (P, L,
    /// R o, entre tríadas que no son vecinas, la secuencia más corta). Encima va un título (el
    /// acorde, la escala, las notas o el recorrido) y debajo, una leyenda de lo que aparece.
    ///
    /// - Parameters:
    ///   - notacion: la de los nombres de las notas.
    ///   - margen: cuántas filas y columnas de red se dibujan alrededor de las notas; si es `nil`,
    ///     una con ortografía y dos con clases de altura, para que se vean sus repeticiones.
    ///   - paso: la distancia entre dos notas vecinas, en píxeles; si es `nil`, 64, o 88 en un
    ///     recorrido, para que quepan las flechas.
    ///   - titulo: el título; si es `nil`, el que corresponda, y si es "", ninguno.
    ///   - leyenda: si se dibuja la leyenda.
    public func svg(notacion: Notacion = .espanol, margen: Int? = nil, paso: Double? = nil,
                    titulo: String? = nil, leyenda: Bool = true) -> String {
        let paso = paso ?? (recorrido.isEmpty ? 64 : 88)
        let margen = margen ?? (tieneOrtografia ? 1 : 2)
        let altura = paso * 0.8660254037844386   // √3/2, entre dos filas
        let trazado = Tonnetz.trazado(paso: paso)
        func x(_ p: PuntoDelTonnetz) -> Double { trazado.centro(de: p.coordenada).x }
        func y(_ p: PuntoDelTonnetz) -> Double { trazado.centro(de: p.coordenada).y }

        // La ventana: un rectángulo alrededor de las notas.
        let base = puntos.isEmpty ? [PuntoDelTonnetz(quintas: 0, terceras: 0)] : puntos
        let filas = (base.map(\.terceras).min()! - margen)...(base.map(\.terceras).max()! + margen)
        // En unidades de `paso` y con la fórmula exacta (a + b/2), no con `x`: los bordes caen en
        // medios enteros y un error de redondeo cambiaría las columnas que se dibujan.
        func columna(_ p: PuntoDelTonnetz) -> Double { Double(p.quintas) + Double(p.terceras) / 2 }
        let minX = (base.map(columna).min()! - Double(margen) - 0.5) * paso
        let maxX = (base.map(columna).max()! + Double(margen) + 0.5) * paso
        var red: [PuntoDelTonnetz] = []
        for b in filas {
            let desde = Int((minX / paso - Double(b) / 2).rounded(.up))
            let hasta = Int((maxX / paso - Double(b) / 2).rounded(.down))
            if desde <= hasta { for a in desde...hasta { red.append(PuntoDelTonnetz(quintas: a, terceras: b)) } }
        }
        let enRed = Set(red)
        // Los puntos marcados: los de las notas o, sin ortografía, todos los de sus clases.
        let marcados = DibujoSVG.marcar(puntos, en: red, clave: tieneOrtografia ? nil : { $0.claseDeAltura }).marcados
        let radio = paso * 0.26
        let borde = radio + paso * 0.1
        // El título de un recorrido: "Do –R→ Lam –L→ Fa".
        let pie = DibujoSVG.titulo(deRecorrido: recorrido, notacion, acordes: acordesDelRecorrido)
        let ancho = maxX - minX + 2 * borde
        let arriba = y(PuntoDelTonnetz(quintas: 0, terceras: filas.upperBound)) - borde
        let alto = Double(filas.count - 1) * altura + 2 * borde
        let f = DibujoSVG.f
        let origenX = minX - borde
        var hayLados = false

        var svg = ""
        // Tríadas.
        let triadasDibujadas = DibujoSVG.triadas(en: red, marcados: marcados)
        for triada in triadasDibujadas {
            let puntosTexto = triada.vertices.map { "\(f(x($0))),\(f(y($0)))" }.joined(separator: " ")
            svg += "  <polygon points=\"\(puntosTexto)\" fill=\"\(triada.mayor ? DibujoSVG.Color.mayor : DibujoSVG.Color.menor)\" fill-opacity=\"0.55\"/>\n"
        }
        // Aristas: grises, y resaltadas entre notas marcadas.
        for punto in red {
            for paso in [(1, 0), (0, 1), (1, -1)] {
                let otro = PuntoDelTonnetz(quintas: punto.quintas + paso.0, terceras: punto.terceras + paso.1)
                guard enRed.contains(otro) else { continue }
                let resaltada = marcados.contains(punto) && marcados.contains(otro)
                if resaltada { hayLados = true }
                svg += "  <line x1=\"\(f(x(punto)))\" y1=\"\(f(y(punto)))\" x2=\"\(f(x(otro)))\" y2=\"\(f(y(otro)))\" "
                svg += resaltada ? "stroke=\"#333333\" stroke-width=\"3\"/>\n" : "stroke=\"#cccccc\" stroke-width=\"1\"/>\n"
            }
        }
        // Recorrido: flechas de triángulo a triángulo.
        svg += DibujoSVG.flechas(recorrido, centro: { $0.centro }, paso: paso)
        // Notas.
        for punto in red {
            let marcado = marcados.contains(punto)
            let nombre = tieneOrtografia ? self.nombre(de: punto).nombreCompacto(en: notacion) : String(punto.claseDeAltura)
            svg += "  <circle cx=\"\(f(x(punto)))\" cy=\"\(f(y(punto)))\" r=\"\(f(radio))\" "
            svg += marcado ? "fill=\"\(DibujoSVG.Color.nota)\" stroke=\"\(DibujoSVG.Color.nota)\"/>\n" : "fill=\"#ffffff\" stroke=\"#bbbbbb\"/>\n"
            svg += "  <text x=\"\(f(x(punto)))\" y=\"\(f(y(punto)))\" text-anchor=\"middle\" dominant-baseline=\"central\" "
            svg += "font-size=\"\(f(paso * (nombre.count > 3 ? 0.17 : 0.22)))\" fill=\"\(marcado ? "#ffffff" : "#777777")\""
            svg += marcado ? " font-weight=\"bold\">" : ">"
            svg += DibujoSVG.escapar(nombre) + "</text>\n"
        }

        // La leyenda: solo lo que aparece.
        var entradas: [EntradaDeLeyenda] = []
        if leyenda && !puntos.isEmpty {
            func entrada(_ muestra: EntradaDeLeyenda.Muestra, _ texto: DibujoSVG.Texto) {
                entradas.append(EntradaDeLeyenda(muestra: muestra, texto: texto.en(notacion)))
            }
            entrada(.circulo(relleno: DibujoSVG.Color.nota, borde: DibujoSVG.Color.nota), tieneOrtografia ? .nota : .claseDeAltura)
            if hayLados { entrada(.linea("#333333", grosor: 3), .intervalos) }
            if triadasDibujadas.contains(where: \.mayor) { entrada(.triangulo(DibujoSVG.Color.mayor), .triadaMayor) }
            if triadasDibujadas.contains(where: { !$0.mayor }) { entrada(.triangulo(DibujoSVG.Color.menor), .triadaMenor) }
            if !recorrido.isEmpty { entrada(.flecha, .pasoDelRecorrido) }
        }
        let titulo = titulo ?? (pie.isEmpty ? (origen?.titulo(notacion) ?? "") : pie)
        return DibujoSVG.componer(caja: (origenX, arriba, ancho, alto), cuerpo: svg, titulo: titulo,
                                  leyenda: entradas, paso: paso)
    }
}

extension Tonnetz: CustomStringConvertible {
    /// "Do (0, 0) · Mi (0, 1) · Sol (1, 0)".
    public var description: String {
        puntos.map { (tieneOrtografia ? nombre(de: $0).description : String($0.claseDeAltura)) + " \($0)" }
            .joined(separator: " · ")
    }
}
