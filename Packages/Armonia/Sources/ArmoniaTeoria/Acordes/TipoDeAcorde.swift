import ArmoniaNucleo
// MARK: - TipoDeAcorde

/// Estructura de un acorde: el conjunto de desplazamientos en quintas de sus notas
/// respecto a la fundamental.
///
/// Dos tipos son iguales cuando contienen las mismas notas con la misma ortografía,
/// independientemente de cómo se hayan creado o escrito: `TipoDeAcorde("add2")`,
/// `TipoDeAcorde("add9")` y `TipoDeAcorde(intervalos: [.unisono, .terceraMayor, .quintaJusta,
/// .segundaMayor])` son el mismo tipo. El cifrado y la disposición se generan a partir
/// del conjunto.
public struct TipoDeAcorde: Sendable {
    /// Desplazamientos en quintas de cada nota respecto a la fundamental (incluye el 0).
    public let pasosDeQuinta: Set<Int>
    package let clasificacion: ClasificacionDeAcorde

    /// Crea un tipo a partir de desplazamientos en quintas. `nil` si no es un acorde
    /// terciano interpretable (por ejemplo, tercera mayor y menor a la vez).
    public init?(pasosDeQuinta: Set<Int>) {
        guard let clasificacion = ClasificacionDeAcorde(pasosDeQuinta) else { return nil }
        self.pasosDeQuinta = pasosDeQuinta
        self.clasificacion = clasificacion
    }

    /// Igual que `init?(pasosDeQuinta:)`, pero explica el motivo si el conjunto no es válido.
    public init(comprobandoPasosDeQuinta pasosDeQuinta: Set<Int>) throws {
        try self.init(comprobandoPasosDeQuinta: pasosDeQuinta, texto: "")
    }

    package init(comprobandoPasosDeQuinta pasosDeQuinta: Set<Int>, texto: String) throws {
        guard let clasificacion = ClasificacionDeAcorde(pasosDeQuinta) else {
            let rechazo = ClasificacionDeAcorde.motivoDeRechazo(pasosDeQuinta) ?? .noEsPorTerceras
            throw ErrorDeLectura(texto: texto, posicion: nil, motivo: .acordeNoInterpretable(rechazo))
        }
        self.pasosDeQuinta = pasosDeQuinta
        self.clasificacion = clasificacion
    }

    /// Crea un tipo a partir de intervalos desde la fundamental (las octavas no importan).
    public init?(intervalos: [Intervalo]) {
        self.init(pasosDeQuinta: Set(intervalos.map(\.pasosDeQuintaConSigno)).union([0]))
    }

    /// Lee un cifrado sin fundamental: "", "m", "7", "maj9", "m7(♭5)", "7(b9,#11)",
    /// "13sus4", "6/9", "(add9)", "7alt", "m11", "5", "°7", "ø", "Δ", "7(omit5)"…
    /// Si no se puede leer, el error indica dónde y por qué.
    public init(leyendo cifrado: String) throws {
        try self.init(lector: Lector(cifrado))
    }

    /// Lee el cifrado que queda en el lector (las posiciones de error se cuentan en su texto completo).
    package init(lector: Lector) throws {
        let conjunto = try ClasificacionDeAcorde.conjunto(desde: lector)
        try self.init(comprobandoPasosDeQuinta: conjunto, texto: lector.texto)
    }

    // MARK: Propiedades

    /// Intervalos desde la fundamental: notas del acorde dentro de la octava y
    /// tensiones (9ª, 11ª, 13ª) como intervalos compuestos.
    public var intervalos: [Intervalo] { clasificacion.intervalos }

    /// Cifrado del tipo, sin fundamental: "", "m", "°", "7", "maj7", "m7(♭5)", "9sus4",
    /// "7(♭9,♯11)", "m(add9)"…
    public var cifrado: String { clasificacion.simbolo }

    /// Cifrado en un estilo concreto: `TipoDeAcorde.semidisminuido.cifrado(estilo: .jazz)` → "ø7".
    public func cifrado(estilo: EstiloDeCifrado) -> String { clasificacion.simbolo(estilo: estilo) }

