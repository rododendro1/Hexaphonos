import ArmoniaNucleo
import ArmoniaTeoria

/// Una forma de tocar un acorde: el traste de cada cuerda, o `nil` si no suena.
///
///     // Do mayor en la guitarra
///     digitacion.tablatura     // "x32010"
public struct Digitacion: Hashable, Sendable, CustomStringConvertible {
    public let mastil: Mastil
    /// Un elemento por cuerda, de la primera a la última: el traste, o `nil` si la cuerda se apaga.
    public let trastes: [Int?]

    /// Detiene el programa si no hay un traste (o `nil`) por cada cuerda. Si los trastes vienen de fuera,
    /// usa `init?(comprobando:en:)` o `init?(leyendo:en:)`, que devuelven `nil` en vez de detenerse.
    public init(mastil: Mastil, trastes: [Int?]) {
        precondition(trastes.count == mastil.encordado.numeroDeCuerdas, "Un traste (o nil) por cada cuerda")
        self.mastil = mastil
        self.trastes = trastes
    }

    /// Una digitación con esos trastes, o `nil` si no hay uno por cada cuerda o alguno no está en el mástil.
    public init?(comprobando trastes: [Int?], en mastil: Mastil) {
        guard trastes.count == mastil.encordado.numeroDeCuerdas,
              trastes.allSatisfy({ $0.map { (0...mastil.trastes).contains($0) } ?? true })
        else { return nil }
        self.init(mastil: mastil, trastes: trastes)
    }

    /// Lee la tablatura que escribe `tablatura`: «x32010», o con guiones si algún traste pasa de 9 («x-10-12-12-11-10»).
    /// `nil` si no se entiende o no encaja en el mástil.
    public init?(leyendo tablatura: String, en mastil: Mastil) {
        let partes = tablatura.contains("-")
            ? tablatura.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
            : tablatura.map { String($0) }
        var trastes: [Int?] = []
        for parte in partes {
            if parte == "x" || parte == "X" {
                trastes.append(nil)
            } else if !parte.isEmpty, parte.allSatisfy({ $0.isASCII && $0.isNumber }), let traste = Int(parte) {
                trastes.append(traste)
            } else {
                return nil
            }
        }
        self.init(comprobando: trastes, en: mastil)
    }

    /// Las posiciones que suenan, de la cuerda más grave a la más aguda.
    public var posiciones: [Posicion] {
        trastes.enumerated().compactMap { cuerda, traste in
            traste.map { Posicion(cuerda: cuerda, traste: $0) }
        }
    }

    /// Las alturas que suenan, de la cuerda más grave a la más aguda.
    public var alturas: [Altura] { posiciones.map { mastil.altura(en: $0) } }

    /// Las notas que suenan, en el orden de las cuerdas, escritas como las escribe el acorde (Si♭ en un
    /// acorde con bemoles, no La♯). Una nota que no es del acorde se escribe como `Altura(midi:)`.
    public func notas(para acorde: Acorde) -> [Nota] {
        var ortografia: [Int: Nota] = [:]
        for nota in acorde.notas where ortografia[nota.claseDeAltura] == nil {
            ortografia[nota.claseDeAltura] = nota
        }
        return alturas.map { ortografia[$0.nota.claseDeAltura] ?? $0.nota }
    }

    public var cuerdasQueSuenan: Int { posiciones.count }

    /// Los trastes que se pisan, de la cuerda más grave a la más aguda (sin las cuerdas al aire ni las apagadas).
    public var trastesPisados: [Int] { trastes.compactMap { $0 }.filter { $0 > 0 } }

    /// Cuántos trastes abarca la mano: de 1 al pisar un solo traste a 4 con el meñique extendido.
    public var abertura: Int {
        guard let menor = trastesPisados.min(), let mayor = trastesPisados.max() else { return 0 }
        return mayor - menor + 1
    }

    /// El traste más bajo que se pisa, o 0 si todo son cuerdas al aire o apagadas.
    public var posicion: Int { trastesPisados.min() ?? 0 }

    /// Cuántos dedos hacen falta, como mínimo, para pisar la digitación.
    ///
    /// Cada nota pisada necesita un dedo, salvo en el traste más bajo, donde el índice puede pisar varias
    /// cuerdas a la vez: si son seguidas (un dedo plano), o si abarcan cuatro cuerdas o más (una cejilla). Una
    /// cuerda al aire entre dos de ellas lo impide, porque la cejilla la apagaría. Son mínimos: muchas formas
    /// (un La mayor, `x02220`) se tocan con un dedo plano o con tres.
    public var dedos: Int {
        let pisados = trastesPisados
        guard let menor = pisados.min() else { return 0 }
        let fueraDelMasBajo = pisados.filter { $0 != menor }.count
        let delMasBajo = gruposEnElTrasteMasBajo.reduce(0) { $0 + (unSoloDedo($1) ? 1 : $1.count) }
        return fueraDelMasBajo + delMasBajo
    }

