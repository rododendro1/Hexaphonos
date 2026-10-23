import ArmoniaNucleo
import ArmoniaTeoria

/// Las cuerdas de un instrumento con trastes y la altura de cada una al aire.
///
/// Las cuerdas se numeran desde la más grave: la cuerda 0 de la guitarra es el Mi2. En los
/// instrumentos con cuerda reentrante (el ukelele) el orden es el de las cuerdas en el mástil,
/// no el de las alturas.
public struct Encordado: Hashable, Sendable {
    public let nombre: String
    /// Altura al aire de cada cuerda, de la primera (la más grave en el mástil) a la última.
    public let cuerdas: [Altura]

    public init(nombre: String, cuerdas: [Altura]) {
        self.nombre = nombre
        self.cuerdas = cuerdas
    }

    public var numeroDeCuerdas: Int { cuerdas.count }

    /// `true` si alguna cuerda suena más grave que la anterior en el mástil: el ukelele, cuya cuerda de Sol
    /// (la primera) es más aguda que la de Do (la segunda). En estos instrumentos la nota más grave de un
    /// acorde no tiene por qué ser su raíz.
    public var esReentrante: Bool {
        zip(cuerdas, cuerdas.dropFirst()).contains { $0.midi > $1.midi }
    }

    // MARK: Afinaciones habituales

    /// Guitarra estándar: Mi2 La2 Re3 Sol3 Si3 Mi4.
    public static let guitarra = Encordado(
        nombre: "guitarra",
        cuerdas: [Altura(.mi, octava: 2), Altura(.la, octava: 2), Altura(.re, octava: 3),
                  Altura(.sol, octava: 3), Altura(.si, octava: 3), Altura(.mi, octava: 4)])

    /// Guitarra de siete cuerdas, con el Si1 grave.
    public static let guitarraDeSieteCuerdas = Encordado(
        nombre: "guitarra de siete cuerdas",
        cuerdas: [Altura(.si, octava: 1)] + Encordado.guitarra.cuerdas)

    /// Guitarra en Re (drop D): Re2 La2 Re3 Sol3 Si3 Mi4.
    public static let guitarraEnReGrave = Encordado(
        nombre: "guitarra en re grave",
        cuerdas: [Altura(.re, octava: 2)] + Encordado.guitarra.cuerdas.dropFirst())

    /// Bajo de cuatro cuerdas: Mi1 La1 Re2 Sol2.
    public static let bajo = Encordado(
        nombre: "bajo",
        cuerdas: [Altura(.mi, octava: 1), Altura(.la, octava: 1), Altura(.re, octava: 2), Altura(.sol, octava: 2)])

    /// Bajo de cinco cuerdas: Si0 Mi1 La1 Re2 Sol2.
    public static let bajoDeCincoCuerdas = Encordado(
        nombre: "bajo de cinco cuerdas",
        cuerdas: [Altura(.si, octava: 0)] + Encordado.bajo.cuerdas)

    /// Ukelele soprano: Sol4 Do4 Mi4 La4 (cuerda reentrante).
    public static let ukelele = Encordado(
        nombre: "ukelele",
        cuerdas: [Altura(.sol, octava: 4), Altura(.do, octava: 4), Altura(.mi, octava: 4), Altura(.la, octava: 4)])

    /// Mandolina, afinada en quintas: Sol3 Re4 La4 Mi5.
    public static let mandolina = Encordado(
        nombre: "mandolina",
        cuerdas: [Altura(.sol, octava: 3), Altura(.re, octava: 4), Altura(.la, octava: 4), Altura(.mi, octava: 5)])

    public static let todos: [Encordado] = [
        .guitarra, .guitarraEnReGrave, .guitarraDeSieteCuerdas, .bajo, .bajoDeCincoCuerdas, .ukelele, .mandolina,
    ]
}

extension Encordado {
    /// Busca un instrumento por su nombre, sin distinguir mayúsculas ni tildes: «guitarra», «bajo de cinco
    /// cuerdas», «ukulele», «drop D»… (también «bass», «mandolin»). `nil` si no se conoce.
    public init?(nombre texto: String) {
        let clave = texto.claveDeBusqueda
        guard let encontrado = Encordado.alias[clave]
                ?? Encordado.todos.first(where: { $0.nombre.claveDeBusqueda == clave }) else { return nil }
        self = encontrado
    }

    /// Otras formas de nombrar los instrumentos de `todos` (los nombres de `todos` ya se aceptan).
    private static let alias: [String: Encordado] = [
        "guitar": .guitarra,
        "guitarra 7": .guitarraDeSieteCuerdas, "guitarra7": .guitarraDeSieteCuerdas,
        "guitarra de 7 cuerdas": .guitarraDeSieteCuerdas, "guitarra de siete": .guitarraDeSieteCuerdas,
        "guitarra en re": .guitarraEnReGrave, "re grave": .guitarraEnReGrave, "drop d": .guitarraEnReGrave,
        "dropd": .guitarraEnReGrave,
        "bass": .bajo,
        "bajo 5": .bajoDeCincoCuerdas, "bajo5": .bajoDeCincoCuerdas, "bajo de 5 cuerdas": .bajoDeCincoCuerdas,
        "bajo de cinco": .bajoDeCincoCuerdas,
        "ukulele": .ukelele, "ukulele soprano": .ukelele, "ukelele soprano": .ukelele,
        "mandolin": .mandolina,
    ]
}
