import ArmoniaNucleo
import ArmoniaTeoria
// Nombres de las correspondencias de colores (español e inglés). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - CorrespondenciaDeColores

extension CorrespondenciaDeColores {
    public var nombre: String {
        switch self {
        case .newton: return "Newton (1704)"
        case .castel: return "Castel (1734)"
        case .scriabin: return "Scriabin (1911)"
        case .circuloDeQuintas: return "círculo de quintas"
        }
    }

    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles, self == .circuloDeQuintas else { return nombre }
        return "circle of fifths"
    }
}
