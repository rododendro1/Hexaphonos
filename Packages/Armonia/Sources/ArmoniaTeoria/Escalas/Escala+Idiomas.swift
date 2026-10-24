import ArmoniaNucleo
// Nombres de los grados de la escala en los cinco idiomas de los textos (`Traduccion`). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - NombreDeGrado

extension NombreDeGrado {
    public var nombre: String { nombre(en: .espanol) }

    public func nombre(en notacion: Nomenclatura) -> String { traduccion.en(notacion) }

    private var traduccion: Traduccion {
        switch self {
        case .tonica: return Traduccion("tónica", "tonic", ca: "tònica", gl: "tónica", eu: "tonika")
        case .supertonica: return Traduccion("supertónica", "supertonic", ca: "supertònica", gl: "supertónica", eu: "supertonika")
        case .mediante: return Traduccion("mediante", "mediant", ca: "mediant", gl: "mediante", eu: "mediantea")
        case .subdominante:
            return Traduccion("subdominante", "subdominant", ca: "subdominant", gl: "subdominante", eu: "subdominantea")
        case .dominante: return Traduccion("dominante", "dominant", ca: "dominant", gl: "dominante", eu: "dominantea")
        case .superdominante:
            return Traduccion("superdominante", "submediant", ca: "superdominant", gl: "superdominante", eu: "superdominantea")
        case .sensible: return Traduccion("sensible", "leading tone", ca: "sensible", gl: "sensible", eu: "sentsiblea")
        case .subtonica: return Traduccion("subtónica", "subtonic", ca: "subtònica", gl: "subtónica", eu: "subtonika")
        }
    }
}
