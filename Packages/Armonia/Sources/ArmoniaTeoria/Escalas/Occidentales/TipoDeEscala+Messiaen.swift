import ArmoniaNucleo
// MARK: - Modos de transposición limitada de Messiaen.

extension TipoDeEscala {
    // Modos de transposición limitada de Messiaen (el 1.º es la de tonos enteros y el 2.º, la
    // disminuida semitono-tono). Cada uno se repite dentro de la octava, así que solo tiene
    // unas pocas transposiciones distintas.

    /// Tono, semitono, semitono, tres veces (Do Re Mi♭ Mi Fa♯ Sol La♭ Si♭ Si): la escala de nueve
    /// notas de Tcherepnin. Cuatro transposiciones.
    public static let messiaen3 = TipoDeEscala(
        nombre: "modo 3 de Messiaen",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .terceraMayor, .cuartaAumentada,
                     .quintaJusta, .sextaMenor, .septimaMenor, .septimaMayor],
        alias: ["Messiaen 3", "Tcherepnin", "de Tcherepnin", "nueve notas", "de nueve notas"])
    /// Semitono, semitono, tercera menor, semitono, dos veces (Do Re♭ Re Fa Fa♯ Sol La♭ Si). Seis
    /// transposiciones.
    public static let messiaen4 = TipoDeEscala(
        nombre: "modo 4 de Messiaen",
        intervalos: [.unisono, .segundaMenor, .segundaMayor, .cuartaJusta, .cuartaAumentada,
                     .quintaJusta, .sextaMenor, .septimaMayor],
        alias: ["Messiaen 4"])
    /// Semitono, tercera mayor, semitono, dos veces (Do Re♭ Fa Fa♯ Sol Si). Seis transposiciones.
    public static let messiaen5 = TipoDeEscala(
        nombre: "modo 5 de Messiaen",
        intervalos: [.unisono, .segundaMenor, .cuartaJusta, .cuartaAumentada, .quintaJusta, .septimaMayor],
        alias: ["Messiaen 5"])
    /// Tono, tono, semitono, semitono, dos veces (Do Re Mi Fa Fa♯ Sol♯ La♯ Si). Seis transposiciones.
    public static let messiaen6 = TipoDeEscala(
        nombre: "modo 6 de Messiaen",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta, .cuartaAumentada,
                     .quintaAumentada, .sextaAumentada, .septimaMayor],
        alias: ["Messiaen 6"])
    /// Semitono, semitono, semitono, tono, semitono, dos veces (Do Re♭ Re Mi♭ Fa Fa♯ Sol La♭ La Si).
    /// Seis transposiciones.
    public static let messiaen7 = TipoDeEscala(
        nombre: "modo 7 de Messiaen",
        intervalos: [.unisono, .segundaMenor, .segundaMayor, .terceraMenor, .cuartaJusta,
                     .cuartaAumentada, .quintaJusta, .sextaMenor, .sextaMayor, .septimaMayor],
        alias: ["Messiaen 7"])
}
