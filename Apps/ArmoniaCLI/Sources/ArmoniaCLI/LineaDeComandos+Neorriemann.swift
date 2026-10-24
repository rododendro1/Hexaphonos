import Armonia
import Foundation

// MARK: - Neorriemanniano y conducción parsimoniosa

extension LineaDeComandos {
    /// `vecinos Sol7`: los acordes de su familia a un semitono.
    static func vecinos(_ argumentos: [String], _ notacion: Notacion) throws -> ResultadoDeOrden {
        var argumentos = Argumentos(argumentos)
        guard let voces = argumentos.quitarNumero("--voces", "--voices", en: 1...2, porDefecto: 1) else {
            return uso(.vocesFueraDeRango, notacion)
        }
        // `--ampliada`: la familia de las séptimas con los maj7, para un acorde de las séptimas.
        let tipos = argumentos.quitarMarca("--ampliada", "--extended") ? TipoDeAcorde.familiaDeSeptimasAmpliada : nil
        let acordes = argumentos.restantes
        guard acordes.count == 1 else { return uso(.unAcordeDeVecinos, notacion) }
        let acorde = try Acorde(leyendo: acordes[0])
        let pasos = tipos.map { $0.contains(acorde.tipo) ? acorde.vecinosParsimoniosos(voces: voces, tipos: $0) : [] }
            ?? acorde.vecinosParsimoniosos(voces: voces)
        guard !pasos.isEmpty else {
            return uso(.vecinosSinFamilia, notacion)
        }
        return bien(pasos.map { $0.texto(en: notacion) }.joined(separator: "\n"))
    }

    /// `conduccion-parsimoniosa Sol7 Rem7`: Sol7 –Si→Do→ … paso a paso.
    static func caminoParsimonioso(_ argumentos: [String], _ notacion: Notacion) throws -> ResultadoDeOrden {
        var argumentos = Argumentos(argumentos)
        guard let voces = argumentos.quitarNumero("--voces", "--voices", en: 1...2, porDefecto: 1) else {
            return uso(.vocesFueraDeRango, notacion)
        }
        // `--ampliada`: la familia de las séptimas con los maj7, para un acorde de las séptimas.
        let tipos = argumentos.quitarMarca("--ampliada", "--extended") ? TipoDeAcorde.familiaDeSeptimasAmpliada : nil
        let acordes = argumentos.restantes
        guard acordes.count == 2 else { return uso(.dosAcordesDeCamino, notacion) }
        let origen = try Acorde(leyendo: acordes[0]), destino = try Acorde(leyendo: acordes[1])
        guard let camino = Tonnetz.caminoParsimonioso(desde: origen, hasta: destino, voces: voces, tipos: tipos) else {
            return uso(.caminoSinConexion, notacion)
        }
        var texto = Acorde(origen.fundamental, origen.tipo).cifrado(en: notacion)
        for paso in camino {
            texto += " –" + paso.movimientos.map { $0.texto(en: notacion) }.joined(separator: ", ") + "→ " + paso.acorde.cifrado(en: notacion)
        }
        return bien(texto + "\n" + Mensaje.pasos(camino.count).texto(en: notacion))
    }

    /// `plr Do PLR`: la tríada tras cada paso. `plr Do Mibm`: el camino más corto.
    static func plr(_ argumentos: [String], _ notacion: Notacion) throws -> ResultadoDeOrden {
        guard argumentos.count >= 2 else { return uso(.faltanPasosDePLR, notacion) }
        let origen = try Acorde(leyendo: argumentos[0])
        guard Tonnetz.Triada(origen) != nil else { return uso(.plrSoloTriadas(camino: false), notacion) }
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
            return bien(texto + "\n" + Mensaje.ciclo(ciclo).texto(en: notacion) + ", "
                        + Mensaje.triadas(ciclo.longitud).texto(en: notacion))
        } else {
            let destino = try Acorde(leyendo: resto)
            guard let camino = Tonnetz.camino(desde: origen, hasta: destino) else {
                return uso(.plrSoloTriadas(camino: true), notacion)
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
        let cuantos = Mensaje.pasos(pasos.count).texto(en: notacion)
        return bien(texto + "\n" + (pasos.isEmpty ? cuantos : pasos.map(\.rawValue).joined() + ", " + cuantos))
    }
}
