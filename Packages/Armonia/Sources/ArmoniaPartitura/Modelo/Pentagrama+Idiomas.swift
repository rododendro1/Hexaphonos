import ArmoniaNucleo
import ArmoniaTeoria
// Nombres de las claves y de los instrumentos predefinidos en los ocho idiomas de los textos (`Traduccion`). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - Clave

extension Clave {
    public var nombre: String { nombre(en: .espanol) }

    public func nombre(en notacion: Nomenclatura) -> String { traduccion.en(notacion) }

    private var traduccion: Traduccion {
        switch self {
        case .sol:
            return Traduccion("clave de sol", "treble clef", ca: "clau de sol", gl: "clave de sol", eu: "sol giltza",
                              pt: "clave de sol", fr: "clé de sol", it: "chiave di violino")
        case .solOctavaBaja:
            return Traduccion("clave de sol octava baja", "treble clef 8vb", ca: "clau de sol octava baixa",
                              gl: "clave de sol oitava baixa", eu: "sol giltza zortzidun bat beherago",
                              pt: "clave de sol oitava abaixo", fr: "clé de sol octave basse", it: "chiave di violino ottava bassa")
        case .solOctavaAlta:
            return Traduccion("clave de sol octava alta", "treble clef 8va", ca: "clau de sol octava alta",
                              gl: "clave de sol oitava alta", eu: "sol giltza zortzidun bat gorago",
                              pt: "clave de sol oitava acima", fr: "clé de sol octave haute", it: "chiave di violino ottava alta")
        case .fa:
            return Traduccion("clave de fa", "bass clef", ca: "clau de fa", gl: "clave de fa", eu: "fa giltza",
                              pt: "clave de fá", fr: "clé de fa", it: "chiave di basso")
        case .faEnTercera:
            return Traduccion("clave de fa en tercera", "baritone clef", ca: "clau de fa en tercera",
                              gl: "clave de fa en terceira", eu: "fa giltza hirugarren lerroan",
                              pt: "clave de fá na terceira linha", fr: "clé de fa troisième ligne", it: "chiave di baritono")
        case .doEnPrimera:
            return Traduccion("clave de do en primera", "soprano clef", ca: "clau de do en primera",
                              gl: "clave de do en primeira", eu: "do giltza lehen lerroan",
                              pt: "clave de dó na primeira linha", fr: "clé d'ut première ligne", it: "chiave di soprano")
        case .doEnSegunda:
            return Traduccion("clave de do en segunda", "mezzo-soprano clef", ca: "clau de do en segona",
                              gl: "clave de do en segunda", eu: "do giltza bigarren lerroan",
                              pt: "clave de dó na segunda linha", fr: "clé d'ut deuxième ligne", it: "chiave di mezzosoprano")
        case .doEnTercera:
            return Traduccion("clave de do en tercera", "alto clef", ca: "clau de do en tercera",
                              gl: "clave de do en terceira", eu: "do giltza hirugarren lerroan",
                              pt: "clave de dó na terceira linha", fr: "clé d'ut troisième ligne", it: "chiave di contralto")
        case .doEnCuarta:
            return Traduccion("clave de do en cuarta", "tenor clef", ca: "clau de do en quarta",
                              gl: "clave de do en cuarta", eu: "do giltza laugarren lerroan",
                              pt: "clave de dó na quarta linha", fr: "clé d'ut quatrième ligne", it: "chiave di tenore")
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

    /// Portugués, francés e italiano de los instrumentos predefinidos, por su nombre en español. Un
    /// instrumento que no está aquí usa su nombre español.
    package static let nombresRomanicos: [String: (portugues: String, frances: String, italiano: String)] = [
        "piano": ("piano", "piano", "pianoforte"),
        "flauta": ("flauta", "flûte", "flauto"),
        "flautín": ("flautim", "piccolo", "ottavino"),
        "flauta en sol": ("flauta em sol", "flûte en sol", "flauto contralto"),
        "oboe": ("oboé", "hautbois", "oboe"),
        "corno inglés": ("corne-inglês", "cor anglais", "corno inglese"),
        "clarinete en si♭": ("clarinete em si♭", "clarinette en si♭", "clarinetto in si♭"),
        "clarinete en la": ("clarinete em lá", "clarinette en la", "clarinetto in la"),
        "clarinete en mi♭": ("clarinete em mi♭", "clarinette en mi♭", "clarinetto in mi♭"),
        "clarinete bajo": ("clarone", "clarinette basse", "clarinetto basso"),
        "fagot": ("fagote", "basson", "fagotto"),
        "saxofón soprano": ("saxofone soprano", "saxophone soprano", "sassofono soprano"),
        "saxofón alto": ("saxofone alto", "saxophone alto", "sassofono contralto"),
        "saxofón tenor": ("saxofone tenor", "saxophone ténor", "sassofono tenore"),
        "saxofón barítono": ("saxofone barítono", "saxophone baryton", "sassofono baritono"),
        "trompeta en si♭": ("trompete em si♭", "trompette en si♭", "tromba in si♭"),
        "trompeta en do": ("trompete em dó", "trompette en ut", "tromba in do"),
        "fliscorno": ("flugelhorn", "bugle", "flicorno"),
        "trompa en fa": ("trompa em fá", "cor en fa", "corno in fa"),
        "trombón": ("trombone", "trombone", "trombone"),
        "tuba": ("tuba", "tuba", "tuba"),
        "violín": ("violino", "violon", "violino"),
        "viola": ("viola", "alto", "viola"),
        "violonchelo": ("violoncelo", "violoncelle", "violoncello"),
        "contrabajo": ("contrabaixo", "contrebasse", "contrabbasso"),
        "guitarra": ("violão", "guitare", "chitarra"),
        "bajo eléctrico": ("baixo elétrico", "basse électrique", "basso elettrico"),
        "xilófono": ("xilofone", "xylophone", "xilofono"),
        "glockenspiel": ("glockenspiel", "glockenspiel", "glockenspiel"),
        "celesta": ("celesta", "célesta", "celesta"),
    ]
}
