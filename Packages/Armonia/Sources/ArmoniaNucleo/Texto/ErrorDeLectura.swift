import Foundation

/// Error al leer un texto: un nombre de nota, una nota, un intervalo, un cifrado o una escala.
///
/// Indica el texto, el carácter donde se detuvo la lectura y el motivo, en los ocho idiomas de los
/// textos (`Traduccion`):
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

    /// Explicación del motivo en el idioma de los textos de la notación: en inglés para el alemán
    /// (`notacion.idiomaDeLosTextos`).
    public func explicacion(en notacion: Notacion) -> String {
        explicacionTraducida(notacion).en(notacion)
    }

    /// Mensaje completo, en español: «No se puede leer «Do7(b3)» (carácter 5): …».
    public var description: String { descripcion(en: .espanol) }

    /// Mensaje completo en el idioma de los textos de la notación.
    public func descripcion(en notacion: Notacion) -> String {
        var inicio = texto.isEmpty
            ? Traduccion("Valor no válido", "Invalid value",
                         ca: "Valor no vàlid", gl: "Valor non válido", eu: "Balio baliogabea",
                         pt: "Valor inválido", fr: "Valeur non valide", it: "Valore non valido").en(notacion)
            : Traduccion("No se puede leer «\(texto)»", "Cannot read \"\(texto)\"",
                         ca: "No es pot llegir «\(texto)»", gl: "Non se pode ler «\(texto)»",
                         eu: "Ezin da «\(texto)» irakurri",
                         pt: "Não é possível ler «\(texto)»", fr: "Impossible de lire « \(texto) »", it: "Impossibile leggere «\(texto)»").en(notacion)
        if let p = posicion {
            inicio += Traduccion(" (carácter \(p + 1))", " (character \(p + 1))",
                                 ca: " (caràcter \(p + 1))", gl: " (carácter \(p + 1))",
                                 eu: " (\(p + 1). karakterea)",
                                 pt: " (caractere \(p + 1))", fr: " (caractère \(p + 1))", it: " (carattere \(p + 1))").en(notacion)
        }
        // En francés, los dos puntos llevan espacio delante.
        return inicio + (notacion.idiomaDeLosTextos == .frances ? " : " : ": ") + explicacion(en: notacion)
    }

    /// La explicación en los ocho idiomas de los textos. La notación solo hace falta para los
    /// nombres de calidades e intervalos en inglés, que siguen su vocabulario.
    private func explicacionTraducida(_ notacion: Notacion) -> Traduccion {
        switch motivo {
        case .textoVacio:
            return Traduccion("el texto está vacío",
                              "the text is empty",
                              ca: "el text és buit",
                              gl: "o texto está baleiro",
                              eu: "testua hutsik dago",
                              pt: "o texto está vazio",
                              fr: "le texte est vide",
                              it: "il testo è vuoto")
        case .notaNoReconocida:
            return Traduccion("se esperaba un nombre de nota (Do, Re, Mi… o C, D, E…)",
                              "expected a note name (C, D, E… or Do, Re, Mi…)",
                              ca: "s'esperava un nom de nota (Do, Re, Mi… o C, D, E…)",
                              gl: "agardábase un nome de nota (Do, Re, Mi… ou C, D, E…)",
                              eu: "nota-izen bat espero zen (Do, Re, Mi… edo C, D, E…)",
                              pt: "esperava-se um nome de nota (Do, Re, Mi… ou C, D, E…)",
                              fr: "un nom de note était attendu (Do, Ré, Mi… ou C, D, E…)",
                              it: "si aspettava un nome di nota (Do, Re, Mi… o C, D, E…)")
        case .caracteresSobrantes(let resto):
            return Traduccion("sobra «\(resto)»",
                              "unexpected \"\(resto)\"",
                              ca: "sobra «\(resto)»",
                              gl: "sobra «\(resto)»",
                              eu: "«\(resto)» soberan dago",
                              pt: "sobra «\(resto)»",
                              fr: "« \(resto) » est en trop",
                              it: "«\(resto)» è di troppo")
        case .octavaNoValida(let resto):
            return resto.isEmpty
                ? Traduccion("falta la octava (por ejemplo, Do4)",
                             "the octave is missing (for example, C4)",
                             ca: "falta l'octava (per exemple, Do4)",
                             gl: "falta a oitava (por exemplo, Do4)",
                             eu: "zortziduna falta da (adibidez, Do4)",
                             pt: "falta a oitava (por exemplo, Do4)",
                             fr: "il manque l'octave (par exemple, Do4)",
                             it: "manca l'ottava (per esempio, Do4)")
                : Traduccion("«\(resto)» no es una octava válida",
                             "\"\(resto)\" is not a valid octave",
                             ca: "«\(resto)» no és una octava vàlida",
                             gl: "«\(resto)» non é unha oitava válida",
                             eu: "«\(resto)» ez da zortzidun baliozkoa",
                             pt: "«\(resto)» não é uma oitava válida",
                             fr: "« \(resto) » n'est pas une octave valide",
                             it: "«\(resto)» non è un'ottava valida")
        case .numeroDeIntervaloNoValido(let resto):
            return resto.isEmpty
                ? Traduccion("falta el número del intervalo (por ejemplo, 3M)",
                             "the interval number is missing (for example, M3)",
                             ca: "falta el número de l'interval (per exemple, 3M)",
                             gl: "falta o número do intervalo (por exemplo, 3M)",
                             eu: "tartearen zenbakia falta da (adibidez, 3M)",
                             pt: "falta o número do intervalo (por exemplo, 3M)",
                             fr: "il manque le numéro de l'intervalle (par exemple, 3M)",
                             it: "manca il numero dell'intervallo (per esempio, 3M)")
                : Traduccion("«\(resto)» no es un número de intervalo",
                             "\"\(resto)\" is not an interval number",
                             ca: "«\(resto)» no és un número d'interval",
                             gl: "«\(resto)» non é un número de intervalo",
                             eu: "«\(resto)» ez da tarte-zenbaki bat",
                             pt: "«\(resto)» não é um número de intervalo",
                             fr: "« \(resto) » n'est pas un numéro d'intervalle",
                             it: "«\(resto)» non è un numero di intervallo")
        case .calidadNoValida(let resto):
            return resto.isEmpty
                ? Traduccion("falta la calidad del intervalo (J, M, m, A o d)",
                             "the interval quality is missing (P, M, m, A or d)",
                             ca: "falta la qualitat de l'interval (J, M, m, A o d)",
                             gl: "falta a calidade do intervalo (J, M, m, A ou d)",
                             eu: "tartearen kalitatea falta da (J, M, m, A edo d)",
                             pt: "falta a qualidade do intervalo (J, M, m, A ou d)",
                             fr: "il manque la qualité de l'intervalle (J, M, m, A ou d)",
                             it: "manca la specie dell'intervallo (J, M, m, A o d)")
                : Traduccion("«\(resto)» no es una calidad de intervalo (J, M, m, A o d)",
                             "\"\(resto)\" is not an interval quality (P, M, m, A or d)",
                             ca: "«\(resto)» no és una qualitat d'interval (J, M, m, A o d)",
                             gl: "«\(resto)» non é unha calidade de intervalo (J, M, m, A ou d)",
                             eu: "«\(resto)» ez da tarte-kalitate bat (J, M, m, A edo d)",
                             pt: "«\(resto)» não é uma qualidade de intervalo (J, M, m, A ou d)",
                             fr: "« \(resto) » n'est pas une qualité d'intervalle (J, M, m, A ou d)",
                             it: "«\(resto)» non è una specie di intervallo (J, M, m, A o d)")
        case .intervaloInexistente(let numero, let calidad):
            if numero == 1, case .disminuida = calidad {
                return Traduccion("no existe el unísono disminuido: de Do a Do♭ hay un unísono aumentado descendente (escríbelo -1A)",
                                  "there is no diminished unison: from C to C♭ is a descending augmented unison (write it -A1)",
                                  ca: "no existeix l'uníson disminuït: de Do a Do♭ hi ha un uníson augmentat descendent (escriu-lo -1A)",
                                  gl: "non existe o unísono diminuído: de Do a Do♭ hai un unísono aumentado descendente (escríbeo -1A)",
                                  eu: "unisono gutxitua ez da existitzen: Do-tik Do♭-ra beheranzko unisono gehitua dago (idatzi -1A)",
                                  pt: "não existe o uníssono diminuto: de Dó a Dó♭ há um uníssono aumentado descendente (escreva -1A)",
                                  fr: "l'unisson diminué n'existe pas : de do à do♭, il y a un unisson augmenté descendant (écrivez -1A)",
                                  it: "l'unisono diminuito non esiste: da Do a Do♭ c'è un unisono aumentato discendente (scrivilo -1A)")
            }
            let clase = (numero - 1) % 7
            let regla = [0, 3, 4].contains(clase)
                ? Traduccion("el unísono, la 4ª, la 5ª y la 8ª son justas, aumentadas o disminuidas",
                             "unisons, 4ths, 5ths and octaves are perfect, augmented or diminished",
                             ca: "l'uníson, la 4a, la 5a i la 8a són justes, augmentades o disminuïdes",
                             gl: "o unísono, a 4ª, a 5ª e a 8ª son xustas, aumentadas ou diminuídas",
                             eu: "unisonoa, 4.a, 5.a eta 8.a justuak, gehituak edo gutxituak dira",
                             pt: "o uníssono, a 4ª, a 5ª e a 8ª são justas, aumentadas ou diminutas",
                             fr: "l'unisson, la quarte, la quinte et l'octave sont justes, augmentées ou diminuées",
                             it: "l'unisono, la 4ª, la 5ª e l'8ª sono giuste, aumentate o diminuite")
                : Traduccion("la 2ª, la 3ª, la 6ª y la 7ª son mayores, menores, aumentadas o disminuidas",
                             "2nds, 3rds, 6ths and 7ths are major, minor, augmented or diminished",
                             ca: "la 2a, la 3a, la 6a i la 7a són majors, menors, augmentades o disminuïdes",
                             gl: "a 2ª, a 3ª, a 6ª e a 7ª son maiores, menores, aumentadas ou diminuídas",
                             eu: "2.a, 3.a, 6.a eta 7.a handiak, txikiak, gehituak edo gutxituak dira",
                             pt: "a 2ª, a 3ª, a 6ª e a 7ª são maiores, menores, aumentadas ou diminutas",
                             fr: "la seconde, la tierce, la sixte et la septième sont majeures, mineures, augmentées ou diminuées",
                             it: "la 2ª, la 3ª, la 6ª e la 7ª sono maggiori, minori, aumentate o diminuite")
            return Traduccion("no existe la \(numero)ª \(calidad.nombre): \(regla.espanol)",
                              "there is no \(calidad.nombre(en: notacion)) \(ErrorDeLectura.ordinalIngles(numero)): \(regla.ingles)",
                              ca: "no existeix la \(numero)a \(calidad.nombre(en: .catalan)): \(regla.catalan)",
                              gl: "non existe a \(numero)ª \(calidad.nombre(en: .gallego)): \(regla.gallego)",
                              eu: "\(numero). \(calidad.nombre(en: .euskera)) ez da existitzen: \(regla.euskera)",
                              pt: "não existe a \(numero)ª \(calidad.nombre(en: .portugues)): \(regla.portugues)",
                              fr: "il n'existe pas de \(numero)e \(calidad.nombre(en: .frances)) : \(regla.frances)",
                              it: "non esiste la \(numero)ª \(calidad.nombre(en: .italiano)): \(regla.italiano)")
        case .simboloNoReconocido(let simbolo):
            return Traduccion("«\(simbolo)» no forma parte de ningún cifrado conocido",
                              "\"\(simbolo)\" is not part of any known chord symbol",
                              ca: "«\(simbolo)» no forma part de cap xifrat conegut",
                              gl: "«\(simbolo)» non forma parte de ningún cifrado coñecido",
                              eu: "«\(simbolo)» ez dago zifratu ezagunetan",
                              pt: "«\(simbolo)» não faz parte de nenhuma cifra conhecida",
                              fr: "« \(simbolo) » ne fait partie d'aucun chiffrage connu",
                              it: "«\(simbolo)» non fa parte di nessuna sigla conosciuta")
        case .tensionNoValida(let tension):
            return Traduccion("«\(tension)» no es una tensión válida (se admiten ♭/♯ con 5, 9, 11 y 13, y add con 2, 4, 6, 9, 11 y 13)",
                              "\"\(tension)\" is not a valid tension (♭/♯ go with 5, 9, 11 and 13, and add with 2, 4, 6, 9, 11 and 13)",
                              ca: "«\(tension)» no és una tensió vàlida (s'admeten ♭/♯ amb 5, 9, 11 i 13, i add amb 2, 4, 6, 9, 11 i 13)",
                              gl: "«\(tension)» non é unha tensión válida (admítense ♭/♯ con 5, 9, 11 e 13, e add con 2, 4, 6, 9, 11 e 13)",
                              eu: "«\(tension)» ez da tentsio baliozkoa (♭/♯ 5, 9, 11 eta 13rekin onartzen dira, eta add 2, 4, 6, 9, 11 eta 13rekin)",
                              pt: "«\(tension)» não é uma tensão válida (admitem-se ♭/♯ com 5, 9, 11 e 13, e add com 2, 4, 6, 9, 11 e 13)",
                              fr: "« \(tension) » n'est pas une tension valide (♭/♯ s'emploient avec 5, 9, 11 et 13, et add avec 2, 4, 6, 9, 11 et 13)",
                              it: "«\(tension)» non è una tensione valida (si ammettono ♭/♯ con 5, 9, 11 e 13, e add con 2, 4, 6, 9, 11 e 13)")
        case .numeroDeAcordeNoValido(let numero):
            return Traduccion("«\(numero)» no es un número de acorde (5, 6, 7, 9, 11 o 13)",
                              "\"\(numero)\" is not a chord number (5, 6, 7, 9, 11 or 13)",
                              ca: "«\(numero)» no és un número d'acord (5, 6, 7, 9, 11 o 13)",
                              gl: "«\(numero)» non é un número de acorde (5, 6, 7, 9, 11 ou 13)",
                              eu: "«\(numero)» ez da akorde-zenbaki bat (5, 6, 7, 9, 11 edo 13)",
                              pt: "«\(numero)» não é um número de acorde (5, 6, 7, 9, 11 ou 13)",
                              fr: "« \(numero) » n'est pas un numéro d'accord (5, 6, 7, 9, 11 ou 13)",
                              it: "«\(numero)» non è un numero di accordo (5, 6, 7, 9, 11 o 13)")
        case .numeroRepetido(let numero):
            return Traduccion("«\(numero)» aparece después de otro número; las tensiones adicionales van entre paréntesis, como en 7(9)",
                              "\"\(numero)\" comes after another number; additional tensions go in parentheses, as in 7(9)",
                              ca: "«\(numero)» apareix després d'un altre número; les tensions addicionals van entre parèntesis, com a 7(9)",
                              gl: "«\(numero)» aparece despois doutro número; as tensións adicionais van entre parénteses, como en 7(9)",
                              eu: "«\(numero)» beste zenbaki baten ondoren dago; tentsio gehigarriak parentesi artean doaz, 7(9)-n bezala",
                              pt: "«\(numero)» aparece depois de outro número; as tensões adicionais vão entre parênteses, como em 7(9)",
                              fr: "« \(numero) » suit un autre numéro ; les tensions supplémentaires se mettent entre parenthèses, comme dans 7(9)",
                              it: "«\(numero)» compare dopo un altro numero; le tensioni aggiuntive vanno tra parentesi, come in 7(9)")
        case .calidadesIncompatibles(.disminuidoYSemidisminuido):
            return Traduccion("disminuido (°) y semidisminuido (ø) no pueden combinarse",
                              "diminished (°) and half-diminished (ø) cannot be combined",
                              ca: "disminuït (°) i semidisminuït (ø) no es poden combinar",
                              gl: "diminuído (°) e semidiminuído (ø) non se poden combinar",
                              eu: "gutxitua (°) eta erdi-gutxitua (ø) ezin dira batera erabili",
                              pt: "diminuto (°) e meio-diminuto (ø) não podem ser combinados",
                              fr: "diminué (°) et semi-diminué (ø) ne peuvent pas se combiner",
                              it: "diminuito (°) e semidiminuito (ø) non si possono combinare")
        case .calidadesIncompatibles(.quintaConCalidad):
            return Traduccion("el acorde de quinta (5) no lleva tercera, así que no admite m, °, ø ni +",
                              "a power chord (5) has no third, so it cannot take m, °, ø or +",
                              ca: "l'acord de quinta (5) no porta tercera, així que no admet m, °, ø ni +",
                              gl: "o acorde de quinta (5) non leva terceira, así que non admite m, °, ø nin +",
                              eu: "bosgarren akordeak (5) ez du hirugarrenik, beraz ez ditu m, °, ø eta + onartzen",
                              pt: "o acorde de quinta (5) não tem terceira, por isso não admite m, °, ø nem +",
                              fr: "l'accord de quinte (5) n'a pas de tierce, il n'admet donc ni m, ni °, ni ø, ni +",
                              it: "l'accordo di quinta (5) non ha la terza, quindi non ammette m, °, ø né +")
        case .gradoNoOmitible(let grado):
            return grado == 1
                ? Traduccion("no se puede omitir la fundamental",
                             "the root cannot be omitted",
                             ca: "no es pot ometre la fonamental",
                             gl: "non se pode omitir a fundamental",
                             eu: "oinarria ezin da kendu",
                             pt: "não se pode omitir a fundamental",
                             fr: "on ne peut pas omettre la fondamentale",
                             it: "non si può omettere la fondamentale")
                : Traduccion("«omit\(grado)» no es válido (se pueden omitir 3, 5, 7, 9, 11 y 13)",
                             "\"omit\(grado)\" is not valid (3, 5, 7, 9, 11 and 13 can be omitted)",
                             ca: "«omit\(grado)» no és vàlid (es poden ometre 3, 5, 7, 9, 11 i 13)",
                             gl: "«omit\(grado)» non é válido (pódense omitir 3, 5, 7, 9, 11 e 13)",
                             eu: "«omit\(grado)» ez da baliozkoa (3, 5, 7, 9, 11 eta 13 ken daitezke)",
                             pt: "«omit\(grado)» não é válido (podem omitir-se 3, 5, 7, 9, 11 e 13)",
                             fr: "« omit\(grado) » n'est pas valide (on peut omettre 3, 5, 7, 9, 11 et 13)",
                             it: "«omit\(grado)» non è valido (si possono omettere 3, 5, 7, 9, 11 e 13)")
        case .acordeNoInterpretable(let rechazo):
            switch rechazo {
            case .faltaLaFundamental:
                return Traduccion("falta la fundamental",
                                  "the root is missing",
                                  ca: "falta la fonamental",
                                  gl: "falta a fundamental",
                                  eu: "oinarria falta da",
                                  pt: "falta a fundamental",
                                  fr: "il manque la fondamentale",
                                  it: "manca la fondamentale")
            case .intervaloSinPapel(let intervalo):
                return Traduccion("la \(intervalo.nombre) no tiene papel en un acorde por terceras",
                                  "the \(intervalo.nombre(en: notacion)) has no role in a tertian chord",
                                  ca: "la \(intervalo.nombre(en: .catalan)) no té cap paper en un acord per terceres",
                                  gl: "a \(intervalo.nombre(en: .gallego)) non ten papel nun acorde por terceiras",
                                  eu: "\(intervalo.nombre(en: .euskera)): tarte honek ez du paperik hirugarrenez osatutako akorde batean",
                                  pt: "a \(intervalo.nombre(en: .portugues)) não tem papel num acorde por terceiras",
                                  fr: "l'intervalle de \(intervalo.nombre(en: .frances)) n'a aucun rôle dans un accord par tierces",
                                  it: "l'intervallo di \(intervalo.nombre(en: .italiano)) non ha un ruolo in un accordo per terze")
            case .terceraMayorYMenor:
                return Traduccion("tiene tercera mayor y menor a la vez (la ♯9 se escribe como 9ª aumentada, no como 3ª menor)",
                                  "it has both a major and a minor third (♯9 is written as an augmented 9th, not a minor 3rd)",
                                  ca: "té tercera major i menor alhora (la ♯9 s'escriu com a 9a augmentada, no com a 3a menor)",
                                  gl: "ten terceira maior e menor á vez (a ♯9 escríbese como 9ª aumentada, non como 3ª menor)",
                                  eu: "hirugarren handia eta txikia ditu aldi berean (♯9 9. gehitu gisa idazten da, ez 3. txiki gisa)",
                                  pt: "tem terceira maior e menor ao mesmo tempo (a ♯9 escreve-se como 9ª aumentada, não como 3ª menor)",
                                  fr: "il a à la fois une tierce majeure et une tierce mineure (la ♯9 s'écrit comme neuvième augmentée, pas comme tierce mineure)",
                                  it: "ha insieme la terza maggiore e quella minore (la ♯9 si scrive come 9ª aumentata, non come 3ª minore)")
            case .variasSeptimas:
                return Traduccion("tiene más de una séptima",
                                  "it has more than one seventh",
                                  ca: "té més d'una sèptima",
                                  gl: "ten máis dunha sétima",
                                  eu: "zazpigarren bat baino gehiago ditu",
                                  pt: "tem mais de uma sétima",
                                  fr: "il a plus d'une septième",
                                  it: "ha più di una settima")
            case .septimaDisminuidaFueraDelDisminuido:
                return Traduccion("la séptima disminuida sólo aparece en el acorde disminuido (con 3ª menor y 5ª disminuida)",
                                  "the diminished seventh only appears in the diminished chord (with a minor 3rd and a diminished 5th)",
                                  ca: "la sèptima disminuïda només apareix a l'acord disminuït (amb 3a menor i 5a disminuïda)",
                                  gl: "a sétima diminuída só aparece no acorde diminuído (con 3ª menor e 5ª diminuída)",
                                  eu: "zazpigarren gutxitua akorde gutxituan bakarrik agertzen da (3. txikiarekin eta 5. gutxituarekin)",
                                  pt: "a sétima diminuta só aparece no acorde diminuto (com 3ª menor e 5ª diminuta)",
                                  fr: "la septième diminuée n'apparaît que dans l'accord diminué (avec tierce mineure et quinte diminuée)",
                                  it: "la settima diminuita compare solo nell'accordo diminuito (con 3ª minore e 5ª diminuita)")
            case .noEsPorTerceras:
                return Traduccion("no es un acorde por terceras",
                                  "it is not a tertian chord",
                                  ca: "no és un acord per terceres",
                                  gl: "non é un acorde por terceiras",
                                  eu: "ez da hirugarrenez osatutako akordea",
                                  pt: "não é um acorde por terceiras",
                                  fr: "ce n'est pas un accord par tierces",
                                  it: "non è un accordo per terze")
            }
        case .bajoNoValido(let bajo):
            return Traduccion("«\(bajo)» no es un nombre de nota para el bajo",
                              "\"\(bajo)\" is not a note name for the bass",
                              ca: "«\(bajo)» no és un nom de nota per al baix",
                              gl: "«\(bajo)» non é un nome de nota para o baixo",
                              eu: "«\(bajo)» ez da baxurako nota-izen bat",
                              pt: "«\(bajo)» não é um nome de nota para o baixo",
                              fr: "« \(bajo) » n'est pas un nom de note pour la basse",
                              it: "«\(bajo)» non è un nome di nota per il basso")
        case .idiomasMezclados(let nombre):
            return Traduccion("«\(nombre)» está escrito en otro idioma que la fundamental: se escribe todo en español (Sol7/Si) o todo con letras (G7/B)",
                              "\"\(nombre)\" is written in a different language from the root: write everything with letters (G7/B) or everything in Spanish (Sol7/Si)",
                              ca: "«\(nombre)» està escrit en un altre idioma que la fonamental: s'escriu tot amb síl·labes (Sol7/Si) o tot amb lletres (G7/B)",
                              gl: "«\(nombre)» está escrito noutro idioma que a fundamental: escríbese todo con sílabas (Sol7/Si) ou todo con letras (G7/B)",
                              eu: "«\(nombre)» oinarria ez bezalako hizkuntzan idatzita dago: idatzi dena silabekin (Sol7/Si) edo dena letrekin (G7/B)",
                              pt: "«\(nombre)» está escrito noutro idioma que a fundamental: escreve-se tudo com sílabas (Sol7/Si) ou tudo com letras (G7/B)",
                              fr: "« \(nombre) » est écrit dans une autre langue que la fondamentale : on écrit tout en syllabes (Sol7/Si) ou tout en lettres (G7/B)",
                              it: "«\(nombre)» è scritto in un'altra lingua rispetto alla fondamentale: si scrive tutto in sillabe (Sol7/Si) o tutto in lettere (G7/B)")
        case .duracionNoValida(let texto):
            return Traduccion("«\(texto)» no es una duración: se esperaba una figura (1, 2, 4, 8, 16…, con puntillos: 4.) o una fracción de redonda (3/8, 1/12)",
                              "\"\(texto)\" is not a duration: expected a note value (1, 2, 4, 8, 16…, dotted: 4.) or a fraction of a whole note (3/8, 1/12)",
                              ca: "«\(texto)» no és una durada: s'esperava una figura (1, 2, 4, 8, 16…, amb punts: 4.) o una fracció de rodona (3/8, 1/12)",
                              gl: "«\(texto)» non é unha duración: agardábase unha figura (1, 2, 4, 8, 16…, con puntiños: 4.) ou unha fracción de redonda (3/8, 1/12)",
                              eu: "«\(texto)» ez da iraupen bat: figura bat espero zen (1, 2, 4, 8, 16…, puntuekin: 4.) edo biribilaren zatiki bat (3/8, 1/12)",
                              pt: "«\(texto)» não é uma duração: esperava-se uma figura (1, 2, 4, 8, 16…, pontuada: 4.) ou uma fração de semibreve (3/8, 1/12)",
                              fr: "« \(texto) » n'est pas une durée : une figure était attendue (1, 2, 4, 8, 16…, pointée : 4.) ou une fraction de ronde (3/8, 1/12)",
                              it: "«\(texto)» non è una durata: si aspettava una figura (1, 2, 4, 8, 16…, puntata: 4.) o una frazione di semibreve (3/8, 1/12)")
        case .compasNoValido(let texto):
            return Traduccion("«\(texto)» no es un compás: se esperaba numerador/denominador con el denominador potencia de 2 (4/4, 6/8, 7/8), C o ¢",
                              "\"\(texto)\" is not a time signature: expected numerator/denominator with a power-of-2 denominator (4/4, 6/8, 7/8), C or ¢",
                              ca: "«\(texto)» no és un compàs: s'esperava numerador/denominador amb el denominador potència de 2 (4/4, 6/8, 7/8), C o ¢",
                              gl: "«\(texto)» non é un compás: agardábase numerador/denominador co denominador potencia de 2 (4/4, 6/8, 7/8), C ou ¢",
                              eu: "«\(texto)» ez da konpas bat: zenbakitzailea/izendatzailea espero zen, izendatzailea 2ren berretura izanik (4/4, 6/8, 7/8), C edo ¢",
                              pt: "«\(texto)» não é um compasso: esperava-se numerador/denominador com o denominador potência de 2 (4/4, 6/8, 7/8), C ou ¢",
                              fr: "« \(texto) » n'est pas une mesure : numérateur/dénominateur attendu, avec un dénominateur puissance de 2 (4/4, 6/8, 7/8), C ou ¢",
                              it: "«\(texto)» non è un tempo: si aspettava numeratore/denominatore con il denominatore potenza di 2 (4/4, 6/8, 7/8), C o ¢")
        case .vocesDistintas:
            return Traduccion("todos los acordes tienen que tener el mismo número de voces, y al menos dos",
                              "every chord must have the same number of voices, and at least two",
                              ca: "tots els acords han de tenir el mateix nombre de veus, i almenys dues",
                              gl: "todos os acordes teñen que ter o mesmo número de voces, e polo menos dúas",
                              eu: "akorde guztiek ahots kopuru bera izan behar dute, eta gutxienez bi",
                              pt: "todos os acordes têm de ter o mesmo número de vozes, e pelo menos duas",
                              fr: "tous les accords doivent avoir le même nombre de voix, et au moins deux",
                              it: "tutti gli accordi devono avere lo stesso numero di voci, e almeno due")
        case .alteracionNoReconocida(let signo):
            return Traduccion("«\(signo)» no es una alteración (se esperaba ♯, ♭, 𝄪, 𝄫, #, b, x o ♮)",
                              "\"\(signo)\" is not an accidental (expected ♯, ♭, 𝄪, 𝄫, #, b, x or ♮)",
                              ca: "«\(signo)» no és una alteració (s'esperava ♯, ♭, 𝄪, 𝄫, #, b, x o ♮)",
                              gl: "«\(signo)» non é unha alteración (agardábase ♯, ♭, 𝄪, 𝄫, #, b, x ou ♮)",
                              eu: "«\(signo)» ez da alterazio bat (♯, ♭, 𝄪, 𝄫, #, b, x edo ♮ espero zen)",
                              pt: "«\(signo)» não é uma alteração (esperava-se ♯, ♭, 𝄪, 𝄫, #, b, x ou ♮)",
                              fr: "« \(signo) » n'est pas une altération (♯, ♭, 𝄪, 𝄫, #, b, x ou ♮ attendu)",
                              it: "«\(signo)» non è un'alterazione (si aspettava ♯, ♭, 𝄪, 𝄫, #, b, x o ♮)")
        case .modoNoReconocido(let nombre):
            return Traduccion("«\(nombre)» no es el modo de una tonalidad: una tonalidad es mayor o menor (para los demás modos, usa Escala)",
                              "\"\(nombre)\" is not the mode of a key: a key is major or minor (for other modes, use Escala)",
                              ca: "«\(nombre)» no és el mode d'una tonalitat: una tonalitat és major o menor (per als altres modes, fes servir Escala)",
                              gl: "«\(nombre)» non é o modo dunha tonalidade: unha tonalidade é maior ou menor (para os demais modos, usa Escala)",
                              eu: "«\(nombre)» ez da tonalitate baten modua: tonalitatea maiorra edo minorra da (beste moduetarako, erabili Escala)",
                              pt: "«\(nombre)» não é o modo de uma tonalidade: uma tonalidade é maior ou menor (para os outros modos, use Escala)",
                              fr: "« \(nombre) » n'est pas le mode d'une tonalité : une tonalité est majeure ou mineure (pour les autres modes, utilisez Escala)",
                              it: "«\(nombre)» non è il modo di una tonalità: una tonalità è maggiore o minore (per gli altri modi, usa Escala)")
        case .tipoDeEscalaNoReconocido(let nombre):
            return nombre.isEmpty
                ? Traduccion("falta el tipo de escala (mayor, dórico, menor armónica…)",
                             "the scale type is missing (major, dorian, harmonic minor…)",
                             ca: "falta el tipus d'escala (mayor, dórico, menor armónica…)",
                             gl: "falta o tipo de escala (mayor, dórico, menor armónica…)",
                             eu: "eskala-mota falta da (mayor, dórico, menor armónica…)",
                             pt: "falta o tipo de escala (maior, dórico, menor harmónica…)",
                             fr: "il manque le type de gamme (majeur, dorien, mineur harmonique…)",
                             it: "manca il tipo di scala (maggiore, dorica, minore armonica…)")
                : Traduccion("«\(nombre)» no es un tipo de escala conocido",
                             "\"\(nombre)\" is not a known scale type",
                             ca: "«\(nombre)» no és un tipus d'escala conegut",
                             gl: "«\(nombre)» non é un tipo de escala coñecido",
                             eu: "«\(nombre)» ez da eskala-mota ezagun bat",
                             pt: "«\(nombre)» não é um tipo de escala conhecido",
                             fr: "« \(nombre) » n'est pas un type de gamme connu",
                             it: "«\(nombre)» non è un tipo di scala conosciuto")
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
