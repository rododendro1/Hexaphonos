import ArmoniaNucleo
// Nombres de los papeles en el acorde y de las calidades de tríada (español e inglés). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - PapelEnAcorde

extension PapelEnAcorde {
    public var nombre: String {
        switch self {
        case .fundamental: return "fundamental"
        case .tercera: return "tercera"
        case .suspension: return "suspensión"
        case .quinta: return "quinta"
        case .sexta: return "sexta"
        case .septima: return "séptima"
        case .tension(9): return "novena"
        case .tension(11): return "undécima"
        case .tension(13): return "decimotercera"
        case .tension(let n): return "tensión \(n)ª"
        }
    }

    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles else { return nombre }
        switch self {
        case .fundamental: return "root"
        case .tercera: return "third"
        case .suspension: return "suspension"
        case .quinta: return "fifth"
        case .sexta: return "sixth"
        case .septima: return "seventh"
        case .tension(let n): return Intervalo.ordinalEnIngles(n)
        }
    }
}

// MARK: - CalidadDeTriada

extension CalidadDeTriada {
    public var nombre: String {
        switch self {
        case .mayor: return "mayor"
        case .menor: return "menor"
        case .disminuida: return "disminuida"
        case .aumentada: return "aumentada"
        case .suspendida: return "suspendida"
        case .potencia: return "de quinta"
        case .sinTercera: return "sin tercera"
        }
    }

    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles else { return nombre }
        switch self {
        case .mayor: return "major"
        case .menor: return "minor"
        case .disminuida: return "diminished"
        case .aumentada: return "augmented"
        case .suspendida: return "suspended"
        case .potencia: return "power chord"
        case .sinTercera: return "no third"
        }
    }
}
