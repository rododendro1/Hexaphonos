// MARK: - Notación

/// Cómo se escribe todo lo que el motor convierte en texto: el idioma (nombres de nota,
/// de intervalos, de acordes, de escalas…) y si las alteraciones usan ♯/♭ o #/b.
///
/// | Notación | Nota | Intervalo | Acorde | Escala |
/// |---|---|---|---|---|
/// | `.espanol` | Fa♯ | 3ª mayor | séptima de dominante | Re dórico |
/// | `.espanolASCII` | Fa# | 3ª mayor | séptima de dominante | Re dórico |
/// | `.ingles` | F# | major third | dominant seventh | D dorian |
/// | `.inglesUnicode` | F♯ | major third | dominant seventh | D dorian |
/// | `.aleman` | Fis | major third | dominant seventh | Fis dorian |
/// | `.frances` | fa dièse | tierce majeure | septième de dominante | fa dièse dorien |
/// | `.italiano` | fa diesis | terza maggiore | settima di dominante | fa diesis dorico |
/// | `.catalan` | fa sostingut | 3a major | sèptima de dominant | fa sostingut dòric |
/// | `.gallego` | fa sostido | 3ª maior | sétima de dominante | fa sostido dórico |
/// | `.euskera` | fa diesa | 3. handia | dominanteko zazpigarrena | fa diesa doriarra |
/// | `.portugues` | fá sustenido | 3ª maior | sétima de dominante | fá sustenido dórico |
/// | `.occitano` | fa dièsi | major third | dominant seventh | fa dièsi dorian |
/// | `.ruso` | фа-диез | major third | dominant seventh | фа-диез dorian |
/// | `.griego` | φα δίεση | major third | dominant seventh | φα δίεση dorian |
///
/// En alemán, francés, italiano, catalán, gallego, euskera y portugués están traducidos los nombres
/// de nota, de alteración y los modos de las tonalidades (Fis-Dur, fa dièse majeur, re bemoll major,
/// fá sustenido maior), y también en occitano, ruso y griego (fa dièsi major, фа-диез мажор,
/// φα δίεση μείζονα). Los textos del motor (mensajes de error, intervalos, cadencias…) y los
/// nombres de los catálogos (acordes, escalas, instrumentos) están además en todos esos idiomas
/// salvo el alemán, el occitano, el ruso y el griego, en los que salen en inglés (`idiomaDeLosTextos`).
///
/// Las notas y los textos pueden ir en idiomas distintos con `conTextos(en:)`:
/// `Nomenclatura.ruso.conTextos(en: .espanol)` escribe «соль séptima de dominante, primera inversión».
public enum Nomenclatura: Hashable, Sendable, CaseIterable {
    /// Español con símbolos tipográficos: Do, Fa♯, Si♭.
    case espanol
    /// Español con caracteres ASCII: Do, Fa#, Sib.
    case espanolASCII
    /// Inglés con caracteres ASCII: C, F#, Bb (la forma habitual de escribir en inglés).
    case ingles
    /// Inglés con símbolos tipográficos: C, F♯, B♭.
    case inglesUnicode
    /// Alemán: C, Fis, Es, B (= Si♭), H (= Si), Heses; los cifrados quedan Fis7, B7, Hm7.
    case aleman
    /// Francés: do, ré, fa dièse, si bémol; en los cifrados, Fa♯7, Si♭m.
    case frances
    /// Italiano: do, re, fa diesis, si bemolle; en los cifrados, Fa♯7, Si♭m.
    case italiano
    /// Catalán: do, re, fa sostingut, si bemoll; en los cifrados, Fa♯7, Si♭m.
    case catalan
    /// Gallego: do, re, fa sostido, si bemol; en los cifrados, Fa♯7, Si♭m.
    case gallego
    /// Euskera: do, re, fa diesa, si bemol; en los cifrados, Fa♯7, Si♭m.
    case euskera
    /// Portugués: dó, ré, fá sustenido, si bemol; en los cifrados, Fá♯7, Si♭m.
    case portugues
    /// Occitano: do, re, fa dièsi, si bemòl; en los cifrados, Fa♯7, Si♭m.
    case occitano
    /// Ruso: до, ре, фа-диез, си-бемоль; en los cifrados, Фа♯7, Си♭m.
    case ruso
    /// Griego: ντο, ρε, φα δίεση, σι ύφεση; en los cifrados, Φα♯7, Σι♭m.
    case griego
    /// Las notas de una notación con los textos (intervalos, acordes, mensajes…) en otro idioma.
    /// Se crea con `conTextos(en:)`, que nunca anida una combinación dentro de otra.
    indirect case combinada(notas: Nomenclatura, textos: Idioma)

