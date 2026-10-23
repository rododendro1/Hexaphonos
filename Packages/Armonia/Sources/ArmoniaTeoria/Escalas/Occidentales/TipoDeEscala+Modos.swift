import ArmoniaNucleo
// MARK: - Modos de la menor armónica, de la menor melódica y de la mayor armónica, y otros modos habituales.

extension TipoDeEscala {
    // Modos de la menor armónica (2.º a 7.º grado).
    public static let locrioSextaNatural = TipoDeEscala(
        nombre: "locrio ♮6",
        intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaJusta,
                     .quintaDisminuida, .sextaMayor, .septimaMenor],
        alias: ["locrio natural 6", "locrio 6"])
    public static let jonicoAumentado = TipoDeEscala(
        nombre: "jónico ♯5",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta,
                     .quintaAumentada, .sextaMayor, .septimaMayor],
        alias: ["jonico #5", "jónico aumentado", "jonico aumentado"])
    public static let doricoCuartaAumentada = TipoDeEscala(
        nombre: "dórico ♯4",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaAumentada,
                     .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["dorico #4", "dórico ucraniano", "dorico ucraniano", "menor rumana", "rumana"])
    public static let frigioDominante = TipoDeEscala(
        nombre: "frigio dominante",
        intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaJusta,
                     .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["frigio mayor", "frigio #3", "frigio ♯3", "española", "espanola", "frigio español",
                "dominante ♭9 ♭13"])
    public static let lidioSegundaAumentada = TipoDeEscala(
        nombre: "lidio ♯2",
        intervalos: [.unisono, .segundaAumentada, .terceraMayor, .cuartaAumentada,
                     .quintaJusta, .sextaMayor, .septimaMayor],
        alias: ["lidio #2"])
    public static let ultralocrio = TipoDeEscala(
        nombre: "ultralocrio",
        intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaDisminuida,
                     .quintaDisminuida, .sextaMenor, .septimaDisminuida],
        alias: ["superlocrio ♭♭7", "superlocrio bb7", "alterada disminuida"])

    // Modos de la menor melódica (2.º a 7.º grado).
    public static let doricoSegundaMenor = TipoDeEscala(
        nombre: "dórico ♭2",
        intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaJusta,
                     .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["dorico b2", "frigio ♮6", "frigio 6"])
    public static let lidioAumentado = TipoDeEscala(
        nombre: "lidio aumentado",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaAumentada,
                     .quintaAumentada, .sextaMayor, .septimaMayor],
        alias: ["lidio #5", "lidio ♯5"])
    public static let lidioDominante = TipoDeEscala(
        nombre: "lidio dominante",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaAumentada,
                     .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["lidio b7", "lidio ♭7", "acústica", "acustica", "de Bartók", "Bartók",
                "de los armónicos", "armónicos", "nordestina", "escala nordestina"])
    public static let mixolidioSextaMenor = TipoDeEscala(
        nombre: "mixolidio ♭6",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta,
                     .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["mixolidio b6", "hindú", "hindu", "mayor melódica", "mayor melodica"])
    public static let locrioSegundaNatural = TipoDeEscala(
        nombre: "locrio ♮2",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                     .quintaDisminuida, .sextaMenor, .septimaMenor],
        alias: ["locrio natural 2", "locrio 2", "semidisminuida"])
    public static let alterada = TipoDeEscala(
        nombre: "alterada",
        intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaDisminuida,
                     .quintaDisminuida, .sextaMenor, .septimaMenor],
        alias: ["superlocrio", "superlocria"])

    // Otras.
    public static let mayorArmonica = TipoDeEscala(
        nombre: "mayor armónica",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta,
                     .quintaJusta, .sextaMenor, .septimaMayor],
        alias: ["mayor armonica"])
    public static let bebopDominante = TipoDeEscala(
        nombre: "bebop dominante",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta,
                     .quintaJusta, .sextaMayor, .septimaMenor, .septimaMayor],
        alias: ["bebop"])
    public static let bebopMayor = TipoDeEscala(
        nombre: "bebop mayor",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta,
                     .quintaJusta, .quintaAumentada, .sextaMayor, .septimaMayor])
    public static let bebopDorico = TipoDeEscala(
        nombre: "bebop dórico",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .terceraMayor,
                     .cuartaJusta, .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["bebop dorico", "bebop menor"])

    // Modos de la mayor armónica (2.º a 7.º grado).
    public static let doricoQuintaDisminuida = TipoDeEscala(
        nombre: "dórico ♭5",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                     .quintaDisminuida, .sextaMayor, .septimaMenor],
        alias: ["dorico b5", "dórico b5"])
    public static let frigioCuartaDisminuida = TipoDeEscala(
        nombre: "frigio ♭4",
        intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaDisminuida,
                     .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["frigio b4"])
    public static let lidioTerceraMenor = TipoDeEscala(
        nombre: "lidio ♭3",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaAumentada,
                     .quintaJusta, .sextaMayor, .septimaMayor],
        alias: ["lidio b3", "lidio disminuido"])
    public static let mixolidioSegundaMenor = TipoDeEscala(
        nombre: "mixolidio ♭2",
        intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaJusta,
                     .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["mixolidio b2"])
    public static let lidioAumentadoSegundaAumentada = TipoDeEscala(
        nombre: "lidio aumentado ♯2",
        intervalos: [.unisono, .segundaAumentada, .terceraMayor, .cuartaAumentada,
                     .quintaAumentada, .sextaMayor, .septimaMayor],
        alias: ["lidio aumentado #2"])
    public static let locrioSeptimaDisminuida = TipoDeEscala(
        nombre: "locrio ♭♭7",
        intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaJusta,
                     .quintaDisminuida, .sextaMenor, .septimaDisminuida],
        alias: ["locrio bb7"])
}
