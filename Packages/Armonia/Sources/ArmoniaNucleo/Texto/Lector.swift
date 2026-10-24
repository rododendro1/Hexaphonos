// Lector común de texto para todos los tipos que se leen desde un `String`.
//
// Avanza sobre el texto y sabe en qué carácter está, así que cualquier error que lance
// lleva la posición correcta sin cálculos aparte. Es un valor: copiarlo permite probar una
// lectura y volver atrás (por ejemplo, leer "Faug" primero como Fa y después como F).

package struct Lector {
    /// Texto completo (para los mensajes de error).
    package let texto: String
    /// Lo que queda por leer; siempre es un fragmento de `texto`.
    package var resto: Substring

    package init(_ texto: String) {
        self.texto = texto
        self.resto = Substring(texto)
    }

    /// Lector sobre un fragmento ya separado de `texto` (las posiciones siguen contando desde el principio).
    package init(texto: String, fragmento: Substring) {
        self.texto = texto
        self.resto = fragmento
    }

    // MARK: Estado

    /// Carácter actual, contando desde 0.
    package var posicion: Int { resto.posicionEnOrigen }
    package var haTerminado: Bool { resto.isEmpty }
    package var siguiente: Character? { resto.first }
    /// Lo que queda, sin espacios a los lados (para citarlo o interpretarlo entero).
    package var restoSinEspacios: String { String(resto).trimmingEspacios() }
    /// Lo que queda hasta el siguiente separador (para citarlo en un error).
    package var fragmento: String { resto.fragmentoParaError }

    // MARK: Avance

    package mutating func saltarEspacios() { resto = resto.sinEspaciosIniciales() }

    /// Consume `prefijo` si el texto sigue con él.
    package mutating func consumir(_ prefijo: String) -> Bool {
        guard resto.hasPrefix(prefijo) else { return false }
        resto = resto.dropFirst(prefijo.count)
        return true
    }

    /// Consume caracteres mientras cumplan la condición y los devuelve.
    package mutating func leer(mientras condicion: (Character) -> Bool) -> String {
        let leido = resto.prefix(while: condicion)
        resto = resto.dropFirst(leido.count)
        return String(leido)
    }

    /// Lee un entero sin signo (sólo cifras ASCII).
    package mutating func leerEntero() -> Int? {
        let cifras = resto.prefix(while: { $0.isASCII && $0.isNumber })
        guard let n = Int(cifras) else { return nil }
        resto = resto.dropFirst(cifras.count)
        return n
    }

    /// Salta los espacios iniciales y lanza `.textoVacio` si no queda nada.
    package mutating func exigirContenido() throws {
        saltarEspacios()
        guard !haTerminado else { throw error(.textoVacio, posicion: 0) }
    }

    // MARK: Nombres de nota

    /// Lee un nombre de nota ("Do", "fa#", "Sib", "Mi♭♭", "Rex", "C#", "Bb") y lo consume.
    /// Con `espanol: false` sólo se aceptan letras (C, D, E…): sirve para desambiguar textos
    /// como "Faug", que en español empezaría por "Fa".
    package mutating func leerNombreNota(espanol: Bool = true) -> Nota? {
        leerNombreNotaConIdioma(espanol: espanol)?.nota
    }

    /// Como `leerNombreNota(espanol:)`, diciendo además cómo estaba escrito: `.espanol` ("Re")
    /// o `.ingles` (con letras, "D"). Sirve para no mezclar idiomas en un mismo texto: la
    /// tónica en español va con el tipo de escala en español, y el bajo de un acorde se
    /// escribe como su fundamental.
    package mutating func leerNombreNotaConIdioma(espanol: Bool = true) -> (nota: Nota, idioma: Idioma)? {
        var copia = self
        copia.saltarEspacios()
        let minusculas = copia.resto.lowercased()
        let nombresEspanoles: [(String, NotaNatural)] = [
            ("sol", .sol), ("do", .do), ("re", .re), ("mi", .mi), ("fa", .fa), ("la", .la), ("si", .si),
        ]
        var letraLeida: NotaNatural?
        var idioma = Idioma.espanol
        for (prefijo, l) in nombresEspanoles where espanol && minusculas.hasPrefix(prefijo) {
            letraLeida = l
            copia.resto = copia.resto.dropFirst(prefijo.count)
            break
        }
        if letraLeida == nil, let c = copia.siguiente {
            let internacional: [Character: NotaNatural] = [
                "C": .do, "D": .re, "E": .mi, "F": .fa, "G": .sol, "A": .la, "B": .si,
            ]
            if let l = internacional[c] {
                letraLeida = l
                idioma = .ingles
                copia.resto = copia.resto.dropFirst()
            }
        }
        guard let letra = letraLeida else { return nil }

        var alteracion = 0
        bucle: while let c = copia.siguiente {
            switch c {
            case "#", "♯": alteracion += 1
            case "x", "𝄪": alteracion += 2
            case "b", "♭": alteracion -= 1
            case "𝄫": alteracion -= 2
            case "♮": break
            default: break bucle
            }
            copia.resto = copia.resto.dropFirst()
        }
        self = copia
        return (Nota(letra, Alteracion(alteracion)), idioma)
    }

    // MARK: Errores

    /// Error en la posición actual.
    package func error(_ motivo: ErrorDeLectura.Motivo) -> ErrorDeLectura {
        ErrorDeLectura(texto: texto, posicion: posicion, motivo: motivo)
    }

    /// Error en una posición concreta (`nil` si el problema no está en un punto del texto).
    package func error(_ motivo: ErrorDeLectura.Motivo, posicion: Int?) -> ErrorDeLectura {
        ErrorDeLectura(texto: texto, posicion: posicion, motivo: motivo)
    }
}

extension String {
    package func trimmingEspacios() -> String {
        String(drop(while: { $0 == " " }).reversed().drop(while: { $0 == " " }).reversed())
    }
}

extension String {
    /// Forma para comparar nombres escritos a mano: minúsculas, sin tildes ni diéresis (tampoco las
    /// griegas, ni la diéresis de la ё rusa),
    /// con guiones como espacios y un solo espacio entre palabras ("Sub-mediante" → "sub mediante").
    package var claveDeBusqueda: String {
        let sinTildes = lowercased().map { (c: Character) -> Character in
            switch c {
            case "á", "à": return "a"
            case "é", "è": return "e"
            case "í", "ì": return "i"
            case "ó", "ò": return "o"
            case "ú", "ù", "ü": return "u"
            case "ё": return "е"
            case "ά": return "α"
            case "έ": return "ε"
            case "ή": return "η"
            case "ί", "ϊ", "ΐ": return "ι"
            case "ό": return "ο"
            case "ύ", "ϋ", "ΰ": return "υ"
            case "ώ": return "ω"
            default: return c
            }
        }
        return String(sinTildes).split(whereSeparator: { $0 == " " || $0 == "-" }).joined(separator: " ")
    }
}

extension Substring {
    /// Posición (en caracteres) de este fragmento dentro del texto original.
    package var posicionEnOrigen: Int { base.distance(from: base.startIndex, to: startIndex) }

    /// El fragmento hasta el siguiente separador, para citarlo en un mensaje de error.
    package var fragmentoParaError: String {
        let separadores: Set<Character> = [" ", ",", "(", ")", "/"]
        let trozo = prefix(while: { !separadores.contains($0) })
        return trozo.isEmpty ? String(prefix(1)) : String(trozo)
    }

    package func sinEspaciosIniciales() -> Substring { drop(while: { $0 == " " }) }
}
