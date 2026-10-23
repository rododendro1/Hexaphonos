import ArmoniaNucleo
// MARK: - Escalas «exóticas» de la tradición occidental, simétricas y otras.

extension TipoDeEscala {
    // Escalas «exóticas» de la tradición occidental, con dos segundas aumentadas o casi.

    /// Dos tetracordos con 2ª aumentada (Do Re♭ Mi Fa Sol La♭ Si): el mismo contenido que el
    /// dromos Hitzazkiár y el thaat Bhairav.
    public static let dobleArmonica = TipoDeEscala(
        nombre: "doble armónica",
        intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaJusta,
                     .quintaJusta, .sextaMenor, .septimaMayor],
        alias: ["doble armonica", "doble armónica mayor", "bizantina", "gitana mayor"])
    /// La menor armónica con la 4ª aumentada (Do Re Mi♭ Fa♯ Sol La♭ Si).
    public static let menorHungara = TipoDeEscala(
        nombre: "menor húngara",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaAumentada,
                     .quintaJusta, .sextaMenor, .septimaMayor],
        alias: ["menor hungara", "gitana menor", "doble armónica menor", "doble armonica menor", "de Liszt", "Liszt"])
    /// Do Re♯ Mi Fa♯ Sol La Si♭.
    public static let mayorHungara = TipoDeEscala(
        nombre: "mayor húngara",
        intervalos: [.unisono, .segundaAumentada, .terceraMayor, .cuartaAumentada,
                     .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["mayor hungara"])
    /// La menor armónica con la 2ª menor (Do Re♭ Mi♭ Fa Sol La♭ Si).
    public static let napolitanaMenor = TipoDeEscala(
        nombre: "napolitana menor",
        intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaJusta,
                     .quintaJusta, .sextaMenor, .septimaMayor])
    /// La menor melódica con la 2ª menor (Do Re♭ Mi♭ Fa Sol La Si).
    public static let napolitanaMayor = TipoDeEscala(
        nombre: "napolitana mayor",
        intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaJusta,
                     .quintaJusta, .sextaMayor, .septimaMayor])
    /// La «escala enigmática» del Ave Maria de Verdi (Do Re♭ Mi Fa♯ Sol♯ La♯ Si).
    public static let enigmatica = TipoDeEscala(
        nombre: "enigmática",
        intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaAumentada,
                     .quintaAumentada, .sextaAumentada, .septimaMayor],
        alias: ["enigmatica"])
    /// Do Re♭ Mi Fa Sol♭ La♭ Si.
    public static let persa = TipoDeEscala(
        nombre: "persa",
        intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaJusta,
                     .quintaDisminuida, .sextaMenor, .septimaMayor])
    /// Do Re Mi Fa Sol♭ La♭ Si♭: la mayor con la mitad superior de tonos enteros.
    public static let mayorLocria = TipoDeEscala(
        nombre: "mayor locria",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta,
                     .quintaDisminuida, .sextaMenor, .septimaMenor],
        alias: ["árabe", "arabe"])
    /// Do Re Mi Fa♯ Sol La♭ Si♭: lidio con la mitad superior menor.
    public static let lidioMenor = TipoDeEscala(
        nombre: "lidio menor",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaAumentada,
                     .quintaJusta, .sextaMenor, .septimaMenor])
    /// La escala del «acorde místico» de Skriabin (Do Re Mi Fa♯ La Si♭).
    public static let prometeo = TipoDeEscala(
        nombre: "Prometeo",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaAumentada,
                     .sextaMayor, .septimaMenor],
        alias: ["mística", "mistica", "de Prometeo", "Skriabin", "Scriabin"])

    // Simétricas y otras.

    /// La disminuida que empieza por semitono (Do Re♭ Mi♭ Mi Fa♯ Sol La Si♭), la de los acordes
    /// de dominante con ♭9 y ♯9.
    public static let disminuidaSemitonoTono = TipoDeEscala(
        nombre: "disminuida semitono-tono",
        intervalos: [.unisono, .segundaMenor, .terceraMenor, .terceraMayor,
                     .cuartaAumentada, .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["disminuida dominante", "dominante disminuida", "modo 2 de Messiaen", "disminuida auxiliar blues",
                "de Rimski-Kórsakov", "Rimski-Kórsakov", "Rimsky-Korsakov"])
    /// Terceras menores y semitonos alternos (Do Mi♭ Mi Sol Sol♯ Si).
    public static let aumentada = TipoDeEscala(
        nombre: "aumentada",
        intervalos: [.unisono, .terceraMenor, .terceraMayor, .quintaJusta,
                     .quintaAumentada, .septimaMayor],
        alias: ["hexatónica aumentada", "hexatonica aumentada", "simétrica aumentada", "simetrica aumentada",
                "de Weitzmann", "Weitzmann"])
    /// Do Re Mi♭ Mi Sol La: la pentatónica mayor con la 3ª menor de paso.
    public static let bluesMayor = TipoDeEscala(
        nombre: "blues mayor",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .terceraMayor,
                     .quintaJusta, .sextaMayor])
    /// La pentatónica suspendida (Do Re Fa Sol Si♭), sin terceras.
    public static let egipcia = TipoDeEscala(
        nombre: "egipcia",
        intervalos: [.unisono, .segundaMayor, .cuartaJusta, .quintaJusta, .septimaMenor],
        alias: ["pentatónica suspendida", "pentatonica suspendida"])
    /// Las doce notas, escritas con sostenidos al subir desde la tónica salvo la 2ª, 3ª, 6ª y 7ª
    /// menores (Do Re♭ Re Mi♭ Mi Fa Fa♯ Sol La♭ La Si♭ Si).
    public static let cromatica = TipoDeEscala(
        nombre: "cromática",
        intervalos: [.unisono, .segundaMenor, .segundaMayor, .terceraMenor, .terceraMayor, .cuartaJusta,
                     .cuartaAumentada, .quintaJusta, .sextaMenor, .sextaMayor, .septimaMenor, .septimaMayor],
        alias: ["cromatica"])
}
