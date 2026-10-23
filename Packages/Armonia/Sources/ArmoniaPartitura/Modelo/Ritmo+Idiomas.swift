import ArmoniaNucleo
import ArmoniaTeoria
// Nombres de las figuras y de las duraciones (español e inglés). El resto de nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - Figura

extension Figura {
    public var nombre: String {
        ["cuadrada", "redonda", "blanca", "negra", "corchea", "semicorchea", "fusa", "semifusa",
         "garrapatea"][rawValue + 1]
    }

    /// En español, `nombre`; en inglés, el nombre estadounidense ("quarter note").
    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles else { return nombre }
        return ["double whole note", "whole note", "half note", "quarter note", "eighth note",
                "sixteenth note", "thirty-second note", "sixty-fourth note",
                "hundred twenty-eighth note"][rawValue + 1]
    }
}

// MARK: - Duracion

extension Duracion {
    /// "negra", "corchea con puntillo", "blanca con doble puntillo"; si no es una figura,
    /// la fracción: "5/8 de redonda". La duración nula es "cero".
    public var nombre: String {
        if esCero { return "cero" }
        guard let escritura = figuraYPuntillos else { return "\(numerador)/\(denominador) de redonda" }
        let sufijos = ["", " con puntillo", " con doble puntillo", " con triple puntillo", " con cuádruple puntillo"]
        return escritura.figura.nombre + sufijos[escritura.puntillos]
    }

    public func nombre(en notacion: Nomenclatura) -> String {
        guard notacion.vocabulario == .ingles else { return nombre }
        if esCero { return "zero" }
        guard let escritura = figuraYPuntillos else { return "\(numerador)/\(denominador) of a whole note" }
        let prefijos = ["", "dotted ", "double-dotted ", "triple-dotted ", "quadruple-dotted "]
        return prefijos[escritura.puntillos] + escritura.figura.nombre(en: .ingles)
    }
}
