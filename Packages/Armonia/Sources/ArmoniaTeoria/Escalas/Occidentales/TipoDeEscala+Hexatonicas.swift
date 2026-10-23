import ArmoniaNucleo
// MARK: - Hexatónicas gaélicas y de dos tríadas, y otras escalas de seis notas.

extension TipoDeEscala {
    // Hexatónicas gaélicas: los modos con un hueco de la música tradicional escocesa e irlandesa.

    /// Do Re Mi Sol La Si.
    public static let jonicoSinCuarta = TipoDeEscala(
        nombre: "jónico sin 4ª",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .quintaJusta, .sextaMayor, .septimaMayor],
        alias: ["jonico sin 4", "jónico sin cuarta", "jónica gaélica"])
    /// Do Re Fa Sol La Si♭.
    public static let mixolidioSinTercera = TipoDeEscala(
        nombre: "mixolidio sin 3ª",
        intervalos: [.unisono, .segundaMayor, .cuartaJusta, .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["mixolidio sin 3", "mixolidio sin tercera", "mixolidia gaélica"])
    /// Do Re Mi♭ Fa Sol Si♭.
    public static let doricoSinSexta = TipoDeEscala(
        nombre: "dórico sin 6ª",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta, .quintaJusta, .septimaMenor],
        alias: ["dorico sin 6", "dórico sin sexta", "dórica gaélica"])
    /// Do Mi♭ Fa Sol La♭ Si♭.
    public static let eolicoSinSegunda = TipoDeEscala(
        nombre: "eólico sin 2ª",
        intervalos: [.unisono, .terceraMenor, .cuartaJusta, .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["eolico sin 2", "eólico sin segunda", "eólica gaélica"])

    /// Dos acordes mayores a un tono (Do + Re: Do Re Mi Fa♯ Sol La), para improvisar con pares de
    /// tríadas.
    public static let hexatonicaDeDosTriadas = TipoDeEscala(
        nombre: "hexatónica de dos tríadas",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaAumentada, .quintaJusta, .sextaMayor],
        alias: ["hexatonica de dos triadas", "dos tríadas", "par de tríadas", "hexatónica mayor de dos tríadas"])
    /// Dos acordes menores a un tono (Rem + Mim: Re Mi Fa Sol La Si), la pareja menor de la
    /// anterior.
    public static let hexatonicaMenorDeDosTriadas = TipoDeEscala(
        nombre: "hexatónica menor de dos tríadas",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta, .quintaJusta, .sextaMayor],
        alias: ["hexatonica menor de dos triadas", "par de tríadas menores"])

    /// Do Re♭ Mi Fa♯ Sol La Si♭, del folclore rumano y balcánico.
    public static let mayorRumana = TipoDeEscala(
        nombre: "mayor rumana",
        intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaAumentada,
                     .quintaJusta, .sextaMayor, .septimaMenor])

    /// La menor húngara con la 4ª justa además de la aumentada, de ocho notas
    /// (Do Re Mi♭ Fa Fa♯ Sol La♭ Si).
    public static let argelina = TipoDeEscala(
        nombre: "argelina",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta, .cuartaAumentada,
                     .quintaJusta, .sextaMenor, .septimaMayor])
    /// Dos acordes mayores a distancia de tritono, el «acorde de Petrushka» de Stravinski
    /// (Do Re♭ Mi Fa♯ Sol Si♭).
    public static let petrushka = TipoDeEscala(
        nombre: "Petrushka",
        intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaAumentada,
                     .quintaJusta, .septimaMenor],
        alias: ["de Petrushka", "Petrouchka", "de tritono", "tritono"])
}
