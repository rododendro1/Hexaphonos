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

extension Tonalidad {
    /// La tonalidad como lugar, en los cinco idiomas de los textos: "en Do mayor", "in C major",
    /// "en do major", "en do maior" y, en euskera, con el inesivo: "do maiorrean".
    package func lugar(en notacion: Nomenclatura) -> String {
        let completo = self.nombre(en: notacion)
        switch notacion.idioma {
        case .espanol, .portugues, .catalan, .gallego: return "en " + completo
        case .ingles, .aleman, .frances, .italiano: return "in " + completo
        case .euskera: return Tonalidad.declinar(completo, "ean")
        }
    }

    /// En euskera los nombres acaban en "maiorra" o "minorra": el caso sustituye a la "a" del artículo
    /// ("do maiorra" → "do maiorrean", "do maiorretik", "do maiorrera").
    package static func declinar(_ nombre: String, _ sufijo: String) -> String {
        nombre.hasSuffix("a") ? String(nombre.dropLast()) + sufijo : nombre + sufijo
    }
}
