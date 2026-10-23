import ArmoniaNucleo
// Análisis armónico: grados, funciones y dominantes secundarias de una sucesión de acordes.

// MARK: - FuncionTonal

/// Función de un acorde en la tonalidad, en el sentido de la armonía funcional: reposo
/// (tónica), alejamiento (subdominante) o tensión que pide resolver (dominante).
public enum FuncionTonal: Hashable, Sendable, CaseIterable, CustomStringConvertible {
    case tonica, subdominante, dominante

    /// Función de cada grado: I, iii y vi son de tónica; ii y IV, de subdominante; V y vii°, de dominante.
    package init(grado: Int) {
        switch grado {
        case 2, 4: self = .subdominante
        case 5, 7: self = .dominante
        default: self = .tonica
        }
    }

    /// "T", "S", "D".
    public var abreviatura: String {
        switch self {
        case .tonica: return "T"
        case .subdominante: return "S"
        case .dominante: return "D"
        }
    }

    public var nombre: String {
        switch self {
        case .tonica: return "tónica"
        case .subdominante: return "subdominante"
        case .dominante: return "dominante"
        }
    }

    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles else { return nombre }
        switch self {
        case .tonica: return "tonic"
        case .subdominante: return "subdominant"
        case .dominante: return "dominant"
        }
    }

    public var description: String { nombre }
}

extension FuncionTonal: Nombrable {}

// MARK: - AcordeAnalizado

/// Un acorde leído en una tonalidad: su cifrado romano, su función y por qué está ahí.
///
///     let a = Tonalidad(.do).analizar(["Re7", "Sol"]).acordes[0]
///     a.cifrado     // "V7/V"
///     a.funcion     // .dominante
///     a.categoria   // .dominanteSecundaria(de: 5)
public struct AcordeAnalizado: Hashable, Sendable, CustomStringConvertible {
    /// De dónde sale un acorde respecto a la tonalidad.
    public enum Categoria: Hashable, Sendable {
        /// Con las notas de la tonalidad (en menor, también el 6.º y el 7.º elevados).
        case diatonico
        /// Dominante (V o V7) de otro grado: V7/V. El grado es el de destino.
        case dominanteSecundaria(de: Int)
        /// Acorde de sensible (vii°, vii°7, viiø7) de otro grado: vii°7/V.
        case sensibleSecundaria(de: Int)
        /// Sexta napolitana: el acorde mayor sobre el 2.º grado rebajado (♭II).
        case napolitana
        /// Sexta aumentada italiana, francesa o alemana: ♭6̂ y ♯4̂ con la tónica (It+6, Fr+6, Ger+6).
        case sextaAumentada
        /// Prestado del modo homónimo: iv o ♭VI en mayor; I (tercera de picardía) en menor.
        case prestamo
        /// Ninguno de los anteriores.
        case cromatico
    }

    public let acorde: Acorde
    /// Grado de la fundamental (1…7), contado por el nombre de la nota: en Do mayor, Si♭ es el 7.º.
    public let grado: Int
    /// Cifrado romano, con la inversión en cifra de bajo continuo: "I", "V65", "♭VI", "vii°7/V".
    public let cifrado: String
    /// `nil` para los acordes cromáticos que no tienen una función clara.
    public let funcion: FuncionTonal?
    public let categoria: Categoria

    public var description: String { cifrado }
}

// MARK: - AnalisisArmonico

/// El análisis de una progresión en una tonalidad.
///
///     let analisis = try AnalisisArmonico.analizar(leyendo: "Do Lam Re7 Sol7 Do")
///     analisis.tonalidad   // Do mayor
///     analisis.cifrados    // ["I", "vi", "V7/V", "V7", "I"]
///     analisis.funciones   // [T, T, D, D, T]
///     print(analisis)      // I–vi–V7/V–V7–I en Do mayor
public struct AnalisisArmonico: Hashable, Sendable, CustomStringConvertible {
    public let tonalidad: Tonalidad
    public let acordes: [AcordeAnalizado]

    public var cifrados: [String] { acordes.map(\.cifrado) }
    public var funciones: [FuncionTonal?] { acordes.map(\.funcion) }

    /// "I–IV–V7–I en Do mayor".
    public var description: String { nombre(en: .espanol) }