    /// Cifrado en el estilo básico de una notación: `.ingles` → "7(b9,#11)".
    public func cifrado(en notacion: Nomenclatura) -> String { cifrado(estilo: EstiloDeCifrado(notacion: notacion)) }

    /// Nombre en español si es un tipo conocido; si no, "acorde 7(♭9,♯11)".
    public var nombre: String { nombre(en: .espanol) }

    /// "séptima de dominante", "dominant seventh", "sèptima de dominant", "dominanteko zazpigarrena"
    /// si es un tipo conocido; si no, "acorde 7(♭9,♯11)", "7(b9,#11) chord", "7(♭9,♯11) akordea"…
    public func nombre(en notacion: Nomenclatura) -> String {
        if let conocido = TipoDeAcorde.nombresConocidos[pasosDeQuinta] { return conocido.en(notacion) }
        switch notacion.idioma {
        case .espanol, .portugues: return "acorde \(cifrado.isEmpty ? "mayor" : cifrado)"
        case .ingles, .aleman, .frances, .italiano: return "\(cifrado(en: notacion)) chord"
        case .catalan: return "acord \(cifrado.isEmpty ? "major" : cifrado)"
        case .gallego: return "acorde \(cifrado.isEmpty ? "maior" : cifrado)"
        case .euskera: return cifrado.isEmpty ? "akorde maiorra" : "\(cifrado) akordea"
        }
    }

    /// Sufijo para el cifrado romano (V7, viiø7, i(maj7), ii°…). La sexta añadida se escribe
    /// "(add6)", porque un 6 solo se leería como primera inversión: iii(add6), no iii6.
    public var sufijoRomano: String {
        if clasificacion.disminuido && clasificacion.septima == -2 && clasificacion.tensiones.isEmpty { return "ø7" }
        var s = cifrado
        if esMenor && s.hasPrefix("m") { s = String(s.dropFirst()) }
        return s == "6" ? "(add6)" : s
    }

    public var esMenor: Bool { pasosDeQuinta.contains(-3) }
    public var esMayor: Bool { pasosDeQuinta.contains(4) }
    public var tieneSeptima: Bool { clasificacion.septima != nil }

    /// Tensiones (9ª, 11ª, 13ª y sus alteraciones) como intervalos compuestos.
    public var tensiones: [Intervalo] {
        clasificacion.tensiones.sorted().map { Intervalo.simpleAscendente(pasosDeQuinta: $0) + .octava }
            .sorted { $0.pasos < $1.pasos }
    }

    // MARK: Transformaciones

    /// Añade una nota (en intervalo desde la fundamental), si el resultado es interpretable.
    public func anadir(_ intervalo: Intervalo) -> TipoDeAcorde? {
        TipoDeAcorde(pasosDeQuinta: pasosDeQuinta.union([intervalo.pasosDeQuintaConSigno]))
    }

    /// Quita una nota (en intervalo desde la fundamental).
    public func quitar(_ intervalo: Intervalo) -> TipoDeAcorde? {
        guard intervalo.pasosDeQuinta != 0 else { return nil }
        return TipoDeAcorde(pasosDeQuinta: pasosDeQuinta.subtracting([intervalo.pasosDeQuintaConSigno]))
    }

    // MARK: Tipos predefinidos

    private static func crear(_ intervalos: [Intervalo]) -> TipoDeAcorde {
        TipoDeAcorde(intervalos: intervalos)!
    }

    // Nombres: «tríada + lo añadido», de abajo arriba, con el calificativo detrás de lo que
    // califica (`mayorSeptimaMayor`). `dominante` es la tríada mayor con séptima menor, así que
    // `dominanteNovena` ya lleva la séptima; la undécima y la decimotercera llevan también la novena.

