import ArmoniaNucleo
import ArmoniaTeoria
// Nombres de las claves en los cinco idiomas de los textos (`Traduccion`). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - Clave

extension Clave {
    public var nombre: String { nombre(en: .espanol) }

    public func nombre(en notacion: Nomenclatura) -> String { traduccion.en(notacion) }

    private var traduccion: Traduccion {
        switch self {
        case .sol:
            return Traduccion("clave de sol", "treble clef", ca: "clau de sol", gl: "clave de sol", eu: "sol giltza")
        case .solOctavaBaja:
            return Traduccion("clave de sol octava baja", "treble clef 8vb", ca: "clau de sol octava baixa",
                              gl: "clave de sol oitava baixa", eu: "sol giltza zortzidun bat beherago")
        case .solOctavaAlta:
            return Traduccion("clave de sol octava alta", "treble clef 8va", ca: "clau de sol octava alta",
                              gl: "clave de sol oitava alta", eu: "sol giltza zortzidun bat gorago")
        case .fa:
            return Traduccion("clave de fa", "bass clef", ca: "clau de fa", gl: "clave de fa", eu: "fa giltza")
        case .faEnTercera:
            return Traduccion("clave de fa en tercera", "baritone clef", ca: "clau de fa en tercera",
                              gl: "clave de fa en terceira", eu: "fa giltza hirugarren lerroan")
        case .doEnPrimera:
            return Traduccion("clave de do en primera", "soprano clef", ca: "clau de do en primera",
                              gl: "clave de do en primeira", eu: "do giltza lehen lerroan")
        case .doEnSegunda:
            return Traduccion("clave de do en segunda", "mezzo-soprano clef", ca: "clau de do en segona",
                              gl: "clave de do en segunda", eu: "do giltza bigarren lerroan")
        case .doEnTercera:
            return Traduccion("clave de do en tercera", "alto clef", ca: "clau de do en tercera",
                              gl: "clave de do en terceira", eu: "do giltza hirugarren lerroan")
        case .doEnCuarta:
            return Traduccion("clave de do en cuarta", "tenor clef", ca: "clau de do en quarta",
                              gl: "clave de do en cuarta", eu: "do giltza laugarren lerroan")
        }
    }
}
