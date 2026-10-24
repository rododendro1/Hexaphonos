import ArmoniaNucleo
// Realización a cuatro voces: escribir una sucesión de acordes como coral (bajo, tenor, contralto y
// soprano) sin faltas de conducción.

extension Coral {
    /// Escribe los acordes a cuatro voces, con el bajo del cifrado (Sol7/Si lleva Si en el bajo) y
    /// sin ninguna falta de las que comprueba ``faltas``: el resultado siempre ``esCorrecta``.
    ///
    ///     let coral = Coral.realizar(["Do", "Fa", "Sol7", "Do"])!
    ///     coral.esCorrecta                // true
    ///     coral.voz(0).map(\.nota)        // [Do, Fa, Sol, Do]
    ///
    /// Entre todas las disposiciones posibles busca la sucesión que mueve menos las voces (en
    /// semitonos, como `conduccionMinima(hasta:)`, pero con alturas), con estas preferencias:
    ///
    /// - Todas las notas del acorde, salvo la quinta justa, que puede faltar (duplicando la
    ///   fundamental). Se duplica antes la fundamental que la quinta, y esta antes que la tercera
    ///   (en las tríadas disminuidas, la tercera). Nunca la sensible ni la séptima.
    /// - La sensible sube a la tónica, sobre todo en el soprano, y la séptima baja por grado conjunto.
    /// - Sin soprano dado, el soprano se queda cerca del centro de su tesitura.
    ///
    /// - Parameters:
    ///   - soprano: la melodía del soprano, una altura por acorde, si está fijada. Cada nota tiene
    ///     que ser del acorde y estar en la tesitura del soprano (Do4–Sol5).
    ///   - tonalidad: para saber cuál es la sensible; si no se da, la que mejor explique los acordes.
    /// - Returns: `nil` si no hay acordes, si el soprano no encaja (otro número de notas, una nota
    ///   ajena al acorde o fuera de tesitura), si un acorde tiene más de cuatro notas obligatorias o si
    ///   no hay ninguna realización sin faltas.
    public static func realizar(_ acordes: [Acorde], soprano: [Altura]? = nil, en tonalidad: Tonalidad? = nil) -> Coral? {
        guard !acordes.isEmpty, soprano == nil || soprano!.count == acordes.count else { return nil }
        let tonalidad = tonalidad ?? AnalisisArmonico.analizar(acordes)?.tonalidad
        let sensible = tonalidad?.escalaDeReferencia.grado(7)
        let tonica = tonalidad?.tonica
        let dominantes = acordes.map { acorde in tonalidad.map { Cadencia.esDominante($0.analizar(acorde)) } ?? false }

        let opciones = acordes.indices.map { i in
            disposiciones(de: acordes[i], soprano: soprano?[i], sensible: sensible)
        }
        guard opciones.allSatisfy({ !$0.isEmpty }) else { return nil }

        // Viterbi: el menor coste de llegar a cada disposición de cada acorde.
        var costes = opciones[0].map(\.coste)
        var previos: [[Int]] = [opciones[0].map { _ in -1 }]
        for i in 1..<max(1, acordes.count) {
            var nuevos = [Double](repeating: .infinity, count: opciones[i].count)
            var desde = [Int](repeating: -1, count: opciones[i].count)
            for (b, siguiente) in opciones[i].enumerated() {
                for (a, actual) in opciones[i - 1].enumerated() where costes[a] < .infinity {
                    guard let paso = costeDePaso(de: actual.alturas, a: siguiente.alturas, septima: acordes[i - 1].septima,
                                                 sensible: dominantes[i - 1] ? sensible : nil, tonica: tonica) else { continue }
                    let total = costes[a] + paso + siguiente.coste
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
        var resultado: [[Altura]] = []
        for i in stride(from: acordes.count - 1, through: 0, by: -1) {
            resultado.insert(opciones[i][indice].alturas, at: 0)
            indice = previos[i][indice]
        }
        return Coral(resultado)
    }

    // MARK: Auxiliares

    /// Las disposiciones a cuatro voces de un acorde que no tienen faltas por sí solas, con lo que
    /// cuesta cada una por sus duplicaciones, sus omisiones y la altura del soprano.
    package static func disposiciones(de acorde: Acorde, soprano: Altura?, sensible: Nota?) -> [(alturas: [Altura], coste: Double)] {
        var notas = acorde.notas
        if !notas.contains(acorde.bajo) { notas.append(acorde.bajo) }
        let quinta = acorde.quinta.flatMap { $0 == acorde.fundamental + .quintaJusta ? $0 : nil }
        let obligatorias = notas.filter { $0 != quinta }
        guard obligatorias.count <= 4 else { return [] }
        if let soprano, !notas.contains(soprano.nota) { return [] }

        func alturas(_ voz: Int) -> [Altura] {
            notas.flatMap { nota in (1...6).map { Altura(nota, octava: $0) } }
                .filter { tesituras[voz].contains($0.midi) }
                .sorted { $0.midi < $1.midi }
        }
        let bajos = (1...4).map { Altura(acorde.bajo, octava: $0) }.filter { tesituras[0].contains($0.midi) }
        let tenores = alturas(1), contraltos = alturas(2)
        let sopranos = soprano.map { [$0] } ?? alturas(3)
        let disminuida = acorde.tipo.estructura.calidadDeTriada == .disminuida

        var resultado: [(alturas: [Altura], coste: Double)] = []
        for b in bajos {
            for t in tenores where t.midi > b.midi {
                for c in contraltos where c.midi >= t.midi && c.midi - t.midi <= 12 {
                    for s in sopranos where s.midi >= c.midi && s.midi - c.midi <= 12 {
                        let voces = [b, t, c, s]
                        var falta = false
                        faltas(en: voces) { _, _ in falta = true }
                        guard !falta else { continue }
                        let escritas = voces.map(\.nota)
                        guard obligatorias.allSatisfy(escritas.contains) else { continue }
                        // Un unísono entre voces superiores se admite, pero cuesta.
                        var coste = c == t || s == c ? 1.0 : 0
                        if let quinta, !escritas.contains(quinta) { coste += 1.5 }
                        // Las duplicaciones.
                        for nota in Set(escritas) {
                            let veces = escritas.filter { $0 == nota }.count
                            guard veces > 1 else { continue }
                            if nota == sensible || nota == acorde.septima || acorde.tensiones.contains(nota) {
                                falta = true
                                break
                            }
                            let porVez: Double
                            switch acorde.papel(de: nota) {
                            case .fundamental?: porVez = disminuida ? 0.5 : 0
                            case .quinta?: porVez = disminuida ? 1.5 : 0.5
                            case .tercera?: porVez = disminuida ? 0 : 1
                            default: porVez = 1
                            }
                            coste += porVez * Double(veces - 1)
                        }
                        guard !falta else { continue }
                        // El soprano, cerca del centro de su tesitura (Mi4–Re5).
                        if soprano == nil { coste += 0.2 * Double(max(0, 64 - s.midi, s.midi - 74)) }
                        resultado.append((voces, coste))
                    }
                }
            }
        }
        return resultado
    }

    /// Lo que cuesta pasar de una disposición a otra, o `nil` si el paso tiene alguna falta.
    /// `septima` es la del primer acorde, si la tiene; `sensible`, solo si el primero es de dominante.
    package static func costeDePaso(de a: [Altura], a b: [Altura], septima: Nota?, sensible: Nota?, tonica: Nota?) -> Double? {
        var falta = false
        faltas(de: a, a: b) { _, _ in falta = true }
        guard !falta else { return nil }
        var coste = 0.5 * Double(abs(b[0].midi - a[0].midi))
        for v in 1..<4 { coste += Double(abs(b[v].midi - a[v].midi)) }
        for v in 0..<4 {
            let movimiento = b[v].midi - a[v].midi
            // La sensible sube a la tónica (si el acorde siguiente la tiene).
            if let sensible, let tonica, a[v].nota == sensible, b.contains(where: { $0.nota == tonica }),
               !(movimiento == 1 && b[v].nota == tonica) {
                coste += v == 3 ? 4 : 1.5
            }
            // La séptima baja por grado conjunto (o se queda).
            if let septima, a[v].nota == septima, !(-2...0).contains(movimiento) {
                coste += 3
            }
        }
        return coste
    }
}
