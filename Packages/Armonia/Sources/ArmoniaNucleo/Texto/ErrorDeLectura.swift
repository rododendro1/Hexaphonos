import Foundation

/// Error al leer un texto: un nombre de nota, una nota, un intervalo, un cifrado o una escala.
///
/// Indica el texto, el carácter donde se detuvo la lectura y el motivo, en español o en inglés:
///
///     do {
///         let acorde = try Acorde(leyendo: "Do7(b3)")
///     } catch let error as ErrorDeLectura {
///         print(error)   // No se puede leer «Do7(b3)» (carácter 5): «b3» no es una tensión válida…
///         error.descripcion(en: .ingles)   // Cannot read "Do7(b3)" (character 5): "b3" is not a valid tension…
///     }

public struct ErrorDeLectura: Error, Hashable, Sendable, CustomStringConvertible {
    public enum Motivo: Hashable, Sendable {
        case textoVacio
        case notaNoReconocida
        case caracteresSobrantes(String)
        case octavaNoValida(String)
        case numeroDeIntervaloNoValido(String)
        case calidadNoValida(String)
        case intervaloInexistente(numero: Int, calidad: CalidadDeIntervalo)
        case simboloNoReconocido(String)
        case tensionNoValida(String)
        case numeroDeAcordeNoValido(Int)
        case numeroRepetido(Int)
        case calidadesIncompatibles(CalidadesIncompatibles)
        case gradoNoOmitible(Int)
        case acordeNoInterpretable(RechazoDeAcorde)
        case bajoNoValido(String)
        /// Un nombre de nota escrito en otro idioma que el resto ("Sol7/B" en lugar de "Sol7/Si").
        case idiomasMezclados(String)
        case tipoDeEscalaNoReconocido(String)
        case modoNoReconocido(String)
        case alteracionNoReconocida(String)
        case duracionNoValida(String)
        case compasNoValido(String)
        /// Los acordes de una conducción de voces no tienen todos el mismo número de voces (o tienen menos de dos).
        case vocesDistintas
    }

    /// Símbolos de un cifrado que no pueden ir juntos.
    public enum CalidadesIncompatibles: Hashable, Sendable {
        /// ° y ø a la vez ("Dodimø").
        case disminuidoYSemidisminuido
        /// El acorde de quinta con m, °, ø o + ("Dom5").
        case quintaConCalidad
    }

    /// Por qué un conjunto de notas no es un acorde por terceras.
    public enum RechazoDeAcorde: Hashable, Sendable {
        case faltaLaFundamental
        /// Un intervalo que no es tercera, quinta, séptima ni tensión (la 1ª aumentada, por ejemplo).
        case intervaloSinPapel(Intervalo)
        case terceraMayorYMenor
        case variasSeptimas
        case septimaDisminuidaFueraDelDisminuido
        case noEsPorTerceras
    }

    /// Texto completo que se intentaba leer.
    public let texto: String
    /// Carácter (contando desde 0) donde se detuvo la lectura; `nil` cuando el problema
    /// no está en un punto concreto sino en el conjunto (por ejemplo, ° y ø a la vez).
    public let posicion: Int?
    public let motivo: Motivo

    public init(texto: String, posicion: Int?, motivo: Motivo) {
        self.texto = texto
        self.posicion = posicion
        self.motivo = motivo
    }

    /// Explicación del motivo, en español.
    public var explicacion: String { explicacion(en: .espanol) }

    /// Explicación del motivo en el idioma del vocabulario de la notación: en español para
    /// español, catalán, gallego, euskera y portugués, y en inglés para las demás (`notacion.vocabulario`).
    public func explicacion(en notacion: Nomenclatura) -> String {
        notacion.vocabulario == .ingles ? explicacionEnIngles(notacion) : explicacionEnEspanol
    }

    /// Mensaje completo, en español: «No se puede leer «Do7(b3)» (carácter 5): …».
    public var description: String { descripcion(en: .espanol) }

    /// Mensaje completo en el idioma del vocabulario de la notación.
    public func descripcion(en notacion: Nomenclatura) -> String {
        let ingles = notacion.vocabulario == .ingles
        var inicio = texto.isEmpty
            ? (ingles ? "Invalid value" : "Valor no válido")
            : (ingles ? "Cannot read \"\(texto)\"" : "No se puede leer «\(texto)»")
        if let p = posicion { inicio += ingles ? " (character \(p + 1))" : " (carácter \(p + 1))" }
        return inicio + ": " + explicacion(en: notacion)
    }

