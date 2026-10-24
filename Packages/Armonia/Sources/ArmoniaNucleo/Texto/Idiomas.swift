// MARK: - Idiomas
//
// Los nombres que dependen del idioma de los tipos del núcleo: las letras y las alteraciones en
// las doce lenguas de `Nomenclatura` (español, inglés, alemán, francés, italiano, catalán,
// gallego, euskera, portugués, occitano, ruso y griego), y los nombres de las calidades de intervalo, los intervalos y
// las consonancias en los ocho idiomas de los textos (`Traduccion`).
//
// El de los tipos de las demás capas está junto a cada tipo, en un fichero `X+Idiomas.swift`
// (`Tonalidad+Idiomas`, `EstructuraDeAcorde+Idiomas`, `Escala+Idiomas`, `Pentagrama+Idiomas`,
// `Ritmo+Idiomas` y `CorrespondenciaDeColores+Idiomas`): así el núcleo no depende de ellas.
//
// Para añadir un idioma: un caso en `Idioma` y en `Nomenclatura`, y sus palabras en esos
// ficheros. Para que el motor escriba también sus textos en él: un campo en `Traduccion`, y su
// caso en `Idioma.deLosTextos` y en los `switch` sobre `notacion.idioma` de los textos. Los `switch` sobre `idioma` no tienen `default`, así que el compilador señala los que
// faltan; tres `switch` sobre `Nomenclatura` sí lo tienen y se revisan a mano: `Altura(leyendo:en:)`,
// `Nota(leyendo:en:)` y `Nota.nombreCompacto(en:)`. Los nombres que son datos de un catálogo
// (tipos de acorde y de escala, instrumentos) siguen junto a su catálogo.

// MARK: - NotaNatural

extension NotaNatural {
    public var nombre: String { ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"][rawValue] }

    /// Nombre en cada idioma: Do (español), C (inglés), H para el Si en alemán, ré (francés),
    /// re (italiano), sòl (occitano), соль (ruso), σολ (griego). En las lenguas que usan sílabas,
    /// salvo el español, en minúscula, como se escriben en el texto.
    public func nombre(en notacion: Nomenclatura) -> String {
        switch notacion.idioma {
        case .espanol: return nombre
        case .ingles: return ["C", "D", "E", "F", "G", "A", "B"][rawValue]
        case .aleman: return ["C", "D", "E", "F", "G", "A", "H"][rawValue]
        case .frances: return ["do", "ré", "mi", "fa", "sol", "la", "si"][rawValue]
        case .italiano, .catalan, .gallego, .euskera: return ["do", "re", "mi", "fa", "sol", "la", "si"][rawValue]
        case .portugues: return ["dó", "ré", "mi", "fá", "sol", "lá", "si"][rawValue]
        case .occitano: return ["do", "re", "mi", "fa", "sòl", "la", "si"][rawValue]
        case .ruso: return ["до", "ре", "ми", "фа", "соль", "ля", "си"][rawValue]
        case .griego: return ["ντο", "ρε", "μι", "φα", "σολ", "λα", "σι"][rawValue]
        }
    }
}

// MARK: - Alteracion

extension Alteracion {
    /// "natural", "sostenido", "doble bemol", "triple sostenido", "5 bemoles"…
    public var nombre: String {
        if semitonos == 0 { return "natural" }
        let base = esSostenido ? "sostenido" : "bemol"
        switch cantidad {
        case 1: return base
        case 2: return "doble " + base
        case 3: return "triple " + base
        case 4: return "cuádruple " + base
        default: return "\(cantidad) " + (esSostenido ? "sostenidos" : "bemoles")
        }
    }

