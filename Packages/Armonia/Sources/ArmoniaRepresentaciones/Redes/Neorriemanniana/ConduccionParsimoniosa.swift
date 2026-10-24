import ArmoniaNucleo
import ArmoniaTeoria
// Conducción parsimoniosa: pasar de un acorde a otro moviendo las voces lo menos posible.
//
// P, L y R (TransformacionesNeorriemannianas.swift) son el caso de las tríadas mayores y menores.
// Aquí se generaliza a cualquier familia de acordes con el mismo número de notas, a la manera de
// Douthett y Steinbach (1998): dos acordes son vecinos si se pasa de uno a otro moviendo una voz
// un semitono (P₁,₀) o dos voces un semitono cada una (P₂,₀). Con las séptimas de dominante, menor,
// semidisminuida y disminuida, el grafo de P₁,₀ son sus «Power Towers»; con P₂,₀, entre séptimas de
// dominante y semidisminuidas, salen las transformaciones de Childs (1998). Con las tríadas mayores,
// menores y aumentadas, P₁,₀ da el «Cube Dance».
//
// Entre acordes de distinto tamaño (Sol7 → Do), `conduccionMinima(hasta:)` da la conducción con menos
// semitonos en total, duplicando las notas que haga falta.

import Foundation

extension TipoDeAcorde {
    /// Séptimas de dominante, menor, semidisminuida y disminuida: las «Power Towers» de Douthett y
    /// Steinbach, en las que cada una pasa a otra moviendo una voz un semitono.
    public static let familiaDeSeptimas: [TipoDeAcorde] = [.dominanteSeptima, .menorSeptima, .semidisminuido, .disminuidoSeptima]
    /// Tríadas mayores, menores y aumentadas: el «Cube Dance» de Douthett y Steinbach.
    public static let familiaDeTriadas: [TipoDeAcorde] = [.mayor, .menor, .aumentado]
    /// Las «Power Towers» con la séptima mayor (maj7): Domaj7 pasa a Do7 (Si→Si♭) y a Do♯ø7
    /// (Do→Do♯), y las séptimas de dominante y semidisminuidas ganan un vecino. Es la familia de
    /// los maj7; las otras séptimas siguen, salvo que se pida, en `familiaDeSeptimas`.
    public static let familiaDeSeptimasAmpliada: [TipoDeAcorde] = familiaDeSeptimas + [.mayorSeptimaMayor]
}

/// Una voz que se mueve de una nota a otra.
public struct MovimientoDeVoz: Hashable, Sendable, CustomStringConvertible {
    public let desde: Nota
    public let hasta: Nota
    /// Semitonos, hacia arriba (+) o hacia abajo (−), por el camino más corto (de −5 a +6).
    public let semitonos: Int

    public init(desde: Nota, hasta: Nota) {
        self.desde = desde
        self.hasta = hasta
        let d = modulo(hasta.claseDeAltura - desde.claseDeAltura, 12)
        semitonos = d > 6 ? d - 12 : d
    }

    /// "Fa→Mi"; con otra notación, `texto(en:)`.
    public var description: String { texto(en: .espanol) }

    public func texto(en notacion: Notacion) -> String {
        desde.nombreCompacto(en: notacion) + "→" + hasta.nombreCompacto(en: notacion)
    }
}

/// Un acorde vecino y las voces que se mueven para llegar a él.
public struct PasoParsimonioso: Hashable, Sendable, CustomStringConvertible {
    public let acorde: Acorde
    public let movimientos: [MovimientoDeVoz]

    /// "Sol♯o7 (Sol→Sol♯)".
    public var description: String { texto(en: .espanol) }

    public func texto(en notacion: Notacion) -> String {
        acorde.cifrado(en: notacion) + " (" + movimientos.map { $0.texto(en: notacion) }.joined(separator: ", ") + ")"
    }
}

extension Acorde {
    /// Las familias conocidas, en el orden en que se eligen.
    package static let familiasParsimoniosas: [[TipoDeAcorde]] = [TipoDeAcorde.familiaDeSeptimas, TipoDeAcorde.familiaDeTriadas, TipoDeAcorde.familiaDeSeptimasAmpliada]

