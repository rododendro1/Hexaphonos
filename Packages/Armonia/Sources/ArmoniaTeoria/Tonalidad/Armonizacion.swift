import ArmoniaNucleo
// Armonización de melodías: qué acordes pueden acompañar cada nota y qué sucesión de acordes
// suena mejor en la tonalidad, según la armonía funcional.

// MARK: - Armonizacion

/// Una propuesta de acordes para una melodía: un acorde por nota.
///
///     let propuesta = Tonalidad(.do).armonizar(melodia: ["Mi", "Re", "Do"]).first!.valor
///     propuesta.acordes      // [Do, Sol, Do]
///     propuesta.cifrados     // ["I", "V", "I"]
public struct Armonizacion: Hashable, Sendable, CustomStringConvertible {
    public let tonalidad: Tonalidad
    public let melodia: [Nota]
    public let acordes: [Acorde]

    /// Los acordes leídos en la tonalidad.
    public var analisis: AnalisisArmonico { tonalidad.analizar(acordes) }
    /// "I", "V7/V", "vii°6"…
    public var cifrados: [String] { analisis.cifrados }

    /// La armonización a cuatro voces con la melodía en el soprano (ver
    /// ``ConduccionDeVoces/realizar(_:soprano:en:)``). `nil` si la melodía no tiene tantas notas como
    /// acordes, si sus notas no son las de la propuesta o si no hay realización sin faltas.
    public func realizar(soprano: [Altura]) -> ConduccionDeVoces? {
        guard soprano.map(\.nota) == melodia else { return nil }
        return ConduccionDeVoces.realizar(acordes, soprano: soprano, en: tonalidad)
    }

    /// "Do Sol Do (I–V–I)".
    public var description: String { texto(.espanol) }

    public func texto(_ notacion: Nomenclatura) -> String {
        acordes.map { $0.cifrado(en: notacion) }.joined(separator: " ") + " (" + cifrados.joined(separator: "–") + ")"
    }
}

// MARK: - Armonizar

extension Tonalidad {
    /// Los acordes de la tonalidad que tienen una nota, del más al menos habitual para
    /// armonizarla: los tres principales (I, IV, V) primero, y antes si la nota es su fundamental.
    ///
    ///     Tonalidad(.do).acordes(para: .sol).prefix(3).map(\.valor)   // [Sol, Do, Sol7]
    ///
    /// Son las tríadas de los siete grados (el vii° en primera inversión, como se usa casi siempre;
    /// en menor, también el ii°), el V7, el ii6 y las dominantes secundarias del V, el vi, el ii y
    /// el IV (en menor, del iv y del VI). Si ninguno tiene la nota, los del modo homónimo.
    public func acordes(para nota: Nota) -> [Candidato<Acorde>] {
        var candidatos = inventarioDeArmonizacion.filter { $0.acorde.notas.contains(nota) }
        if candidatos.isEmpty {
            candidatos = homonima.inventarioDeArmonizacion.filter { $0.acorde.notas.contains(nota) && $0.destino == nil }
                .map { (acorde: $0.acorde, coste: $0.coste + 1, destino: nil as Int?) }
        }
        return candidatos
            .map { Candidato($0.acorde, coste: $0.coste + Tonalidad.costeDePapel(nota, en: $0.acorde)) }
            .sorted { $0.coste < $1.coste }
    }

