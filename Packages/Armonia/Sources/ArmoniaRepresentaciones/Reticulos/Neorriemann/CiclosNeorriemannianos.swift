import ArmoniaNucleo
import ArmoniaTeoria
// Los ciclos neorriemannianos: alternando dos de las transformaciones P, L y R se vuelve a la
// tríada de partida, recorriendo en el Tonnetz una banda de triángulos.
//
//   hexatónico (P, L): seis tríadas, Do – Dom – La♭ – La♭m – Mi – Mim (Cohn, 1996);
//   octatónico (P, R): ocho, Do – Dom – Mi♭ – Mi♭m – Sol♭ – Fa♯m – La – Lam;
//   LR (L, R): las veinticuatro, por quintas, Do – Mim – Sol – Sim – Re…
//
// Con ortografía, el ciclo no se cierra: tras seis pasos del hexatónico, Do llega a Re♭♭. Por
// eso cada tríada se escribe con la ortografía más sencilla (Mi, no Fa♭; Fa♯m, no Sol♭m) y la
// última es la de partida. En el dibujo, la banda sigue recta y los puntos llevan el nombre de
// la primera tríada del ciclo que los toca.

import Foundation

/// Un ciclo de tríadas que se cierra alternando dos transformaciones neorriemannianas.
///
///     Acorde("Do").ciclo(.hexatonico)    // [Do, Dom, La♭, La♭m, Mi, Mim, Do]
///     Tonnetz(ciclo: .octatonico, desde: "Do").svg()
public enum CicloNeorriemanniano: String, CaseIterable, Hashable, Sendable, CustomStringConvertible {
    /// P y L: seis tríadas, que se reparten las seis notas de una escala hexatónica.
    case hexatonico
    /// P y R: ocho tríadas, con las notas de una escala octatónica.
    case octatonico
    /// L y R: las veinticuatro tríadas mayores y menores, avanzando por quintas.
    case lr

    /// Las dos transformaciones que se alternan, empezando por la primera.
    public var transformaciones: [TransformacionNeorriemanniana] {
        switch self {
        case .hexatonico: return [.p, .l]
        case .octatonico: return [.p, .r]
        case .lr: return [.l, .r]
        }
    }

    /// Cuántas tríadas distintas tiene: 6, 8 o 24.
    public var longitud: Int {
        switch self {
        case .hexatonico: return 6
        case .octatonico: return 8
        case .lr: return 24
        }
    }

    /// "ciclo hexatónico", "ciclo octatónico" o "ciclo LR".
    public var nombre: String {
        switch self {
        case .hexatonico: return "ciclo hexatónico"
        case .octatonico: return "ciclo octatónico"
        case .lr: return "ciclo LR"
        }
    }

    /// "hexatonic cycle", "octatonic cycle" o "LR cycle".
    public var nombreEnIngles: String {
        switch self {
        case .hexatonico: return "hexatonic cycle"
        case .octatonico: return "octatonic cycle"
        case .lr: return "LR cycle"
        }
    }

    /// En los ocho idiomas de los textos: "ciclo hexatónico", "hexatonic cycle", "cicle hexatònic",
    /// "ciclo hexatónico", "ziklo hexatonikoa".
    public func nombre(en notacion: Nomenclatura) -> String {
        switch self {
        case .hexatonico:
            return Traduccion(nombre, nombreEnIngles, ca: "cicle hexatònic", gl: "ciclo hexatónico",
                              eu: "ziklo hexatonikoa",
                              pt: "ciclo hexatônico", fr: "cycle hexatonique", it: "ciclo esatonico").en(notacion)
        case .octatonico:
            return Traduccion(nombre, nombreEnIngles, ca: "cicle octatònic", gl: "ciclo octatónico",
                              eu: "ziklo oktatonikoa",
                              pt: "ciclo octatônico", fr: "cycle octatonique", it: "ciclo ottatonico").en(notacion)
        case .lr:
            return Traduccion(nombre, nombreEnIngles, ca: "cicle LR", gl: "ciclo LR", eu: "LR zikloa",
                              pt: "ciclo LR", fr: "cycle LR", it: "ciclo LR").en(notacion)
        }
    }

    public var description: String { nombre }

    /// Lee "hexatónico", "hexatonico", "hexatonic", "octatónico", "octatonic", "LR"… o el ciclo
    /// por sus transformaciones ("PL", "PR", "LR").
    public init?(leyendo texto: String) {
        let limpio = texto.lowercased().folding(options: .diacriticInsensitive, locale: nil)
            .replacingOccurrences(of: "ciclo ", with: "").replacingOccurrences(of: " cycle", with: "")
            .trimmingCharacters(in: .whitespaces)
        switch limpio {
        case "hexatonico", "hexatonic", "pl", "lp": self = .hexatonico
        case "octatonico", "octatonic", "pr", "rp": self = .octatonico
        case "lr", "rl": self = .lr
        default: return nil
        }
    }
}

