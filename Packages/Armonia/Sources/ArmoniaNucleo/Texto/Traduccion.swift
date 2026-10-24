// MARK: - Traducción
//
// Los textos del motor que no son nombres de nota (mensajes de error, nombres de intervalos, de
// papeles en el acorde, de grados, de claves, de figuras, de cadencias…) se escriben en cinco
// idiomas: español, inglés, catalán, gallego y euskera. Las demás notaciones toman los de un
// idioma cercano: el alemán, el francés y el italiano, los ingleses; el portugués, los españoles.
//
// `Traduccion` pide los cinco textos sin valores por omisión, así que un texto nuevo no compila
// hasta que los tiene todos. Los nombres de los catálogos (tipos de acorde y de escala,
// instrumentos) también están en los cinco idiomas, salvo los nombres tradicionales de escala
// (raga, maqam, pentatónicas japonesas…), que se escriben igual en todos.

/// Un texto en los cinco idiomas en los que escribe el motor.
///
///     let t = Traduccion("consonancia perfecta", "perfect consonance",
///                        ca: "consonància perfecta", gl: "consonancia perfecta", eu: "kontsonantzia perfektua")
///     t.en(.euskera)    // "kontsonantzia perfektua"
///     t.en(.aleman)     // "perfect consonance"
public struct Traduccion: Hashable, Sendable {
    public let espanol: String
    public let ingles: String
    public let catalan: String
    public let gallego: String
    public let euskera: String

    public init(_ espanol: String, _ ingles: String, ca catalan: String, gl gallego: String, eu euskera: String) {
        self.espanol = espanol
        self.ingles = ingles
        self.catalan = catalan
        self.gallego = gallego
        self.euskera = euskera
    }

    /// El texto en el idioma de los textos de la notación (`Nomenclatura.idiomaDeLosTextos`).
    public func en(_ notacion: Nomenclatura) -> String { texto(en: notacion.idioma) }

    /// El texto en un idioma, o en el de sus textos si no es uno de los cinco (`Idioma.deLosTextos`).
    public func texto(en idioma: Idioma) -> String {
        switch idioma {
        case .espanol, .portugues: return espanol
        case .ingles, .aleman, .frances, .italiano: return ingles
        case .catalan: return catalan
        case .gallego: return gallego
        case .euskera: return euskera
        }
    }
}

extension Idioma {
    /// Idiomas en los que el motor escribe sus textos.
    public static let traducidos: [Idioma] = [.espanol, .ingles, .catalan, .gallego, .euskera]

    /// El idioma en que salen los textos: el propio si está entre `traducidos`; si no, el inglés
    /// para el alemán, el francés y el italiano, y el español para el portugués.
    public var deLosTextos: Idioma {
        switch self {
        case .espanol, .ingles, .catalan, .gallego, .euskera: return self
        case .aleman, .frances, .italiano: return .ingles
        case .portugues: return .espanol
        }
    }
}

extension Nomenclatura {
    /// Idioma de los textos que no son nombres de nota (mensajes, intervalos, cadencias…):
    /// el de la notación en español, inglés, catalán, gallego y euskera; el inglés en alemán,
    /// francés e italiano, y el español en portugués.
    public var idiomaDeLosTextos: Idioma { idioma.deLosTextos }
}