    /// La familia a la que pertenece el acorde, si es una de las conocidas (la de las séptimas
    /// ampliada, solo para los maj7).
    package var familiaParsimoniosa: [TipoDeAcorde]? {
        Acorde.familiasParsimoniosas.first { $0.contains(tipo) }
    }

    /// Los acordes de la familia a los que se llega moviendo `voces` voces un semitono cada una.
    ///
    ///     Acorde("Sol7").vecinosParsimoniosos()          // Solm7 (Si→Si♭), Sol♯o7 (Sol→Sol♯)…
    ///     Acorde("Sol7").vecinosParsimoniosos(voces: 2)  // también Re♭7, a un tritono
    ///
    /// - Parameters:
    ///   - voces: cuántas voces se mueven: 1 (P₁,₀) o 2 (P₂,₀).
    ///   - tipos: la familia de acordes; si es `nil`, la del acorde (`TipoDeAcorde.familiaDeSeptimas`,
    ///     `familiaDeTriadas` o, para un maj7, `familiaDeSeptimasAmpliada`), o ninguna si no
    ///     pertenece a ellas.
    /// - Returns: un paso por acorde distinto (sin contar ortografía ni inversión), con la nota que
    ///   se mueve escrita como semitono cromático o diatónico según encaje en el acorde.
    public func vecinosParsimoniosos(voces: Int = 1, tipos: [TipoDeAcorde]? = nil) -> [PasoParsimonioso] {
        guard let tipos = tipos ?? familiaParsimoniosa, (1...2).contains(voces) else { return [] }
        let notas = self.notas
        // Las combinaciones de voces que se mueven.
        let grupos: [[Int]] = voces == 1 ? notas.indices.map { [$0] }
            : notas.indices.flatMap { i in notas.indices.filter { $0 > i }.map { [i, $0] } }
        var vistos: Set<[Int]> = []
        var pasos: [PasoParsimonioso] = []
        for grupo in grupos {
            // Cada voz, un semitono abajo o arriba.
            var direcciones: [[Int]] = [[]]
            for _ in grupo { direcciones = direcciones.flatMap { d in [d + [-1], d + [1]] } }
            for direccion in direcciones {
                guard let paso = Acorde.mover(notas, grupo, direccion, tipos: tipos) else { continue }
                let clave = [paso.acorde.tipo.intervalos.count] + paso.acorde.notas.map(\.claseDeAltura).sorted()
                    + [TipoDeAcorde.todos.firstIndex(of: paso.acorde.tipo) ?? -1]
                if vistos.insert(clave).inserted { pasos.append(paso) }
            }
        }
        return pasos
    }