    // Tríadas y acordes de tres notas o menos
    public static let mayor = crear([.unisono, .terceraMayor, .quintaJusta])
    public static let menor = crear([.unisono, .terceraMenor, .quintaJusta])
    public static let disminuido = crear([.unisono, .terceraMenor, .quintaDisminuida])
    public static let aumentado = crear([.unisono, .terceraMayor, .quintaAumentada])
    public static let sus2 = crear([.unisono, .segundaMayor, .quintaJusta])
    public static let sus4 = crear([.unisono, .cuartaJusta, .quintaJusta])
    /// Acorde de potencia o de quinta («5»): fundamental y quinta, sin tercera.
    public static let potencia = crear([.unisono, .quintaJusta])

    // Cuatríadas
    public static let dominanteSeptima = crear([.unisono, .terceraMayor, .quintaJusta, .septimaMenor])
    public static let mayorSeptimaMayor = crear([.unisono, .terceraMayor, .quintaJusta, .septimaMayor])
    public static let menorSeptima = crear([.unisono, .terceraMenor, .quintaJusta, .septimaMenor])
    public static let menorSeptimaMayor = crear([.unisono, .terceraMenor, .quintaJusta, .septimaMayor])
    public static let semidisminuido = crear([.unisono, .terceraMenor, .quintaDisminuida, .septimaMenor])
    public static let disminuidoSeptima = crear([.unisono, .terceraMenor, .quintaDisminuida, .septimaDisminuida])
    public static let aumentadoSeptima = crear([.unisono, .terceraMayor, .quintaAumentada, .septimaMenor])
    public static let aumentadoSeptimaMayor = crear([.unisono, .terceraMayor, .quintaAumentada, .septimaMayor])
    public static let sus4Septima = crear([.unisono, .cuartaJusta, .quintaJusta, .septimaMenor])

    // Sextas
    public static let mayorSexta = crear([.unisono, .terceraMayor, .quintaJusta, .sextaMayor])
    public static let menorSexta = crear([.unisono, .terceraMenor, .quintaJusta, .sextaMayor])
    public static let mayorSextaNovena = crear([.unisono, .terceraMayor, .quintaJusta, .sextaMayor, .novenaMayor])

    // Novenas, undécimas y decimoterceras
    public static let dominanteNovena = crear([.unisono, .terceraMayor, .quintaJusta, .septimaMenor, .novenaMayor])
    public static let mayorSeptimaMayorNovena = crear([.unisono, .terceraMayor, .quintaJusta, .septimaMayor, .novenaMayor])
    public static let menorSeptimaNovena = crear([.unisono, .terceraMenor, .quintaJusta, .septimaMenor, .novenaMayor])
    public static let mayorNovenaAnadida = crear([.unisono, .terceraMayor, .quintaJusta, .novenaMayor])
    public static let dominanteUndecima = crear([.unisono, .terceraMayor, .quintaJusta, .septimaMenor, .novenaMayor, .undecima])
    public static let menorSeptimaUndecima = crear([.unisono, .terceraMenor, .quintaJusta, .septimaMenor, .novenaMayor, .undecima])
    public static let dominanteDecimotercera = crear([.unisono, .terceraMayor, .quintaJusta, .septimaMenor, .novenaMayor,
                                                      .decimoterceraMayor])

    public static let todos: [TipoDeAcorde] = [
        .mayor, .menor, .disminuido, .aumentado, .sus2, .sus4, .potencia,
        .dominanteSeptima, .mayorSeptimaMayor, .menorSeptima, .semidisminuido, .disminuidoSeptima,
        .menorSeptimaMayor, .aumentadoSeptima, .aumentadoSeptimaMayor, .sus4Septima,
        .mayorSexta, .menorSexta, .mayorSextaNovena, .dominanteNovena, .mayorSeptimaMayorNovena, .menorSeptimaNovena,
        .mayorNovenaAnadida, .dominanteUndecima, .menorSeptimaUndecima, .dominanteDecimotercera,
    ]

