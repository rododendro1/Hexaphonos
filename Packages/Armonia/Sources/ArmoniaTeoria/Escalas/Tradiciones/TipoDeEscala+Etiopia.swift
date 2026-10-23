import ArmoniaNucleo
extension TipoDeEscala {
    // MARK: Escalas etíopes (qenet)
    //
    // Los cuatro qenet pentatónicos (Təzəta, Bati, Ambassäl y Ančihoye) y las variantes mayor y
    // menor de Təzəta y Bati, transliterados como en la Encyclopaedia Aethiopica (ə, ä, č) y con
    // la grafía inglesa habitual como alias. Las fuentes no coinciden del todo en sus notas (ni la afinación es
    // temperada): aquí va la versión más citada, sobre Do.

    /// ትዝታ, «nostalgia» (Do Re Mi Sol La).
    public static let tezetaMayor = TipoDeEscala(
        nombre: "Təzəta mayor", intervalos: [.unisono, .segundaMayor, .terceraMayor, .quintaJusta, .sextaMayor],
        alias: ["Tezeta mayor", "Tezeta", "Təzəta", "Tizita", "Tizita mayor", "Tezeta major", "Tizita major", "ትዝታ"])
    /// Do Re Mi♭ Sol La♭.
    public static let tezetaMenor = TipoDeEscala(
        nombre: "Təzəta menor", intervalos: [.unisono, .segundaMayor, .terceraMenor, .quintaJusta, .sextaMenor],
        alias: ["Tezeta menor", "Tizita menor", "Tezeta minor", "Tizita minor"])
    /// ባቲ (Do Mi Fa Sol Si).
    public static let batiMayor = TipoDeEscala(
        nombre: "Bati mayor", intervalos: [.unisono, .terceraMayor, .cuartaJusta, .quintaJusta, .septimaMayor],
        alias: ["Bati", "Batti", "Bati major", "ባቲ"])
    /// Do Mi♭ Fa Sol Si♭.
    public static let batiMenor = TipoDeEscala(
        nombre: "Bati menor", intervalos: [.unisono, .terceraMenor, .cuartaJusta, .quintaJusta, .septimaMenor],
        alias: ["Batti menor", "Bati minor"])
    /// አምባሰል (Do Re♭ Fa Sol La♭).
    public static let ambassel = TipoDeEscala(
        nombre: "Ambassäl", intervalos: [.unisono, .segundaMenor, .cuartaJusta, .quintaJusta, .sextaMenor],
        alias: ["Ambassel", "Ambasel", "Ambessel", "አምባሰል"])
    /// አንቺሆዬ (Do Re♭ Fa Sol♭ La).
    public static let anchihoye = TipoDeEscala(
        nombre: "Ančihoye", intervalos: [.unisono, .segundaMenor, .cuartaJusta, .quintaDisminuida, .sextaMayor],
        alias: ["Anchihoye", "Anchihoy", "Anchi hoye", "አንቺሆዬ"])

    public static let etiopes: [TipoDeEscala] = [.tezetaMayor, .tezetaMenor, .batiMayor, .batiMenor, .ambassel, .anchihoye]
}