    /// Mueve las voces de `grupo` un semitono en `direccion` y busca el acorde de la familia que
    /// forman. Cada nota movida puede escribirse como semitono cromático (misma letra) o diatónico,
    /// y la fundamental, con cualquier nombre de su clase; se elige la escritura con
    /// menos alteraciones, contando doble cada nota que no se mueve pero cambia de nombre (así
    /// Re♭7 pasa a Re♭m7 y no a Do♯m7, y Si°7 a Mi7 y no a Fa♭7).
    package static func mover(_ notas: [Nota], _ grupo: [Int], _ direccion: [Int], tipos: [TipoDeAcorde]) -> PasoParsimonioso? {
        var variantes: [[Nota]] = [notas]
        for (indice, d) in zip(grupo, direccion) {
            let base = notas[indice].pasosDeQuinta
            let opciones = [Nota(pasosDeQuinta: base + 7 * d), Nota(pasosDeQuinta: base - 5 * d)]
            variantes = variantes.flatMap { v in opciones.map { o -> [Nota] in var w = v; w[indice] = o; return w } }
        }
        let quietas = Set(notas.indices).subtracting(grupo)
        // Las clases de altura como máscara de bits, para comparar deprisa.
        func mascara<S: Sequence>(_ clases: S) -> Int where S.Element == Int { clases.reduce(0) { $0 | 1 << $1 } }
        let mascarasDeTipos = tipos.map { mascara($0.intervalos.map { modulo($0.semitonos, 12) }) }
        func rotar(_ m: Int, _ n: Int) -> Int { ((m << n) | (m >> (12 - n))) & 0xFFF }
        var mejor: (coste: Int, paso: PasoParsimonioso)?
        for nuevas in variantes {
            let clases = Set(nuevas.map(\.claseDeAltura))
            guard clases.count == notas.count else { continue }
            let objetivo = mascara(clases)
            // Las fundamentales posibles: cada clase, escrita con a lo sumo un sostenido o bemol
            // doble (de Fa𝄫 a Si𝄪), además de como está.
            let fundamentales = nuevas + (-9...9).map(Nota.init(pasosDeQuinta:)).filter { clases.contains($0.claseDeAltura) }
            for fundamental in fundamentales {
                for (tipo, mascaraDelTipo) in zip(tipos, mascarasDeTipos) {
                    // Primero, sin construir el acorde: ¿suenan las mismas clases?
                    guard rotar(mascaraDelTipo, fundamental.claseDeAltura) == objetivo else { continue }
                    let acorde = Acorde(fundamental, tipo)
                    // Cada nota, con el nombre que tiene en el acorde.
                    let escritas = nuevas.map { n in acorde.notas.first { $0.claseDeAltura == n.claseDeAltura }! }
                    let alteraciones = acorde.notas.reduce(0) { $0 + abs($1.alteracion.semitonos) }
                    let cambiadas = quietas.filter { escritas[$0] != notas[$0] }.count
                    let coste = alteraciones + 2 * cambiadas
                    if mejor == nil || coste < mejor!.coste {
                        let movimientos = grupo.map { MovimientoDeVoz(desde: notas[$0], hasta: escritas[$0]) }
                        mejor = (coste, PasoParsimonioso(acorde: acorde, movimientos: movimientos))
                    }
                }
            }
        }
        return mejor?.paso
    }

    /// La conducción con menos semitonos en total hasta otro acorde, de cualquier tamaño: si tienen
    /// distinto número de notas, alguna se duplica (todas las notas de los dos acordes intervienen).
    /// A igual total, la que mueve menos voces.
    ///
    ///     Acorde("Sol7").conduccionMinima(hasta: "Do").total     // 4: Si→Do, Re→Do, Fa→Mi
    public func conduccionMinima(hasta otro: Acorde) -> ConduccionMinima {
        var origen: [Nota] = [], destino: [Nota] = []
        for n in notas where !origen.contains(n) { origen.append(n) }
        for n in otro.notas where !destino.contains(n) { destino.append(n) }
        // Se asigna a cada nota del acorde mayor una del menor, sin dejar ninguna sin usar.
        let invertir = origen.count < destino.count
        let (grande, pequeno) = invertir ? (destino, origen) : (origen, destino)
        var mejor: (coste: (Int, Int), pares: [(Nota, Nota)])?
        var eleccion = [Int](repeating: 0, count: grande.count)
        func probar(_ i: Int) {
            if i == grande.count {
                guard Set(eleccion).count == pequeno.count else { return }
                let pares = grande.indices.map { invertir ? (pequeno[eleccion[$0]], grande[$0]) : (grande[$0], pequeno[eleccion[$0]]) }
                let movimientos = pares.map { MovimientoDeVoz(desde: $0.0, hasta: $0.1) }
                let coste = (movimientos.reduce(0) { $0 + abs($1.semitonos) }, movimientos.filter { $0.semitonos != 0 }.count)
                if mejor == nil || coste < mejor!.coste { mejor = (coste, pares) }
                return
            }
            for j in pequeno.indices { eleccion[i] = j; probar(i + 1) }
        }
        if !grande.isEmpty && !pequeno.isEmpty { probar(0) }
        let movimientos = (mejor?.pares ?? []).map { MovimientoDeVoz(desde: $0.0, hasta: $0.1) }
        // En el orden de las notas del primer acorde.
        let ordenados = movimientos.enumerated().sorted {
            ((origen.firstIndex(of: $0.element.desde) ?? 0), $0.offset) < ((origen.firstIndex(of: $1.element.desde) ?? 0), $1.offset)
        }.map(\.element)
        return ConduccionMinima(movimientos: ordenados)
    }
}