    /// Nombre en cada idioma: "double sharp", "Doppelkreuz", "double dièse", "doppio diesis"…
    public func nombre(en notacion: Nomenclatura) -> String {
        // (natural, sostenido, bemol, prefijos de 2, 3 y 4, plural de sostenido y de bemol)
        let palabras: (String, String, String, [String], String, String)
        switch notacion.idioma {
        case .espanol: return nombre
        case .ingles: palabras = ("natural", "sharp", "flat", ["double ", "triple ", "quadruple "], "sharps", "flats")
        case .aleman:
            // En alemán las palabras se unen: Kreuz, Doppelkreuz, Be, Doppel-Be.
            if semitonos == 0 { return "Auflösungszeichen" }
            let base = esSostenido ? "kreuz" : "-Be"
            switch cantidad {
            case 1: return esSostenido ? "Kreuz" : "Be"
            case 2: return "Doppel" + base
            case 3: return "Dreifach" + base
            default: return "\(cantidad)" + (esSostenido ? " Kreuze" : " Be")
            }
        case .frances: palabras = ("bécarre", "dièse", "bémol", ["double ", "triple ", "quadruple "], "dièses", "bémols")
        case .italiano: palabras = ("bequadro", "diesis", "bemolle", ["doppio ", "triplo ", "quadruplo "], "diesis", "bemolli")
        case .catalan: palabras = ("becaire", "sostingut", "bemoll", ["doble ", "triple ", "quàdruple "], "sostinguts", "bemolls")
        case .gallego: palabras = ("becadro", "sostido", "bemol", ["dobre ", "triplo ", "cuádruplo "], "sostidos", "bemois")
        case .portugues: palabras = ("bequadro", "sustenido", "bemol", ["duplo ", "triplo ", "quádruplo "], "sustenidos", "bemóis")
        case .occitano: palabras = ("becarre", "dièsi", "bemòl", ["doble ", "triple ", "quadruple "], "dièsis", "bemòls")
        case .ruso: palabras = ("бекар", "диез", "бемоль", ["дубль-", "тройной ", "четверной "], "диезов", "бемолей")
        case .griego: palabras = ("αναίρεση", "δίεση", "ύφεση", ["διπλή ", "τριπλή ", "τετραπλή "], "διέσεις", "υφέσεις")
        case .euskera:
            // En euskera el adjetivo va detrás: diesa bikoitza, bemol hirukoitza.
            if semitonos == 0 { return "bekadro" }
            let base = esSostenido ? "diesa" : "bemol"
            switch cantidad {
            case 1: return base
            case 2: return base + " bikoitza"
            case 3: return base + " hirukoitza"
            case 4: return base + " laukoitza"
            default: return "\(cantidad) \(base)"
            }
        }
        if semitonos == 0 { return palabras.0 }
        let base = esSostenido ? palabras.1 : palabras.2
        if cantidad == 1 { return base }
        if cantidad <= 4 { return palabras.3[cantidad - 2] + base }
        return "\(cantidad) " + (esSostenido ? palabras.4 : palabras.5)
    }
}

// MARK: - Nota

extension Nota {
    /// Nombre con símbolos tipográficos: "Fa♯", "Si♭".
    public var nombre: String { natural.nombre + alteracion.simbolo }

    /// Nombre en ASCII: "Fa#", "Sib".
    public var nombreASCII: String { natural.nombre + alteracion.simboloASCII }

    /// Nombre en la notación indicada: `.espanol` → "Fa♯", `.espanolASCII` → "Fa#",
    /// `.ingles` → "F#", `.inglesUnicode` → "F♯", `.aleman` → "Fis", `.frances` → "fa dièse",
    /// `.italiano` → "fa diesis", `.ruso` → "фа-диез", `.griego` → "φα δίεση".
    public func nombre(en notacion: Nomenclatura) -> String {
        switch notacion {
        case .espanol: return nombre
        case .espanolASCII: return nombreASCII
        case .ingles:
            return natural.nombre(en: .ingles) + alteracion.simboloASCII
        case .inglesUnicode:
            return natural.nombre(en: .ingles) + alteracion.simbolo
        case .aleman:
            return nombreAleman
        case .frances, .italiano, .catalan, .gallego, .euskera, .portugues, .occitano, .griego:
            let base = natural.nombre(en: notacion)
            return alteracion.esNatural ? base : base + " " + alteracion.nombre(en: notacion)
        case .ruso:
            // En ruso la alteración se une con guiones: фа-диез, си-дубль-бемоль.
            let base = natural.nombre(en: notacion)
            let alteracion = self.alteracion.nombre(en: notacion).replacingOccurrences(of: " ", with: "-")
            return self.alteracion.esNatural ? base : base + "-" + alteracion
        }
    }

