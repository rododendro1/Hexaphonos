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

// MARK: - Instrumento

extension Instrumento {
    /// Catalán, gallego y euskera de los instrumentos predefinidos, por su nombre en español. Un
    /// instrumento que no está aquí usa su nombre español.
    package static let nombresPeninsulares: [String: (catalan: String, gallego: String, euskera: String)] = [
        "piano": ("piano", "piano", "pianoa"),
        "flauta": ("flauta", "frauta", "flauta"),
        "flautín": ("flautí", "frautín", "pikoloa"),
        "flauta en sol": ("flauta en sol", "frauta en sol", "sol flauta"),
        "oboe": ("oboè", "óboe", "oboea"),
        "corno inglés": ("corn anglès", "corno inglés", "korno ingelesa"),
        "clarinete en si♭": ("clarinet en si♭", "clarinete en si♭", "si♭ klarinetea"),
        "clarinete en la": ("clarinet en la", "clarinete en la", "la klarinetea"),
        "clarinete en mi♭": ("clarinet en mi♭", "clarinete en mi♭", "mi♭ klarinetea"),
        "clarinete bajo": ("clarinet baix", "clarinete baixo", "klarinete baxua"),
        "fagot": ("fagot", "fagot", "fagota"),
        "saxofón soprano": ("saxòfon soprano", "saxofón soprano", "saxofoi sopranoa"),
        "saxofón alto": ("saxòfon alt", "saxofón alto", "saxofoi altua"),
        "saxofón tenor": ("saxòfon tenor", "saxofón tenor", "saxofoi tenorra"),
        "saxofón barítono": ("saxòfon baríton", "saxofón barítono", "saxofoi baritonoa"),
        "trompeta en si♭": ("trompeta en si♭", "trompeta en si♭", "si♭ tronpeta"),
        "trompeta en do": ("trompeta en do", "trompeta en do", "do tronpeta"),
        "fliscorno": ("fiscorn", "fliscorno", "fliscornoa"),
        "trompa en fa": ("trompa en fa", "trompa en fa", "fa tronpa"),
        "trombón": ("trombó", "trombón", "tronboia"),
        "tuba": ("tuba", "tuba", "tuba"),
        "violín": ("violí", "violín", "biolina"),
        "viola": ("viola", "viola", "biola"),
        "violonchelo": ("violoncel", "violonchelo", "biolontxeloa"),
        "contrabajo": ("contrabaix", "contrabaixo", "kontrabaxua"),
        "guitarra": ("guitarra", "guitarra", "gitarra"),
        "bajo eléctrico": ("baix elèctric", "baixo eléctrico", "baxu elektrikoa"),
        "xilófono": ("xilòfon", "xilófono", "xilofonoa"),
        "glockenspiel": ("glockenspiel", "glockenspiel", "glockenspiela"),
        "celesta": ("celesta", "celesta", "zelesta"),
    ]
}
