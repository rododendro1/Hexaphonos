import ArmoniaNucleo
// MARK: - Detección de tonalidad

extension Tonalidad {
    /// Perfiles de Krumhansl y Kessler (1982): cuánto "pertenece" cada grado cromático a una
    /// tonalidad mayor o menor, medido en experimentos de escucha.
    package static let perfilMayor = [6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]
    package static let perfilMenor = [6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]

    /// Las 24 tonalidades mayores y menores ordenadas de más a menos probable para unas notas
    /// MIDI (algoritmo de Krumhansl-Schmuckler). `duraciones`, si se da, pondera cada nota.
    ///
    ///     Tonalidad.identificar(midi: [69, 71, 72, 74, 76, 77, 80, 81]).first   // La menor
    ///
    /// La tónica se escribe con la armadura más sencilla (Re♭ mayor, no Do♯ mayor); con seis
    /// alteraciones se prefieren los sostenidos.
    public static func candidatos(midi: [Int], duraciones: [Double]? = nil) -> [Candidato<Tonalidad>] {
        estimar(clases: midi.map { modulo($0, 12) }, pesos: duraciones, nombres: nil)
    }

    /// Igual, a partir de alturas (notas con octava).
    public static func candidatos(alturas: [Altura], duraciones: [Double]? = nil) -> [Candidato<Tonalidad>] {
        estimar(clases: alturas.map(\.nota.claseDeAltura), pesos: duraciones, nombres: alturas.map(\.nota))
    }

    /// Igual, a partir de notas sin octava. La ortografía decide los empates enarmónicos:
    /// con Sol♭, Si♭ y Re♭ sale Sol♭ mayor, y con Fa♯, La♯ y Do♯, Fa♯ mayor.
    public static func candidatos(notas: [Nota], duraciones: [Double]? = nil) -> [Candidato<Tonalidad>] {
        estimar(clases: notas.map(\.claseDeAltura), pesos: duraciones, nombres: notas)
    }

    /// Tonalidades de más a menos probable, sin el coste: `Tonalidad.identificar(midi: …).first`.
    public static func identificar(midi: [Int], duraciones: [Double]? = nil) -> [Tonalidad] {
        candidatos(midi: midi, duraciones: duraciones).map(\.valor)
    }

    /// Igual, a partir de alturas.
    public static func identificar(alturas: [Altura], duraciones: [Double]? = nil) -> [Tonalidad] {
        candidatos(alturas: alturas, duraciones: duraciones).map(\.valor)
    }

    /// Igual, a partir de notas sin octava.
    public static func identificar(notas: [Nota], duraciones: [Double]? = nil) -> [Tonalidad] {
        candidatos(notas: notas, duraciones: duraciones).map(\.valor)
    }

    private static func estimar(clases: [Int], pesos: [Double]?, nombres: [Nota]?) -> [Candidato<Tonalidad>] {
        guard !clases.isEmpty else { return [] }
        var histograma = [Double](repeating: 0, count: 12)
        for (i, clase) in clases.enumerated() {
            let peso = pesos.flatMap { i < $0.count ? $0[i] : nil } ?? 1
            histograma[clase] += peso
        }
        var resultado: [Candidato<Tonalidad>] = []
        for tonica in 0..<12 {
            for (perfil, modo) in [(perfilMayor, Modo.mayor), (perfilMenor, Modo.menor)] {
                let rotado = (0..<12).map { perfil[modulo($0 - tonica, 12)] }
                let r = correlacionDePearson(histograma, rotado)
                // Coste = 1 − correlación: el mejor ajuste es el de menor coste, como en los acordes.
                resultado.append(Candidato(escribir(tonica: tonica, modo: modo, nombres: nombres), coste: 1 - r))
            }
        }
        return resultado.sorted { $0.coste < $1.coste }
    }

    /// Escritura de la tónica: la que más notas dadas contiene con su ortografía exacta,
    /// luego la de armadura más sencilla, luego la más sostenida.
    private static func escribir(tonica: Int, modo: Modo, nombres: [Nota]?) -> Tonalidad {
        let q0 = modulo(tonica * 7, 12)
        let opciones = [q0 - 12, q0, q0 + 12].map { Tonalidad(Nota(pasosDeQuinta: $0), modo) }
        func clave(_ t: Tonalidad) -> [Int] {
            let coincidencias = nombres.map { lista in lista.filter { t.escala.contiene($0) }.count } ?? 0
            return [-coincidencias, abs(t.armadura), -t.tonica.pasosDeQuinta]
        }
        return opciones.min { clave($0).lexicographicallyPrecedes(clave($1)) } ?? opciones[1]
    }

    private static func correlacionDePearson(_ a: [Double], _ b: [Double]) -> Double {
        let n = Double(a.count)
        let ma = a.reduce(0, +) / n
        let mb = b.reduce(0, +) / n
        var numerador = 0.0, sa = 0.0, sb = 0.0
        for (x, y) in zip(a, b) {
            numerador += (x - ma) * (y - mb)
            sa += (x - ma) * (x - ma)
            sb += (y - mb) * (y - mb)
        }
        let denominador = (sa * sb).squareRoot()
        return denominador == 0 ? 0 : numerador / denominador
    }
}

extension Candidato where Valor == Tonalidad {
    /// Correlación de Pearson entre el perfil de las notas y el de la tonalidad (−1…1).
    /// El coste es 1 − correlación, así que va de 0 (ajuste perfecto) a 2.
    public var correlacion: Double { 1 - coste }
}
