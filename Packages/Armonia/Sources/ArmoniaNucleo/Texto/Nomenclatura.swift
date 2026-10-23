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
/// | `.frances` | fa dièse | major third | dominant seventh | fa dièse dorian |
/// | `.italiano` | fa diesis | major third | dominant seventh | fa diesis dorian |
/// | `.catalan` | fa sostingut | 3ª mayor | séptima de dominante | fa sostingut dórico |
/// | `.gallego` | fa sostido | 3ª mayor | séptima de dominante | fa sostido dórico |
/// | `.euskera` | fa diesa | 3ª mayor | séptima de dominante | fa diesa dórico |
/// | `.portugues` | fá sustenido | 3ª mayor | séptima de dominante | fá sustenido dórico |
///
/// En alemán, francés, italiano, catalán, gallego, euskera y portugués están traducidos los nombres
/// de nota, de alteración y los modos de las tonalidades (Fis-Dur, fa dièse majeur, re bemoll major,
/// fá sustenido maior); el resto del vocabulario (intervalos, acordes, escalas) sale en inglés en
/// las tres primeras y en español en las demás, que es lo que da `vocabulario`.
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
        }
    }

    public var idioma: Idioma {
        switch self {
        case .espanol, .espanolASCII: return .espanol
        case .ingles, .inglesUnicode: return .ingles
        case .aleman: return .aleman
        case .frances: return .frances
        case .italiano: return .italiano
        case .catalan: return .catalan
        case .gallego: return .gallego
        case .euskera: return .euskera
        case .portugues: return .portugues
        }
    }

    /// Idioma de los nombres que no son de nota (intervalos, acordes, escalas…): español en
    /// español, catalán, gallego, euskera y portugués; inglés en las demás.
    public var vocabulario: Idioma {
        switch idioma {
        case .espanol, .catalan, .gallego, .euskera, .portugues: return .espanol
        case .ingles, .aleman, .frances, .italiano: return .ingles
        }
    }

    /// Alteraciones como # y b en lugar de ♯ y ♭ (en alemán, francés e italiano las alteraciones
    /// de las notas van en palabras o sufijos; esto afecta a las tensiones de los cifrados).
    public var usaASCII: Bool { self == .espanolASCII || self == .ingles || self == .aleman }
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
