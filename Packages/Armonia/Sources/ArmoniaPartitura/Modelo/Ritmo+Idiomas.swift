import ArmoniaNucleo
import ArmoniaTeoria
// Nombres de las figuras y de las duraciones en los ocho idiomas de los textos (`Traduccion`). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - Figura

extension Figura {
    public var nombre: String { nombre(en: .espanol) }

    /// En español, "negra"; en inglés, el nombre estadounidense ("quarter note").
    public func nombre(en notacion: Nomenclatura) -> String { Figura.nombres[rawValue + 1].en(notacion) }

    private static let nombres = [
        Traduccion("cuadrada", "double whole note", ca: "quadrada", gl: "cadrada", eu: "karratua",
                   pt: "breve", fr: "carrée", it: "breve"),
        Traduccion("redonda", "whole note", ca: "rodona", gl: "redonda", eu: "biribila",
                   pt: "semibreve", fr: "ronde", it: "semibreve"),
        Traduccion("blanca", "half note", ca: "blanca", gl: "branca", eu: "zuria",
                   pt: "mínima", fr: "blanche", it: "minima"),
        Traduccion("negra", "quarter note", ca: "negra", gl: "negra", eu: "beltza",
                   pt: "semínima", fr: "noire", it: "semiminima"),
        Traduccion("corchea", "eighth note", ca: "corxera", gl: "corchea", eu: "kortxea",
                   pt: "colcheia", fr: "croche", it: "croma"),
        Traduccion("semicorchea", "sixteenth note", ca: "semicorxera", gl: "semicorchea", eu: "semikortxea",
                   pt: "semicolcheia", fr: "double croche", it: "semicroma"),
        Traduccion("fusa", "thirty-second note", ca: "fusa", gl: "fusa", eu: "fusa",
                   pt: "fusa", fr: "triple croche", it: "biscroma"),
        Traduccion("semifusa", "sixty-fourth note", ca: "semifusa", gl: "semifusa", eu: "semifusa",
                   pt: "semifusa", fr: "quadruple croche", it: "semibiscroma"),
        Traduccion("garrapatea", "hundred twenty-eighth note", ca: "garrapatea", gl: "garrapatea", eu: "garrapatea",
                   pt: "quartifusa", fr: "quintuple croche", it: "fusa"),
    ]
}

// MARK: - Duracion

extension Duracion {
    /// "negra", "corchea con puntillo", "blanca con doble puntillo"; si no es una figura,
    /// la fracción: "5/8 de redonda". La duración nula es "cero".
    public var nombre: String { nombre(en: .espanol) }

    public func nombre(en notacion: Nomenclatura) -> String {
        if esCero { return Traduccion("cero", "zero", ca: "zero", gl: "cero", eu: "zero",
                                      pt: "zero", fr: "zéro", it: "zero").en(notacion) }
        guard let escritura = figuraYPuntillos else {
            let fraccion = "\(numerador)/\(denominador)"
            return Traduccion("\(fraccion) de redonda", "\(fraccion) of a whole note", ca: "\(fraccion) de rodona",
                              gl: "\(fraccion) de redonda", eu: "biribilaren \(fraccion)",
                              pt: "\(fraccion) de semibreve", fr: "\(fraccion) de ronde", it: "\(fraccion) di semibreve").en(notacion)
        }
        let figura = escritura.figura.nombre(en: notacion)
        let puntillos = escritura.puntillos
        guard puntillos > 0 else { return figura }
        switch notacion.idioma {
        case .espanol:
            return figura + ["", " con puntillo", " con doble puntillo", " con triple puntillo",
                             " con cuádruple puntillo"][puntillos]
        case .ingles, .aleman:
            return ["", "dotted ", "double-dotted ", "triple-dotted ", "quadruple-dotted "][puntillos] + figura
        case .portugues:
            return figura + ["", " pontuada", " duplamente pontuada", " triplamente pontuada",
                             " quadruplamente pontuada"][puntillos]
        case .frances:
            return figura + ["", " pointée", " doublement pointée", " triplement pointée",
                             " quadruplement pointée"][puntillos]
        case .italiano:
            return figura + ["", " puntata", " doppiamente puntata", " triplamente puntata",
                             " quadruplamente puntata"][puntillos]
        case .catalan:
            return figura + ["", " amb punt", " amb doble punt", " amb triple punt", " amb quàdruple punt"][puntillos]
        case .gallego:
            return figura + ["", " con puntiño", " con dobre puntiño", " con triplo puntiño",
                             " con cuádruplo puntiño"][puntillos]
        case .euskera:
            return figura + ["", " puntuduna", " puntu bikoitzarekin", " puntu hirukoitzarekin",
                             " puntu laukoitzarekin"][puntillos]
        }
    }
}
