import ArmoniaNucleo
import ArmoniaTeoria
// Las transformaciones neorriemannianas: P, L y R cambian una tríada mayor o menor por la que
// comparte con ella dos notas, moviendo la tercera solo un semitono o un tono. En el Tonnetz
// son giros del triángulo sobre uno de sus lados:
//
//   P (homónima): sobre la quinta. Do ↔ Do menor.
//   L (cambio de sensible, Leittonwechsel): sobre la tercera menor. Do ↔ Mi menor.
//   R (relativa): sobre la tercera mayor. Do ↔ La menor.
//
// Las tres son involuciones (aplicadas dos veces, devuelven la tríada) y conservan la
// ortografía: R de Mi♭ es Do menor, no Si♯ menor. N, S y H son las compuestas habituales.

import Foundation

/// P, L o R: el paso de una tríada mayor o menor a una vecina en el Tonnetz.
///
///     Acorde("Do").transformar(.r)                 // Lam
///     Acorde("Do").transformar(leyendo: "LP")      // Mi
///     Tonnetz.camino(desde: "Do", hasta: "Mibm")   // [.p, .r, .p]
public enum TransformacionNeorriemanniana: String, CaseIterable, Hashable, Sendable, CustomStringConvertible {
    /// Paralela: la tercera sube o baja un semitono (Do ↔ Dom).
    case p = "P"
    /// Cambio de sensible: en mayor, la fundamental baja un semitono (Do → Mim); en menor, la
    /// quinta sube un semitono (Mim → Do).
    case l = "L"
    /// Relativa: en mayor, la quinta sube un tono (Do → Lam); en menor, la fundamental baja un
    /// tono (Lam → Do).
    case r = "R"

    public var description: String { rawValue }

    /// "homónima", "cambio de sensible" o "relativa".
    public var nombre: String {
        switch self {
        case .p: return "homónima"
        case .l: return "cambio de sensible"
        case .r: return "relativa"
        }
    }

    /// N (Nebenverwandt), RLP: Do → Fam. Lleva a la subdominante menor.
    public static let n: [TransformacionNeorriemanniana] = [.r, .l, .p]
    /// S (Slide), LPR: Do → Do♯m. Conserva la tercera y mueve las otras dos un semitono.
    public static let s: [TransformacionNeorriemanniana] = [.l, .p, .r]
    /// H (polo hexatónico), LPL: Do → Sol♯m. Mueve las tres notas un semitono.
    public static let h: [TransformacionNeorriemanniana] = [.l, .p, .l]

    /// Lee una secuencia como "PLR", "P L R", "R·L·P" o "LP-R", que se aplica de izquierda a
    /// derecha; N, S y H se desarrollan en sus tres pasos. `nil` si hay otra cosa.
    public static func secuencia(leyendo texto: String) -> [TransformacionNeorriemanniana]? {
        var resultado: [TransformacionNeorriemanniana] = []
        for caracter in texto.uppercased() {
            switch caracter {
            case "P": resultado.append(.p)
            case "L": resultado.append(.l)
            case "R": resultado.append(.r)
            case "N": resultado += n
            case "S": resultado += s
            case "H": resultado += h
            case " ", "·", "-", ",", ".", "*", "∘": continue
            default: return nil
            }
        }
        return resultado.isEmpty ? nil : resultado
    }

    /// La que lleva de una tríada a otra vecina, si la hay: `entre("Do", "Lam")` → `.r`.
    public static func entre(_ origen: Acorde, _ destino: Acorde) -> TransformacionNeorriemanniana? {
        allCases.first { origen.transformar($0).map { $0 == destino.enEstadoFundamental } ?? false }
    }
}

extension Tonnetz.Triada {
    /// El triángulo de una tríada mayor o menor, con la fundamental en la fila 0 (en el punto
    /// (pasos de quinta, 0)); `nil` para otros acordes. Se ignora la inversión.
    public init?(_ acorde: Acorde) {
        guard acorde.tipo == .mayor || acorde.tipo == .menor else { return nil }
        self.init(fundamental: PuntoDelTonnetz(quintas: acorde.fundamental.pasosDeQuinta, terceras: 0),
                  mayor: acorde.tipo == .mayor)
    }

    /// El triángulo vecino por uno de sus lados.
    public func transformar(_ transformacion: TransformacionNeorriemanniana) -> Tonnetz.Triada {
        let a = fundamental.quintas, b = fundamental.terceras
        func triada(_ a: Int, _ b: Int, _ mayor: Bool) -> Tonnetz.Triada {
            Tonnetz.Triada(fundamental: PuntoDelTonnetz(quintas: a, terceras: b), mayor: mayor)
        }
        switch (transformacion, mayor) {
        case (.p, _): return triada(a, b, !mayor)          // el lado de la quinta
        case (.l, true): return triada(a, b + 1, false)    // el de la tercera menor (Mi–Sol)
        case (.l, false): return triada(a, b - 1, true)
        case (.r, true): return triada(a - 1, b + 1, false) // el de la tercera mayor (Do–Mi)
        case (.r, false): return triada(a + 1, b - 1, true)
        }
    }

    /// Aplica las transformaciones de izquierda a derecha.
    public func transformar(_ secuencia: [TransformacionNeorriemanniana]) -> Tonnetz.Triada {
        secuencia.reduce(self) { $0.transformar($1) }
    }

    /// Las tres tríadas vecinas, por P, L y R.
    public var vecinas: [Tonnetz.Triada] { TransformacionNeorriemanniana.allCases.map(transformar) }
}

