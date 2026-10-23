import ArmoniaNucleo
// Nombres de los modos y de las tonalidades en cada idioma. El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - Tonalidad.Modo

extension Tonalidad.Modo {
    public var nombre: String { self == .mayor ? "mayor" : "menor" }

    public func nombre(en notacion: Nomenclatura) -> String {
        switch notacion.idioma {
        case .espanol: return nombre
        case .ingles: return self == .mayor ? "major" : "minor"
        case .aleman: return self == .mayor ? "Dur" : "Moll"
        case .frances: return self == .mayor ? "majeur" : "mineur"
        case .italiano: return self == .mayor ? "maggiore" : "minore"
        case .catalan: return self == .mayor ? "major" : "menor"
        case .gallego: return self == .mayor ? "maior" : "menor"
        case .euskera: return self == .mayor ? "maiorra" : "minorra"
        case .portugues: return self == .mayor ? "maior" : "menor"
        }
    }
}

// MARK: - Tonalidad

extension Tonalidad {
    /// "La menor" en español, "A minor" en inglés, "a-Moll" en alemán (con la tónica en minúscula
    /// si es menor), "la mineur" en francés, "la minore" en italiano.
    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion == .aleman else { return "\(tonica.nombre(en: notacion)) \(modo.nombre(en: notacion))" }
        let nombreTonica = tonica.nombre(en: .aleman)
        return (modo == .menor ? nombreTonica.lowercased() : nombreTonica) + "-" + modo.nombre(en: .aleman)
    }
}
