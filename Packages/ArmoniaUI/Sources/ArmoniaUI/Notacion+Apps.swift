import Foundation
import Armonia

/// Lo que comparten las apps al elegir y guardar la notación. No usa SwiftUI, así que se prueba en Linux.
extension Notacion {
    /// Cómo se llama cada notación en el selector.
    public var titulo: String {
        esCombinada ? "\(escritura.titulo) · \(textos.titulo)" : escritura.titulo
    }

    /// El nombre con que se guarda en los ajustes. Es estable: no depende del orden de `allCases`.
    /// Una notación combinada se guarda como «ruso+espanol».
    public var clave: String {
        esCombinada ? escritura.clave + "+" + textos.clave : escritura.clave
    }

    /// La notación del idioma del sistema, para cuando aún no se ha elegido ninguna: con el sistema en
    /// catalán, `.catalan`; en un idioma sin notación propia, la española. `idiomas` son los códigos
    /// de `Locale.preferredLanguages` («ca-ES», «en-GB»…), y manda el primero que se conozca.
    public static func delSistema(idiomas: [String] = Locale.preferredLanguages) -> Notacion {
        for codigo in idiomas {
            switch codigo.lowercased().split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) {
            case "es": return .espanol
            case "en": return .ingles
            case "de": return .aleman
            case "fr": return .frances
            case "it": return .italiano
            case "ca": return .catalan
            case "gl": return .gallego
            case "eu": return .euskera
            case "pt": return .portugues
            case "oc": return .occitano
            case "ru": return .ruso
            case "el": return .griego
            default: continue
            }
        }
        return .espanol
    }

    /// La notación guardada con esa clave; si no existe, el español.
    public static func desde(clave: String) -> Notacion {
        let partes = clave.split(separator: "+", maxSplits: 1).map(String.init)
        let notas = allCases.first { $0.clave == partes.first } ?? .espanol
        guard partes.count == 2, let textos = Idioma.allCases.first(where: { $0.clave == partes[1] }) else { return notas }
        return notas.conTextos(en: textos)
    }

    /// El idioma elegido para los textos, o `nil` si van en el de las notas.
    public var idiomaElegidoParaLosTextos: Idioma? {
        esCombinada ? textos : nil
    }

    /// Otras notas, conservando el idioma elegido para los textos.
    public func conNotas(_ notas: Notacion) -> Notacion {
        idiomaElegidoParaLosTextos.map { notas.conTextos(en: $0) } ?? notas.notas
    }

    /// Los mismos nombres de nota con los textos en otro idioma, o en el de las notas si es `nil`.
    public func conTextosElegidos(_ idioma: Idioma?) -> Notacion {
        idioma.map { conTextos(en: $0) } ?? notas
    }

    /// Mensaje legible de un error del motor, en el idioma de esta notación.
    public func mensaje(de error: Error) -> String {
        (error as? ErrorDeLectura)?.descripcion(en: self) ?? error.localizedDescription
    }
}

extension EscrituraDeNotas {
    /// Cómo se llama cada escritura en el selector.
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

    /// El nombre con que se guarda en los ajustes.
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
}

extension Idioma {
    /// Cómo se llama cada idioma en el selector de los textos.
    public var titulo: String {
        switch self {
        case .espanol: return "Español"
        case .ingles: return "English"
        case .aleman: return "Deutsch"
        case .frances: return "Français"
        case .italiano: return "Italiano"
        case .catalan: return "Català"
        case .gallego: return "Galego"
        case .euskera: return "Euskara"
        case .portugues: return "Português"
        case .occitano: return "Occitan"
        case .ruso: return "Русский"
        case .griego: return "Ελληνικά"
        }
    }

    /// El nombre con que se guarda en los ajustes.
    public var clave: String {
        switch self {
        case .espanol: return "espanol"
        case .ingles: return "ingles"
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
}
