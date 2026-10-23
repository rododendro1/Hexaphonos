// MARK: - Idiomas
//
// Los nombres que dependen del idioma de los tipos del núcleo: las letras y las alteraciones en
// las nueve lenguas de `Nomenclatura` (español, inglés, alemán, francés, italiano, catalán,
// gallego, euskera y portugués), y el vocabulario en español e inglés de las calidades de
// intervalo, los intervalos y las consonancias.
//
// El de los tipos de las demás capas está junto a cada tipo, en un fichero `X+Idiomas.swift`
// (`Tonalidad+Idiomas`, `EstructuraDeAcorde+Idiomas`, `Escala+Idiomas`, `Pentagrama+Idiomas`,
// `Ritmo+Idiomas` y `CorrespondenciaDeColores+Idiomas`): así el núcleo no depende de ellas.
//
// Para añadir un idioma: un caso en `Idioma` y en `Nomenclatura`, y sus palabras en esos
// ficheros. Los `switch` sobre `idioma` no tienen `default`, así que el compilador señala los que
// faltan; tres `switch` sobre `Nomenclatura` sí lo tienen y se revisan a mano: `Altura(leyendo:en:)`,
// `Nota(leyendo:en:)` y `Nota.nombreCompacto(en:)`. Los nombres que son datos de un catálogo
// (tipos de acorde y de escala, instrumentos) siguen junto a su catálogo.

// MARK: - NotaNatural

extension NotaNatural {
    public var nombre: String { ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"][rawValue] }

    /// Nombre en cada idioma: Do (español), C (inglés), H para el Si en alemán, ré (francés),
    /// re (italiano). En francés e italiano, en minúscula, como se escriben en el texto.
    public func nombre(en notacion: Nomenclatura) -> String {
        switch notacion.idioma {
        case .espanol: return nombre
        case .ingles: return ["C", "D", "E", "F", "G", "A", "B"][rawValue]
        case .aleman: return ["C", "D", "E", "F", "G", "A", "H"][rawValue]
        case .frances: return ["do", "ré", "mi", "fa", "sol", "la", "si"][rawValue]
        case .italiano, .catalan, .gallego, .euskera: return ["do", "re", "mi", "fa", "sol", "la", "si"][rawValue]
        case .portugues: return ["dó", "ré", "mi", "fá", "sol", "lá", "si"][rawValue]
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
    /// `.italiano` → "fa diesis".
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
        case .frances, .italiano, .catalan, .gallego, .euskera, .portugues:
            let base = natural.nombre(en: notacion)
            return alteracion.esNatural ? base : base + " " + alteracion.nombre(en: notacion)
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
    /// las alteraciones con palabras, que usan la sílaba con mayúscula y el símbolo (Fa♯, Ré♭).
    public func nombreCompacto(en notacion: Nomenclatura) -> String {
        switch notacion {
        case .frances, .italiano, .catalan, .gallego, .euskera, .portugues:
            let silaba = natural.nombre(en: notacion)
            return silaba.prefix(1).uppercased() + String(silaba.dropFirst()) + alteracion.simbolo
        default:
            return nombre(en: notacion)
        }
    }
}

// MARK: - CalidadDeIntervalo

extension CalidadDeIntervalo {
    public var nombre: String {
        switch self {
        case .justa: return "justa"
        case .mayor: return "mayor"
        case .menor: return "menor"
        case .aumentada(let n): return CalidadDeIntervalo.multiplicidad(n) + "aumentada"
        case .disminuida(let n): return CalidadDeIntervalo.multiplicidad(n) + "disminuida"
        }
    }

    /// "justa", "mayor"… en español; "perfect", "major", "doubly diminished"… en inglés.
    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles else { return nombre }
        switch self {
        case .justa: return "perfect"
        case .mayor: return "major"
        case .menor: return "minor"
        case .aumentada(let n): return CalidadDeIntervalo.multiplicidadInternacional(n) + "augmented"
        case .disminuida(let n): return CalidadDeIntervalo.multiplicidadInternacional(n) + "diminished"
        }
    }

    private static func multiplicidadInternacional(_ n: Int) -> String {
        switch n {
        case 1: return ""
        case 2: return "doubly "
        case 3: return "triply "
        default: return "\(n)× "
        }
    }

    private static func multiplicidad(_ n: Int) -> String {
        switch n {
        case 1: return ""
        case 2: return "doble "
        case 3: return "triple "
        default: return "\(n) veces "
        }
    }
}

// MARK: - Intervalo

extension Intervalo {
    /// "3ª mayor", "5ª justa descendente".
    public var nombre: String {
        "\(numero)ª \(calidad.nombre)" + (direccion == .descendente ? " descendente" : "")
    }

    /// "3ª mayor" en español; "major third", "descending minor sixth" en inglés.
    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles else { return nombre }
        return (direccion == .descendente ? "descending " : "")
            + "\(calidad.nombre(en: .ingles)) \(Intervalo.ordinalEnIngles(numero))"
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
    public var nombre: String {
        switch self {
        case .perfecta: return "consonancia perfecta"
        case .imperfecta: return "consonancia imperfecta"
        case .disonancia: return "disonancia"
        }
    }

    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles else { return nombre }
        switch self {
        case .perfecta: return "perfect consonance"
        case .imperfecta: return "imperfect consonance"
        case .disonancia: return "dissonance"
        }
    }
}
