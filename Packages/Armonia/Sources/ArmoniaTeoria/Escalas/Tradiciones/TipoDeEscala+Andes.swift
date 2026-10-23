import ArmoniaNucleo
extension TipoDeEscala {
    // MARK: Escalas andinas

    /// La pentatónica menor de los Andes (huayno, yaraví).
    public static let andina = TipoDeEscala(
        nombre: "pentatónica andina", intervalos: [.unisono, .terceraMenor, .cuartaJusta, .quintaJusta, .septimaMenor],
        alias: ["andina"])
    /// La tritónica de las melodías más antiguas: una tríada menor (Do Mi♭ Sol).
    public static let tritonicaAndina = TipoDeEscala(
        nombre: "tritónica andina", intervalos: [.unisono, .terceraMenor, .quintaJusta],
        alias: ["tritónica", "tritonica"])

    public static let andinas: [TipoDeEscala] = [.andina, .tritonicaAndina]
}
