import ArmoniaNucleo
extension Acorde {
    // MARK: Identificación

    /// Todas las lecturas razonables de un conjunto de nombres de nota, de más a menos probable.
    ///
    /// - La primera nota es el bajo; las repeticiones se ignoran.
    /// - Se admite la quinta justa omitida (Do–Mi–Si♭ → Do7, con Sol en `omitidas`).
    /// - Se admiten tensiones y alteraciones (Do–Mi–Si♭–Re♭ → Do7(♭9)).
    /// - Con cuatro notas o más se prueba también el bajo como nota ajena (Re–Do–Mi–Sol → Do/Re).
    public static func candidatos(_ notas: [Nota]) -> [Candidato<Acorde>] {
        var unicas: [Nota] = []
        for n in notas where !unicas.contains(n) { unicas.append(n) }
        guard let bajo = unicas.first, unicas.count >= 2 else { return [] }

        var orden: [Acorde] = []
        var mejores: [Acorde: Candidato<Acorde>] = [:]

        func considerar(_ raiz: Nota, _ grupo: [Nota], penalizacionExtra: Double) {
            let conjunto = Set(grupo.map { $0.pasosDeQuinta - raiz.pasosDeQuinta })
            guard let candidato = evaluar(raiz: raiz, conjunto: conjunto, bajo: bajo,
                                          penalizacionExtra: penalizacionExtra) else { return }
            let acorde = candidato.valor
            if let previo = mejores[acorde] {
                if candidato.coste < previo.coste { mejores[acorde] = candidato }
            } else {
                mejores[acorde] = candidato
                orden.append(acorde)
            }
        }

        for raiz in unicas { considerar(raiz, unicas, penalizacionExtra: 0) }
        if unicas.count >= 4 {
            let resto = Array(unicas.dropFirst())
            for raiz in resto { considerar(raiz, resto, penalizacionExtra: 2.5) }
        }

        return orden.enumerated()
            .compactMap { indice, acorde in mejores[acorde].map { (indice, $0) } }
            .sorted { ($0.1.coste, $0.0) < ($1.1.coste, $1.0) }
            .map(\.1)
    }

    /// Puntúa una lectura: fundamental, desplazamientos en quintas de las notas presentes y bajo.
    /// Supone la quinta justa si falta (y la anota en `omitidas`); penaliza las inversiones,
    /// más aún si el bajo es una tensión, y lo que `ClasificacionDeAcorde.penalizacion` considere raro.
    package static func evaluar(raiz: Nota, conjunto presentes: Set<Int>, bajo: Nota,
                        penalizacionExtra: Double) -> Candidato<Acorde>? {
        var conjunto = presentes
        guard let clasificacion = ClasificacionDeAcorde(conjunto) else { return nil }
        // Sin tercera, suspensión ni quinta no hay acorde (Do–Re♭ no es Re♭maj7 sin 3ª ni 5ª).
        guard clasificacion.tercera != nil || clasificacion.sus2 || clasificacion.sus4
                || !clasificacion.quintasDelAcorde.isEmpty else { return nil }
        var omitidas: [Nota] = []
        var penalizacion = penalizacionExtra
        let tieneTerceraOSus = clasificacion.tercera != nil || clasificacion.sus2 || clasificacion.sus4
        // Las sextas aumentadas italiana y francesa no llevan quinta: no se les supone.
        if clasificacion.quintasDelAcorde.isEmpty, tieneTerceraOSus, TipoDeAcorde.nombresConocidos[conjunto] == nil,
           ClasificacionDeAcorde(conjunto.union([1])) != nil {
            conjunto.insert(1)
            omitidas.append(raiz + .quintaJusta)
            penalizacion += 1
        }
        guard let tipo = TipoDeAcorde(pasosDeQuinta: conjunto) else { return nil }
        penalizacion += tipo.clasificacion.penalizacion
        let acorde = Acorde(raiz, tipo, bajo: bajo)
        if bajo != raiz && acorde.inversion != nil {
            // Una tensión en el bajo (Do/Re como Do(add9)/Re) es menos habitual que una inversión.
            penalizacion += tipo.clasificacion.tensiones.contains(bajo.pasosDeQuinta - raiz.pasosDeQuinta) ? 2 : 1
        }
        return Candidato(acorde, coste: penalizacion, notasOmitidas: omitidas)
    }

    /// Acordes que forman las notas, del más al menos probable.
    /// `Acorde.identificar([.mi, .sol, .do]).first` → Do/Mi.
    public static func identificar(_ notas: [Nota]) -> [Acorde] {
        candidatos(notas).map(\.valor)
    }