extension Acorde {
    /// Las tríadas de un ciclo desde esta, hasta volver a ella (que se repite al final), cada
    /// una con la ortografía más sencilla; `nil` si no es una tríada mayor o menor.
    ///
    ///     Acorde("Do").ciclo(.hexatonico)    // [Do, Dom, La♭, La♭m, Mi, Mim, Do]
    public func ciclo(_ ciclo: CicloNeorriemanniano) -> [Acorde]? {
        guard let inicio = Tonnetz.Triada(self) else { return nil }
        var triadas = [inicio]
        while triadas.count <= ciclo.longitud {
            let siguiente = triadas.last!.transformar(ciclo.transformaciones[(triadas.count - 1) % 2])
            triadas.append(triadas.count == ciclo.longitud ? inicio : siguiente.sencilla)
        }
        return triadas.map(\.acorde)
    }
}

extension Tonnetz.Triada {
    /// La misma tríada escrita como su enarmónica (la fundamental, doce quintas más allá) si
    /// tiene dobles alteraciones o si la enarmónica lleva al menos dos alteraciones menos: Fa♭
    /// pasa a Mi y Sol♭m (con Si♭♭) a Fa♯m, pero La♭m sigue siendo La♭m.
    package var sencilla: Tonnetz.Triada {
        func alteraciones(_ triada: Tonnetz.Triada) -> Int {
            triada.vertices.map { abs($0.nota.alteracion.semitonos) }.reduce(0, +)
        }
        func conDobles(_ triada: Tonnetz.Triada) -> Bool {
            triada.vertices.contains { abs($0.nota.alteracion.semitonos) > 1 }
        }
        let enarmonicas = [-12, 12].map { desplazamiento in
            Tonnetz.Triada(fundamental: PuntoDelTonnetz(quintas: fundamental.quintas + desplazamiento,
                                                        terceras: fundamental.terceras), mayor: mayor)
        }
        let mejor = enarmonicas.min { alteraciones($0) < alteraciones($1) }!
        if conDobles(self) && !conDobles(mejor) || alteraciones(mejor) <= alteraciones(self) - 2 { return mejor }
        return self
    }
}

extension Tonnetz {
    /// Un ciclo neorriemanniano dibujado como recorrido: la banda de triángulos de la tríada de
    /// partida a la misma tríada, con los nombres de `Acorde.ciclo(_:)`. `nil` si el acorde no
    /// es una tríada mayor o menor.
    ///
    ///     Tonnetz(ciclo: .hexatonico, desde: "Do")
    public init?(ciclo: CicloNeorriemanniano, desde acorde: Acorde) {
        guard let acordes = acorde.ciclo(ciclo), let colocado = Tonnetz(recorrido: [acorde]) else { return nil }
        // La banda, recta: cada triángulo, el vecino del anterior.
        var triadas = colocado.recorrido
        for i in 0..<ciclo.longitud {
            triadas.append(triadas.last!.transformar(ciclo.transformaciones[i % 2]))
        }
        var puntos: [PuntoDelTonnetz] = []
        var nombres: [PuntoDelTonnetz: Nota] = [:]
        for (triada, acordeDelCiclo) in zip(triadas, acordes) {
            for vertice in triada.vertices {
                if !puntos.contains(vertice) { puntos.append(vertice) }
                if nombres[vertice] == nil {
                    nombres[vertice] = acordeDelCiclo.notas.first { $0.claseDeAltura == vertice.claseDeAltura }
                }
            }
        }
        self.init(puntos: puntos, conOrtografia: true, recorrido: triadas)
        self.nombres = nombres
        self.acordesDelRecorrido = acordes
        self.origen = .ciclo(ciclo, acorde)
    }

    /// La nota que se escribe en un punto: la suya o, en un ciclo, la de la tríada que lo toca;
    /// en los puntos de alrededor, la enarmónica con menos alteraciones (y, entre Fa♯ y Sol♭, la
    /// del punto con nombre más cercano).
    package func nombre(de punto: PuntoDelTonnetz) -> Nota {
        guard !nombres.isEmpty else { return punto.nota }
        if let nota = nombres[punto] { return nota }
        func distancia(_ otro: PuntoDelTonnetz) -> Double {
            let dx = Double(otro.quintas - punto.quintas) + Double(otro.terceras - punto.terceras) / 2
            let dy = Double(otro.terceras - punto.terceras) * 0.8660254037844386
            return dx * dx + dy * dy
        }
        let cercano = puntos.min { (distancia($0), $0.terceras, $0.quintas) < (distancia($1), $1.terceras, $1.quintas) }!
        let cerca = nombres[cercano]!.pasosDeQuinta - cercano.pasosDeQuinta
        let opciones = (-3...3).map { Nota(pasosDeQuinta: punto.pasosDeQuinta + 12 * $0) }
        return opciones.min {
            (abs($0.alteracion.semitonos), abs($0.pasosDeQuinta - punto.pasosDeQuinta - cerca))
                < (abs($1.alteracion.semitonos), abs($1.pasosDeQuinta - punto.pasosDeQuinta - cerca))
        }!
    }
}
