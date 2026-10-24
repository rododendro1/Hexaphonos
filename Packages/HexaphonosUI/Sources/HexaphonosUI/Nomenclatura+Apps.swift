import Armonia

/// Lo que comparten las apps al elegir y guardar la notación. No usa SwiftUI, así que se prueba en Linux.
extension Nomenclatura {
    /// Cómo se llama cada notación en el selector.
    public var titulo: String {
        switch self {
        case .espanol: return "Español (Fa♯)"
        case .espanolASCII: return "Español ASCII (Fa#)"
        case .ingles: return "English (F#)"
        case .inglesUnicode: return "English (F♯)"
        case .aleman: return "Deutsch (Fis)"
        case .frances: return "Français (fa dièse)"
        case .italiano: return "Italiano (fa diesis)"
        case .catalan: return "Català (fa sostingut)"
        case .gallego: return "Galego (fa sostido)"
        case .euskera: return "Euskara (fa diesa)"
        case .portugues: return "Português (fá sustenido)"
        case .occitano: return "Occitan (fa dièsi)"
        case .ruso: return "Русский (фа-диез)"
        case .griego: return "Ελληνικά (φα δίεση)"
        }
    }

    /// El nombre con que se guarda en los ajustes. Es estable: no depende del orden de `allCases`.
    public var clave: String {
        switch self {
        case .espanol: return "espanol"
        case .espanolASCII: return "espanolASCII"
        case .ingles: return "ingles"
        case .inglesUnicode: return "inglesUnicode"
        case .aleman: return "aleman"
        case .frances: return "frances"
        case .italiano: return "italiano"
        case .catalan: return "catalan"
        case .gallego: return "gallego"
        case .euskera: return "euskera"
        case .portugues: return "portugues"
        case .occitano: return "occitano"
        case .ruso: return "ruso"
        case .griego: return "griego"
        }
    }

    /// La notación guardada con esa clave; si no existe, el español.
    public static func desde(clave: String) -> Nomenclatura {
        allCases.first { $0.clave == clave } ?? .espanol
    }

    /// Mensaje legible de un error del motor, en el idioma de esta notación.
    public func mensaje(de error: Error) -> String {
        (error as? ErrorDeLectura)?.descripcion(en: self) ?? error.localizedDescription
    }
}
