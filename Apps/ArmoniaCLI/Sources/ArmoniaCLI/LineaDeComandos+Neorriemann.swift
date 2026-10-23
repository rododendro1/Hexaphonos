import Armonia
import Foundation

// MARK: - Neorriemanniano y conducción parsimoniosa

extension LineaDeComandos {
    /// Quita `--voces N` (1 o 2) de los argumentos.
    static func leerVoces(_ argumentos: inout [String]) -> Int? {
        guard let i = argumentos.firstIndex(of: "--voces") ?? argumentos.firstIndex(of: "--voices") else { return 1 }
        guard i + 1 < argumentos.count, let n = Int(argumentos[i + 1]), (1...2).contains(n) else { return nil }
        argumentos.removeSubrange(i...(i + 1))
        return n
    }

    /// `--ampliada`: la familia de las séptimas con los maj7, para un acorde de las séptimas.
    static func leerAmpliada(_ argumentos: inout [String]) -> [TipoDeAcorde]? {
        guard let i = argumentos.firstIndex(of: "--ampliada") ?? argumentos.firstIndex(of: "--extended") else { return nil }
        argumentos.remove(at: i)
        return TipoDeAcorde.familiaDeSeptimasAmpliada
    }

    /// `vecinos Sol7`: los acordes de su familia a un semitono.
    static func vecinos(_ argumentos: [String], _ notacion: Nomenclatura) throws -> ResultadoDeOrden {
        var argumentos = argumentos
        guard let voces = leerVoces(&argumentos) else { return uso("las voces que se mueven son 1 o 2: --voces 2") }
        let tipos = leerAmpliada(&argumentos)
        guard argumentos.count == 1 else { return uso("hace falta un acorde: armonia vecinos Sol7") }
        let acorde = try Acorde(leyendo: argumentos[0])
        let pasos = tipos.map { $0.contains(acorde.tipo) ? acorde.vecinosParsimoniosos(voces: voces, tipos: $0) : [] }
            ?? acorde.vecinosParsimoniosos(voces: voces)
        guard !pasos.isEmpty else {
            return uso("los vecinos se buscan entre séptimas de dominante, menores, semidisminuidas, disminuidas y maj7, o entre tríadas mayores, menores y aumentadas")
        }
        return bien(pasos.map { $0.texto(notacion) }.joined(separator: "\n"))
    }

    /// `camino Sol7 Rem7`: Sol7 –Si→Do→ … paso a paso.
    static func caminoParsimonioso(_ argumentos: [String], _ notacion: Nomenclatura) throws -> ResultadoDeOrden {
        var argumentos = argumentos
        guard let voces = leerVoces(&argumentos) else { return uso("las voces que se mueven son 1 o 2: --voces 2") }
        let tipos = leerAmpliada(&argumentos)
        guard argumentos.count == 2 else { return uso("hacen falta dos acordes: armonia camino Sol7 Rem7") }
        let origen = try Acorde(leyendo: argumentos[0]), destino = try Acorde(leyendo: argumentos[1])
        guard let camino = Tonnetz.caminoParsimonioso(desde: origen, hasta: destino, voces: voces, tipos: tipos) else {
            return uso("los dos acordes han de ser de la misma familia (séptimas, con o sin maj7, o tríadas) y estar conectados")
        }
        var texto = Acorde(origen.fundamental, origen.tipo).cifrado(en: notacion)
        for paso in camino {
            texto += " –" + paso.movimientos.map { $0.texto(notacion) }.joined(separator: ", ") + "→ " + paso.acorde.cifrado(en: notacion)
        }
        let cuantos = camino.count == 1 ? "1 paso" : "\(camino.count) pasos"
        return bien(texto + "\n" + (camino.isEmpty ? "ningún paso" : cuantos))
    }

    /// `plr Do PLR`: la tríada tras cada paso. `plr Do Mibm`: el camino más corto.
    static func plr(_ argumentos: [String], _ notacion: Nomenclatura) throws -> ResultadoDeOrden {
        guard argumentos.count >= 2 else { return uso("hacen falta una tríada y unos pasos u otra tríada: armonia plr Do PLR") }
        let origen = try Acorde(leyendo: argumentos[0])
        guard Tonnetz.Triada(origen) != nil else { return uso("P, L y R se aplican a tríadas mayores y menores: armonia plr Do PLR") }
        let resto = argumentos.dropFirst().joined(separator: " ")
        let pasos: [TransformacionNeorriemanniana]
        if let secuencia = TransformacionNeorriemanniana.secuencia(leyendo: resto) {
            pasos = secuencia
        } else if let ciclo = CicloNeorriemanniano(leyendo: resto) {
            // Do –P→ Dom –L→ La♭ … –L→ Do, con la ortografía más sencilla.
            let acordes = origen.ciclo(ciclo)!
            var texto = acordes[0].cifrado(en: notacion)
            for (i, acorde) in acordes.dropFirst().enumerated() {
                texto += " –\(ciclo.transformaciones[i % 2])→ " + acorde.cifrado(en: notacion)
            }
            let nombre = notacion.vocabulario == .ingles ? ciclo.nombreEnIngles : ciclo.nombre
            let triadas = notacion.vocabulario == .ingles ? "triads" : "tríadas"
            return bien(texto + "\n" + nombre + ", \(ciclo.longitud) " + triadas)
        } else {
            let destino = try Acorde(leyendo: resto)
            guard let camino = Tonnetz.camino(desde: origen, hasta: destino) else {
                return uso("P, L y R se aplican a tríadas mayores y menores: armonia plr Do Mibm")
            }
            pasos = camino
        }
        // Do –P→ Dom –L→ La♭
        var acorde = origen.transformar([])!
        var texto = acorde.cifrado(en: notacion)
        for paso in pasos {
            acorde = acorde.transformar(paso)!
            texto += " –\(paso)→ " + acorde.cifrado(en: notacion)
        }
        let cuantos = pasos.count == 1 ? "1 paso" : "\(pasos.count) pasos"
        return bien(texto + "\n" + (pasos.isEmpty ? "ningún paso" : pasos.map(\.rawValue).joined() + ", " + cuantos))
    }
}
