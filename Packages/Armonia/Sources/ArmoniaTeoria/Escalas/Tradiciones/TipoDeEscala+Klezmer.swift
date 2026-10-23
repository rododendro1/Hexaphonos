import ArmoniaNucleo
extension TipoDeEscala {
    // MARK: Modos del klezmer

    /// פֿריגיש, el frigio dominante (Ahavah Rabbah en la sinagoga).
    public static let freygish = TipoDeEscala(
        nombre: "Freygish", intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaJusta,
                                          .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["Freigish", "Ahavah Rabbah", "Ahava Rabbah", "Ahava Raba"])
    /// Misheberakh, el dórico ♯4.
    public static let misheberakh = TipoDeEscala(
        nombre: "Misheberakh", intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaAumentada,
                                             .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["Mi Sheberach", "Av Harachamim"])
    /// Adonai Malakh: un mixolidio con la 3ª menor de paso (Do Re Mi♭ Mi Fa Sol La Si♭).
    public static let adonaiMalakh = TipoDeEscala(
        nombre: "Adonai Malakh", intervalos: [.unisono, .segundaMayor, .terceraMenor, .terceraMayor, .cuartaJusta,
                                               .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["Adonoi Moloch", "Adoshem Malakh"])
    /// Magen Avot, la menor natural.
    public static let magenAvot = TipoDeEscala(
        nombre: "Magen Avot", intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                                            .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["Mogen Ovos"])

    public static let klezmer: [TipoDeEscala] = [.freygish, .misheberakh, .adonaiMalakh, .magenAvot]
}
