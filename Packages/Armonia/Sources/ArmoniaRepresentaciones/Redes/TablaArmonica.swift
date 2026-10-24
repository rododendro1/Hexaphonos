import ArmoniaNucleo
import ArmoniaTeoria
import Hexagonos
// La tabla armónica (Harmonic Table): la disposición de notas en hexágonos de teclados
// isomórficos como el C-Thru AXiS. Hacia arriba, una quinta justa; en diagonal hacia arriba a la
// derecha, una tercera mayor; en diagonal hacia arriba a la izquierda, una tercera menor.
//
// Es el dual del Tonnetz: la misma red, con cada nota en un hexágono en lugar de un punto, de
// modo que una tríada son tres hexágonos que se tocan en un vértice. Por eso usa sus mismas
// coordenadas, (a, b) = a quintas y b terceras mayores, y su misma colocación. Además puede
// colocar alturas, como en el instrumento: el hexágono (a, b) suena 7a + 4b semitonos por encima
// de Do4, y cada altura está en un sitio concreto (afinación igual, sin ortografía).
//
// Los hexágonos se colocan y se dibujan con el paquete `Hexagonos` (Tonnetz+Hexagonos.swift): son
// hexágonos planos, en la rejilla del Tonnetz girada 120°.

import Foundation

/// Unas notas, un acorde, una escala, un conjunto de clases de altura o unas alturas en la tabla
/// armónica.
///
///     TablaArmonica(Acorde("Do")).svg()                   // tres hexágonos con un vértice común
///     TablaArmonica([Altura("Do3"), Altura("Sol3"), Altura("Mi4")]).svg()   // una disposición abierta
///
/// La forma de un acorde o una escala es la misma en todas las tonalidades: transportar es mover
/// la forma.
public struct TablaArmonica: Hashable, Sendable {
    /// Cómo se colocaron las notas.
    public enum Colocacion: Hashable, Sendable {
        /// Notas con su ortografía, como en el Tonnetz.
        case notas
        /// Clases de altura: la tabla se repite como un toro.
        case clasesDeAltura
        /// Alturas con octava: cada hexágono es una altura, como en el instrumento.
        case alturas
    }

    /// Los hexágonos de las notas, en el orden en que se dieron (sin repetir).
    public let puntos: [PuntoDelTonnetz]
    public let colocacion: Colocacion
    /// Las alturas dadas, con la colocación `.alturas`.
    public let alturas: [Altura]
    /// De dónde salen las notas, para el título del dibujo.
    package var origen: OrigenDelDibujo?
    /// Las tríadas de un recorrido, en orden (`init(recorrido:)`); vacío si no lo es.
    public private(set) var recorrido: [Tonnetz.Triada] = []
    /// En un ciclo, el nombre de cada hexágono y las tríadas con su ortografía, como en el Tonnetz.
    package var nombres: [PuntoDelTonnetz: Nota] = [:]
    package var acordesDelRecorrido: [Acorde] = []

    /// Las notas como en el Tonnetz, con los nombres de un ciclo si lo es.
    private var comoTonnetz: Tonnetz {
        var tonnetz = Tonnetz(puntos: puntos, tieneOrtografia: colocacion == .notas, recorrido: [])
        tonnetz.nombres = nombres
        return tonnetz
    }

    /// Un recorrido de tríadas mayores y menores, colocado como en el Tonnetz: cada una, junto a
    /// la anterior. `svg()` dibuja una flecha de tríada en tríada, entre los vértices donde se
    /// tocan sus tres hexágonos. `nil` si algún acorde no es una tríada mayor o menor.
    ///
    ///     TablaArmonica(recorrido: ["Do", "Lam", "Fa", "Rem"])
    public init?(recorrido acordes: [Acorde]) {
        guard let tonnetz = Tonnetz(recorrido: acordes) else { return nil }
        puntos = tonnetz.puntos
        colocacion = .notas
        alturas = []
        recorrido = tonnetz.recorrido
    }

