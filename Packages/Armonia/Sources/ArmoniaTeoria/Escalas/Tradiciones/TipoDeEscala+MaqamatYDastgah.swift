import ArmoniaNucleo
extension TipoDeEscala {
    // MARK: Maqamat árabes (temperados)
    //
    // Solo los maqamat sin cuartos de tono, que el temperamento igual escribe sin aproximar (Rast,
    // Bayati o Saba los necesitan y no están). Son nombres de escalas que ya había: Ḥijāz es el
    // frigio dominante; Nahāwand, la menor armónica… Transliterados con el sistema ALA-LC (ḥ, ā,
    // ʿ), y sin diacríticos como alias.

    /// حجاز (Re Mi♭ Fa♯ Sol La Si♭ Do).
    public static let hiyaz = TipoDeEscala(
        nombre: "Ḥijāz", intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaJusta,
                                       .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["Hijaz", "Hiyaz", "Ḥiŷāz", "Hejaz", "maqam Hijaz", "حجاز"])
    /// نهاوند, la menor armónica.
    public static let nahawand = TipoDeEscala(
        nombre: "Nahāwand", intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                                          .quintaJusta, .sextaMenor, .septimaMayor],
        alias: ["Nahawand", "Nihavend", "Nihavent", "نهاوند"])
    /// كرد, el frigio.
    public static let kurd = TipoDeEscala(
        nombre: "Kurd", intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaJusta,
                                      .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["maqam Kurd", "كرد"])
    /// عجم, la mayor.
    public static let ajam = TipoDeEscala(
        nombre: "ʿAjam", intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta,
                                      .quintaJusta, .sextaMayor, .septimaMayor],
        alias: ["Ajam", "Acem", "عجم"])
    /// حجازكار, la doble armónica.
    public static let hiyazkar = TipoDeEscala(
        nombre: "Ḥijāzkār", intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaJusta,
                                          .quintaJusta, .sextaMenor, .septimaMayor],
        alias: ["Hijazkar", "Hiyazkar", "Ḥiŷāzkār", "حجازكار"])
    /// نوى أثر, la menor húngara.
    public static let nawaAthar = TipoDeEscala(
        nombre: "Nawā Athar", intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaAumentada,
                                            .quintaJusta, .sextaMenor, .septimaMayor],
        alias: ["Nawa Athar", "Nawathar", "Neveser", "نوى أثر"])

    public static let maqamat: [TipoDeEscala] = [.hiyaz, .nahawand, .kurd, .ajam, .hiyazkar, .nawaAthar]

    // MARK: Dastgāh persas (temperados)
    //
    // Casi todos los dastgāh usan koron (un cuarto de tono bajo): solo Māhur se escribe sin
    // aproximar. Homāyun y Čahārgāh van con la aproximación temperada habitual, el koron
    // redondeado a semitono. Transliterados como en la Encyclopædia Iranica.

    /// ماهور: la mayor.
    public static let mahur = TipoDeEscala(
        nombre: "Māhur", intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta,
                                       .quintaJusta, .sextaMayor, .septimaMayor],
        alias: ["Mahur", "Mahoor", "ماهور"])
    /// همایون, aproximado: como el frigio dominante.
    public static let homayun = TipoDeEscala(
        nombre: "Homāyun", intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaJusta,
                                         .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["Homayun", "Homayoun", "همایون"])
    /// چهارگاه, aproximado: como la doble armónica.
    public static let cahargah = TipoDeEscala(
        nombre: "Čahārgāh", intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaJusta,
                                          .quintaJusta, .sextaMenor, .septimaMayor],
        alias: ["Chahārgāh", "Chahargah", "چهارگاه"])

    public static let dastgah: [TipoDeEscala] = [.mahur, .homayun, .cahargah]
}