    /// Las mejores armonizaciones de una melodía, de menor a mayor coste.
    ///
    ///     let mejor = Tonalidad(.do).armonizar(melodia: ["Do", "Re", "Mi", "Fa", "Re", "Si", "Do"]).first!
    ///     mejor.valor.cifrados   // ["I", "V", "I", "IV", "ii", "V", "I"]
    ///
    /// Cada nota recibe uno de sus ``acordes(para:)``, y la sucesión se puntúa como en la armonía
    /// funcional: tónica, subdominante, dominante y vuelta a la tónica es lo natural; de la
    /// dominante a la subdominante (una retrogresión) cuesta mucho, y una dominante secundaria
    /// tiene que ir a su destino. Se prefiere empezar en la tónica y terminar con una cadencia
    /// auténtica (o, si la última nota no es del I, en la dominante: una semicadencia). Una
    /// séptima en la melodía tiene que bajar por grado conjunto.
    ///
    /// - Parameter propuestas: cuántas armonizaciones distintas devolver como mucho.
    /// - Returns: vacío si la melodía está vacía o alguna nota no tiene acorde.
    public func armonizar(melodia: [Nota], propuestas: Int = 5) -> [Candidato<Armonizacion>] {
        guard !melodia.isEmpty, propuestas > 0 else { return [] }
        let opciones = melodia.map { acordes(para: $0) }
        guard opciones.allSatisfy({ !$0.isEmpty }) else { return [] }
        let lecturas = opciones.map { $0.map { analizar($0.valor) } }
        let destinos = Dictionary(inventarioDeArmonizacion.map { ($0.acorde, $0.destino) }, uniquingKeysWith: { a, _ in a })
        let n = melodia.count

        // Para cada nota y cada acorde posible, las mejores sucesiones que terminan en él.
        typealias Camino = (coste: Double, indices: [Int])
        var caminos: [[Camino]] = opciones[0].indices.map { j in
            [(opciones[0][j].coste + costeDeInicio(lecturas[0][j]), [j])]
        }
        for i in 1..<max(1, n) {
            var nuevos: [[Camino]] = []
            for (j, opcion) in opciones[i].enumerated() {
                var llegadas: [Camino] = []
                for (k, anteriores) in caminos.enumerated() {
                    let paso = costeDePaso(lecturas[i - 1][k], lecturas[i][j],
                                           destino: destinos[opciones[i - 1][k].valor] ?? nil,
                                           melodia: (melodia[i - 1], melodia[i]))
                    for camino in anteriores {
                        llegadas.append((camino.coste + paso + opcion.coste, camino.indices + [j]))
                    }
                }
                nuevos.append(Array(llegadas.sorted { $0.coste < $1.coste }.prefix(propuestas)))
            }
            caminos = nuevos
        }
        // El final: la cadencia.
        var finales: [Camino] = []
        for (j, terminados) in caminos.enumerated() {
            for camino in terminados {
                let penultimo = n > 1 ? lecturas[n - 2][camino.indices[n - 2]] : nil
                let fin = costeDeFinal(lecturas[n - 1][j], penultimo: penultimo, destino: n > 1
                    ? (destinos[opciones[n - 2][camino.indices[n - 2]].valor] ?? nil) : nil, melodia: melodia)
                finales.append((camino.coste + fin, camino.indices))
            }
        }
        var vistas: Set<[Acorde]> = []
        var resultado: [Candidato<Armonizacion>] = []
        for camino in finales.sorted(by: { $0.coste < $1.coste }) {
            let acordes = camino.indices.enumerated().map { opciones[$0.offset][$0.element].valor }
            guard vistas.insert(acordes).inserted else { continue }
            resultado.append(Candidato(Armonizacion(tonalidad: self, melodia: melodia, acordes: acordes),
                                       coste: (camino.coste * 100).rounded() / 100))
            if resultado.count == propuestas { break }
        }
        return resultado
    }

