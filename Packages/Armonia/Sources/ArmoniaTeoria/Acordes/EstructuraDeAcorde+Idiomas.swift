import ArmoniaNucleo
// Nombres de los papeles en el acorde y de las calidades de tríada en los cinco idiomas de los textos (`Traduccion`). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - PapelEnAcorde

extension PapelEnAcorde {
    public var nombre: String { nombre(en: .espanol) }

    public func nombre(en notacion: Nomenclatura) -> String { traduccion.en(notacion) }

    private var traduccion: Traduccion {
        switch self {
        case .fundamental: return Traduccion("fundamental", "root", ca: "fonamental", gl: "fundamental", eu: "oinarria")
        case .tercera: return Traduccion("tercera", "third", ca: "tercera", gl: "terceira", eu: "hirugarrena")
        case .suspension: return Traduccion("suspensión", "suspension", ca: "suspensió", gl: "suspensión", eu: "esekidura")
        case .quinta: return Traduccion("quinta", "fifth", ca: "quinta", gl: "quinta", eu: "bosgarrena")
        case .sexta: return Traduccion("sexta", "sixth", ca: "sexta", gl: "sexta", eu: "seigarrena")
        case .septima: return Traduccion("séptima", "seventh", ca: "sèptima", gl: "sétima", eu: "zazpigarrena")
        case .tension(9):
            return Traduccion("novena", "ninth", ca: "novena", gl: "novena", eu: "bederatzigarrena")
        case .tension(11):
            return Traduccion("undécima", "eleventh", ca: "onzena", gl: "undécima", eu: "hamaikagarrena")
        case .tension(13):
            return Traduccion("decimotercera", "thirteenth", ca: "tretzena", gl: "décimo terceira", eu: "hamahirugarrena")
        case .tension(let n):
            return Traduccion("tensión \(n)ª", Intervalo.ordinalEnIngles(n), ca: "tensió \(n)a", gl: "tensión \(n)ª",
                              eu: "\(n). tentsioa")
        }
    }
}

// MARK: - CalidadDeTriada

extension CalidadDeTriada {
    public var nombre: String { nombre(en: .espanol) }

    public func nombre(en notacion: Nomenclatura) -> String { traduccion.en(notacion) }

    private var traduccion: Traduccion {
        switch self {
        case .mayor: return Traduccion("mayor", "major", ca: "major", gl: "maior", eu: "handia")
        case .menor: return Traduccion("menor", "minor", ca: "menor", gl: "menor", eu: "txikia")
        case .disminuida: return Traduccion("disminuida", "diminished", ca: "disminuïda", gl: "diminuída", eu: "gutxitua")
        case .aumentada: return Traduccion("aumentada", "augmented", ca: "augmentada", gl: "aumentada", eu: "gehitua")
        case .suspendida: return Traduccion("suspendida", "suspended", ca: "suspesa", gl: "suspendida", eu: "esekia")
        case .potencia: return Traduccion("de quinta", "power chord", ca: "de quinta", gl: "de quinta", eu: "bosgarrenekoa")
        case .sinTercera:
            return Traduccion("sin tercera", "no third", ca: "sense tercera", gl: "sen terceira", eu: "hirugarrenik gabea")
        }
    }
}