    /// Nombres en los cinco idiomas de los textos (`Traduccion`) de los tipos habituales, indexados
    /// por su conjunto de quintas.
    /// Se construye sin crear `TipoDeAcorde` para no depender de otras constantes estáticas.
    package static let nombresConocidos: [Set<Int>: Traduccion] = {
        let tabla: [([Intervalo], Traduccion)] = [
            ([.terceraMayor, .quintaJusta], Traduccion("mayor", "major", ca: "major", gl: "maior", eu: "maiorra")),
            ([.terceraMenor, .quintaJusta], Traduccion("menor", "minor", ca: "menor", gl: "menor", eu: "minorra")),
            ([.terceraMenor, .quintaDisminuida], Traduccion("disminuido", "diminished", ca: "disminuït", gl: "diminuído", eu: "gutxitua")),
            ([.terceraMayor, .quintaAumentada], Traduccion("aumentado", "augmented", ca: "augmentat", gl: "aumentado", eu: "gehitua")),
            ([.segundaMayor, .quintaJusta], Traduccion("suspendido de segunda", "suspended second", ca: "suspès de segona", gl: "suspendido de segunda", eu: "bigarrenera esekia")),
            ([.cuartaJusta, .quintaJusta], Traduccion("suspendido de cuarta", "suspended fourth", ca: "suspès de quarta", gl: "suspendido de cuarta", eu: "laugarrenera esekia")),
            ([.quintaJusta], Traduccion("quinta (acorde de potencia)", "power chord", ca: "quinta (acord de potència)", gl: "quinta (acorde de potencia)", eu: "bosgarrena (potentzia-akordea)")),
            ([.terceraMayor, .quintaJusta, .septimaMenor], Traduccion("séptima de dominante", "dominant seventh", ca: "sèptima de dominant", gl: "sétima de dominante", eu: "dominanteko zazpigarrena")),
            ([.terceraMayor, .quintaJusta, .septimaMayor], Traduccion("séptima mayor", "major seventh", ca: "sèptima major", gl: "sétima maior", eu: "zazpigarren handia")),
            ([.terceraMenor, .quintaJusta, .septimaMenor], Traduccion("menor séptima", "minor seventh", ca: "menor sèptima", gl: "menor sétima", eu: "minor zazpigarrena")),
            ([.terceraMenor, .quintaDisminuida, .septimaMenor], Traduccion("semidisminuido", "half-diminished seventh", ca: "semidisminuït", gl: "semidiminuído", eu: "erdi-gutxitua")),
            ([.terceraMenor, .quintaDisminuida, .septimaDisminuida], Traduccion("séptima disminuida", "diminished seventh", ca: "sèptima disminuïda", gl: "sétima diminuída", eu: "zazpigarren gutxitua")),
            ([.terceraMenor, .quintaJusta, .septimaMayor], Traduccion("menor con séptima mayor", "minor major seventh", ca: "menor amb sèptima major", gl: "menor con sétima maior", eu: "minorra zazpigarren handiarekin")),
            ([.terceraMayor, .quintaAumentada, .septimaMenor], Traduccion("aumentado con séptima menor", "augmented seventh", ca: "augmentat amb sèptima menor", gl: "aumentado con sétima menor", eu: "gehitua zazpigarren txikiarekin")),
            ([.terceraMayor, .quintaAumentada, .septimaMayor], Traduccion("aumentado con séptima mayor", "augmented major seventh", ca: "augmentat amb sèptima major", gl: "aumentado con sétima maior", eu: "gehitua zazpigarren handiarekin")),
            ([.cuartaJusta, .quintaJusta, .septimaMenor], Traduccion("séptima suspendida", "dominant seventh suspended fourth", ca: "sèptima suspesa", gl: "sétima suspendida", eu: "zazpigarren esekia")),
            ([.terceraMayor, .quintaJusta, .sextaMayor], Traduccion("sexta", "major sixth", ca: "sexta", gl: "sexta", eu: "seigarrena")),
            ([.terceraMenor, .quintaJusta, .sextaMayor], Traduccion("menor sexta", "minor sixth", ca: "menor sexta", gl: "menor sexta", eu: "minor seigarrena")),
            ([.terceraMayor, .quintaJusta, .sextaMayor, .segundaMayor], Traduccion("sexta y novena", "six-nine", ca: "sexta i novena", gl: "sexta e novena", eu: "seigarrena eta bederatzigarrena")),
            ([.terceraMayor, .quintaJusta, .septimaMenor, .segundaMayor], Traduccion("novena de dominante", "dominant ninth", ca: "novena de dominant", gl: "novena de dominante", eu: "dominanteko bederatzigarrena")),
            ([.terceraMayor, .quintaJusta, .septimaMayor, .segundaMayor], Traduccion("novena mayor", "major ninth", ca: "novena major", gl: "novena maior", eu: "bederatzigarren handia")),
            ([.terceraMenor, .quintaJusta, .septimaMenor, .segundaMayor], Traduccion("menor novena", "minor ninth", ca: "menor novena", gl: "menor novena", eu: "minor bederatzigarrena")),
            ([.terceraMayor, .quintaJusta, .segundaMayor], Traduccion("novena añadida", "added ninth", ca: "novena afegida", gl: "novena engadida", eu: "bederatzigarren gehigarria")),
            ([.terceraMayor, .quintaJusta, .septimaMenor, .segundaMayor, .cuartaJusta], Traduccion("undécima", "dominant eleventh", ca: "onzena", gl: "undécima", eu: "hamaikagarrena")),
            ([.terceraMenor, .quintaJusta, .septimaMenor, .segundaMayor, .cuartaJusta], Traduccion("menor undécima", "minor eleventh", ca: "menor onzena", gl: "menor undécima", eu: "minor hamaikagarrena")),
            ([.terceraMayor, .quintaJusta, .septimaMenor, .segundaMayor, .sextaMayor], Traduccion("decimotercera", "dominant thirteenth", ca: "tretzena", gl: "décimo terceira", eu: "hamahirugarrena")),
            ([.terceraMenor, .quintaJusta, .septimaMenor, .segundaMayor, .cuartaJusta, .sextaMayor],
             Traduccion("menor decimotercera", "minor thirteenth", ca: "menor tretzena", gl: "menor décimo terceira", eu: "minor hamahirugarrena")),
            ([.terceraMayor, .quintaJusta, .septimaMenor, .segundaMenor], Traduccion("séptima con novena menor", "dominant seventh flat nine", ca: "sèptima amb novena menor", gl: "sétima con novena menor", eu: "zazpigarrena bederatzigarren txikiarekin")),
            ([.terceraMayor, .sextaAumentada], Traduccion("sexta aumentada italiana", "Italian augmented sixth", ca: "sexta augmentada italiana", gl: "sexta aumentada italiana", eu: "seigarren gehitu italiarra")),
            ([.terceraMayor, .cuartaAumentada, .sextaAumentada], Traduccion("sexta aumentada francesa", "French augmented sixth", ca: "sexta augmentada francesa", gl: "sexta aumentada francesa", eu: "seigarren gehitu frantsesa")),
            ([.terceraMayor, .quintaJusta, .sextaAumentada], Traduccion("sexta aumentada alemana", "German augmented sixth", ca: "sexta augmentada alemanya", gl: "sexta aumentada alemá", eu: "seigarren gehitu alemana")),
        ]
        var diccionario: [Set<Int>: Traduccion] = [:]
        for (intervalos, nombre) in tabla {
            diccionario[Set(intervalos.map(\.pasosDeQuinta)).union([0])] = nombre
        }
        return diccionario
    }()
}

extension TipoDeAcorde: Hashable {
    public static func == (a: TipoDeAcorde, b: TipoDeAcorde) -> Bool { a.pasosDeQuinta == b.pasosDeQuinta }
    public func hash(into hasher: inout Hasher) { hasher.combine(pasosDeQuinta) }
}

extension TipoDeAcorde: CustomStringConvertible {
    public var description: String { cifrado.isEmpty ? "mayor" : cifrado }
}

extension TipoDeAcorde: RepresentableComoTexto, Nombrable {
    public func texto(_ notacion: Nomenclatura) -> String { cifrado(en: notacion) }
}

// MARK: - Acceso desde el acorde

extension TipoDeAcorde {
    /// Qué intervalo cumple cada papel en este tipo de acorde.
    public var estructura: EstructuraDeAcorde { EstructuraDeAcorde(clasificacion) }
}