extension Acorde {
    /// Esta tríada en estado fundamental (sin inversión).
    package var enEstadoFundamental: Acorde { Acorde(fundamental, tipo) }

    /// La tríada transformada por P, L o R, en estado fundamental; `nil` si no es una tríada
    /// mayor o menor.
    ///
    ///     Acorde("Do").transformar(.p)    // Dom
    ///     Acorde("Lam").transformar(.l)   // Fa
    public func transformar(_ transformacion: TransformacionNeorriemanniana) -> Acorde? {
        Tonnetz.Triada(self)?.transformar(transformacion).acorde
    }

    /// La tríada tras una secuencia, de izquierda a derecha: `transformar([.l, .p])` es P de L.
    public func transformar(_ secuencia: [TransformacionNeorriemanniana]) -> Acorde? {
        Tonnetz.Triada(self)?.transformar(secuencia).acorde
    }

    /// La tríada tras una secuencia escrita: `transformar(leyendo: "PLR")`, `transformar(leyendo: "N")`.
    public func transformar(leyendo secuencia: String) -> Acorde? {
        TransformacionNeorriemanniana.secuencia(leyendo: secuencia).flatMap(transformar)
    }
}

extension Tonnetz {
    /// La secuencia más corta de P, L y R que lleva de una tríada a otra (vacía si son la
    /// misma); `nil` si alguno de los acordes no es una tríada mayor o menor. Con ortografía,
    /// Do♯ y Re♭ son destinos distintos; con `enarmonico: true` basta que suenen igual.
    /// A igual longitud, se prefiere P, luego L y luego R al principio del camino.
    ///
    ///     Tonnetz.camino(desde: "Do", hasta: "Lab")    // [.p, .l]: Do → Dom → La♭
    public static func camino(desde origen: Acorde, hasta destino: Acorde,
                              enarmonico: Bool = false) -> [TransformacionNeorriemanniana]? {
        guard let inicio = Triada(origen), let meta = Triada(destino) else { return nil }
        func llega(_ triada: Triada) -> Bool {
            guard triada.mayor == meta.mayor else { return false }
            return enarmonico ? triada.fundamental.claseDeAltura == meta.fundamental.claseDeAltura
                              : triada.fundamental.pasosDeQuinta == meta.fundamental.pasosDeQuinta
        }
        // Por la red de triángulos, que es infinita y conexa: siempre llega.
        return caminoMasCorto(desde: inicio, clave: { $0 },
                              vecinos: { triada in TransformacionNeorriemanniana.allCases.map { ($0, triada.transformar($0)) } },
                              llega: llega)
    }

    /// Un recorrido de tríadas mayores y menores por el Tonnetz: cada una, en el triángulo más
    /// cercano a la anterior, de modo que los pasos de P, L o R son triángulos vecinos. `nil` si
    /// algún acorde no es una tríada mayor o menor. `svg()` dibuja el recorrido con flechas.
    ///
    ///     Tonnetz(recorrido: ["Do", "Lam", "Fa", "Rem"])
    public init?(recorrido acordes: [Acorde]) {
        var triadas: [Triada] = []
        for acorde in acordes {
            guard let triada = Triada(acorde) else { return nil }
            guard let anterior = triadas.last else {
                // La primera, como al colocar el acorde solo.
                let puntos = Tonnetz(acorde).puntos
                triadas.append(Triada(fundamental: puntos[0], mayor: triada.mayor))
                continue
            }
            // Las copias del triángulo, desplazadas por (4, −1), que da la misma nota.
            let b0 = anterior.fundamental.terceras
            let copias = ((b0 - 3)...(b0 + 3)).map { b in
                Triada(fundamental: PuntoDelTonnetz(quintas: triada.fundamental.quintas - 4 * b, terceras: b),
                       mayor: triada.mayor)
            }
            triadas.append(copias.min { Tonnetz.separacion(anterior, $0) < Tonnetz.separacion(anterior, $1) }!)
        }
        var puntos: [PuntoDelTonnetz] = []
        for vertice in triadas.flatMap(\.vertices) where !puntos.contains(vertice) { puntos.append(vertice) }
        self.init(puntos: puntos, conOrtografia: true, recorrido: triadas)
    }

    /// El recorrido por el camino más corto entre dos tríadas: `Tonnetz(caminoDesde: "Do", hasta: "Mibm")`.
    public init?(caminoDesde origen: Acorde, hasta destino: Acorde) {
        guard let camino = Tonnetz.camino(desde: origen, hasta: destino) else { return nil }
        let inicio = Triada(origen)!
        let triadas = camino.reduce(into: [inicio]) { $0.append($0.last!.transformar($1)) }
        self.init(recorrido: triadas.map(\.acorde))
    }

    /// Distancia al cuadrado entre los centros de dos triángulos, en el dibujo.
    package static func separacion(_ uno: Triada, _ otro: Triada) -> Double {
        let (x1, y1) = uno.centro, (x2, y2) = otro.centro
        return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
    }
}

extension Tonnetz.Triada {
    /// El centro del triángulo en el dibujo, con paso 1.
    package var centro: (Double, Double) {
        let xs = vertices.map { Double($0.quintas) + Double($0.terceras) / 2 }
        let ys = vertices.map { -Double($0.terceras) * 0.8660254037844386 }
        return (xs.reduce(0, +) / 3, ys.reduce(0, +) / 3)
    }
}