    /// Armoniza una melodía y la escribe a cuatro voces, con la melodía en el soprano.
    ///
    ///     let coral = Tonalidad(.do).armonizarACuatroVoces(["Mi4", "Re4", "Do4"])!
    ///     coral.armonizacion.cifrados   // ["I", "V", "I"]
    ///     coral.voces.esCorrecta        // true
    ///
    /// Elige a la vez los acordes y las disposiciones: entre todas las armonizaciones que se pueden
    /// realizar sin faltas (con las reglas de ``ConduccionDeVoces/realizar(_:soprano:en:)``), la que
    /// suma menos coste armónico, como en ``armonizar(melodia:propuestas:)``, y, a igualdad, la que
    /// mueve menos las voces. Por eso no siempre es la primera de `armonizar`: si la mejor sucesión
    /// de acordes obliga a una falta con esa melodía, se queda con otra.
    ///
    /// `nil` si no hay ninguna (por ejemplo, si la melodía se sale de la tesitura del soprano, Do4–Sol5).
    public func armonizarACuatroVoces(_ melodia: [Altura]) -> (armonizacion: Armonizacion, voces: ConduccionDeVoces)? {
        guard !melodia.isEmpty else { return nil }
        let notas = melodia.map(\.nota)
        let opciones = notas.map { acordes(para: $0) }
        let lecturas = opciones.map { $0.map { analizar($0.valor) } }
        let destinos = Dictionary(inventarioDeArmonizacion.map { ($0.acorde, $0.destino) }, uniquingKeysWith: { a, _ in a })
        let sensible = escalaDeReferencia.grado(7)
        let n = melodia.count
        // Lo que pesan las voces frente a la armonía: un semitono de movimiento vale poco.
        let pesoDeLasVoces = 0.15

        // Los estados: un acorde de los posibles para la nota y una de sus disposiciones.
        let estados: [[(acorde: Int, alturas: [Altura], coste: Double)]] = (0..<n).map { i in
            opciones[i].indices.flatMap { j in
                ConduccionDeVoces.disposiciones(de: opciones[i][j].valor, soprano: melodia[i], sensible: sensible)
                    .map { (j, $0.alturas, opciones[i][j].coste + pesoDeLasVoces * $0.coste) }
            }
        }
        guard estados.allSatisfy({ !$0.isEmpty }) else { return nil }

        var costes = estados[0].map { $0.coste + costeDeInicio(lecturas[0][$0.acorde]) }
        if n == 1 {
            costes = zip(costes, estados[0]).map { $0 + costeDeFinal(lecturas[0][$1.acorde], penultimo: nil, destino: nil, melodia: notas) }
        }
        var previos: [[Int]] = [estados[0].map { _ in -1 }]
        for i in 1..<max(1, n) {
            var nuevos = [Double](repeating: .infinity, count: estados[i].count)
            var desde = [Int](repeating: -1, count: estados[i].count)
            for (b, siguiente) in estados[i].enumerated() {
                let lectura = lecturas[i][siguiente.acorde]
                for (a, actual) in estados[i - 1].enumerated() where costes[a] < .infinity {
                    let anterior = lecturas[i - 1][actual.acorde]
                    let destino = destinos[opciones[i - 1][actual.acorde].valor] ?? nil
                    guard let voces = ConduccionDeVoces.costeDePaso(
                        de: actual.alturas, a: siguiente.alturas, septima: anterior.acorde.septima,
                        sensible: Cadencia.esDominante(anterior) ? sensible : nil, tonica: tonica) else { continue }
                    var total = costes[a] + siguiente.coste + pesoDeLasVoces * voces
                        + costeDePaso(anterior, lectura, destino: destino, melodia: (notas[i - 1], notas[i]))
                    if i == n - 1 { total += costeDeFinal(lectura, penultimo: anterior, destino: destino, melodia: notas) }
                    if total < nuevos[b] {
                        nuevos[b] = total
                        desde[b] = a
                    }
                }
            }
            costes = nuevos
            previos.append(desde)
        }
        guard var indice = costes.indices.min(by: { costes[$0] < costes[$1] }), costes[indice] < .infinity else { return nil }
        var elegidos: [Acorde] = []
        var voces: [[Altura]] = []
        for i in stride(from: n - 1, through: 0, by: -1) {
            let estado = estados[i][indice]
            elegidos.insert(opciones[i][estado.acorde].valor, at: 0)
            voces.insert(estado.alturas, at: 0)
            indice = previos[i][indice]
        }
        guard let conduccion = ConduccionDeVoces(voces) else { return nil }
        return (Armonizacion(tonalidad: self, melodia: notas, acordes: elegidos), conduccion)
    }

    // MARK: Auxiliares

    /// Los acordes con los que se armoniza, con su coste y, en las dominantes secundarias, el
    /// grado al que tienen que ir.
    package var inventarioDeArmonizacion: [(acorde: Acorde, coste: Double, destino: Int?)] {
        var inventario: [(acorde: Acorde, coste: Double, destino: Int?)] = []
        func anadir(_ acorde: Acorde, _ coste: Double, _ destino: Int? = nil) {
            guard !inventario.contains(where: { $0.acorde == acorde }) else { return }
            inventario.append((acorde, coste, destino))
        }
        let costes: [Double] = modo == .mayor ? [0, 0.2, 0.9, 0, 0, 0.3, 0.8] : [0, 0.5, 0.6, 0, 0, 0.3, 0.8]
        for grado in 1...7 {
            let acorde = self.acorde(grado: grado)
            // vii° (y en menor ii°) en primera inversión.
            let disminuido = acorde.tipo.estructura.calidadDeTriada == .disminuida
            anadir(disminuido ? acorde.invertir(1) : acorde, costes[grado - 1])
        }
        anadir(acorde(grado: 5, cuatriada: true), 0.15)
        if modo == .mayor { anadir(acorde(grado: 2).invertir(1), 0.25) }
        // Dominantes secundarias.
        for destino in modo == .mayor ? [5, 6, 2, 4] : [4, 6] {
            let raiz = acorde(grado: destino).fundamental + .quintaJusta
            anadir(Acorde(raiz, .mayor), destino == 5 ? 0.6 : 0.8, destino)
            anadir(Acorde(raiz, .dominanteSeptima), destino == 5 ? 0.6 : 0.8, destino)
        }
        return inventario
    }

