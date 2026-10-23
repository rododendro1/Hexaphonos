import ArmoniaNucleo
import ArmoniaTeoria
// Nombres de las claves (español e inglés). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - Clave

extension Clave {
    public var nombre: String {
        switch self {
        case .sol: return "clave de sol"
        case .solOctavaBaja: return "clave de sol octava baja"
        case .solOctavaAlta: return "clave de sol octava alta"
        case .fa: return "clave de fa"
        case .faEnTercera: return "clave de fa en tercera"
        case .doEnPrimera: return "clave de do en primera"
        case .doEnSegunda: return "clave de do en segunda"
        case .doEnTercera: return "clave de do en tercera"
        case .doEnCuarta: return "clave de do en cuarta"
        }
    }

    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles else { return nombre }
        switch self {
        case .sol: return "treble clef"
        case .solOctavaBaja: return "treble clef 8vb"
        case .solOctavaAlta: return "treble clef 8va"
        case .fa: return "bass clef"
        case .faEnTercera: return "baritone clef"
        case .doEnPrimera: return "soprano clef"
        case .doEnSegunda: return "mezzo-soprano clef"
        case .doEnTercera: return "alto clef"
        case .doEnCuarta: return "tenor clef"
        }
    }
}
