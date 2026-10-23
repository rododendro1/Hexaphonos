import ArmoniaNucleo
extension TipoDeEscala {
    // MARK: Escalas de Indonesia (aproximadas)
    //
    // Las afinaciones del gamelan no son temperadas ni iguales de un conjunto a otro: estas son
    // las aproximaciones habituales a doce notas. Los nombres van con la grafía javanesa (pélog,
    // sléndro).

    /// Pélog en el modo selisir de Bali (Do Re♭ Mi♭ Sol La♭).
    public static let pelog = TipoDeEscala(
        nombre: "Pélog selisir", intervalos: [.unisono, .segundaMenor, .terceraMenor, .quintaJusta, .sextaMenor],
        alias: ["Pelog selisir", "Pélog", "Pelog", "Selisir", "balinesa", "Bali"])
    /// Sléndro, de cinco notas casi equidistantes (Do Re Fa Sol La).
    public static let slendro = TipoDeEscala(
        nombre: "Sléndro", intervalos: [.unisono, .segundaMayor, .cuartaJusta, .quintaJusta, .sextaMayor],
        alias: ["Slendro", "Saléndro", "Salendro"])

    public static let indonesias: [TipoDeEscala] = [.pelog, .slendro]
}
