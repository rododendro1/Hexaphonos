import ArmoniaNucleo
// Nombres de los papeles en el acorde y de las calidades de tríada en los ocho idiomas de los textos (`Traduccion`). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - PapelEnAcorde

extension PapelEnAcorde {
    public var nombre: String { nombre(en: .espanol) }

    public func nombre(en notacion: Nomenclatura) -> String { traduccion.en(notacion) }

    private var traduccion: Traduccion {
        switch self {
        case .fundamental: return Traduccion("fundamental", "root", ca: "fonamental", gl: "fundamental", eu: "oinarria",
                                             pt: "fundamental", fr: "fondamentale", it: "fondamentale")
        case .tercera: return Traduccion("tercera", "third", ca: "tercera", gl: "terceira", eu: "hirugarrena",
                                         pt: "terça", fr: "tierce", it: "terza")
        case .suspension: return Traduccion("suspensión", "suspension", ca: "suspensió", gl: "suspensión", eu: "esekidura",
                                            pt: "suspensão", fr: "suspension", it: "sospensione")
        case .quinta: return Traduccion("quinta", "fifth", ca: "quinta", gl: "quinta", eu: "bosgarrena",
                                        pt: "quinta", fr: "quinte", it: "quinta")
        case .sexta: return Traduccion("sexta", "sixth", ca: "sexta", gl: "sexta", eu: "seigarrena",
                                       pt: "sexta", fr: "sixte", it: "sesta")
        case .septima: return Traduccion("séptima", "seventh", ca: "sèptima", gl: "sétima", eu: "zazpigarrena",
                                         pt: "sétima", fr: "septième", it: "settima")
        case .tension(9):
            return Traduccion("novena", "ninth", ca: "novena", gl: "novena", eu: "bederatzigarrena",
                              pt: "nona", fr: "neuvième", it: "nona")
        case .tension(11):
            return Traduccion("undécima", "eleventh", ca: "onzena", gl: "undécima", eu: "hamaikagarrena",
                              pt: "décima primeira", fr: "onzième", it: "undicesima")
        case .tension(13):
            return Traduccion("decimotercera", "thirteenth", ca: "tretzena", gl: "décimo terceira", eu: "hamahirugarrena",
                              pt: "décima terceira", fr: "treizième", it: "tredicesima")
        case .tension(let n):
            return Traduccion("tensión \(n)ª", Intervalo.ordinalEnIngles(n), ca: "tensió \(n)a", gl: "tensión \(n)ª",
                              eu: "\(n). tentsioa", pt: "tensão \(n)ª", fr: "tension \(n)e", it: "tensione \(n)ª")
        }
    }
}

// MARK: - CalidadDeTriada

extension CalidadDeTriada {
    public var nombre: String { nombre(en: .espanol) }

    public func nombre(en notacion: Nomenclatura) -> String { traduccion.en(notacion) }

    private var traduccion: Traduccion {
        switch self {
        case .mayor: return Traduccion("mayor", "major", ca: "major", gl: "maior", eu: "handia",
                                       pt: "maior", fr: "majeure", it: "maggiore")
        case .menor: return Traduccion("menor", "minor", ca: "menor", gl: "menor", eu: "txikia",
                                       pt: "menor", fr: "mineure", it: "minore")
        case .disminuida: return Traduccion("disminuida", "diminished", ca: "disminuïda", gl: "diminuída", eu: "gutxitua",
                                            pt: "diminuta", fr: "diminuée", it: "diminuita")
        case .aumentada: return Traduccion("aumentada", "augmented", ca: "augmentada", gl: "aumentada", eu: "gehitua",
                                           pt: "aumentada", fr: "augmentée", it: "aumentata")
        case .suspendida: return Traduccion("suspendida", "suspended", ca: "suspesa", gl: "suspendida", eu: "esekia",
                                            pt: "suspensa", fr: "suspendue", it: "sospesa")
        case .potencia: return Traduccion("de quinta", "power chord", ca: "de quinta", gl: "de quinta", eu: "bosgarrenekoa",
                                          pt: "de quinta", fr: "de quinte", it: "di quinta")
        case .sinTercera:
            return Traduccion("sin tercera", "no third", ca: "sense tercera", gl: "sen terceira", eu: "hirugarrenik gabea",
                              pt: "sem terça", fr: "sans tierce", it: "senza terza")
        }
    }
}