    /// "I–IV–V7–I en Do mayor", "I–IV–V7–I in C major".
    public func nombre(en notacion: Nomenclatura) -> String {
        let preposicion = notacion.vocabulario == .ingles ? "in" : "en"
        return cifrados.joined(separator: "–") + " \(preposicion) " + tonalidad.nombre(en: notacion)
    }

    /// Analiza los acordes buscando antes la tonalidad: entre las más probables por sus notas,
    /// la que explica más acordes con la armonía de la tonalidad y, a igualdad, la que empieza o
    /// termina en su tónica. `nil` si no hay acordes.
    public static func analizar(_ acordes: [Acorde]) -> AnalisisArmonico? {
        guard !acordes.isEmpty else { return nil }
        // La fundamental pesa el doble: es lo que más define la tonalidad de un acorde.
        let notas = acordes.flatMap { $0.notas + [$0.fundamental] }
        let posibles = Tonalidad.candidatos(notas: notas).prefix(6)
        var mejor: (analisis: AnalisisArmonico, coste: Double)?
        for (puesto, candidato) in posibles.enumerated() {
            let analisis = candidato.valor.analizar(acordes)
            let coste = analisis.coste + 0.01 * Double(puesto)
            if mejor == nil || coste < mejor!.coste { mejor = (analisis, coste) }
        }
        return mejor?.analisis
    }

    /// Lee una progresión escrita como cifrados separados por espacios, comas o barras
    /// ("Do Fa Sol7 Do", "Am | Dm | E7 | Am"; las comas entre paréntesis son del cifrado:
    /// "Do7(♭9,♯11)") y la analiza, en la tonalidad dada o en la que
    /// mejor la explique.
    public static func analizar(leyendo texto: String, en tonalidad: Tonalidad? = nil) throws -> AnalisisArmonico {
        let acordes = try leerAcordes(texto)
        return tonalidad.map { $0.analizar(acordes) } ?? analizar(acordes)!
    }

    /// Los acordes de una progresión escrita como cifrados separados por espacios, comas o barras.
    /// Lanza un error si alguno no se puede leer o si no hay ninguno.
    package static func leerAcordes(_ texto: String) throws -> [Acorde] {
        var acordes: [Acorde] = []
        var posicion = 0
        var actual = ""
        var enParentesis = false
        func cerrar() throws {
            defer { actual = "" }
            guard !actual.isEmpty else { return }
            do {
                acordes.append(try Acorde(leyendo: actual))
            } catch let error as ErrorDeLectura {
                let inicio = posicion - actual.count
                throw ErrorDeLectura(texto: texto, posicion: error.posicion.map { inicio + $0 } ?? inicio,
                                     motivo: error.motivo)
            }
        }
        for caracter in texto {
            if caracter == "(" { enParentesis = true } else if caracter == ")" { enParentesis = false }
            if caracter.isWhitespace || (caracter == "," && !enParentesis) || caracter == "|" || caracter == "–" {
                try cerrar()
            } else {
                actual.append(caracter)
            }
            posicion += 1
        }
        try cerrar()
        guard !acordes.isEmpty else { throw ErrorDeLectura(texto: texto, posicion: nil, motivo: .textoVacio) }
        return acordes
    }

    /// Cuánto le cuesta a la tonalidad explicar la progresión: nada por los acordes diatónicos,
    /// algo por los secundarios y los prestados, y mucho por los cromáticos. Empezar y, sobre
    /// todo, terminar en la tónica lo rebaja.
    package var coste: Double {
        var total = 0.0
        for (i, analizado) in acordes.enumerated() {
            total += AnalisisArmonico.coste(de: analizado, siguiente: i + 1 < acordes.count ? acordes[i + 1] : nil)
        }
        return total - AnalisisArmonico.rebaja(acordes.last, 1) - AnalisisArmonico.rebaja(acordes.first, 0.5)
    }

    /// Lo que cuesta un acorde: nada si es diatónico, algo si es secundario (menos si resuelve en
    /// su destino) o prestado, y mucho si es cromático.
    package static func coste(de analizado: AcordeAnalizado, siguiente: AcordeAnalizado?) -> Double {
        switch analizado.categoria {
        case .diatonico: return 0
        case .dominanteSecundaria(let destino), .sensibleSecundaria(let destino):
            return siguiente?.grado == destino ? 0.25 : 0.75
        case .napolitana, .sextaAumentada, .prestamo: return 0.5
        case .cromatico: return 1.5
        }
    }

