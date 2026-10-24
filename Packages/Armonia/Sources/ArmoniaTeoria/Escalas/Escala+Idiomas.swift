import ArmoniaNucleo
// Nombres de los grados de la escala en los ocho idiomas de los textos (`Traduccion`). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - NombreDeGrado

extension NombreDeGrado {
    public var nombre: String { nombre(en: .espanol) }

    public func nombre(en notacion: Nomenclatura) -> String { traduccion.en(notacion) }

    private var traduccion: Traduccion {
        switch self {
        case .tonica: return Traduccion("tónica", "tonic", ca: "tònica", gl: "tónica", eu: "tonika",
                                        pt: "tônica", fr: "tonique", it: "tonica")
        case .supertonica: return Traduccion("supertónica", "supertonic", ca: "supertònica", gl: "supertónica", eu: "supertonika",
                                             pt: "supertônica", fr: "sus-tonique", it: "sopratonica")
        case .mediante: return Traduccion("mediante", "mediant", ca: "mediant", gl: "mediante", eu: "mediantea",
                                          pt: "mediante", fr: "médiante", it: "mediante")
        case .subdominante:
            return Traduccion("subdominante", "subdominant", ca: "subdominant", gl: "subdominante", eu: "subdominantea",
                              pt: "subdominante", fr: "sous-dominante", it: "sottodominante")
        case .dominante: return Traduccion("dominante", "dominant", ca: "dominant", gl: "dominante", eu: "dominantea",
                                           pt: "dominante", fr: "dominante", it: "dominante")
        case .superdominante:
            return Traduccion("superdominante", "submediant", ca: "superdominant", gl: "superdominante", eu: "superdominantea",
                              pt: "superdominante", fr: "sus-dominante", it: "sopradominante")
        case .sensible: return Traduccion("sensible", "leading tone", ca: "sensible", gl: "sensible", eu: "sentsiblea",
                                          pt: "sensível", fr: "sensible", it: "sensibile")
        case .subtonica: return Traduccion("subtónica", "subtonic", ca: "subtònica", gl: "subtónica", eu: "subtonika",
                                           pt: "subtônica", fr: "sous-tonique", it: "sottotonica")
        }
    }
}