    /// Igual, a partir de notas con octava (el bajo es la más grave).
    public static func candidatos(_ notas: [Altura]) -> [Candidato<Acorde>] {
        candidatos(notas.sorted().map(\.nota))
    }

    public static func identificar(_ notas: [Altura]) -> [Acorde] {
        candidatos(notas).map(\.valor)
    }
}

// Identificación de acordes a partir de alturas sin ortografía (MIDI o clases de altura).
//
// Un teclado o un archivo MIDI sólo da alturas: 60, 64, 68 puede ser Do–Mi–Sol♯ (Do+)
// o Do–Mi–La♭ (La♭+/Do). Para cada fundamental posible, cada distancia en semitonos
// admite una o dos posiciones en la línea de quintas:
//
//   semitonos:  0  1   2  3      4  5   6      7  8      9      10  11
//   pasosDeQuinta:    0  −5  2  −3, 9  4  −1  −6, 6  1  8, −4  3, −9  −2  5
//               1  ♭9  9  m3,♯9  M3 11  ♭5,♯11 5  ♯5,♭13 6,°7   m7  M7
//
// El motor prueba todas las combinaciones (como mucho 16 por fundamental), puntúa cada
// lectura igual que con nombres de nota y escribe la fundamental de la forma más sencilla
// (Re♭ antes que Do♯, Do°7 antes que Si♯°7), o según la tonalidad si se indica.

extension Acorde {
    package static let posicionesPorSemitono: [[Int]] = [
        [0], [-5], [2], [-3, 9], [4], [-1], [-6, 6], [1], [8, -4], [3, -9], [-2], [5],
    ]

    /// Lecturas de un conjunto de clases de altura (0 = Do … 11 = Si), de más a menos probable.
    /// La primera es el bajo; las repeticiones y las octavas se ignoran.
    ///
    /// Con `tonalidad`, se prefieren las ortografías de sus notas propias (en La menor, también
    /// Fa♯ y Sol♯): 0–4–8 se escribe Do–Mi–Sol♯, y cada nota ajena resta un poco de probabilidad.
    /// Para usar una escala cualquiera como contexto (un modo, por ejemplo), usa `escala:`.
    ///
    ///     Acorde.identificar(clasesDeAltura: [0, 3, 6, 9]).first   // Do°7
    ///     Acorde.identificar(clasesDeAltura: [1, 5, 8]).first      // Re♭
    public static func candidatos(clasesDeAltura alturas: [Int], tonalidad: Tonalidad? = nil) -> [Candidato<Acorde>] {
        candidatos(clasesDeAltura: alturas, preferidas: tonalidad.map { Set($0.notasPropias.map(\.pasosDeQuinta)) })
    }

    /// Igual, prefiriendo las ortografías de las notas de una escala cualquiera.
    public static func candidatos(clasesDeAltura alturas: [Int], escala: Escala) -> [Candidato<Acorde>] {
        candidatos(clasesDeAltura: alturas, preferidas: Set(escala.notas.map(\.pasosDeQuinta)))
    }

