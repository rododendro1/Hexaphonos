import ArmoniaNucleo
import Foundation

extension TipoDeEscala {
    // MARK: Tipos predefinidos

    public static let mayor = TipoDeEscala(
        nombre: "mayor",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta,
                     .quintaJusta, .sextaMayor, .septimaMayor],
        alias: ["jónico", "jonico", "jónica", "jonica"])
    public static let dorico = TipoDeEscala(
        nombre: "dórico",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                     .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["dorico", "dórica", "dorica"])
    public static let frigio = TipoDeEscala(
        nombre: "frigio",
        intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaJusta,
                     .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["frigia"])
    public static let lidio = TipoDeEscala(
        nombre: "lidio",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaAumentada,
                     .quintaJusta, .sextaMayor, .septimaMayor],
        alias: ["lidia"])
    public static let mixolidio = TipoDeEscala(
        nombre: "mixolidio",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta,
                     .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["mixolidia"])
    public static let menorNatural = TipoDeEscala(
        nombre: "menor natural",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                     .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["menor", "eólico", "eolico", "eólica", "eolica"])
    public static let locrio = TipoDeEscala(
        nombre: "locrio",
        intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaJusta,
                     .quintaDisminuida, .sextaMenor, .septimaMenor],
        alias: ["locria"])
    public static let menorArmonica = TipoDeEscala(
        nombre: "menor armónica",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                     .quintaJusta, .sextaMenor, .septimaMayor],
        alias: ["menor armonica"])
    /// Sube con la 6ª y la 7ª mayores y baja como la menor natural.
    public static let menorMelodica = TipoDeEscala(
        nombre: "menor melódica",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                     .quintaJusta, .sextaMayor, .septimaMayor],
        descenso: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                   .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["menor melodica", "menor melódica clásica", "menor melodica clasica"])
    /// La menor melódica tal como se usa en el jazz: con la 6ª y la 7ª mayores también al bajar.
    /// Es el mismo contenido que el melakarta 23 (Gaurīmanoharī), y la escala madre de los modos
    /// de la menor melódica (dórico ♭2, lidio aumentado, lidio dominante, alterada…).
    public static let menorMelodicaJazz = TipoDeEscala(
        nombre: "menor melódica de jazz",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                     .quintaJusta, .sextaMayor, .septimaMayor],
        alias: ["menor de jazz", "menor melódica ascendente", "menor melodica ascendente"])
    public static let pentatonicaMayor = TipoDeEscala(
        nombre: "pentatónica mayor",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .quintaJusta, .sextaMayor],
        alias: ["pentatonica mayor"])
    public static let pentatonicaMenor = TipoDeEscala(
        nombre: "pentatónica menor",
        intervalos: [.unisono, .terceraMenor, .cuartaJusta, .quintaJusta, .septimaMenor],
        alias: ["pentatonica menor"])
    public static let blues = TipoDeEscala(
        nombre: "blues",
        intervalos: [.unisono, .terceraMenor, .cuartaJusta, .cuartaAumentada,
                     .quintaJusta, .septimaMenor])
    public static let tonosEnteros = TipoDeEscala(
        nombre: "tonos enteros",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaAumentada,
                     .quintaAumentada, .sextaAumentada],
        alias: ["hexatónica", "hexatonica", "modo 1 de Messiaen", "aumentada auxiliar", "de Debussy", "Debussy"])
    public static let disminuida = TipoDeEscala(
        nombre: "disminuida tono-semitono",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                     .quintaDisminuida, .sextaMenor, .sextaMayor, .septimaMayor],
        alias: ["disminuida", "octatónica", "octatonica", "modo 2 de Messiaen inverso", "disminuida auxiliar"])
}
