import ArmoniaNucleo
// MARK: - Escalas que contienen unas notas

extension Escala {
    /// Escalas que contienen todas las notas dadas, con su ortografía exacta, de más a menos probable.
    /// El coste es el número de notas de la escala que sobran más una décima por cada alteración;
    /// en caso de empate, el orden de `tipos` y la armadura más sencilla.
    ///
    ///     Escala.candidatos([.do, .mi, .sol, .si, "Fa#"]).first?.valor   // Do pentatónica lidia
    public static func candidatos(_ notas: [Nota], tipos: [TipoDeEscala] = TipoDeEscala.todos) -> [Candidato<Escala>] {
        ordenar(contenedoras(notas, tipos: tipos)) { escala in
            escala.notasEnAmbasDirecciones.filter { !notas.contains($0) }.count
        }
    }

    /// Escalas que contienen las notas dadas, de más a menos probable (sin el coste).
    public static func identificar(_ notas: [Nota], tipos: [TipoDeEscala] = TipoDeEscala.todos) -> [Escala] {
        candidatos(notas, tipos: tipos).map(\.valor)
    }

    /// Escalas que contienen todas las clases de altura dadas (sin importar la ortografía), de más
    /// a menos probable; cada escala se escribe con la tónica que da menos alteraciones.
    ///
    ///     Escala.candidatos(clasesDeAltura: [0, 4, 7, 11, 6]).first?.valor   // Do pentatónica lidia
    public static func candidatos(clasesDeAltura alturas: [Int],
                                  tipos: [TipoDeEscala] = TipoDeEscala.todos) -> [Candidato<Escala>] {
        let buscadas = Set(alturas.map { modulo($0, 12) })
        return ordenar(contenedoras(clasesDeAltura: alturas, tipos: tipos)) { escala in
            Set(escala.notasEnAmbasDirecciones.map(\.claseDeAltura)).subtracting(buscadas).count
        }
    }

    /// Escalas que contienen las clases de altura dadas, de más a menos probable (sin el coste).
    public static func identificar(clasesDeAltura alturas: [Int],
                                   tipos: [TipoDeEscala] = TipoDeEscala.todos) -> [Escala] {
        candidatos(clasesDeAltura: alturas, tipos: tipos).map(\.valor)
    }

    /// Ordena por coste (notas que sobran + 0,1 por alteración) conservando el orden previo en
    /// los empates.
    private static func ordenar(_ escalas: [Escala], sobrantes: (Escala) -> Int) -> [Candidato<Escala>] {
        escalas.enumerated()
            .map { (indice: $0.offset, candidato: Candidato($0.element,
                                                             coste: Double(sobrantes($0.element)) + 0.1 * Double($0.element.costeDeEscritura))) }
            .sorted { ($0.candidato.coste, $0.indice) < ($1.candidato.coste, $1.indice) }
            .map(\.candidato)
    }

    /// Escalas que contienen todos los nombres dados, por tipo y armadura más sencilla.
    private static func contenedoras(_ notas: [Nota], tipos: [TipoDeEscala]) -> [Escala] {
        guard let primera = notas.first else { return [] }
        var resultado: [Escala] = []
        for tipo in tipos {
            // La primera nota tiene que ser algún grado de la escala: eso fija las tónicas posibles.
            let tonicas = tipo.intervalosEnAmbasDirecciones.map { primera - $0 }
            var delTipo: [Escala] = []
            for tonica in tonicas {
                let escala = Escala(tonica, tipo)
                if !delTipo.contains(escala) && notas.allSatisfy({ escala.contiene($0) }) { delTipo.append(escala) }
            }
            resultado += delTipo.sorted { $0.costeDeEscritura < $1.costeDeEscritura }
        }
        return resultado
    }

    /// Escalas que contienen todas las clases de altura dadas, por tipo y armadura más sencilla.
    private static func contenedoras(clasesDeAltura alturas: [Int], tipos: [TipoDeEscala]) -> [Escala] {
        let buscadas = Set(alturas.map { modulo($0, 12) })
        guard !buscadas.isEmpty else { return [] }
        var resultado: [Escala] = []
        for tipo in tipos {
            var delTipo: [Escala] = []
            for tonica in 0..<12 {
                let q0 = modulo(tonica * 7, 12)
                let opciones = [q0 - 12, q0, q0 + 12].map { Escala(Nota(pasosDeQuinta: $0), tipo) }
                guard let escala = opciones.min(by: { $0.costeDeEscritura < $1.costeDeEscritura }) else { continue }
                if buscadas.isSubset(of: Set(escala.notasEnAmbasDirecciones.map(\.claseDeAltura)))
                    && !delTipo.contains(escala) {
                    delTipo.append(escala)
                }
            }
            resultado += delTipo.sorted { $0.costeDeEscritura < $1.costeDeEscritura }
        }
        return resultado
    }

    /// Total de alteraciones de las notas (para elegir escrituras sencillas).
    package var costeDeEscritura: Int { notas.reduce(0) { $0 + $1.alteracion.cantidad } }
}
