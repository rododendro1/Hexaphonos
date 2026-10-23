import ArmoniaNucleo
// Conducción de voces: las reglas de la armonía a cuatro voces sobre una sucesión de acordes.

// MARK: - ProblemaDeConduccion

/// Una falta de conducción de voces: qué regla se rompe, dónde y entre qué voces.
///
/// Las voces se numeran de grave a agudo desde 0; a cuatro voces son bajo, tenor, contralto y
/// soprano. `acorde` es el índice del acorde donde está la falta o, si es un movimiento, del
/// acorde de partida (el movimiento va de `acorde` a `acorde + 1`).
public struct ProblemaDeConduccion: Hashable, Sendable, CustomStringConvertible {
    public enum Tipo: Hashable, Sendable, CaseIterable {
        /// Dos voces a distancia de quinta justa que se mueven a otra quinta justa.
        case quintasParalelas
        /// Dos voces a distancia de octava justa (o unísono) que se mueven a otra.
        case octavasParalelas
        /// Las voces extremas llegan a una quinta justa por movimiento directo con salto en el soprano.
        case quintasDirectas
        /// Las voces extremas llegan a una octava justa por movimiento directo con salto en el soprano.
        case octavasDirectas
        /// Una voz queda por encima de la que debería ir más aguda.
        case cruceDeVoces
        /// Una voz pasa por encima (o por debajo) de la nota que la voz vecina tenía antes.
        case superposicion
        /// Más de una octava entre dos voces superiores vecinas (contralto–soprano, tenor–contralto).
        case separacionExcesiva
        /// Un salto mayor que una octava o un intervalo aumentado en una voz.
        case saltoNoMelodico
        /// Una nota fuera de la extensión habitual de la voz (solo a cuatro voces).
        case fueraDeTesitura
    }

    public let tipo: Tipo
    public let acorde: Int
    public let voces: [Int]
    package let numeroDeVoces: Int

    /// "Quintas paralelas entre bajo y soprano (acordes 1 → 2)". Los acordes se cuentan desde 1.
    public var description: String { descripcion(en: .espanol) }

    public func descripcion(en notacion: Nomenclatura) -> String {
        let ingles = notacion.vocabulario == .ingles
        let nombres = voces.map { ConduccionDeVoces.nombreDeVoz($0, de: numeroDeVoces, ingles: ingles) }
        let entre = ingles ? "between \(nombres.joined(separator: " and "))"
                           : "entre \(nombres.joined(separator: " y "))"
        let en = ingles ? "in the \(nombres.first ?? "")" : "en \(nombres.first ?? "")"
        let lugar: String
        switch tipo {
        case .quintasParalelas, .octavasParalelas, .quintasDirectas, .octavasDirectas, .superposicion, .saltoNoMelodico:
            lugar = ingles ? "(chords \(acorde + 1) → \(acorde + 2))" : "(acordes \(acorde + 1) → \(acorde + 2))"
        case .cruceDeVoces, .separacionExcesiva, .fueraDeTesitura:
            lugar = ingles ? "(chord \(acorde + 1))" : "(acorde \(acorde + 1))"
        }
        switch tipo {
        case .saltoNoMelodico, .fueraDeTesitura:
            return "\(tipo.nombre(en: notacion)) \(en) \(lugar)"
        default:
            return "\(tipo.nombre(en: notacion)) \(entre) \(lugar)"
        }
    }
}

extension ProblemaDeConduccion.Tipo: Nombrable, CustomStringConvertible {
    public var nombre: String {
        switch self {
        case .quintasParalelas: return "Quintas paralelas"
        case .octavasParalelas: return "Octavas paralelas"
        case .quintasDirectas: return "Quintas directas"
        case .octavasDirectas: return "Octavas directas"
        case .cruceDeVoces: return "Cruce de voces"
        case .superposicion: return "Superposición"
        case .separacionExcesiva: return "Más de una octava"
        case .saltoNoMelodico: return "Salto no melódico"
        case .fueraDeTesitura: return "Fuera de tesitura"
        }
    }

    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles else { return nombre }
        switch self {
        case .quintasParalelas: return "Parallel fifths"
        case .octavasParalelas: return "Parallel octaves"
        case .quintasDirectas: return "Direct fifths"
        case .octavasDirectas: return "Direct octaves"
        case .cruceDeVoces: return "Voice crossing"
        case .superposicion: return "Voice overlap"
        case .separacionExcesiva: return "More than an octave"
        case .saltoNoMelodico: return "Unmelodic leap"
        case .fueraDeTesitura: return "Out of range"
        }
    }

    public var description: String { nombre }
}

