// MARK: - Traducción
//
// Los textos del motor que no son nombres de nota (mensajes de error, nombres de intervalos, de
// papeles en el acorde, de grados, de claves, de figuras, de cadencias…) se escriben en ocho
// idiomas: español, inglés, catalán, gallego, euskera, portugués, francés e italiano. El alemán,
// el occitano, el ruso y el griego toman los ingleses.
//
// `Traduccion` pide los ocho textos sin valores por omisión, así que un texto nuevo no compila
// hasta que los tiene todos. Los nombres de los catálogos (tipos de acorde y de escala,
// instrumentos) también están en los ocho idiomas, salvo los nombres tradicionales de escala
// (raga, maqam, pentatónicas japonesas…), que se escriben igual en todos.

/// Un texto en los ocho idiomas en los que escribe el motor.
///
///     let t = Traduccion("consonancia perfecta", "perfect consonance",
///                        ca: "consonància perfecta", gl: "consonancia perfecta", eu: "kontsonantzia perfektua",
///                        pt: "consonância perfeita", fr: "consonance parfaite", it: "consonanza perfetta")
///     t.en(.euskera)    // "kontsonantzia perfektua"
///     t.en(.frances)    // "consonance parfaite"
///     t.en(.aleman)     // "perfect consonance"
public struct Traduccion: Hashable, Sendable {
    public let espanol: String
    public let ingles: String
    public let catalan: String
    public let gallego: String
    public let euskera: String
    public let portugues: String
    public let frances: String
    public let italiano: String

    public init(_ espanol: String, _ ingles: String, ca catalan: String, gl gallego: String, eu euskera: String,
                pt portugues: String, fr frances: String, it italiano: String) {
        self.espanol = espanol
        self.ingles = ingles
        self.catalan = catalan
        self.gallego = gallego
        self.euskera = euskera
        self.portugues = portugues
        self.frances = frances
        self.italiano = italiano
    }

    /// El texto en el idioma de los textos de la notación (`Nomenclatura.idiomaDeLosTextos`).
    public func en(_ notacion: Nomenclatura) -> String { texto(en: notacion.idioma) }

    /// El texto en un idioma, o en inglés si es el alemán, el occitano, el ruso o el griego
    /// (`Idioma.deLosTextos`).
    public func texto(en idioma: Idioma) -> String {
        switch idioma {
        case .espanol: return espanol
        case .ingles, .aleman, .occitano, .ruso, .griego: return ingles
        case .catalan: return catalan
        case .gallego: return gallego
        case .euskera: return euskera
        case .portugues: return portugues
        case .frances: return frances
        case .italiano: return italiano
        }
    }
}

extension Idioma {
    /// Idiomas en los que el motor escribe sus textos.
    public static let traducidos: [Idioma] = [.espanol, .ingles, .catalan, .gallego, .euskera,
                                              .portugues, .frances, .italiano]

    /// El idioma en que salen los textos: el propio si está entre `traducidos`; si no (el alemán,
    /// el occitano, el ruso y el griego), el inglés.
    public var deLosTextos: Idioma {
        switch self {
        case .espanol, .ingles, .catalan, .gallego, .euskera, .portugues, .frances, .italiano: return self
        case .aleman, .occitano, .ruso, .griego: return .ingles
        }
    }
}

extension Nomenclatura {
    /// Idioma de los textos que no son nombres de nota (mensajes, intervalos, cadencias…):
    /// el de la notación, salvo en alemán, occitano, ruso y griego, que es el inglés.
    public var idiomaDeLosTextos: Idioma { idioma.deLosTextos }
}