    private var explicacionEnEspanol: String {
        switch motivo {
        case .textoVacio:
            return "el texto está vacío"
        case .notaNoReconocida:
            return "se esperaba un nombre de nota (Do, Re, Mi… o C, D, E…)"
        case .caracteresSobrantes(let resto):
            return "sobra «\(resto)»"
        case .octavaNoValida(let resto):
            return resto.isEmpty ? "falta la octava (por ejemplo, Do4)" : "«\(resto)» no es una octava válida"
        case .numeroDeIntervaloNoValido(let resto):
            return resto.isEmpty ? "falta el número del intervalo (por ejemplo, 3M)"
                : "«\(resto)» no es un número de intervalo"
        case .calidadNoValida(let resto):
            return resto.isEmpty ? "falta la calidad del intervalo (J, M, m, A o d)"
                : "«\(resto)» no es una calidad de intervalo (J, M, m, A o d)"
        case .intervaloInexistente(let numero, let calidad):
            if numero == 1, case .disminuida = calidad {
                return "no existe el unísono disminuido: de Do a Do♭ hay un unísono aumentado "
                    + "descendente (escríbelo -1A)"
            }
            let clase = (numero - 1) % 7
            let regla = [0, 3, 4].contains(clase)
                ? "el unísono, la 4ª, la 5ª y la 8ª son justas, aumentadas o disminuidas"
                : "la 2ª, la 3ª, la 6ª y la 7ª son mayores, menores, aumentadas o disminuidas"
            return "no existe la \(numero)ª \(calidad.nombre): \(regla)"
        case .simboloNoReconocido(let simbolo):
            return "«\(simbolo)» no forma parte de ningún cifrado conocido"
        case .tensionNoValida(let tension):
            return "«\(tension)» no es una tensión válida (se admiten ♭/♯ con 5, 9, 11 y 13, "
                + "y add con 2, 4, 6, 9, 11 y 13)"
        case .numeroDeAcordeNoValido(let numero):
            return "«\(numero)» no es un número de acorde (5, 6, 7, 9, 11 o 13)"
        case .numeroRepetido(let numero):
            return "«\(numero)» aparece después de otro número; las tensiones adicionales "
                + "van entre paréntesis, como en 7(9)"
        case .calidadesIncompatibles(.disminuidoYSemidisminuido):
            return "disminuido (°) y semidisminuido (ø) no pueden combinarse"
        case .calidadesIncompatibles(.quintaConCalidad):
            return "el acorde de quinta (5) no lleva tercera, así que no admite m, °, ø ni +"
        case .gradoNoOmitible(let grado):
            return grado == 1 ? "no se puede omitir la fundamental"
                : "«omit\(grado)» no es válido (se pueden omitir 3, 5, 7, 9, 11 y 13)"
        case .acordeNoInterpretable(let rechazo):
            switch rechazo {
            case .faltaLaFundamental: return "falta la fundamental"
            case .intervaloSinPapel(let intervalo):
                return "la \(intervalo.nombre) no tiene papel en un acorde por terceras"
            case .terceraMayorYMenor:
                return "tiene tercera mayor y menor a la vez (la ♯9 se escribe como 9ª aumentada, no como 3ª menor)"
            case .variasSeptimas: return "tiene más de una séptima"
            case .septimaDisminuidaFueraDelDisminuido:
                return "la séptima disminuida sólo aparece en el acorde disminuido (con 3ª menor y 5ª disminuida)"
            case .noEsPorTerceras: return "no es un acorde por terceras"
            }
        case .bajoNoValido(let bajo):
            return "«\(bajo)» no es un nombre de nota para el bajo"
        case .idiomasMezclados(let nombre):
            return "«\(nombre)» está escrito en otro idioma que la fundamental: "
                + "se escribe todo en español (Sol7/Si) o todo con letras (G7/B)"
        case .duracionNoValida(let texto):
            return "«\(texto)» no es una duración: se esperaba una figura (1, 2, 4, 8, 16…, con puntillos: 4.) "
                + "o una fracción de redonda (3/8, 1/12)"
        case .compasNoValido(let texto):
            return "«\(texto)» no es un compás: se esperaba numerador/denominador con el denominador "
                + "potencia de 2 (4/4, 6/8, 7/8), C o ¢"
        case .vocesDistintas:
            return "todos los acordes tienen que tener el mismo número de voces, y al menos dos"
        case .alteracionNoReconocida(let signo):
            return "«\(signo)» no es una alteración (se esperaba ♯, ♭, 𝄪, 𝄫, #, b, x o ♮)"
        case .modoNoReconocido(let nombre):
            return "«\(nombre)» no es el modo de una tonalidad: una tonalidad es mayor o menor "
                + "(para los demás modos, usa Escala)"
        case .tipoDeEscalaNoReconocido(let nombre):
            return nombre.isEmpty ? "falta el tipo de escala (mayor, dórico, menor armónica…)"
                : "«\(nombre)» no es un tipo de escala conocido"
        }
    }

