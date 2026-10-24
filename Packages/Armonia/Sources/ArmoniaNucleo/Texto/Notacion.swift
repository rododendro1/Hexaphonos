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
/// salvo el alemán, el occitano, el ruso y el griego, en los que salen en inglés (`textos`).
///
/// Una notación son dos elecciones: cómo se escriben las notas (`escritura`) y en qué idioma salen los
/// textos (`textos`). Las notaciones con nombre (`.espanol`, `.ruso`…) llevan los textos en el idioma de sus
/// notas, y `conTextos(en:)` los cambia: `Notacion.ruso.conTextos(en: .espanol)` escribe
/// «соль séptima de dominante, primera inversión».
public struct Notacion: Hashable, Sendable, CaseIterable {
    /// Cómo se escriben los nombres de nota.
    public let escritura: EscrituraDeNotas
    /// El idioma de los textos (intervalos, acordes, mensajes…). Siempre uno con textos propios: el alemán,
    /// el occitano, el ruso y el griego se guardan como el inglés.
    public let textos: Idioma

    /// Las notas escritas como `escritura`, con los textos en `textos` o, si no se da, en el idioma de las
    /// notas.
    public init(escritura: EscrituraDeNotas, textos: Idioma? = nil) {
        self.escritura = escritura
        self.textos = (textos ?? escritura.idioma).deLosTextos
    }

    /// Español con símbolos tipográficos: Do, Fa♯, Si♭.
    public static let espanol = Notacion(escritura: .espanol)
    /// Español con caracteres ASCII: Do, Fa#, Sib.
    public static let espanolASCII = Notacion(escritura: .espanolASCII)
    /// Inglés con caracteres ASCII: C, F#, Bb (la forma habitual de escribir en inglés).
    public static let ingles = Notacion(escritura: .ingles)
    /// Inglés con símbolos tipográficos: C, F♯, B♭.
    public static let inglesUnicode = Notacion(escritura: .inglesUnicode)
    /// Alemán: C, Fis, Es, B (= Si♭), H (= Si), Heses; los cifrados quedan Fis7, B7, Hm7.
    public static let aleman = Notacion(escritura: .aleman)
    /// Francés: do, ré, fa dièse, si bémol; en los cifrados, Fa♯7, Si♭m.
    public static let frances = Notacion(escritura: .frances)
    /// Italiano: do, re, fa diesis, si bemolle; en los cifrados, Fa♯7, Si♭m.
    public static let italiano = Notacion(escritura: .italiano)
    /// Catalán: do, re, fa sostingut, si bemoll; en los cifrados, Fa♯7, Si♭m.
    public static let catalan = Notacion(escritura: .catalan)
    /// Gallego: do, re, fa sostido, si bemol; en los cifrados, Fa♯7, Si♭m.
    public static let gallego = Notacion(escritura: .gallego)
    /// Euskera: do, re, fa diesa, si bemol; en los cifrados, Fa♯7, Si♭m.
    public static let euskera = Notacion(escritura: .euskera)
    /// Portugués: dó, ré, fá sustenido, si bemol; en los cifrados, Fá♯7, Si♭m.
    public static let portugues = Notacion(escritura: .portugues)
    /// Occitano: do, re, fa dièsi, si bemòl; en los cifrados, Fa♯7, Si♭m.
    public static let occitano = Notacion(escritura: .occitano)
    /// Ruso: до, ре, фа-диез, си-бемоль; en los cifrados, Фа♯7, Си♭m.
    public static let ruso = Notacion(escritura: .ruso)
    /// Griego: ντο, ρε, φα δίεση, σι ύφεση; en los cifrados, Φα♯7, Σι♭m.
    public static let griego = Notacion(escritura: .griego)

    /// Las notaciones con nombre, una por escritura, con los textos en el idioma de sus notas.
    public static let allCases: [Notacion] = EscrituraDeNotas.allCases.map { Notacion(escritura: $0) }

    /// La misma notación de las notas con los textos en otro idioma: `Notacion.ruso.conTextos(en:
    /// .espanol)`. Un idioma sin textos propios (el alemán…) cuenta como el inglés.
    public func conTextos(en idioma: Idioma) -> Notacion {
        Notacion(escritura: escritura, textos: idioma)
    }

    /// La notación de las notas con los textos en su propio idioma: `.ruso.conTextos(en: .espanol).notas`
    /// es `.ruso`.
    public var notas: Notacion { Notacion(escritura: escritura) }

    /// ¿Lleva los textos en un idioma distinto del de sus notas?
    public var esCombinada: Bool { textos != escritura.idioma.deLosTextos }

    /// El idioma de los nombres de nota.
    public var idiomaDeLasNotas: Idioma { escritura.idioma }