    private static func candidatos(clasesDeAltura alturas: [Int], preferidas: Set<Int>?) -> [Candidato<Acorde>] {
        var unicas: [Int] = []
        for altura in alturas.map({ modulo($0, 12) }) where !unicas.contains(altura) {
            unicas.append(altura)
        }
        guard let bajo = unicas.first, unicas.count >= 2 else { return [] }
        let escala = preferidas

        func fueraDeEscala(_ quintas: Int) -> Int {
            guard let escala else { return 0 }
            return escala.contains(quintas) ? 0 : 1
        }
        func alteraciones(_ quintas: Int) -> Int { Nota(pasosDeQuinta: quintas).alteracion.cantidad }
        /// Las tres escrituras razonables de una clase de altura en la línea de quintas.
        func escrituras(_ altura: Int) -> [Int] {
            let q0 = modulo(altura * 7, 12)
            return [q0 - 12, q0, q0 + 12]
        }

        var mejores: [Acorde: (candidato: Candidato<Acorde>, clave: [Double], orden: Int)] = [:]

        func considerar(_ raiz: Int, _ grupo: [Int], penalizacionExtra: Double) {
            let distancias = Set(grupo.map { modulo($0 - raiz, 12) }).sorted()
            var combinaciones: [[Int]] = [[]]
            for d in distancias {
                combinaciones = combinaciones.flatMap { previa in
                    Acorde.posicionesPorSemitono[d].map { previa + [$0] }
                }
            }
            for combinacion in combinaciones {
                let conjunto = Set(combinacion)
                guard ClasificacionDeAcorde(conjunto) != nil else { continue }

                // Escritura de la fundamental: primero la tonalidad, luego la propia
                // fundamental, luego el total de alteraciones, y entre Re♭ y Fa♯ en caso de empate.
                var mejorCoste: [Int]?
                var quintasRaiz = 0
                for rq in escrituras(raiz) {
                    let notas = conjunto.map { rq + $0 }
                    let coste = [
                        notas.reduce(0) { $0 + fueraDeEscala($1) },
                        alteraciones(rq),
                        notas.reduce(0) { $0 + alteraciones($1) },
                        (-5...6).contains(rq) ? 0 : 1,
                    ]
                    if mejorCoste.map({ coste.lexicographicallyPrecedes($0) }) ?? true {
                        mejorCoste = coste
                        quintasRaiz = rq
                    }
                }
                guard let coste = mejorCoste else { continue }

                let fundamental = Nota(pasosDeQuinta: quintasRaiz)
                let notas = conjunto.map { Nota(pasosDeQuinta: quintasRaiz + $0) }
                let nombreBajo: Nota
                if let deAcorde = notas.first(where: { $0.claseDeAltura == bajo }) {
                    nombreBajo = deAcorde
                } else {
                    let q = escrituras(bajo).min { a, b in
                        [fueraDeEscala(a), alteraciones(a), abs(a - quintasRaiz)]
                            .lexicographicallyPrecedes([fueraDeEscala(b), alteraciones(b), abs(b - quintasRaiz)])
                    } ?? bajo
                    nombreBajo = Nota(pasosDeQuinta: q)
                }

                guard let candidato = evaluar(raiz: fundamental, conjunto: conjunto, bajo: nombreBajo,
                                              penalizacionExtra: penalizacionExtra + 0.25 * Double(coste[0]))
                else { continue }
                let clave = [candidato.coste, Double(coste[1]), Double(coste[2])]
                if let previo = mejores[candidato.valor] {
                    if clave.lexicographicallyPrecedes(previo.clave) {
                        mejores[candidato.valor] = (candidato, clave, previo.orden)
                    }
                } else {
                    mejores[candidato.valor] = (candidato, clave, mejores.count)
                }
            }
        }

        for raiz in unicas { considerar(raiz, unicas, penalizacionExtra: 0) }
        if unicas.count >= 4 {
            let resto = Array(unicas.dropFirst())
            for raiz in resto { considerar(raiz, resto, penalizacionExtra: 2.5) }
        }

        return mejores.values
            .sorted { a, b in
                a.clave == b.clave ? a.orden < b.orden : a.clave.lexicographicallyPrecedes(b.clave)
            }
            .map(\.candidato)
    }

    /// Lecturas de notas MIDI (el bajo es la más grave).
    ///
    ///     Acorde.identificar(midi: [55, 59, 62, 65, 68]).first   // Sol7(♭9)
    public static func candidatos(midi: [Int], tonalidad: Tonalidad? = nil) -> [Candidato<Acorde>] {
        candidatos(clasesDeAltura: midi.sorted(), tonalidad: tonalidad)
    }

    public static func candidatos(midi: [Int], escala: Escala) -> [Candidato<Acorde>] {
        candidatos(clasesDeAltura: midi.sorted(), escala: escala)
    }

    public static func identificar(clasesDeAltura alturas: [Int], tonalidad: Tonalidad? = nil) -> [Acorde] {
        candidatos(clasesDeAltura: alturas, tonalidad: tonalidad).map(\.valor)
    }

    public static func identificar(clasesDeAltura alturas: [Int], escala: Escala) -> [Acorde] {
        candidatos(clasesDeAltura: alturas, escala: escala).map(\.valor)
    }

    public static func identificar(midi: [Int], tonalidad: Tonalidad? = nil) -> [Acorde] {
        candidatos(midi: midi, tonalidad: tonalidad).map(\.valor)
    }

    public static func identificar(midi: [Int], escala: Escala) -> [Acorde] {
        candidatos(midi: midi, escala: escala).map(\.valor)
    }

    /// Escribe unas notas MIDI con la ortografía del acorde (las que no pertenecen a él
    /// se escriben con sostenidos de Fa a La♯).
    ///
    ///     let acorde = Acorde.identificar(midi: [60, 64, 68]).first!   // Do+
    ///     acorde.ortografiar(midi: [60, 64, 68])                       // [Do4, Mi4, Sol♯4]
    public func ortografiar(midi: [Int]) -> [Altura] {
        let nombres = notas + [bajo]
        return midi.map { altura in
            nombres.lazy.compactMap { Altura($0, midi: altura) }.first ?? Altura(midi: altura)
        }
    }
}

extension Candidato where Valor == Acorde {
    /// Notas que la lectura supone aunque falten (por ahora, la quinta justa):
    /// Do–Mi–Si♭ se lee como Do7 con Sol omitido.
    public var omitidas: [Nota] { notasOmitidas }
}