    /// Nombre alemán: sostenidos con -is (Fis, Cisis), bemoles con -es (Des, Ges), con Es y As
    /// para Mi♭ y La♭ (Eses, Asas), B para Si♭ y H para Si (His, Heses).
    package var nombreAleman: String {
        let n = alteracion.cantidad
        if alteracion.esNatural { return natural.nombre(en: .aleman) }
        if alteracion.esSostenido { return natural.nombre(en: .aleman) + String(repeating: "is", count: n) }
        switch natural {
        case .si: return n == 1 ? "B" : "H" + String(repeating: "es", count: n)
        case .mi: return "Es" + String(repeating: "es", count: n - 1)
        case .la: return "As" + String(repeating: "as", count: n - 1)
        default: return natural.nombre(en: .aleman) + String(repeating: "es", count: n)
        }
    }

    /// Nombre compacto para cifrados: igual que `nombre(en:)` salvo en las notaciones que escriben
    /// las alteraciones con palabras, que usan la sílaba con mayúscula y el símbolo (Fa♯, Ré♭, Фа♯, Φα♯).
    public func nombreCompacto(en notacion: Nomenclatura) -> String {
        switch notacion {
        case .frances, .italiano, .catalan, .gallego, .euskera, .portugues, .occitano, .ruso, .griego:
            let silaba = natural.nombre(en: notacion)
            return silaba.prefix(1).uppercased() + String(silaba.dropFirst()) + alteracion.simbolo
        default:
            return nombre(en: notacion)
        }
    }
}

// MARK: - CalidadDeIntervalo

extension CalidadDeIntervalo {
    public var nombre: String { nombre(en: .espanol) }

    /// "justa", "mayor"… en español; "perfect", "major", "doubly diminished"… en inglés; "justa",
    /// "major" en catalán; "xusta", "maior" en gallego; "justua", "handia", "bi aldiz gehitua" en
    /// euskera; "justa", "diminuta" en portugués; "juste", "majeure" en francés; "giusta",
    /// "maggiore" en italiano.
    public func nombre(en notacion: Nomenclatura) -> String {
        switch self {
        case .justa: return Traduccion("justa", "perfect", ca: "justa", gl: "xusta", eu: "justua",
                                       pt: "justa", fr: "juste", it: "giusta").en(notacion)
        case .mayor: return Traduccion("mayor", "major", ca: "major", gl: "maior", eu: "handia",
                                       pt: "maior", fr: "majeure", it: "maggiore").en(notacion)
        case .menor: return Traduccion("menor", "minor", ca: "menor", gl: "menor", eu: "txikia",
                                       pt: "menor", fr: "mineure", it: "minore").en(notacion)
        case .aumentada(let n):
            return CalidadDeIntervalo.multiplicidad(n).en(notacion)
                + Traduccion("aumentada", "augmented", ca: "augmentada", gl: "aumentada", eu: "gehitua",
                             pt: "aumentada", fr: "augmentée", it: "aumentata").en(notacion)
        case .disminuida(let n):
            return CalidadDeIntervalo.multiplicidad(n).en(notacion)
                + Traduccion("disminuida", "diminished", ca: "disminuïda", gl: "diminuída", eu: "gutxitua",
                             pt: "diminuta", fr: "diminuée", it: "diminuita").en(notacion)
        }
    }

    private static func multiplicidad(_ n: Int) -> Traduccion {
        switch n {
        case 1: return Traduccion("", "", ca: "", gl: "", eu: "", pt: "", fr: "", it: "")
        case 2: return Traduccion("doble ", "doubly ", ca: "doble ", gl: "dobre ", eu: "bi aldiz ",
                                  pt: "duplamente ", fr: "doublement ", it: "doppiamente ")
        case 3: return Traduccion("triple ", "triply ", ca: "triple ", gl: "triple ", eu: "hiru aldiz ",
                                  pt: "triplamente ", fr: "triplement ", it: "triplamente ")
        default: return Traduccion("\(n) veces ", "\(n)× ", ca: "\(n) vegades ", gl: "\(n) veces ", eu: "\(n) aldiz ",
                                   pt: "\(n) vezes ", fr: "\(n) fois ", it: "\(n) volte ")
        }
    }
}

// MARK: - Intervalo

extension Intervalo {
    /// "3ª mayor", "5ª justa descendente".
    public var nombre: String { nombre(en: .espanol) }