// MARK: - ConduccionDeVoces

/// Una sucesión de acordes escritos voz por voz, para comprobar su conducción.
///
///     let c = try ConduccionDeVoces(leyendo: "Do3 Sol3 Mi4 Do5 | Re3 La3 Fa4 Re5")
///     c.problemas.map(\.tipo)   // [.quintasParalelas, .octavasParalelas]
///
/// Cada acorde lleva sus alturas de grave a agudo, y todos tienen el mismo número de voces.
/// A cuatro voces se comprueban también las tesituras: bajo Mi2–Do4, tenor Do3–Sol4,
/// contralto Sol3–Re5 y soprano Do4–Sol5.
public struct ConduccionDeVoces: Hashable, Sendable {
    /// Los acordes, cada uno con sus alturas de la voz más grave a la más aguda.
    public let acordes: [[Altura]]

    /// `nil` si no hay acordes, si hay menos de dos voces o si no todos tienen las mismas.
    public init?(_ acordes: [[Altura]]) {
        guard let voces = acordes.first?.count, voces >= 2,
              acordes.allSatisfy({ $0.count == voces }) else { return nil }
        self.acordes = acordes
    }

    /// Las mismas alturas dadas voz por voz, de grave a agudo: `[bajo, tenor, contralto, soprano]`,
    /// cada una con sus notas en orden. `nil` si las voces no tienen todas las mismas notas.
    public init?(voces: [[Altura]]) {
        guard let longitud = voces.first?.count, voces.allSatisfy({ $0.count == longitud }) else { return nil }
        self.init((0..<longitud).map { i in voces.map { $0[i] } })
    }

    /// Lee los acordes separados por barras o comas, y en cada uno las alturas de grave a agudo:
    /// "Do3 Mi4 Sol4 Do5 | Sol2 Re4 Sol4 Si4".
    public init(leyendo texto: String) throws {
        var acordes: [[Altura]] = [[]]
        var actual = ""
        var posicion = 0
        func cerrarAltura() throws {
            defer { actual = "" }
            guard !actual.isEmpty else { return }
            do {
                acordes[acordes.count - 1].append(try Altura(leyendo: actual))
            } catch let error as ErrorDeLectura {
                let inicio = posicion - actual.count
                throw ErrorDeLectura(texto: texto, posicion: error.posicion.map { inicio + $0 } ?? inicio,
                                     motivo: error.motivo)
            }
        }
        for caracter in texto {
            if caracter == "|" || caracter == "," {
                try cerrarAltura()
                acordes.append([])
            } else if caracter.isWhitespace {
                try cerrarAltura()
            } else {
                actual.append(caracter)
            }
            posicion += 1
        }
        try cerrarAltura()
        acordes.removeAll { $0.isEmpty }
        guard !acordes.isEmpty else { throw ErrorDeLectura(texto: texto, posicion: nil, motivo: .textoVacio) }
        guard let conduccion = ConduccionDeVoces(acordes) else {
            throw ErrorDeLectura(texto: texto, posicion: nil, motivo: .vocesDistintas)
        }
        self = conduccion
    }

    public var numeroDeVoces: Int { acordes[0].count }

    /// Las notas de una voz (0 = la más grave), en orden.
    public func voz(_ indice: Int) -> [Altura] { acordes.map { $0[indice] } }

