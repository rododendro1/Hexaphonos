import ArmoniaNucleo
/// Uno de los ocho modos del canto gregoriano: además de sus notas, la nota final (*finalis*),
/// la nota de recitación (tenor o dominante) y el ámbito de la melodía.
///
/// Los modos van por parejas, una por cada final (protus en Re, deuterus en Mi, tritus en Fa y
/// tetrardus en Sol). El impar es el auténtico, con la melodía de la final a su octava; el par
/// es el plagal, con la melodía una 4ª por debajo de la final hasta una 5ª por encima. Los dos
/// tienen las mismas notas y la misma final, y se distinguen por el ámbito y el tenor.
///
/// ```swift
/// ModoGregoriano.todos[1].nombre               // "protus plagal"
/// ModoGregoriano(2)!.tenor                     // Fa
/// ModoGregoriano(nombre: "hipofrigio")!.numero // 4
/// ```
public struct ModoGregoriano: Hashable, Sendable, CustomStringConvertible {
    /// Las cuatro finales.
    public enum Maneria: Int, CaseIterable, Hashable, Sendable, CustomStringConvertible {
        case protus, deuterus, tritus, tetrardus

        /// La final de los dos modos de la maneria: Re, Mi, Fa o Sol.
        public var finalis: Nota { [Nota.re, .mi, .fa, .sol][rawValue] }

        /// El modo eclesiástico con las mismas notas desde la final: dórico, frigio, lidio o
        /// mixolidio.
        public var tipo: TipoDeEscala { [TipoDeEscala.dorico, .frigio, .lidio, .mixolidio][rawValue] }

        public var description: String { ["protus", "deuterus", "tritus", "tetrardus"][rawValue] }
    }

    /// Del 1 al 8.
    public let numero: Int

    /// `nil` si `numero` no está entre 1 y 8.
    public init?(_ numero: Int) {
        guard (1...8).contains(numero) else { return nil }
        self.numero = numero
    }

    /// Lee "modo 2", "protus plagal", "hipodórico" o "hipodorico".
    public init?(nombre: String) {
        let texto = TipoDeEscala.normalizar(nombre)
        guard let modo = ModoGregoriano.todos.first(where: { modo in
            [modo.nombre, modo.nombreGriego, "modo \(modo.numero)"].contains { TipoDeEscala.normalizar($0) == texto }
        }) else { return nil }
        self = modo
    }

    /// Los ocho modos, del 1 al 8.
    public static let todos: [ModoGregoriano] = (1...8).map { ModoGregoriano($0)! }

    public var maneria: Maneria { Maneria(rawValue: (numero - 1) / 2)! }

    /// Los modos impares son auténticos, y los pares, plagales.
    public var esAutentico: Bool { numero % 2 == 1 }

    /// "protus auténtico", "protus plagal"…
    public var nombre: String { "\(maneria) \(esAutentico ? "auténtico" : "plagal")" }

    /// El nombre que le dio la teoría medieval: "dórico", "hipodórico"…
    public var nombreGriego: String { (esAutentico ? "" : "hipo") + maneria.tipo.nombre }

    /// La nota en la que acaba la melodía.
    public var finalis: Nota { maneria.finalis }

    /// La nota de recitación, también llamada dominante. En los auténticos está una 5ª por encima
    /// de la final, salvo en el 3 (Do y no Si); en los plagales, una 3ª por debajo de la del
    /// auténtico, salvo en el 8 (Do y no Si).
    public var tenor: Nota { [Nota.la, .fa, .do, .la, .do, .la, .re, .do][numero - 1] }

    /// Las notas desde la final. Los modos 5 y 6 se cantan muchas veces con Si♭, que aquí no
    /// figura.
    public var escala: Escala { Escala(finalis, maneria.tipo) }

    /// La nota más grave del ámbito: la final en los auténticos y la 4ª por debajo en los
    /// plagales. La final está en la octava 4.
    public var grave: Altura {
        let final = Altura(finalis, octava: 4)
        return esAutentico ? final : final + (-Intervalo.cuartaJusta)
    }

    /// La nota más aguda del ámbito, una octava por encima de la más grave.
    public var agudo: Altura { grave + Intervalo.octava }

    /// Las notas del ámbito, de la más grave a la más aguda.
    public var ambito: [Altura] {
        let blancas = (3...5).flatMap { Escala(.do).alturas(octava: $0).dropLast() }
        return blancas.filter { $0 >= grave && $0 <= agudo }
    }

    /// "modo 1 (protus auténtico, dórico): final Re, tenor La, ámbito Re4–Re5".
    public var description: String {
        "modo \(numero) (\(nombre), \(nombreGriego)): final \(finalis), tenor \(tenor), ámbito \(grave)–\(agudo)"
    }
}