    /// Lo que rebaja el coste empezar o terminar en la tónica: entera si es la de la tonalidad, y
    /// poco si es prestada (Do mayor en Do menor).
    package static func rebaja(_ analizado: AcordeAnalizado?, _ entera: Double) -> Double {
        guard let analizado, analizado.grado == 1 else { return 0 }
        switch analizado.categoria {
        case .diatonico: return entera
        case .prestamo: return entera / 4
        default: return 0
        }
    }
}

// MARK: - Análisis en una tonalidad

extension Tonalidad {
    /// Analiza una sucesión de acordes en esta tonalidad.
    ///
    ///     Tonalidad(.la, .menor).analizar(["Lam", "Rem/Fa", "Mi7", "La"]).cifrados
    ///     // ["i", "iv6", "V7", "I"]   (el último, con tercera de picardía)
    public func analizar(_ acordes: [Acorde]) -> AnalisisArmonico {
        let analizados = acordes.indices.map { i in
            analizar(acordes[i], siguiente: i + 1 < acordes.count ? acordes[i + 1] : nil)
        }
        return AnalisisArmonico(tonalidad: self, acordes: analizados)
    }

    /// Analiza un acorde suelto. `siguiente`, si se da, decide si un acorde que podría ser una
    /// dominante secundaria lo es (cuando resuelve en su destino) o es prestado.
    public func analizar(_ acorde: Acorde, siguiente: Acorde? = nil) -> AcordeAnalizado {
        let grado = gradoDe(acorde.fundamental)
        let tipo = acorde.tipo
        let propias = notasPropias

        func analizado(_ cifrado: String, _ funcion: FuncionTonal?, _ categoria: AcordeAnalizado.Categoria) -> AcordeAnalizado {
            AcordeAnalizado(acorde: acorde, grado: grado, cifrado: cifrado, funcion: funcion, categoria: categoria)
        }

        // Diatónico.
        if acorde.notas.allSatisfy(propias.contains) {
            return analizado(numeral(acorde, grado: grado) + sufijo(acorde), FuncionTonal(grado: grado), .diatonico)
        }

        // Sexta aumentada, antes que cualquier lectura por su fundamental.
        if let cifrado = sextaAumentada(acorde, siguiente: siguiente) {
            return analizado(cifrado, .subdominante, .sextaAumentada)
        }

        // Dominante o sensible de otro grado (cuando resuelve en él, o si no hay otra lectura).
        let secundaria = secundariaDe(acorde)
        if let secundaria, gradoDe(siguiente?.fundamental) == secundaria.destino {
            return analizado(secundaria.cifrado, .dominante, secundaria.categoria)
        }

        // Sexta napolitana: ♭II mayor.
        if tipo == .mayor, acorde.fundamental == tonica + .segundaMenor {
            return analizado("♭II" + sufijo(acorde), .subdominante, .napolitana)
        }

        // Prestado del modo homónimo.
        if acorde.notas.allSatisfy(homonima.notasPropias.contains) {
            return analizado(numeral(acorde, grado: grado) + sufijo(acorde), FuncionTonal(grado: grado), .prestamo)
        }

        if let secundaria {
            return analizado(secundaria.cifrado, .dominante, secundaria.categoria)
        }
        return analizado(numeral(acorde, grado: grado) + sufijo(acorde), nil, .cromatico)
    }

    // MARK: Auxiliares

    /// Grado de una nota por su nombre (1…7): en Do mayor, Si♭ y Si son el 7.º.
    package func gradoDe(_ nota: Nota) -> Int {
        modulo(nota.natural.indiceDiatonico - tonica.natural.indiceDiatonico, 7) + 1
    }

    private func gradoDe(_ nota: Nota?) -> Int? { nota.map { gradoDe($0) } }

    /// Numeral romano del grado de la fundamental, en minúscula si el acorde es menor o disminuido
    /// y con la alteración delante si la fundamental no es propia de la tonalidad: ♭VII, ♯iv°.
    private func numeral(_ acorde: Acorde, grado: Int) -> String {
        let romanos = ["I", "II", "III", "IV", "V", "VI", "VII"]
        let numeral = acorde.tipo.esMenor ? romanos[grado - 1].lowercased() : romanos[grado - 1]
        guard !notasPropias.contains(acorde.fundamental) else { return numeral }
        let alteracion = (acorde.fundamental.pasosDeQuinta - escala.grado(grado).pasosDeQuinta) / 7
        return Alteracion(alteracion).simbolo + numeral
    }

