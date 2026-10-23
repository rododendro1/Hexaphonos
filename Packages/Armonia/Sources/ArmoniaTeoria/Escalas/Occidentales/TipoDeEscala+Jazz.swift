import ArmoniaNucleo
// MARK: - Escalas de jazz: bebop menores, pentatónicas del jazz y blues ampliadas.

extension TipoDeEscala {
    // Bebop menores: una nota de paso más para que los tiempos caigan en notas del acorde.

    /// La menor melódica con la 5ª aumentada de paso (Do Re Mi♭ Fa Sol Sol♯ La Si).
    public static let bebopMenorMelodica = TipoDeEscala(
        nombre: "bebop menor melódica",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                     .quintaJusta, .quintaAumentada, .sextaMayor, .septimaMayor],
        alias: ["bebop menor melodica", "bebop melódica", "bebop melodica"])
    /// La menor armónica con la 7ª menor de paso (Do Re Mi♭ Fa Sol La♭ Si♭ Si).
    public static let bebopMenorArmonica = TipoDeEscala(
        nombre: "bebop menor armónica",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                     .quintaJusta, .sextaMenor, .septimaMenor, .septimaMayor],
        alias: ["bebop menor armonica", "bebop armónica", "bebop armonica"])

    /// El frigio con la 3ª mayor y la menor, de ocho notas (Do Re♭ Mi♭ Mi Fa Sol La♭ Si♭): la del
    /// flamenco, sobre la cadencia andaluza.
    public static let flamenca = TipoDeEscala(
        nombre: "flamenca",
        intervalos: [.unisono, .segundaMenor, .terceraMenor, .terceraMayor, .cuartaJusta,
                     .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["andaluza", "frigio flamenco", "española de ocho notas", "espanola de ocho notas",
                "gitana española", "gitana espanola"])

    // Pentatónicas del jazz.

    /// Do Re Mi Sol Si♭: la de los acordes de séptima de dominante.
    public static let pentatonicaDominante = TipoDeEscala(
        nombre: "pentatónica dominante",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .quintaJusta, .septimaMenor])
    /// Do Mi♭ Fa Sol La: la menor con la 6ª mayor en vez de la 7ª.
    public static let pentatonicaMenorSexta = TipoDeEscala(
        nombre: "pentatónica menor 6",
        intervalos: [.unisono, .terceraMenor, .cuartaJusta, .quintaJusta, .sextaMayor],
        alias: ["pentatónica dórica", "pentatonica dorica", "pentatónica menor con sexta"])
    /// Do Re Mi Sol La♭, también llamada «de Coltrane».
    public static let pentatonicaMayorSextaMenor = TipoDeEscala(
        nombre: "pentatónica mayor ♭6",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .quintaJusta, .sextaMenor],
        alias: ["pentatónica de Coltrane", "pentatonica de Coltrane", "Coltrane"])
    /// Do Mi♭ Fa Sol♭ Si♭.
    public static let pentatonicaMenorQuintaDisminuida = TipoDeEscala(
        nombre: "pentatónica menor ♭5",
        intervalos: [.unisono, .terceraMenor, .cuartaJusta, .quintaDisminuida, .septimaMenor])
    /// Do Mi Fa Sol Si♭: la de los acordes de séptima de dominante con 4ª.
    public static let pentatonicaMixolidia = TipoDeEscala(
        nombre: "pentatónica mixolidia",
        intervalos: [.unisono, .terceraMayor, .cuartaJusta, .quintaJusta, .septimaMenor],
        alias: ["pentatonica mixolidia"])
    /// Do Mi Fa♯ Sol Si: la de los acordes de séptima mayor con ♯11.
    public static let pentatonicaLidia = TipoDeEscala(
        nombre: "pentatónica lidia",
        intervalos: [.unisono, .terceraMayor, .cuartaAumentada, .quintaJusta, .septimaMayor],
        alias: ["pentatonica lidia"])
    /// Do Re Fa Sol La: la pentatónica mayor desde su 4.º grado, la de las gaitas escocesas (las
    /// mismas notas que Sléndro, Durgā o Zhǐ).
    public static let pentatonicaEscocesa = TipoDeEscala(
        nombre: "pentatónica escocesa",
        intervalos: [.unisono, .segundaMayor, .cuartaJusta, .quintaJusta, .sextaMayor],
        alias: ["pentatonica escocesa", "escocesa"])

    // Blues ampliadas.

    /// Do Re Mi♭ Mi Fa Sol♭ Sol La Si♭: la blues con la mayor y la menor juntas.
    public static let bluesDeNueveNotas = TipoDeEscala(
        nombre: "blues de nueve notas",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .terceraMayor, .cuartaJusta,
                     .quintaDisminuida, .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["blues de 9 notas", "blues eneatónica", "blues eneatonica"])
    /// Do Re Mi♭ Fa Sol♭ Sol Si♭: la blues con la 2ª.
    public static let bluesMenorConSegunda = TipoDeEscala(
        nombre: "blues menor con 2ª",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                     .quintaDisminuida, .quintaJusta, .septimaMenor],
        alias: ["blues con segunda", "blues menor con segunda", "blues con 2ª"])

    /// El hexacordo de Guido d'Arezzo: ut re mi fa sol la, tono, tono, semitono, tono, tono.
    /// Natural sobre Do, duro sobre Sol y blando sobre Fa (`Escala.hexacordoNatural`…).
    public static let hexacordo = TipoDeEscala(
        nombre: "hexacordo",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta, .quintaJusta, .sextaMayor],
        alias: ["hexacordo de Guido", "ut re mi fa sol la"])
}
