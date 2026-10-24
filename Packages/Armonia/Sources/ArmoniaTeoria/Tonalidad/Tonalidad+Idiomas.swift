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
        case .occitano: return self == .mayor ? "major" : "menor"
        case .ruso: return self == .mayor ? "мажор" : "минор"
        case .griego: return self == .mayor ? "μείζονα" : "ελάσσονα"
        }
    }
}

// MARK: - Tonalidad

extension Tonalidad {
    /// "La menor" en español, "A minor" en inglés, "a-Moll" en alemán (con la tónica en minúscula
    /// si es menor), "la mineur" en francés, "la minore" en italiano, "ля минор" en ruso, "λα ελάσσονα"
    /// en griego.
    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.idioma == .aleman else { return "\(tonica.nombre(en: notacion)) \(modo.nombre(en: notacion))" }
        let nombreTonica = tonica.nombre(en: .aleman)
        return (modo == .menor ? nombreTonica.lowercased() : nombreTonica) + "-" + modo.nombre(en: .aleman)
    }
}

extension Tonalidad {
    /// La tonalidad como lugar, en los idiomas de los textos: "en Do mayor", "in C major",
    /// "en do major", "en do maior", "em dó maior", "en do majeur", "in do maggiore" y, en euskera,
    /// con el inesivo: "do maiorrean".
    package func lugar(en notacion: Nomenclatura) -> String {
        let completo = self.nombre(en: notacion)
        switch notacion.idiomaDeLosTextos {
        case .espanol, .catalan, .gallego, .frances: return "en " + completo
        case .portugues: return "em " + completo
        case .ingles, .aleman, .italiano, .occitano, .ruso, .griego: return "in " + completo
        case .euskera: return Tonalidad.declinar(completo, "ean")
        }
    }

    /// En euskera los nombres acaban en "maiorra" o "minorra": el caso sustituye a la "a" del artículo
    /// ("do maiorra" → "do maiorrean", "do maiorretik", "do maiorrera").
    package static func declinar(_ nombre: String, _ sufijo: String) -> String {
        nombre.hasSuffix("a") ? String(nombre.dropLast()) + sufijo : nombre + sufijo
    }
}