    /// El sufijo del tipo con la inversión en cifra de bajo continuo: tríadas 6 y 64;
    /// cuatríadas 65, 43 y 42 ("V65", "viiø43"). En los demás acordes invertidos se escriben
    /// todos los intervalos sobre el bajo, de mayor a menor: Fa6/La en Do es "IV(add6)643".
    private func sufijo(_ acorde: Acorde) -> String {
        let sufijo = acorde.tipo.sufijoRomano
        guard let inversion = acorde.inversion, inversion > 0 else { return sufijo }
        switch acorde.tipo.intervalos.count {
        case 3 where (acorde.tipo.esMayor || acorde.tipo.esMenor) && inversion <= 2:
            return sufijo + ["6", "64"][inversion - 1]
        case 4 where sufijo.hasSuffix("7") && inversion <= 3:
            return String(sufijo.dropLast()) + ["65", "43", "42"][inversion - 1]
        default:
            let bajo = acorde.bajo.natural.indiceDiatonico
            let cifras = Set(acorde.notas.filter { $0 != acorde.bajo }.map { modulo($0.natural.indiceDiatonico - bajo, 7) + 1 })
            return sufijo + cifras.sorted(by: >).map(String.init).joined()
        }
    }

    /// "It+6", "Fr+6" o "Ger+6" si el acorde tiene ♭6̂, la tónica y ♯4̂, y además nada (italiana),
    /// 2̂ (francesa) o ♭3̂ (alemana), sea cual sea el bajo. La alemana escrita como séptima de
    /// dominante (La♭7 en Do, con Sol♭ en vez de Fa♯) también lo es si va a la dominante.
    private func sextaAumentada(_ acorde: Acorde, siguiente: Acorde?) -> String? {
        var resto = Set(acorde.notas)
        guard resto.remove(tonica + .sextaMenor) != nil, resto.remove(tonica) != nil else { return nil }
        let terceraMenor = tonica + .terceraMenor
        if resto.remove(tonica + .cuartaAumentada) != nil {
            switch resto {
            case []: return "It+6"
            case [tonica + .segundaMayor]: return "Fr+6"
            case [terceraMenor]: return "Ger+6"
            default: return nil
            }
        }
        let dominante = tonica + .quintaJusta
        guard resto == [terceraMenor, tonica + .quintaDisminuida],
              let siguiente, siguiente.fundamental == dominante || siguiente.bajo == dominante else { return nil }
        return "Ger+6"
    }

    /// Si el acorde es la dominante (V, V7) o el acorde de sensible (vii°, vii°7, viiø7) de un
    /// grado de la tonalidad que no sea la tónica, su cifrado ("V7/V"), su categoría y el grado.
    private func secundariaDe(_ acorde: Acorde) -> (cifrado: String, categoria: AcordeAnalizado.Categoria, destino: Int)? {
        let estructura = acorde.tipo.estructura
        let esDeDominante = estructura.calidadDeTriada == .mayor
            && (estructura.septima == nil || estructura.septima == .septimaMenor)
        let esDeSensible = estructura.calidadDeTriada == .disminuida
        guard esDeDominante || esDeSensible else { return nil }
        let destino = acorde.fundamental + (esDeDominante ? Intervalo.cuartaJusta : .segundaMenor)
        let grado = gradoDe(destino)
        guard grado != 1, notasPropias.contains(destino) else { return nil }
        let acordeDestino = self.acorde(grado: grado)
        guard acordeDestino.fundamental == destino,
              acordeDestino.tipo.estructura.calidadDeTriada != .disminuida else { return nil }
        let romanoDestino = cifradoRomano(grado: grado)
        if esDeDominante {
            return ("V" + sufijo(acorde) + "/" + romanoDestino, .dominanteSecundaria(de: grado), grado)
        }
        return ("vii" + sufijo(acorde) + "/" + romanoDestino, .sensibleSecundaria(de: grado), grado)
    }
}
