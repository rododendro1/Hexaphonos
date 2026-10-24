import ArmoniaNucleo
import ArmoniaTeoria
// Nombres de las correspondencias de colores en los cinco idiomas de los textos (`Traduccion`). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - CorrespondenciaDeColores

extension CorrespondenciaDeColores {
    public var nombre: String { nombre(en: .espanol) }

    public func nombre(en notacion: Nomenclatura) -> String {
        switch self {
        case .newton: return "Newton (1704)"
        case .castel: return "Castel (1734)"
        case .scriabin: return "Scriabin (1911)"
        case .circuloDeQuintas:
            return Traduccion("círculo de quintas", "circle of fifths", ca: "cercle de quintes",
                              gl: "círculo de quintas", eu: "bosgarrenen zirkulua").en(notacion)
        }
    }
}