    /// Lo que cuesta que la nota sea una u otra del acorde: mejor la fundamental.
    private static func costeDePapel(_ nota: Nota, en acorde: Acorde) -> Double {
        switch acorde.papel(de: nota) {
        case .fundamental?: return 0
        case .quinta?: return 0.15
        case .tercera?: return 0.25
        default: return 0.3
        }
    }

    private func costeDeInicio(_ a: AcordeAnalizado) -> Double {
        if a.grado == 1 && a.categoria == .diatonico { return 0 }
        return a.grado == 5 && a.categoria == .diatonico ? 0.5 : 1
    }

    /// Lo que cuesta ir de un acorde al siguiente, según sus funciones.
    private func costeDePaso(_ a: AcordeAnalizado, _ b: AcordeAnalizado, destino: Int?,
                             melodia: (Nota, Nota)) -> Double {
        var coste = 0.0
        // Una séptima en la melodía baja por grado conjunto.
        if a.acorde.papel(de: melodia.0) == .septima {
            let paso = modulo(melodia.0.claseDeAltura - melodia.1.claseDeAltura, 12)
            if !(1...2).contains(paso) { coste += 2 }
        }
        if let destino {
            return coste + (b.grado == destino && b.acorde.fundamental == acorde(grado: destino).fundamental ? 0 : 5)
        }
        if a.acorde.notas == b.acorde.notas { return coste + (a.acorde == b.acorde ? 0.6 : 0.3) }
        // V7 → V: la séptima se queda sin resolver.
        if a.acorde.septima != nil, b.acorde.fundamental == a.acorde.fundamental { return coste + 1 }
        switch (a.funcion, b.funcion) {
        case (.dominante?, .tonica?):
            switch b.grado {
            case 1: return coste
            case 6: return coste + 0.5
            default: return coste + 1.2
            }
        case (.dominante?, .subdominante?): return coste + 2
        case (.dominante?, .dominante?): return coste + (a.grado == 5 && b.grado == 5 ? 0.1 : 0.6)
        case (.subdominante?, .dominante?): return coste
        case (.subdominante?, .subdominante?): return coste + (a.grado == 4 && b.grado == 2 ? 0.2 : 0.8)
        case (.subdominante?, .tonica?): return coste + (b.grado == 1 ? 0.6 : 0.9)
        case (.tonica?, .tonica?):
            if a.grado == 1 { return coste + (b.grado == 6 ? 0.1 : 0.3) }
            return coste + (a.grado == 3 && b.grado == 6 ? 0.2 : 0.8)
        default: return coste + 0.1
        }
    }

    /// Lo que cuesta terminar así: lo mejor, una cadencia auténtica; si la última nota no es del
    /// I, una semicadencia.
    private func costeDeFinal(_ ultimo: AcordeAnalizado, penultimo: AcordeAnalizado?, destino: Int?,
                              melodia: [Nota]) -> Double {
        if destino != nil { return 5 }
        if Cadencia.esTonica(ultimo) && ultimo.acorde.inversion == 0 {
            guard let penultimo else { return 0 }
            return Cadencia.esDominante(penultimo) ? 0 : 1
        }
        let iTieneLaNota = acorde(grado: 1).notas.contains(melodia[melodia.count - 1])
        if ultimo.grado == 5 && ultimo.categoria == .diatonico && ultimo.acorde.tipo == .mayor {
            return iTieneLaNota ? 2 : 0.5
        }
        return 4
    }
}
