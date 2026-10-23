import ArmoniaNucleo
// Cadencias: las parejas de acordes que cierran (o dejan en suspenso) una frase tonal.

// MARK: - Cadencia

/// Dos acordes seguidos que forman una cadencia en una tonalidad.
///
///     let analisis = try AnalisisArmonico.analizar(leyendo: "Do Fa Sol7 Do")
///     analisis.cadencias[0].tipo          // .autentica
///     analisis.cadencias[0].description   // "Cadencia auténtica V7–I (acordes 3 → 4)"
///
/// Sin la partitura no se sabe dónde acaban las frases, así que cuenta cada pareja que tenga la
/// forma de una cadencia: V–I es auténtica también en mitad de la progresión. La semicadencia, que
/// es solo llegar a la dominante, se reconoce únicamente al final.
public struct Cadencia: Hashable, Sendable, CustomStringConvertible {
    public enum Tipo: Hashable, Sendable, CaseIterable {
        /// De la dominante (V, V7, vii°, vii°7) a la tónica.
        case autentica
        /// De la subdominante (IV, iv) a la tónica.
        case plagal
        /// De la dominante al VI (vi en mayor, VI en menor, o el ♭VI prestado): rota o evitada.
        case rota
        /// Una frase que termina en la dominante (V en estado fundamental), venga de donde venga.
        case semicadencia
    }

    public let tipo: Tipo
    /// Índice del primer acorde de la pareja (el segundo es `acorde + 1`), contado desde 0.
    public let acorde: Int
    /// La tonalidad en la que se lee la cadencia.
    public let tonalidad: Tonalidad
    /// Los dos acordes leídos en `tonalidad`.
    public let acordes: [AcordeAnalizado]

    /// Auténtica con los dos acordes en estado fundamental y la dominante V (no vii°): la cadencia
    /// perfecta. Las demás auténticas son imperfectas.
    public var esPerfecta: Bool {
        tipo == .autentica && acordes[0].grado == 5 && acordes.allSatisfy { $0.acorde.inversion == 0 }
    }

    /// "Cadencia auténtica V7–I (acordes 3 → 4)". Los acordes se cuentan desde 1.
    public var description: String { descripcion(en: .espanol) }

    public func descripcion(en notacion: Nomenclatura) -> String {
        let lugar = notacion.vocabulario == .ingles ? "chords" : "acordes"
        let nombre = tipo.nombre(en: notacion)
        return nombre.prefix(1).uppercased() + nombre.dropFirst()
            + " " + acordes.map(\.cifrado).joined(separator: "–") + " (\(lugar) \(acorde + 1) → \(acorde + 2))"
    }

    // MARK: Reconocimiento

    /// El tipo de cadencia que forman dos acordes leídos en la misma tonalidad, si forman alguna.
    /// `final` dice si el segundo es el último de la progresión (solo entonces hay semicadencia).
    package static func tipo(_ a: AcordeAnalizado, _ b: AcordeAnalizado, final: Bool) -> Tipo? {
        if esDominante(a) && esTonica(b) { return .autentica }
        if a.grado == 4, propio(a), a.acorde.tipo.esMayor || a.acorde.tipo.esMenor, esTonica(b) { return .plagal }
        if esDominante(a), a.grado == 5, b.grado == 6, propio(b), b.acorde.tipo.esMayor || b.acorde.tipo.esMenor {
            return .rota
        }
        if final, b.grado == 5, b.categoria == .diatonico, b.acorde.tipo.estructura.calidadDeTriada == .mayor,
           b.acorde.inversion == 0, !(a.grado == 5 && a.categoria == .diatonico) {
            return .semicadencia
        }
        return nil
    }

    /// Las cadencias de una sucesión de acordes leídos en una tonalidad.
    package static func buscar(en acordes: [AcordeAnalizado], tonalidad: Tonalidad, desde inicio: Int = 0,
                               esFinal: Bool = true) -> [Cadencia] {
        guard acordes.count >= 2 else { return [] }
        return (0..<(acordes.count - 1)).compactMap { i in
            let final = esFinal && i + 2 == acordes.count
            guard let tipo = tipo(acordes[i], acordes[i + 1], final: final) else { return nil }
            return Cadencia(tipo: tipo, acorde: inicio + i, tonalidad: tonalidad, acordes: [acordes[i], acordes[i + 1]])
        }
    }

    /// Diatónico o prestado del modo homónimo: sin secundarias ni cromatismos.
    private static func propio(_ a: AcordeAnalizado) -> Bool {
        a.categoria == .diatonico || a.categoria == .prestamo
    }

    /// V o V7 (tríada mayor sobre el 5.º grado), o un acorde de sensible (tríada disminuida sobre el 7.º).
    package static func esDominante(_ a: AcordeAnalizado) -> Bool {
        guard a.categoria == .diatonico else { return false }
        let calidad = a.acorde.tipo.estructura.calidadDeTriada
        return (a.grado == 5 && calidad == .mayor) || (a.grado == 7 && calidad == .disminuida)
    }

    /// I o i (también con tercera de picardía), que no esté en segunda inversión: el I64 cadencial
    /// va a la dominante, no cierra.
    package static func esTonica(_ a: AcordeAnalizado) -> Bool {
        a.grado == 1 && propio(a) && (a.acorde.tipo.esMayor || a.acorde.tipo.esMenor) && a.acorde.inversion != 2
    }
}

extension Cadencia.Tipo: Nombrable, CustomStringConvertible {
    /// "cadencia auténtica", "semicadencia".
    public var nombre: String {
        switch self {
        case .autentica: return "cadencia auténtica"
        case .plagal: return "cadencia plagal"
        case .rota: return "cadencia rota"
        case .semicadencia: return "semicadencia"
        }
    }

    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles else { return nombre }
        switch self {
        case .autentica: return "authentic cadence"
        case .plagal: return "plagal cadence"
        case .rota: return "deceptive cadence"
        case .semicadencia: return "half cadence"
        }
    }

    public var description: String { nombre }
}

extension AnalisisArmonico {
    /// Las cadencias de la progresión en su tonalidad, en orden.
    ///
    ///     Tonalidad(.do).analizar(["Do", "Lam", "Fa", "Sol"]).cadencias.map(\.tipo)   // [.semicadencia]
    public var cadencias: [Cadencia] { Cadencia.buscar(en: acordes, tonalidad: tonalidad) }
}