    /// Idioma de las abreviaturas de los intervalos (5J, P5), que solo están en español e inglés:
    /// español en español, catalán, gallego, euskera, portugués y occitano; inglés en las demás. Los demás
    /// textos siguen `textos`.
    public var idiomaDeLasAbreviaturas: Idioma {
        // Con los textos en otro idioma manda ese; si no, el de las notas (el occitano usa las españolas).
        switch esCombinada ? textos : idiomaDeLasNotas {
        case .espanol, .catalan, .gallego, .euskera, .portugues, .occitano: return .espanol
        case .ingles, .aleman, .frances, .italiano, .ruso, .griego: return .ingles
        }
    }

    /// Alteraciones como # y b en lugar de ♯ y ♭ (en alemán, francés e italiano las alteraciones
    /// de las notas van en palabras o sufijos; esto afecta a las tensiones de los cifrados).
    public var usaASCII: Bool { escritura.usaASCII }
}

// MARK: - Escritura de las notas

/// Cómo se escriben los nombres de nota en una `Notacion`: el idioma y, en español e inglés, si las
/// alteraciones son ♯/♭ o #/b. Para recorrerlas con un `switch` exhaustivo: el compilador avisa al añadir una.
public enum EscrituraDeNotas: Hashable, Sendable, CaseIterable {
    /// Do, Fa♯, Si♭.
    case espanol
    /// Do, Fa#, Sib.
    case espanolASCII
    /// C, F#, Bb.
    case ingles
    /// C, F♯, B♭.
    case inglesUnicode
    /// C, Fis, Es, B, H.
    case aleman
    /// do, ré, fa dièse, si bémol.
    case frances
    /// do, re, fa diesis, si bemolle.
    case italiano
    /// do, re, fa sostingut, si bemoll.
    case catalan
    /// do, re, fa sostido, si bemol.
    case gallego
    /// do, re, fa diesa, si bemol.
    case euskera
    /// dó, ré, fá sustenido, si bemol.
    case portugues
    /// do, re, fa dièsi, si bemòl.
    case occitano
    /// до, ре, фа-диез, си-бемоль.
    case ruso
    /// ντο, ρε, φα δίεση, σι ύφεση.
    case griego

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

    /// El idioma de los nombres de nota.
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
        case .occitano: return .occitano
        case .ruso: return .ruso
        case .griego: return .griego
        }
    }

    /// Alteraciones como # y b en lugar de ♯ y ♭.
    public var usaASCII: Bool {
        switch self {
        case .espanolASCII, .ingles, .aleman: return true
        case .espanol, .inglesUnicode, .frances, .italiano, .catalan, .gallego, .euskera, .portugues, .occitano,
             .ruso, .griego:
            return false
        }
    }
}

// MARK: - Idioma

/// Idioma de una `Notacion` (la notación añade si las alteraciones son ♯/♭ o #/b).
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

    public var notacion: Notacion
    /// Escribe ♭ y ♯ como b y # en las tensiones.
    public var alteracionesASCII: Bool
    public var menor: Menor
    public var disminuido: Disminuido
    public var aumentado: Aumentado
    public var septimaMayor: SeptimaMayor
    public var semidisminuido: Semidisminuido

    /// Sin `alteracionesASCII`, las tensiones llevan b y # si las notas las llevan (`Notacion.usaASCII`): el
    /// estilo básico de cada notación es `EstiloDeCifrado(notacion:)`, y `.ingles` escribe Bb7(b9).
    public init(notacion: Notacion = .espanol,
                alteracionesASCII: Bool? = nil,
                menor: Menor = .m,
                disminuido: Disminuido = .circulo,
                aumentado: Aumentado = .mas,
                septimaMayor: SeptimaMayor = .maj,
                semidisminuido: Semidisminuido = .menorSeptimaQuintaBemol) {
        self.notacion = notacion
        self.alteracionesASCII = alteracionesASCII ?? notacion.usaASCII
        self.menor = menor
        self.disminuido = disminuido
        self.aumentado = aumentado
        self.septimaMayor = septimaMayor
        self.semidisminuido = semidisminuido
    }

    /// Do♯m7(♭5), Mi♭maj7.
    public static let predeterminado = EstiloDeCifrado()
    /// Sólo caracteres ASCII: Do#m7(b5), Mibmaj7.
    public static let ascii = EstiloDeCifrado(notacion: .espanolASCII)
    /// Letras internacionales: C#m7(b5), Ebmaj7.
    public static let ingles = EstiloDeCifrado(notacion: .ingles)
    /// Letras internacionales con símbolos tipográficos: C♯m7(♭5), E♭maj7.
    public static let inglesUnicode = EstiloDeCifrado(notacion: .inglesUnicode)
    /// Notación habitual en jazz: C#ø7, EbΔ7.
    public static let jazz = EstiloDeCifrado(notacion: .ingles, septimaMayor: .delta, semidisminuido: .barrado)
    /// Calidades escritas con palabras: Domin7, Fadim, Solaug.
    public static let palabras = EstiloDeCifrado(menor: .min, disminuido: .dim, aumentado: .aug)

    package func nombre(_ nota: Nota) -> String { nota.nombreCompacto(en: notacion) }
}