    private func explicacionEnIngles(_ notacion: Nomenclatura) -> String {
        switch motivo {
        case .textoVacio:
            return "the text is empty"
        case .notaNoReconocida:
            return "expected a note name (C, D, E… or Do, Re, Mi…)"
        case .caracteresSobrantes(let resto):
            return "unexpected \"\(resto)\""
        case .octavaNoValida(let resto):
            return resto.isEmpty ? "the octave is missing (for example, C4)" : "\"\(resto)\" is not a valid octave"
        case .numeroDeIntervaloNoValido(let resto):
            return resto.isEmpty ? "the interval number is missing (for example, M3)"
                : "\"\(resto)\" is not an interval number"
        case .calidadNoValida(let resto):
            return resto.isEmpty ? "the interval quality is missing (P, M, m, A or d)"
                : "\"\(resto)\" is not an interval quality (P, M, m, A or d)"
        case .intervaloInexistente(let numero, let calidad):
            if numero == 1, case .disminuida = calidad {
                return "there is no diminished unison: from C to C♭ is a descending augmented unison "
                    + "(write it -A1)"
            }
            let clase = (numero - 1) % 7
            let regla = [0, 3, 4].contains(clase)
                ? "unisons, 4ths, 5ths and octaves are perfect, augmented or diminished"
                : "2nds, 3rds, 6ths and 7ths are major, minor, augmented or diminished"
            return "there is no \(calidad.nombre(en: notacion)) \(ErrorDeLectura.ordinalIngles(numero)): \(regla)"
        case .simboloNoReconocido(let simbolo):
            return "\"\(simbolo)\" is not part of any known chord symbol"
        case .tensionNoValida(let tension):
            return "\"\(tension)\" is not a valid tension (♭/♯ go with 5, 9, 11 and 13, "
                + "and add with 2, 4, 6, 9, 11 and 13)"
        case .numeroDeAcordeNoValido(let numero):
            return "\"\(numero)\" is not a chord number (5, 6, 7, 9, 11 or 13)"
        case .numeroRepetido(let numero):
            return "\"\(numero)\" comes after another number; additional tensions "
                + "go in parentheses, as in 7(9)"
        case .calidadesIncompatibles(.disminuidoYSemidisminuido):
            return "diminished (°) and half-diminished (ø) cannot be combined"
        case .calidadesIncompatibles(.quintaConCalidad):
            return "a power chord (5) has no third, so it cannot take m, °, ø or +"
        case .gradoNoOmitible(let grado):
            return grado == 1 ? "the root cannot be omitted"
                : "\"omit\(grado)\" is not valid (3, 5, 7, 9, 11 and 13 can be omitted)"
        case .acordeNoInterpretable(let rechazo):
            switch rechazo {
            case .faltaLaFundamental: return "the root is missing"
            case .intervaloSinPapel(let intervalo):
                return "the \(intervalo.nombre(en: notacion)) has no role in a tertian chord"
            case .terceraMayorYMenor:
                return "it has both a major and a minor third (♯9 is written as an augmented 9th, not a minor 3rd)"
            case .variasSeptimas: return "it has more than one seventh"
            case .septimaDisminuidaFueraDelDisminuido:
                return "the diminished seventh only appears in the diminished chord (with a minor 3rd and a diminished 5th)"
            case .noEsPorTerceras: return "it is not a tertian chord"
            }
        case .bajoNoValido(let bajo):
            return "\"\(bajo)\" is not a note name for the bass"
        case .idiomasMezclados(let nombre):
            return "\"\(nombre)\" is written in a different language from the root: "
                + "write everything with letters (G7/B) or everything in Spanish (Sol7/Si)"
        case .duracionNoValida(let texto):
            return "\"\(texto)\" is not a duration: expected a note value (1, 2, 4, 8, 16…, dotted: 4.) "
                + "or a fraction of a whole note (3/8, 1/12)"
        case .compasNoValido(let texto):
            return "\"\(texto)\" is not a time signature: expected numerator/denominator with a "
                + "power-of-2 denominator (4/4, 6/8, 7/8), C or ¢"
        case .vocesDistintas:
            return "every chord must have the same number of voices, and at least two"
        case .alteracionNoReconocida(let signo):
            return "\"\(signo)\" is not an accidental (expected ♯, ♭, 𝄪, 𝄫, #, b, x or ♮)"
        case .modoNoReconocido(let nombre):
            return "\"\(nombre)\" is not the mode of a key: a key is major or minor "
                + "(for other modes, use Escala)"
        case .tipoDeEscalaNoReconocido(let nombre):
            return nombre.isEmpty ? "the scale type is missing (major, dorian, harmonic minor…)"
                : "\"\(nombre)\" is not a known scale type"
        }
    }

    /// 1st, 2nd, 3rd, 4th… 11th, 12th, 13th, 21st.
    package static func ordinalIngles(_ n: Int) -> String {
        let sufijo: String
        switch (n % 10, n % 100) {
        case (_, 11...13): sufijo = "th"
        case (1, _): sufijo = "st"
        case (2, _): sufijo = "nd"
        case (3, _): sufijo = "rd"
        default: sufijo = "th"
        }
        return "\(n)\(sufijo)"
    }
}

extension ErrorDeLectura: LocalizedError {
    public var errorDescription: String? { description }
}