    /// El traste de la cejilla, si la forma la lleva: cuatro cuerdas o más, de la primera a la última, pisadas
    /// con el índice en el traste más bajo (el Fa de `133211` tiene una en el traste 1).
    public var cejilla: Int? {
        guard let menor = trastesPisados.min() else { return nil }
        let hay = gruposEnElTrasteMasBajo.contains { $0.count >= 2 && $0[$0.count - 1] - $0[0] + 1 >= 4 }
        return hay ? menor : nil
    }

    /// Las cuerdas (por su índice) que se pisan en el traste más bajo, en grupos que el índice puede cubrir a la
    /// vez: una cuerda al aire entre dos de ellas las separa en grupos distintos.
    private var gruposEnElTrasteMasBajo: [[Int]] {
        guard let traste = trastesPisados.min() else { return [] }
        var grupos: [[Int]] = []
        for cuerda in trastes.indices where trastes[cuerda] == traste {
            if let ultima = grupos.last?.last, !((ultima + 1)..<cuerda).contains(where: { trastes[$0] == 0 }) {
                grupos[grupos.count - 1].append(cuerda)
            } else {
                grupos.append([cuerda])
            }
        }
        return grupos
    }

    /// ¿Pisa un solo dedo todas las cuerdas del grupo? Sí si son seguidas o abarcan cuatro cuerdas o más.
    private func unSoloDedo(_ grupo: [Int]) -> Bool {
        let ancho = grupo[grupo.count - 1] - grupo[0] + 1
        return ancho == grupo.count || ancho >= 4
    }

    /// La forma habitual de escribirla: "x32010", o con guiones si algún traste pasa de 9:
    /// "x-10-12-12-11-10".
    public var tablatura: String {
        let partes = trastes.map { $0.map(String.init) ?? "x" }
        return partes.contains { $0.count > 1 } ? partes.joined(separator: "-") : partes.joined()
    }

    public var description: String { tablatura }
}