    /// Todas las faltas, en orden de aparición.
    public var problemas: [ProblemaDeConduccion] {
        var problemas: [ProblemaDeConduccion] = []
        func anotar(_ tipo: ProblemaDeConduccion.Tipo, _ acorde: Int, _ voces: [Int]) {
            problemas.append(ProblemaDeConduccion(tipo: tipo, acorde: acorde, voces: voces, numeroDeVoces: numeroDeVoces))
        }
        let n = numeroDeVoces
        let soprano = n - 1

        for (i, acorde) in acordes.enumerated() {
            // En el acorde: cruces, separación y tesituras.
            for v in 0..<(n - 1) where acorde[v].midi > acorde[v + 1].midi {
                anotar(.cruceDeVoces, i, [v, v + 1])
            }
            for v in 1..<(n - 1) where acorde[v + 1].midi - acorde[v].midi > 12 {
                anotar(.separacionExcesiva, i, [v, v + 1])
            }
            if n == 4 {
                for v in 0..<4 where !ConduccionDeVoces.tesituras[v].contains(acorde[v].midi) {
                    anotar(.fueraDeTesitura, i, [v])
                }
            }
            guard i + 1 < acordes.count else { continue }
            let siguiente = acordes[i + 1]

            // Cada voz: saltos.
            for v in 0..<n {
                let salto = siguiente[v] - acorde[v]
                if case .aumentada = salto.calidad, salto.numero != 1 {
                    anotar(.saltoNoMelodico, i, [v])
                } else if salto.semitonos > 12 {
                    anotar(.saltoNoMelodico, i, [v])
                }
            }

            // Voces vecinas: superposición.
            for v in 0..<(n - 1) {
                if siguiente[v].midi > acorde[v + 1].midi || siguiente[v + 1].midi < acorde[v].midi {
                    anotar(.superposicion, i, [v, v + 1])
                }
            }

            // Cada pareja de voces: paralelas.
            for grave in 0..<(n - 1) {
                for aguda in (grave + 1)..<n {
                    let antes = ConduccionDeVoces.consonanciaPerfecta(acorde[grave], acorde[aguda])
                    let despues = ConduccionDeVoces.consonanciaPerfecta(siguiente[grave], siguiente[aguda])
                    let semueven = acorde[grave] != siguiente[grave] && acorde[aguda] != siguiente[aguda]
                    if let antes, antes == despues, semueven {
                        anotar(antes == 5 ? .quintasParalelas : .octavasParalelas, i, [grave, aguda])
                    }
                }
            }

            // Voces extremas: quintas y octavas directas (movimiento directo y salto en el soprano).
            let movimientoBajo = siguiente[0].midi - acorde[0].midi
            let movimientoSoprano = siguiente[soprano].midi - acorde[soprano].midi
            if let despues = ConduccionDeVoces.consonanciaPerfecta(siguiente[0], siguiente[soprano]),
               ConduccionDeVoces.consonanciaPerfecta(acorde[0], acorde[soprano]) != despues,
               movimientoBajo != 0, movimientoSoprano != 0,
               (movimientoBajo > 0) == (movimientoSoprano > 0),
               abs(movimientoSoprano) > 2 {
                anotar(despues == 5 ? .quintasDirectas : .octavasDirectas, i, [0, soprano])
            }
        }
        return problemas
    }

    /// `true` si no hay ninguna falta.
    public var esCorrecta: Bool { problemas.isEmpty }

    // MARK: Auxiliares

    /// Extensión de cada voz en MIDI: bajo Mi2–Do4, tenor Do3–Sol4, contralto Sol3–Re5, soprano Do4–Sol5.
    package static let tesituras = [40...60, 48...67, 55...74, 60...79]

    /// 5 si las dos alturas forman una quinta justa (simple o compuesta), 8 si forman una octava
    /// justa o un unísono; `nil` en otro caso.
    package static func consonanciaPerfecta(_ grave: Altura, _ aguda: Altura) -> Int? {
        let intervalo = aguda - grave
        guard intervalo.calidad == .justa else { return nil }
        switch intervalo.numeroSimple {
        case 5: return 5
        case 1, 8: return 8
        default: return nil
        }
    }

    package static func nombreDeVoz(_ voz: Int, de total: Int, ingles: Bool) -> String {
        if total == 4 {
            return (ingles ? ["bass", "tenor", "alto", "soprano"] : ["bajo", "tenor", "contralto", "soprano"])[voz]
        }
        return ingles ? "voice \(voz + 1)" : "voz \(voz + 1)"
    }
}