    /// Las notaciones simples, sin combinar.
    public static let allCases: [Nomenclatura] = [.espanol, .espanolASCII, .ingles, .inglesUnicode, .aleman,
                                                  .frances, .italiano, .catalan, .gallego, .euskera,
                                                  .portugues, .occitano, .ruso, .griego]

    /// La misma notación de las notas con los textos en otro idioma: `Nomenclatura.ruso.conTextos(en:
    /// .espanol)`. Un idioma sin textos propios (el alemán…) cuenta como el inglés. Si el idioma ya es el de
    /// los textos de la notación, devuelve la notación simple.
    public func conTextos(en idioma: Idioma) -> Nomenclatura {
        let notas = self.notas, textos = idioma.deLosTextos
        return notas.idiomaDeLosTextos == textos ? notas : .combinada(notas: notas, textos: textos)
    }

    /// La notación de las notas, sin el idioma de los textos (la propia si no es combinada).
    public var notas: Nomenclatura {
        if case .combinada(let notas, _) = self { return notas.notas }
        return self
    }

    public init(idioma: Idioma, ascii: Bool) {
        switch (idioma, ascii) {
        case (.espanol, false): self = .espanol
        case (.espanol, true): self = .espanolASCII
        case (.ingles, true): self = .ingles
        case (.ingles, false): self = .inglesUnicode
        case (.aleman, _): self = .aleman
        case (.frances, _): self = .frances
        case (.italiano, _): self = .italiano
        case (.catalan, _): self = .catalan
        case (.gallego, _): self = .gallego
        case (.euskera, _): self = .euskera
        case (.portugues, _): self = .portugues
        case (.occitano, _): self = .occitano
        case (.ruso, _): self = .ruso
        case (.griego, _): self = .griego
        }
    }

    /// El idioma de los nombres de nota (en una combinada, el de sus notas).
    public var idioma: Idioma {
        switch self {
        case .combinada(let notas, _): return notas.idioma
        case .espanol, .espanolASCII: return .espanol
        case .ingles, .inglesUnicode: return .ingles
        case .aleman: return .aleman
        case .frances: return .frances
        case .italiano: return .italiano
        case .catalan: return .catalan
        case .gallego: return .gallego
        case .euskera: return .euskera
        case .portugues: return .portugues
        case .occitano: return .occitano
        case .ruso: return .ruso
        case .griego: return .griego
        }
    }

    /// Idioma de las abreviaturas de los intervalos (5J, P5), que solo están en español e inglés:
    /// español en español, catalán, gallego, euskera, portugués y occitano; inglés en las demás. Los demás
    /// textos siguen `idiomaDeLosTextos`.
    public var vocabulario: Idioma {
        let idioma: Idioma
        if case .combinada(_, let textos) = self { idioma = textos } else { idioma = self.idioma }
        switch idioma {
        case .espanol, .catalan, .gallego, .euskera, .portugues, .occitano: return .espanol
        case .ingles, .aleman, .frances, .italiano, .ruso, .griego: return .ingles
        }
    }

    /// Alteraciones como # y b en lugar de ♯ y ♭ (en alemán, francés e italiano las alteraciones
    /// de las notas van en palabras o sufijos; esto afecta a las tensiones de los cifrados).
    public var usaASCII: Bool { [.espanolASCII, .ingles, .aleman].contains(notas) }
}

// MARK: - Idioma

/// Idioma de una `Nomenclatura` (la notación añade si las alteraciones son ♯/♭ o #/b).
public enum Idioma: Hashable, Sendable, CaseIterable {
    case espanol
    case ingles
    case aleman
    case frances
    case italiano
    case catalan
    case gallego
    case euskera
    case portugues
    case occitano
    case ruso
    case griego
}

// MARK: - Estilo de cifrado