    /// "3ª mayor" en español; "major third", "descending minor sixth" en inglés; "3a major" en
    /// catalán; "3ª maior" en gallego y en portugués; "3. handia", "beheranzko 6. txikia" en
    /// euskera; "tierce majeure" en francés; "terza maggiore" en italiano.
    public func nombre(en notacion: Nomenclatura) -> String {
        let calidad = self.calidad.nombre(en: notacion)
        let descendente = direccion == .descendente
        switch notacion.idioma {
        case .espanol, .portugues:
            return "\(numero)ª \(calidad)" + (descendente ? " descendente" : "")
        case .ingles, .aleman, .occitano, .ruso, .griego:
            return (descendente ? "descending " : "") + "\(calidad) \(Intervalo.ordinalEnIngles(numero))"
        case .frances:
            // El unísono es masculino: "unisson augmenté".
            let nombre = Intervalo.ordinalEnFrances(numero)
            let concordada = numero == 1 && calidad.hasSuffix("ée") ? String(calidad.dropLast()) : calidad
            return "\(nombre) \(concordada)" + (descendente ? " descendante" : "")
        case .italiano:
            // El unísono es masculino: "unisono aumentato".
            let nombre = Intervalo.ordinalEnItaliano(numero)
            let concordada = numero == 1 && calidad.hasSuffix("a") ? String(calidad.dropLast()) + "o" : calidad
            return "\(nombre) \(concordada)" + (descendente ? " discendente" : "")
        case .catalan:
            return "\(numero)a \(calidad)" + (descendente ? " descendent" : "")
        case .gallego:
            return "\(numero)ª \(calidad)" + (descendente ? " descendente" : "")
        case .euskera:
            return (descendente ? "beheranzko " : "") + "\(numero). \(calidad)"
        }
    }

    /// "unisson", "seconde", "tierce"… "octave", "neuvième", "16e".
    package static func ordinalEnFrances(_ n: Int) -> String {
        let nombres = [1: "unisson", 2: "seconde", 3: "tierce", 4: "quarte", 5: "quinte", 6: "sixte",
                       7: "septième", 8: "octave", 9: "neuvième", 10: "dixième", 11: "onzième",
                       12: "douzième", 13: "treizième", 14: "quatorzième", 15: "double octave"]
        return nombres[n] ?? "\(n)e"
    }

    /// "unisono", "seconda", "terza"… "ottava", "nona", "16ª".
    package static func ordinalEnItaliano(_ n: Int) -> String {
        let nombres = [1: "unisono", 2: "seconda", 3: "terza", 4: "quarta", 5: "quinta", 6: "sesta",
                       7: "settima", 8: "ottava", 9: "nona", 10: "decima", 11: "undicesima",
                       12: "dodicesima", 13: "tredicesima", 14: "quattordicesima", 15: "doppia ottava"]
        return nombres[n] ?? "\(n)ª"
    }

    package static func ordinalEnIngles(_ n: Int) -> String {
        let nombres = [1: "unison", 2: "second", 3: "third", 4: "fourth", 5: "fifth", 6: "sixth",
                       7: "seventh", 8: "octave", 9: "ninth", 10: "tenth", 11: "eleventh",
                       12: "twelfth", 13: "thirteenth", 14: "fourteenth", 15: "double octave"]
        if let nombre = nombres[n] { return nombre }
        let sufijo: String
        switch (n % 100, n % 10) {
        case (11...13, _): sufijo = "th"
        case (_, 1): sufijo = "st"
        case (_, 2): sufijo = "nd"
        case (_, 3): sufijo = "rd"
        default: sufijo = "th"
        }
        return "\(n)\(sufijo)"
    }
}

// MARK: - Consonancia

extension Consonancia {
    public var nombre: String { nombre(en: .espanol) }

    public func nombre(en notacion: Nomenclatura) -> String {
        switch self {
        case .perfecta:
            return Traduccion("consonancia perfecta", "perfect consonance", ca: "consonància perfecta",
                              gl: "consonancia perfecta", eu: "kontsonantzia perfektua",
                              pt: "consonância perfeita", fr: "consonance parfaite", it: "consonanza perfetta").en(notacion)
        case .imperfecta:
            return Traduccion("consonancia imperfecta", "imperfect consonance", ca: "consonància imperfecta",
                              gl: "consonancia imperfecta", eu: "kontsonantzia inperfektua",
                              pt: "consonância imperfeita", fr: "consonance imparfaite", it: "consonanza imperfetta").en(notacion)
        case .disonancia:
            return Traduccion("disonancia", "dissonance", ca: "dissonància", gl: "disonancia",
                              eu: "disonantzia", pt: "dissonância", fr: "dissonance", it: "dissonanza").en(notacion)
        }
    }
}
