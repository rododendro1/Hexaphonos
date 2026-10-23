import ArmoniaNucleo
// Nombres de los grados de la escala (español e inglés). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - NombreDeGrado

extension NombreDeGrado {
    public var nombre: String {
        switch self {
        case .tonica: return "tónica"
        case .supertonica: return "supertónica"
        case .mediante: return "mediante"
        case .subdominante: return "subdominante"
        case .dominante: return "dominante"
        case .superdominante: return "superdominante"
        case .sensible: return "sensible"
        case .subtonica: return "subtónica"
        }
    }

    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles else { return nombre }
        switch self {
        case .tonica: return "tonic"
        case .supertonica: return "supertonic"
        case .mediante: return "mediant"
        case .subdominante: return "subdominant"
        case .dominante: return "dominant"
        case .superdominante: return "submediant"
        case .sensible: return "leading tone"
        case .subtonica: return "subtonic"
        }
    }
}