/// Cómo pasan las voces de un acorde a otro: `Acorde("Sol7").conduccionMinima(hasta: "Do")`.
public struct ConduccionMinima: Hashable, Sendable, CustomStringConvertible {
    /// Una por voz, en el orden de las notas del primer acorde (con las duplicadas repetidas).
    public let movimientos: [MovimientoDeVoz]

    /// Semitonos movidos en total.
    public var total: Int { movimientos.reduce(0) { $0 + abs($1.semitonos) } }
    /// Las voces que se mueven (sin las notas comunes).
    public var vocesQueSeMueven: [MovimientoDeVoz] { movimientos.filter { $0.semitonos != 0 } }

    /// "Sol→Sol, Si→Do (+1), Re→Do (−2), Fa→Mi (−1): 4 semitonos".
    public var description: String { texto(en: .espanol) }

    public func texto(en notacion: Notacion) -> String {
        let voces = movimientos.map { m -> String in
            m.semitonos == 0 ? m.texto(en: notacion) : m.texto(en: notacion) + " (" + (m.semitonos > 0 ? "+" : "−") + "\(abs(m.semitonos)))"
        }
        let n = total
        let semitonos = Traduccion(n == 1 ? "1 semitono" : "\(n) semitonos", n == 1 ? "1 semitone" : "\(n) semitones",
                                   ca: n == 1 ? "1 semitò" : "\(n) semitons", gl: n == 1 ? "1 semiton" : "\(n) semitons",
                                   eu: "\(n) tonuerdi",
                                   pt: n == 1 ? "1 meio-tom" : "\(n) meios-tons", fr: n == 1 ? "1 demi-ton" : "\(n) demi-tons", it: n == 1 ? "1 semitono" : "\(n) semitoni").en(notacion)
        return voces.joined(separator: ", ") + ": " + semitonos
    }
}

extension Tonnetz {
    /// El camino más corto entre dos acordes de una familia moviendo `voces` voces un semitono en
    /// cada paso: entre séptimas, por las «Power Towers»; entre tríadas, por el «Cube Dance» (que,
    /// a diferencia de P, L y R, pasa por las aumentadas). La meta se compara sin ortografía
    /// (Do♯7 llega a Re♭7). Sin `tipos`, la primera familia conocida que contenga a los dos (Do7 →
    /// Domaj7 va por la ampliada). `nil` si los acordes no son de la misma familia.
    ///
    ///     Tonnetz.caminoParsimonioso(desde: "Sol7", hasta: "Rem7")   // Sol7 → Rem7 en dos pasos
    public static func caminoParsimonioso(desde origen: Acorde, hasta destino: Acorde, voces: Int = 1,
                                          tipos: [TipoDeAcorde]? = nil) -> [PasoParsimonioso]? {
        let comun = Acorde.familiasParsimoniosas.first { $0.contains(origen.tipo) && $0.contains(destino.tipo) }
        guard let familia = tipos ?? comun, familia.contains(origen.tipo),
              familia.contains(destino.tipo), (1...2).contains(voces) else { return nil }
        func clave(_ a: Acorde) -> [Int] {
            a.notas.map(\.claseDeAltura).sorted() + [familia.firstIndex(of: a.tipo)!]
        }
        let meta = clave(destino)
        // Con dos voces, hay familias que no están conectadas: puede no haber camino.
        guard var camino = caminoMasCorto(
            desde: Acorde(origen.fundamental, origen.tipo), clave: clave,
            vecinos: { acorde in acorde.vecinosParsimoniosos(voces: voces, tipos: familia).map { ($0, $0.acorde) } },
            llega: { clave($0) == meta }) else { return nil }
        // El último, con la ortografía del destino.
        if let ultimo = camino.last {
            let final = Acorde(destino.fundamental, destino.tipo)
            let escritas = ultimo.movimientos.map { m in
                MovimientoDeVoz(desde: m.desde, hasta: final.notas.first { $0.claseDeAltura == m.hasta.claseDeAltura } ?? m.hasta)
            }
            camino[camino.count - 1] = PasoParsimonioso(acorde: final, movimientos: escritas)
        }
        return camino
    }
}