    /// El camino más corto por P, L y R entre dos tríadas: `TablaArmonica(caminoDesde: "Do", hasta: "Mibm")`.
    public init?(caminoDesde origen: Acorde, hasta destino: Acorde) {
        guard let tonnetz = Tonnetz(caminoDesde: origen, hasta: destino) else { return nil }
        puntos = tonnetz.puntos
        colocacion = .notas
        alturas = []
        recorrido = tonnetz.recorrido
    }

    /// Un ciclo neorriemanniano en la tabla armónica, como `Tonnetz(ciclo:desde:)`: la banda de
    /// tríadas de la de partida a la misma, con los nombres de `Acorde.ciclo(_:)`.
    ///
    ///     TablaArmonica(ciclo: .octatonico, desde: "Do")
    public init?(ciclo: CicloNeorriemanniano, desde acorde: Acorde) {
        guard let tonnetz = Tonnetz(ciclo: ciclo, desde: acorde) else { return nil }
        puntos = tonnetz.puntos
        colocacion = .notas
        alturas = []
        recorrido = tonnetz.recorrido
        nombres = tonnetz.nombres
        acordesDelRecorrido = tonnetz.acordesDelRecorrido
        origen = tonnetz.origen
    }

    /// Coloca las notas con su ortografía, como `Tonnetz(_:)`.
    public init(_ notas: [Nota]) {
        puntos = Tonnetz(notas).puntos
        colocacion = .notas
        alturas = []
        origen = .notas(notas.reduce(into: []) { if !$0.contains($1) { $0.append($1) } })
    }

    public init(_ acorde: Acorde) { self.init(acorde.notas); origen = .acorde(acorde) }
    public init(_ escala: Escala) { self.init(escala.notas); origen = .escala(escala) }

    /// Coloca las clases de altura en la tabla de doce notas, como `Tonnetz(_:)`.
    public init(_ conjunto: ConjuntoDeClases) {
        puntos = Tonnetz(conjunto).puntos
        colocacion = .clasesDeAltura
        alturas = []
        origen = .conjunto(conjunto)
    }

    /// Coloca las alturas como en el instrumento: cada una en un hexágono que suena a esa altura,
    /// en la disposición más compacta, como en el Tonnetz. Las alturas enarmónicas comparten hexágono.
    public init(_ alturas: [Altura]) {
        var vistas: [Altura] = []
        for altura in alturas where !vistas.contains(where: { $0.midi == altura.midi }) { vistas.append(altura) }
        puntos = Tonnetz.colocar(vistas.map(\.midi)) { midi, filas in
            // Los puntos con 7a + 4b = midi − 60: uno de cada siete columnas, así que se amplían
            // las que se buscan para que siempre haya alguno.
            ((filas.lowerBound - 3)...(filas.upperBound + 3)).compactMap { b in
                let resto = midi - 60 - 4 * b
                return modulo(resto, 7) == 0 ? PuntoDelTonnetz(quintas: resto / 7, terceras: b) : nil
            }
        }
        colocacion = .alturas
        self.alturas = vistas
        origen = .alturas(vistas)
    }

    /// El número MIDI del hexágono, como en el instrumento: Do4 (60) en (0, 0).
    public static func midi(de punto: PuntoDelTonnetz) -> Int { 60 + 7 * punto.quintas + 4 * punto.terceras }

    /// Las tríadas mayores y menores completas: tres hexágonos que se tocan en un vértice.
    public var triadas: [Tonnetz.Triada] {
        comoTonnetz.triadas
    }

    /// ¿Están todas las notas unidas por hexágonos vecinos?
    public var esConexo: Bool { comoTonnetz.esConexo }

    // MARK: Dibujo

