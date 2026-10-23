import ArmoniaNucleo
extension TipoDeEscala {
    // MARK: Escalas coreanas
    //
    // Las dos pentatónicas de la música tradicional, en McCune-Reischauer (con breves y
    // apóstrofo) y en la romanización oficial y en hangul como alias.

    /// 평조 (Sol La Do Re Mi).
    public static let pyongjo = TipoDeEscala(
        nombre: "P'yŏngjo", intervalos: [.unisono, .segundaMayor, .cuartaJusta, .quintaJusta, .sextaMayor],
        alias: ["Pyeongjo", "Pyongjo", "평조"])
    /// 계면조 (La Do Re Mi Sol).
    public static let kyemyonjo = TipoDeEscala(
        nombre: "Kyemyŏnjo", intervalos: [.unisono, .terceraMenor, .cuartaJusta, .quintaJusta, .septimaMenor],
        alias: ["Gyemyeonjo", "Kyemyonjo", "계면조"])

    public static let coreanas: [TipoDeEscala] = [.pyongjo, .kyemyonjo]
}