/// Cómo se escribe un cifrado. Todos los estilos se vuelven a leer igual con
/// `Acorde(leyendo:)`, así que el estilo sólo cambia la presentación.
///
///     let a: Acorde = "Sib7(b9)"
///     a.cifrado                           // "Si♭7(♭9)"
///     a.cifrado(estilo: .ingles)   // "Bb7(b9)"
///     Acorde("Sim7b5").cifrado(estilo: .jazz)   // "Bø7"
public struct EstiloDeCifrado: Hashable, Sendable {
    public enum Menor: String, Hashable, Sendable { case m = "m", min = "min" }
    public enum Disminuido: String, Hashable, Sendable { case circulo = "°", dim = "dim" }
    public enum Aumentado: String, Hashable, Sendable { case mas = "+", aug = "aug" }
    public enum SeptimaMayor: String, Hashable, Sendable { case maj = "maj", mayuscula = "M", delta = "Δ" }
    public enum Semidisminuido: Hashable, Sendable {
        /// m7(♭5)
        case menorSeptimaQuintaBemol
        /// ø7
        case barrado
    }

    public var nomenclatura: Nomenclatura
    /// Escribe ♭ y ♯ como b y # en las tensiones.
    public var alteracionesASCII: Bool
    public var menor: Menor
    public var disminuido: Disminuido
    public var aumentado: Aumentado
    public var septimaMayor: SeptimaMayor
    public var semidisminuido: Semidisminuido

    public init(nomenclatura: Nomenclatura = .espanol,
                alteracionesASCII: Bool = false,
                menor: Menor = .m,
                disminuido: Disminuido = .circulo,
                aumentado: Aumentado = .mas,
                septimaMayor: SeptimaMayor = .maj,
                semidisminuido: Semidisminuido = .menorSeptimaQuintaBemol) {
        self.nomenclatura = nomenclatura
        self.alteracionesASCII = alteracionesASCII
        self.menor = menor
        self.disminuido = disminuido
        self.aumentado = aumentado
        self.septimaMayor = septimaMayor
        self.semidisminuido = semidisminuido
    }

    /// El estilo básico de cada notación: `.espanol` → `.predeterminado`, `.espanolASCII` → `.ascii`,
    /// `.ingles` → `.ingles`, `.inglesUnicode` → `.inglesUnicode`.
    public init(notacion: Nomenclatura) {
        switch notacion {
        case .combinada(let notas, _):
            self.init(notacion: notas)
            nomenclatura = notacion
        case .espanol: self.init()
        case .espanolASCII: self.init(nomenclatura: .espanolASCII, alteracionesASCII: true)
        case .ingles: self.init(nomenclatura: .ingles, alteracionesASCII: true)
        case .inglesUnicode: self.init(nomenclatura: .inglesUnicode)
        case .aleman: self.init(nomenclatura: .aleman, alteracionesASCII: true)
        case .frances: self.init(nomenclatura: .frances)
        case .italiano: self.init(nomenclatura: .italiano)
        case .catalan: self.init(nomenclatura: .catalan)
        case .gallego: self.init(nomenclatura: .gallego)
        case .euskera: self.init(nomenclatura: .euskera)
        case .portugues: self.init(nomenclatura: .portugues)
        case .occitano: self.init(nomenclatura: .occitano)
        case .ruso: self.init(nomenclatura: .ruso)
        case .griego: self.init(nomenclatura: .griego)
        }
    }

    /// Do♯m7(♭5), Mi♭maj7.
    public static let predeterminado = EstiloDeCifrado()
    /// Sólo caracteres ASCII: Do#m7(b5), Mibmaj7.
    public static let ascii = EstiloDeCifrado(nomenclatura: .espanolASCII, alteracionesASCII: true)
    /// Letras internacionales: C#m7(b5), Ebmaj7.
    public static let ingles = EstiloDeCifrado(nomenclatura: .ingles, alteracionesASCII: true)
    /// Letras internacionales con símbolos tipográficos: C♯m7(♭5), E♭maj7.
    public static let inglesUnicode = EstiloDeCifrado(nomenclatura: .inglesUnicode)
    /// Notación habitual en jazz: C#ø7, EbΔ7.
    public static let jazz = EstiloDeCifrado(nomenclatura: .ingles, alteracionesASCII: true,
                                           septimaMayor: .delta, semidisminuido: .barrado)
    /// Calidades escritas con palabras: Domin7, Fadim, Solaug.
    public static let palabras = EstiloDeCifrado(menor: .min, disminuido: .dim, aumentado: .aug)

    package func nombre(_ nota: Nota) -> String { nota.nombreCompacto(en: nomenclatura) }
}