    /// La tabla como imagen SVG: hexágonos con la quinta hacia arriba, las notas rellenas, la
    /// primera (la tónica de una escala o la fundamental de un acorde) con borde naranja, el
    /// contorno de la forma en trazo grueso y un punto donde se tocan los hexágonos de cada
    /// tríada (naranja si es mayor, azul si es menor). Con clases de altura o alturas se marcan
    /// todos los hexágonos que suenan igual dentro de la ventana. En un recorrido, unas flechas rojas
    /// van de tríada en tríada. Encima va un título (el acorde, la escala, las notas, las alturas o
    /// la progresión) y debajo, una leyenda de lo que aparece.
    ///
    /// - Parameters:
    ///   - notacion: la de los nombres de las notas.
    ///   - margen: cuántos hexágonos se dibujan alrededor de las notas; si es `nil`, uno con
    ///     ortografía y dos en las demás colocaciones, para que se vean las repeticiones.
    ///   - paso: la distancia entre los centros de dos hexágonos vecinos, en píxeles; si es `nil`,
    ///     56, o 72 en un recorrido, para que quepan las flechas.
    ///   - titulo: el título; si es `nil`, el que corresponda, y si es "", ninguno.
    ///   - leyenda: si se dibuja la leyenda.
    public func svg(notacion: Notacion = .espanol, margen: Int? = nil, paso: Double? = nil,
                    titulo: String? = nil, leyenda: Bool = true) -> String {
        let paso = paso ?? (recorrido.isEmpty ? 56 : 72)
        let margen = margen ?? (colocacion == .notas ? 1 : 2)
        let coseno = 0.8660254037844386   // cos 30°
        let trazado = TablaArmonica.trazado(paso: paso)
        let radio = trazado.tamano.x   // del centro a un vértice
        func x(_ p: PuntoDelTonnetz) -> Double { trazado.centro(de: TablaArmonica.coordenada(de: p)).x }
        func y(_ p: PuntoDelTonnetz) -> Double { trazado.centro(de: TablaArmonica.coordenada(de: p)).y }
        /// Los seis vértices, empezando por el de la derecha (0°) y en sentido horario en pantalla.
        func vertices(_ p: PuntoDelTonnetz) -> [(Double, Double)] {
            trazado.vertices(de: TablaArmonica.coordenada(de: p)).map { ($0.x, $0.y) }
        }

        // La ventana: un rectángulo alrededor de las notas.
        let base = puntos.isEmpty ? [PuntoDelTonnetz(quintas: 0, terceras: 0)] : puntos
        let minX = base.map(x).min()! - Double(margen) * coseno * paso - paso * 0.1
        let maxX = base.map(x).max()! + Double(margen) * coseno * paso + paso * 0.1
        let minY = base.map(y).min()! - Double(margen) * paso - paso * 0.1
        let maxY = base.map(y).max()! + Double(margen) * paso + paso * 0.1
        var red: [PuntoDelTonnetz] = []
        let columnas = Int((minX / (coseno * paso)).rounded(.up))...Int((maxX / (coseno * paso)).rounded(.down))
        for b in columnas {
            // y = −(a + b/2)·paso entre minY y maxY.
            let desde = Int((-maxY / paso - Double(b) / 2).rounded(.up))
            let hasta = Int((-minY / paso - Double(b) / 2).rounded(.down))
            if desde <= hasta { for a in desde...hasta { red.append(PuntoDelTonnetz(quintas: a, terceras: b)) } }
        }

        // Los hexágonos marcados (con clases de altura o alturas, todos los que suenan igual) y los
        // de la primera nota.
        let clave: ((PuntoDelTonnetz) -> Int)?
        switch colocacion {
        case .notas: clave = nil
        case .clasesDeAltura: clave = { $0.claseDeAltura }
        case .alturas: clave = { TablaArmonica.midi(de: $0) }
        }
        let (marcados, principales) = DibujoSVG.marcar(puntos, en: red, clave: clave)
        // Los nombres de las alturas dadas, por número MIDI.
        let nombres = Dictionary(alturas.map { ($0.midi, $0.nota.nombreCompacto(en: notacion) + "\($0.octava)") },
                                 uniquingKeysWith: { uno, _ in uno })
        // Con bemoles en las alturas dadas, los demás hexágonos también los usan.
        let bemoles = alturas.contains { $0.nota.alteracion.simbolo.contains("♭") }
        let rotulos = comoTonnetz
        func nombre(_ p: PuntoDelTonnetz) -> String {
            switch colocacion {
            case .notas: return rotulos.nombre(de: p).nombreCompacto(en: notacion)
            case .clasesDeAltura: return String(p.claseDeAltura)
            case .alturas:
                let midi = TablaArmonica.midi(de: p)
                if let nombre = nombres[midi] { return nombre }
                let altura = Altura(midi: midi, preferirBemoles: bemoles)
                return altura.nota.nombreCompacto(en: notacion) + "\(altura.octava)"
            }
        }

        let borde = paso * 0.08
        let origenX = minX - radio - borde, origenY = minY - paso / 2 - borde
        let ancho = maxX - minX + 2 * (radio + borde), alto = maxY - minY + paso + 2 * borde
        let f = DibujoSVG.f
        /// El vértice a `angulo` grados (un múltiplo de 60°).
        func vertice(_ p: PuntoDelTonnetz, _ angulo: Double) -> (Double, Double) {
            vertices(p)[modulo(Int(angulo) / 60, 6)]
        }

        var svg = ""
        // Hexágonos (de lados horizontales arriba y abajo).
        for punto in red {
            let marcado = marcados.contains(punto)
            let esquinas = vertices(punto)
            svg += "  <polygon points=\"\(esquinas.map { "\(f($0.0)),\(f($0.1))" }.joined(separator: " "))\" "
            svg += marcado ? "fill=\"\(DibujoSVG.Color.nota)\" stroke=\"#ffffff\" stroke-width=\"1.5\"/>\n" : "fill=\"#f4f4f4\" stroke=\"#bbbbbb\" stroke-width=\"1\"/>\n"
        }
        // El contorno de la forma: los lados entre un hexágono marcado y uno que no lo está.
        // El vecino en la dirección θ comparte el lado entre los vértices θ − 30° y θ + 30°.
        let direcciones: [((Int, Int), Double)] = [((1, 0), 270), ((0, 1), 330), ((-1, 1), 30),
                                                    ((-1, 0), 90), ((0, -1), 150), ((1, -1), 210)]
        for punto in red where marcados.contains(punto) {
            for (desplazamiento, angulo) in direcciones {
                let vecino = PuntoDelTonnetz(quintas: punto.quintas + desplazamiento.0, terceras: punto.terceras + desplazamiento.1)
                guard !marcados.contains(vecino) else { continue }
                let (x1, y1) = vertice(punto, angulo - 30), (x2, y2) = vertice(punto, angulo + 30)
                svg += "  <line x1=\"\(f(x1))\" y1=\"\(f(y1))\" x2=\"\(f(x2))\" y2=\"\(f(y2))\" stroke=\"#111111\" stroke-width=\"3\" stroke-linecap=\"round\"/>\n"
            }
        }
        // La primera nota, con borde naranja.
        for punto in red where principales.contains(punto) {
            let esquinas = vertices(punto)
            svg += "  <polygon points=\"\(esquinas.map { "\(f($0.0)),\(f($0.1))" }.joined(separator: " "))\" "
            svg += "fill=\"none\" stroke=\"\(DibujoSVG.Color.primera)\" stroke-width=\"3.5\" transform=\"translate(\(f(x(punto))) \(f(y(punto)))) scale(0.86) translate(\(f(-x(punto))) \(f(-y(punto))))\"/>\n"
        }
        // Nombres.
        for punto in red {
            let marcado = marcados.contains(punto)
            let texto = nombre(punto)
            let tamano = paso * (texto.count > 4 ? 0.2 : texto.count > 3 ? 0.23 : 0.27)
            svg += "  <text x=\"\(f(x(punto)))\" y=\"\(f(y(punto)))\" text-anchor=\"middle\" dominant-baseline=\"central\" "
            svg += "font-size=\"\(f(tamano))\" fill=\"\(marcado ? "#ffffff" : "#888888")\""
            svg += marcado ? " font-weight=\"bold\">" : ">"
            svg += DibujoSVG.escapar(texto) + "</text>\n"
        }
        // Las tríadas: un punto en el vértice común de sus tres hexágonos.
        let triadas = DibujoSVG.triadas(en: red, marcados: marcados)
        for triada in triadas {
            let cx = triada.vertices.map(x).reduce(0, +) / 3, cy = triada.vertices.map(y).reduce(0, +) / 3
            svg += "  <circle cx=\"\(f(cx))\" cy=\"\(f(cy))\" r=\"\(f(paso * (recorrido.isEmpty ? 0.1 : 0.075)))\" fill=\"\(triada.mayor ? DibujoSVG.Color.mayor : DibujoSVG.Color.menor)\" "
            svg += "stroke=\"#111111\" stroke-width=\"1.5\"/>\n"
        }
        // Recorrido: flechas entre los vértices comunes de las tríadas.
        svg += DibujoSVG.flechas(recorrido, centro: { triada in
            (triada.vertices.map(x).reduce(0, +) / 3 / paso, triada.vertices.map(y).reduce(0, +) / 3 / paso)
        }, paso: paso)

        // La leyenda: solo lo que aparece.
        var entradas: [EntradaDeLeyenda] = []
        if leyenda && !puntos.isEmpty {
            func entrada(_ muestra: EntradaDeLeyenda.Muestra, _ texto: String) {
                entradas.append(EntradaDeLeyenda(muestra: muestra, texto: texto))
            }
            let nota: DibujoSVG.Texto = colocacion == .notas ? .nota : colocacion == .clasesDeAltura ? .claseDeAltura : .altura
            entrada(.hexagono(relleno: DibujoSVG.Color.nota, borde: DibujoSVG.Color.nota), nota.en(notacion))
            let primera = !recorrido.isEmpty ? DibujoSVG.Texto.fundamentalDelPrimerAcorde.en(notacion)
                : (origen ?? .notas([])).primera(notacion)
            entrada(.hexagono(relleno: DibujoSVG.Color.nota, borde: DibujoSVG.Color.primera), primera)
            entrada(.linea("#111111", grosor: 3), DibujoSVG.Texto.contorno.en(notacion))
            if triadas.contains(where: \.mayor) {
                entrada(.circulo(relleno: DibujoSVG.Color.mayor, borde: "#111111"), DibujoSVG.Texto.triadaMayor.en(notacion))
            }
            if triadas.contains(where: { !$0.mayor }) {
                entrada(.circulo(relleno: DibujoSVG.Color.menor, borde: "#111111"), DibujoSVG.Texto.triadaMenor.en(notacion))
            }
            if !recorrido.isEmpty { entrada(.flecha, DibujoSVG.Texto.pasoDelRecorrido.en(notacion)) }
        }
        return DibujoSVG.componer(caja: (origenX, origenY, ancho, alto), cuerpo: svg,
                                  titulo: titulo ?? (recorrido.isEmpty ? origen?.titulo(notacion) ?? "" : DibujoSVG.titulo(deRecorrido: recorrido, notacion, acordes: acordesDelRecorrido)), leyenda: entradas, paso: paso)
    }
}

extension TablaArmonica: CustomStringConvertible {
    /// "Do (0, 0) · Mi (0, 1) · Sol (1, 0)"; con alturas, "Do4 (0, 0) · …".
    public var description: String {
        switch colocacion {
        case .notas, .clasesDeAltura: return comoTonnetz.description
        case .alturas:
            return zip(alturas, puntos).map { "\($0.0) \($0.1)" }.joined(separator: " · ")
        }
    }
}

// Nombres anteriores, que se siguen aceptando.
extension TablaArmonica {
    @available(*, deprecated, renamed: "Colocacion")
    public typealias Modo = Colocacion
    @available(*, deprecated, renamed: "colocacion")
    public var modo: Colocacion { colocacion }
}
