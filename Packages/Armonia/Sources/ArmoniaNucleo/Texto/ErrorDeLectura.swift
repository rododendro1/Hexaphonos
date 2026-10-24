import Foundation

/// Error al leer un texto: un nombre de nota, una nota, un intervalo, un cifrado o una escala.
///
/// Indica el texto, el carácter donde se detuvo la lectura y el motivo, en español, inglés,
/// catalán, gallego o euskera:
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

    /// Explicación del motivo en el idioma de los textos de la notación: en español, inglés, catalán,
    /// gallego o euskera; en inglés para el alemán, el francés y el italiano, y en español para el
    /// portugués (`notacion.idiomaDeLosTextos`).
    public func explicacion(en notacion: Nomenclatura) -> String {
        switch notacion.idioma {
        case .espanol, .portugues: return explicacionEnEspanol
        case .ingles, .aleman, .frances, .italiano: return explicacionEnIngles(notacion)
        case .catalan: return explicacionEnCatalan
        case .gallego: return explicacionEnGallego
        case .euskera: return explicacionEnEuskera
        }
    }

    /// Mensaje completo, en español: «No se puede leer «Do7(b3)» (carácter 5): …».
    public var description: String { descripcion(en: .espanol) }

    /// Mensaje completo en el idioma de los textos de la notación.
    public func descripcion(en notacion: Nomenclatura) -> String {
        var inicio = texto.isEmpty
            ? Traduccion("Valor no válido", "Invalid value",
                         ca: "Valor no vàlid", gl: "Valor non válido", eu: "Balio baliogabea").en(notacion)
            : Traduccion("No se puede leer «\(texto)»", "Cannot read \"\(texto)\"",
                         ca: "No es pot llegir «\(texto)»", gl: "Non se pode ler «\(texto)»",
                         eu: "Ezin da «\(texto)» irakurri").en(notacion)
        if let p = posicion {
            inicio += Traduccion(" (carácter \(p + 1))", " (character \(p + 1))",
                                 ca: " (caràcter \(p + 1))", gl: " (carácter \(p + 1))",
                                 eu: " (\(p + 1). karakterea)").en(notacion)
        }
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

    private var explicacionEnCatalan: String {
        switch motivo {
        case .textoVacio:
            return "el text és buit"
        case .notaNoReconocida:
            return "s'esperava un nom de nota (Do, Re, Mi… o C, D, E…)"
        case .caracteresSobrantes(let resto):
            return "sobra «\(resto)»"
        case .octavaNoValida(let resto):
            return resto.isEmpty ? "falta l'octava (per exemple, Do4)" : "«\(resto)» no és una octava vàlida"
        case .numeroDeIntervaloNoValido(let resto):
            return resto.isEmpty ? "falta el número de l'interval (per exemple, 3M)"
                : "«\(resto)» no és un número d'interval"
        case .calidadNoValida(let resto):
            return resto.isEmpty ? "falta la qualitat de l'interval (J, M, m, A o d)"
                : "«\(resto)» no és una qualitat d'interval (J, M, m, A o d)"
        case .intervaloInexistente(let numero, let calidad):
            if numero == 1, case .disminuida = calidad {
                return "no existeix l'uníson disminuït: de Do a Do♭ hi ha un uníson augmentat "
                    + "descendent (escriu-lo -1A)"
            }
            let clase = (numero - 1) % 7
            let regla = [0, 3, 4].contains(clase)
                ? "l'uníson, la 4a, la 5a i la 8a són justes, augmentades o disminuïdes"
                : "la 2a, la 3a, la 6a i la 7a són majors, menors, augmentades o disminuïdes"
            return "no existeix la \(numero)a \(calidad.nombre(en: .catalan)): \(regla)"
        case .simboloNoReconocido(let simbolo):
            return "«\(simbolo)» no forma part de cap xifrat conegut"
        case .tensionNoValida(let tension):
            return "«\(tension)» no és una tensió vàlida (s'admeten ♭/♯ amb 5, 9, 11 i 13, "
                + "i add amb 2, 4, 6, 9, 11 i 13)"
        case .numeroDeAcordeNoValido(let numero):
            return "«\(numero)» no és un número d'acord (5, 6, 7, 9, 11 o 13)"
        case .numeroRepetido(let numero):
            return "«\(numero)» apareix després d'un altre número; les tensions addicionals "
                + "van entre parèntesis, com a 7(9)"
        case .calidadesIncompatibles(.disminuidoYSemidisminuido):
            return "disminuït (°) i semidisminuït (ø) no es poden combinar"
        case .calidadesIncompatibles(.quintaConCalidad):
            return "l'acord de quinta (5) no porta tercera, així que no admet m, °, ø ni +"
        case .gradoNoOmitible(let grado):
            return grado == 1 ? "no es pot ometre la fonamental"
                : "«omit\(grado)» no és vàlid (es poden ometre 3, 5, 7, 9, 11 i 13)"
        case .acordeNoInterpretable(let rechazo):
            switch rechazo {
            case .faltaLaFundamental: return "falta la fonamental"
            case .intervaloSinPapel(let intervalo):
                return "la \(intervalo.nombre(en: .catalan)) no té cap paper en un acord per terceres"
            case .terceraMayorYMenor:
                return "té tercera major i menor alhora (la ♯9 s'escriu com a 9a augmentada, no com a 3a menor)"
            case .variasSeptimas: return "té més d'una sèptima"
            case .septimaDisminuidaFueraDelDisminuido:
                return "la sèptima disminuïda només apareix a l'acord disminuït (amb 3a menor i 5a disminuïda)"
            case .noEsPorTerceras: return "no és un acord per terceres"
            }
        case .bajoNoValido(let bajo):
            return "«\(bajo)» no és un nom de nota per al baix"
        case .idiomasMezclados(let nombre):
            return "«\(nombre)» està escrit en un altre idioma que la fonamental: "
                + "s'escriu tot amb síl·labes (Sol7/Si) o tot amb lletres (G7/B)"
        case .duracionNoValida(let texto):
            return "«\(texto)» no és una durada: s'esperava una figura (1, 2, 4, 8, 16…, amb punts: 4.) "
                + "o una fracció de rodona (3/8, 1/12)"
        case .compasNoValido(let texto):
            return "«\(texto)» no és un compàs: s'esperava numerador/denominador amb el denominador "
                + "potència de 2 (4/4, 6/8, 7/8), C o ¢"
        case .vocesDistintas:
            return "tots els acords han de tenir el mateix nombre de veus, i almenys dues"
        case .alteracionNoReconocida(let signo):
            return "«\(signo)» no és una alteració (s'esperava ♯, ♭, 𝄪, 𝄫, #, b, x o ♮)"
        case .modoNoReconocido(let nombre):
            return "«\(nombre)» no és el mode d'una tonalitat: una tonalitat és major o menor "
                + "(per als altres modes, fes servir Escala)"
        case .tipoDeEscalaNoReconocido(let nombre):
            return nombre.isEmpty ? "falta el tipus d'escala (mayor, dórico, menor armónica…)"
                : "«\(nombre)» no és un tipus d'escala conegut"
        }
    }

    private var explicacionEnGallego: String {
        switch motivo {
        case .textoVacio:
            return "o texto está baleiro"
        case .notaNoReconocida:
            return "agardábase un nome de nota (Do, Re, Mi… ou C, D, E…)"
        case .caracteresSobrantes(let resto):
            return "sobra «\(resto)»"
        case .octavaNoValida(let resto):
            return resto.isEmpty ? "falta a oitava (por exemplo, Do4)" : "«\(resto)» non é unha oitava válida"
        case .numeroDeIntervaloNoValido(let resto):
            return resto.isEmpty ? "falta o número do intervalo (por exemplo, 3M)"
                : "«\(resto)» non é un número de intervalo"
        case .calidadNoValida(let resto):
            return resto.isEmpty ? "falta a calidade do intervalo (J, M, m, A ou d)"
                : "«\(resto)» non é unha calidade de intervalo (J, M, m, A ou d)"
        case .intervaloInexistente(let numero, let calidad):
            if numero == 1, case .disminuida = calidad {
                return "non existe o unísono diminuído: de Do a Do♭ hai un unísono aumentado "
                    + "descendente (escríbeo -1A)"
            }
            let clase = (numero - 1) % 7
            let regla = [0, 3, 4].contains(clase)
                ? "o unísono, a 4ª, a 5ª e a 8ª son xustas, aumentadas ou diminuídas"
                : "a 2ª, a 3ª, a 6ª e a 7ª son maiores, menores, aumentadas ou diminuídas"
            return "non existe a \(numero)ª \(calidad.nombre(en: .gallego)): \(regla)"
        case .simboloNoReconocido(let simbolo):
            return "«\(simbolo)» non forma parte de ningún cifrado coñecido"
        case .tensionNoValida(let tension):
            return "«\(tension)» non é unha tensión válida (admítense ♭/♯ con 5, 9, 11 e 13, "
                + "e add con 2, 4, 6, 9, 11 e 13)"
        case .numeroDeAcordeNoValido(let numero):
            return "«\(numero)» non é un número de acorde (5, 6, 7, 9, 11 ou 13)"
        case .numeroRepetido(let numero):
            return "«\(numero)» aparece despois doutro número; as tensións adicionais "
                + "van entre parénteses, como en 7(9)"
        case .calidadesIncompatibles(.disminuidoYSemidisminuido):
            return "diminuído (°) e semidiminuído (ø) non se poden combinar"
        case .calidadesIncompatibles(.quintaConCalidad):
            return "o acorde de quinta (5) non leva terceira, así que non admite m, °, ø nin +"
        case .gradoNoOmitible(let grado):
            return grado == 1 ? "non se pode omitir a fundamental"
                : "«omit\(grado)» non é válido (pódense omitir 3, 5, 7, 9, 11 e 13)"
        case .acordeNoInterpretable(let rechazo):
            switch rechazo {
            case .faltaLaFundamental: return "falta a fundamental"
            case .intervaloSinPapel(let intervalo):
                return "a \(intervalo.nombre(en: .gallego)) non ten papel nun acorde por terceiras"
            case .terceraMayorYMenor:
                return "ten terceira maior e menor á vez (a ♯9 escríbese como 9ª aumentada, non como 3ª menor)"
            case .variasSeptimas: return "ten máis dunha sétima"
            case .septimaDisminuidaFueraDelDisminuido:
                return "a sétima diminuída só aparece no acorde diminuído (con 3ª menor e 5ª diminuída)"
            case .noEsPorTerceras: return "non é un acorde por terceiras"
            }
        case .bajoNoValido(let bajo):
            return "«\(bajo)» non é un nome de nota para o baixo"
        case .idiomasMezclados(let nombre):
            return "«\(nombre)» está escrito noutro idioma que a fundamental: "
                + "escríbese todo con sílabas (Sol7/Si) ou todo con letras (G7/B)"
        case .duracionNoValida(let texto):
            return "«\(texto)» non é unha duración: agardábase unha figura (1, 2, 4, 8, 16…, con puntiños: 4.) "
                + "ou unha fracción de redonda (3/8, 1/12)"
        case .compasNoValido(let texto):
            return "«\(texto)» non é un compás: agardábase numerador/denominador co denominador "
                + "potencia de 2 (4/4, 6/8, 7/8), C ou ¢"
        case .vocesDistintas:
            return "todos os acordes teñen que ter o mesmo número de voces, e polo menos dúas"
        case .alteracionNoReconocida(let signo):
            return "«\(signo)» non é unha alteración (agardábase ♯, ♭, 𝄪, 𝄫, #, b, x ou ♮)"
        case .modoNoReconocido(let nombre):
            return "«\(nombre)» non é o modo dunha tonalidade: unha tonalidade é maior ou menor "
                + "(para os demais modos, usa Escala)"
        case .tipoDeEscalaNoReconocido(let nombre):
            return nombre.isEmpty ? "falta o tipo de escala (mayor, dórico, menor armónica…)"
                : "«\(nombre)» non é un tipo de escala coñecido"
        }
    }

    private var explicacionEnEuskera: String {
        switch motivo {
        case .textoVacio:
            return "testua hutsik dago"
        case .notaNoReconocida:
            return "nota-izen bat espero zen (Do, Re, Mi… edo C, D, E…)"
        case .caracteresSobrantes(let resto):
            return "«\(resto)» soberan dago"
        case .octavaNoValida(let resto):
            return resto.isEmpty ? "zortziduna falta da (adibidez, Do4)" : "«\(resto)» ez da zortzidun baliozkoa"
        case .numeroDeIntervaloNoValido(let resto):
            return resto.isEmpty ? "tartearen zenbakia falta da (adibidez, 3M)"
                : "«\(resto)» ez da tarte-zenbaki bat"
        case .calidadNoValida(let resto):
            return resto.isEmpty ? "tartearen kalitatea falta da (J, M, m, A edo d)"
                : "«\(resto)» ez da tarte-kalitate bat (J, M, m, A edo d)"
        case .intervaloInexistente(let numero, let calidad):
            if numero == 1, case .disminuida = calidad {
                return "unisono gutxitua ez da existitzen: Do-tik Do♭-ra beheranzko unisono gehitua dago "
                    + "(idatzi -1A)"
            }
            let clase = (numero - 1) % 7
            let regla = [0, 3, 4].contains(clase)
                ? "unisonoa, 4.a, 5.a eta 8.a justuak, gehituak edo gutxituak dira"
                : "2.a, 3.a, 6.a eta 7.a handiak, txikiak, gehituak edo gutxituak dira"
            return "\(numero). \(calidad.nombre(en: .euskera)) ez da existitzen: \(regla)"
        case .simboloNoReconocido(let simbolo):
            return "«\(simbolo)» ez dago zifratu ezagunetan"
        case .tensionNoValida(let tension):
            return "«\(tension)» ez da tentsio baliozkoa (♭/♯ 5, 9, 11 eta 13rekin onartzen dira, "
                + "eta add 2, 4, 6, 9, 11 eta 13rekin)"
        case .numeroDeAcordeNoValido(let numero):
            return "«\(numero)» ez da akorde-zenbaki bat (5, 6, 7, 9, 11 edo 13)"
        case .numeroRepetido(let numero):
            return "«\(numero)» beste zenbaki baten ondoren dago; tentsio gehigarriak "
                + "parentesi artean doaz, 7(9)-n bezala"
        case .calidadesIncompatibles(.disminuidoYSemidisminuido):
            return "gutxitua (°) eta erdi-gutxitua (ø) ezin dira batera erabili"
        case .calidadesIncompatibles(.quintaConCalidad):
            return "bosgarren akordeak (5) ez du hirugarrenik, beraz ez ditu m, °, ø eta + onartzen"
        case .gradoNoOmitible(let grado):
            return grado == 1 ? "oinarria ezin da kendu"
                : "«omit\(grado)» ez da baliozkoa (3, 5, 7, 9, 11 eta 13 ken daitezke)"
        case .acordeNoInterpretable(let rechazo):
            switch rechazo {
            case .faltaLaFundamental: return "oinarria falta da"
            case .intervaloSinPapel(let intervalo):
                return "\(intervalo.nombre(en: .euskera)): tarte honek ez du paperik hirugarrenez osatutako akorde batean"
            case .terceraMayorYMenor:
                return "hirugarren handia eta txikia ditu aldi berean (♯9 9. gehitu gisa idazten da, ez 3. txiki gisa)"
            case .variasSeptimas: return "zazpigarren bat baino gehiago ditu"
            case .septimaDisminuidaFueraDelDisminuido:
                return "zazpigarren gutxitua akorde gutxituan bakarrik agertzen da (3. txikiarekin eta 5. gutxituarekin)"
            case .noEsPorTerceras: return "ez da hirugarrenez osatutako akordea"
            }
        case .bajoNoValido(let bajo):
            return "«\(bajo)» ez da baxurako nota-izen bat"
        case .idiomasMezclados(let nombre):
            return "«\(nombre)» oinarria ez bezalako hizkuntzan idatzita dago: "
                + "idatzi dena silabekin (Sol7/Si) edo dena letrekin (G7/B)"
        case .duracionNoValida(let texto):
            return "«\(texto)» ez da iraupen bat: figura bat espero zen (1, 2, 4, 8, 16…, puntuekin: 4.) "
                + "edo biribilaren zatiki bat (3/8, 1/12)"
        case .compasNoValido(let texto):
            return "«\(texto)» ez da konpas bat: zenbakitzailea/izendatzailea espero zen, izendatzailea "
                + "2ren berretura izanik (4/4, 6/8, 7/8), C edo ¢"
        case .vocesDistintas:
            return "akorde guztiek ahots kopuru bera izan behar dute, eta gutxienez bi"
        case .alteracionNoReconocida(let signo):
            return "«\(signo)» ez da alterazio bat (♯, ♭, 𝄪, 𝄫, #, b, x edo ♮ espero zen)"
        case .modoNoReconocido(let nombre):
            return "«\(nombre)» ez da tonalitate baten modua: tonalitatea maiorra edo minorra da "
                + "(beste moduetarako, erabili Escala)"
        case .tipoDeEscalaNoReconocido(let nombre):
            return nombre.isEmpty ? "eskala-mota falta da (mayor, dórico, menor armónica…)"
                : "«\(nombre)» ez da eskala-mota ezagun bat"
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