extension Mastil {
    /// Formas de tocar un acorde en este mástil, de la más cómoda a la menos.
    ///
    /// Una forma vale si:
    /// - toca todas las notas del acorde (con `exigirQuinta: false`, la quinta puede faltar en los acordes de cuatro notas o más);
    /// - la nota más grave que suena es el bajo del acorde (Sol7/Si tiene a Si debajo). En un instrumento
    ///   reentrante (``Encordado/esReentrante``) esto solo se exige a un acorde con bajo propio: el La menor
    ///   del ukelele, `2000`, suena con el Do más grave y es un La menor;
    /// - las cuerdas que suenan son seguidas (sin huecos apagados en medio);
    /// - la mano no abarca más de `abertura` trastes;
    /// - se puede tocar con `maximoDeDedos` dedos (ver ``Digitacion/dedos``).
    ///
    /// El orden es el de un coste de comodidad, de menor a mayor: un punto por cada traste de la posición
    /// (cerca de la cejilla es más cómodo), por cada dedo y por cada traste de abertura, dos por cada cuerda
    /// apagada y uno si falta la quinta de un acorde de cuatro notas o más. A igual coste, antes la que tiene
    /// más cuerdas sonando. Así `x32010` es la primera forma de Do, y no `8-10-10-0-8-0`.
    ///
    /// - Parameters:
    ///   - acorde: el acorde.
    ///   - abertura: trastes que puede abarcar la mano (4 por defecto).
    ///   - maximoDeDedos: dedos que se pueden usar (4 por defecto: el pulgar no cuenta).
    ///   - maximoTraste: no se usan trastes más altos que este.
    ///   - cuerdasMinimas: cuántas cuerdas deben sonar (4, o todas si el instrumento tiene menos).
    ///   - exigirQuinta: si es `false`, se aceptan formas sin la quinta (frecuente en acordes de siete o más notas).
    ///   - limite: cuántas formas se devuelven como máximo.
    public func digitaciones(de acorde: Acorde, abertura: Int = 4, maximoDeDedos: Int = 4, maximoTraste: Int = 12,
                             cuerdasMinimas: Int = 4, exigirQuinta: Bool = true,
                             limite: Int = 12) -> [Digitacion] {
        let cuerdas = encordado.cuerdas
        let ultimoTraste = min(maximoTraste, trastes)
        let notas = acorde.notas
        let clases = Set(notas.map(\.claseDeAltura))
        let claseDelBajo = acorde.bajo.claseDeAltura
        // Las clases que no pueden faltar: todas, salvo la quinta si no se exige.
        var obligatorias = clases
        if !exigirQuinta, let quinta = acorde.quinta, notas.count > 3 {
            obligatorias.remove(quinta.claseDeAltura)
        }
        let minimas = min(cuerdasMinimas, cuerdas.count)
        // En un instrumento reentrante el nombre de un acorde en estado fundamental no promete la raíz en la nota
        // más grave; el de un acorde con bajo propio (Do/Mi) sí.
        let exigirElBajoAbajo = !encordado.esReentrante || acorde.bajo != acorde.fundamental

        var encontradas = Set<[Int?]>()
        var actual = [Int?](repeating: nil, count: cuerdas.count)

        // Búsqueda cuerda a cuerda, desde la primera. `empezo` y `acabo` aseguran que las cuerdas
        // que suenan son seguidas; `menor` y `mayor` son los trastes pisados extremos.
        func buscar(_ cuerda: Int, empezo: Bool, acabo: Bool, menor: Int?, mayor: Int?, clasesTocadas: Set<Int>) {
            if cuerda == cuerdas.count {
                let sonando = actual.compactMap { $0 }.count
                guard sonando >= minimas, obligatorias.isSubset(of: clasesTocadas) else { return }
                // La nota más grave (no la primera cuerda: en el ukelele no coinciden) es el bajo.
                if exigirElBajoAbajo {
                    let alturaMasGrave = zip(cuerdas, actual).compactMap { alAire, traste in traste.map { alAire.midi + $0 } }.min()
                    guard let midiMasGrave = alturaMasGrave, Mastil.clase(midiMasGrave) == claseDelBajo else { return }
                }
                guard Digitacion(mastil: self, trastes: actual).dedos <= maximoDeDedos else { return }
                encontradas.insert(actual)
                return
            }
            // Opción 1: la cuerda no suena (antes de empezar, o para terminar).
            actual[cuerda] = nil
            buscar(cuerda + 1, empezo: empezo, acabo: empezo, menor: menor, mayor: mayor, clasesTocadas: clasesTocadas)
            // Opción 2: suena, si no ha terminado ya.
            guard !acabo else { return }
            for traste in 0...ultimoTraste {
                let midi = cuerdas[cuerda].midi + traste
                let clase = Mastil.clase(midi)
                guard clases.contains(clase) else { continue }
                var nuevoMenor = menor, nuevoMayor = mayor
                if traste > 0 {
                    nuevoMenor = min(menor ?? traste, traste)
                    nuevoMayor = max(mayor ?? traste, traste)
                    if let a = nuevoMenor, let b = nuevoMayor, b - a + 1 > abertura { continue }
                }
                actual[cuerda] = traste
                buscar(cuerda + 1, empezo: true, acabo: false, menor: nuevoMenor, mayor: nuevoMayor,
                       clasesTocadas: clasesTocadas.union([clase]))
            }
            actual[cuerda] = nil
        }
        buscar(0, empezo: false, acabo: false, menor: nil, mayor: nil, clasesTocadas: [])

        // Sin la quinta solo se penaliza a un acorde de cuatro notas o más (en uno de tres, la quinta es obligatoria).
        let claseDeLaQuinta = notas.count > 3 ? acorde.quinta?.claseDeAltura : nil
        let conClave = encontradas.map { trastes -> (forma: Digitacion, clave: [Int]) in
            let forma = Digitacion(mastil: self, trastes: trastes)
            let sinQuinta = claseDeLaQuinta.map { quinta in
                !forma.alturas.contains { Mastil.clase($0.midi) == quinta }
            } ?? false
            return (forma, [forma.coste(sinQuinta: sinQuinta), -forma.cuerdasQueSuenan])
        }
        let ordenadas = conClave.sorted { a, b in
            a.clave != b.clave ? a.clave.lexicographicallyPrecedes(b.clave) : a.forma.tablatura < b.forma.tablatura
        }
        return ordenadas.prefix(limite).map { $0.forma }
    }
}

extension Digitacion {
    /// El coste de comodidad con que se ordenan las formas (menor es mejor): la posición, los dedos, la
    /// abertura, dos por cada cuerda apagada y uno si falta la quinta.
    fileprivate func coste(sinQuinta: Bool) -> Int {
        posicion + dedos + abertura + 2 * (trastes.count - cuerdasQueSuenan) + (sinQuinta ? 1 : 0)
    }
}
