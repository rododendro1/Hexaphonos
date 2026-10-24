import Armonia

/// Los argumentos de una orden, de los que se van quitando las opciones según se leen. Lo que queda al final
/// (`restantes`) es lo que procesa la orden: notas, cifrados, una escala…
///
///     var argumentos = Argumentos(["Sol7", "--instrumento", "ukelele", "--diagrama"])
///     argumentos.quitarMarca("--diagrama", "--diagram")        // true
///     argumentos.quitarOpcion("--instrumento", "--instrument") // .valor("ukelele")
///     argumentos.restantes                                    // ["Sol7"]
///
/// Cada opción se acepta con su nombre en español y en inglés; las órdenes solo dicen cuáles.
struct Argumentos {
    private(set) var restantes: [String]

    init(_ argumentos: [String]) {
        restantes = argumentos
    }

    /// Lo que queda, separado por espacios: «Do Fa Sol7 Do».
    var unidos: String { restantes.joined(separator: " ") }

    /// La primera opción (`--algo`) que queda sin leer, que ninguna lectura ha reconocido.
    var opcionDesconocida: String? { restantes.first { $0.hasPrefix("--") } }

    /// Una opción con valor, tal como se ha encontrado.
    enum Opcion: Equatable {
        case ausente
        /// Está, pero no la sigue nada o la sigue otra opción. `nombre` es el que se escribió, sin los guiones.
        case sinValor(nombre: String)
        case valor(String)
    }

    /// Quita una marca, una opción sin valor (`--diagrama`), con cualquiera de sus nombres y todas las veces
    /// que aparezca. Dice si estaba.
    mutating func quitarMarca(_ nombres: String...) -> Bool {
        let antes = restantes.count
        restantes.removeAll { nombres.contains($0) }
        return restantes.count != antes
    }

    /// Quita una opción con valor (`--limite 5`) y su valor.
    mutating func quitarOpcion(_ nombres: String...) -> Opcion {
        guard let i = restantes.firstIndex(where: { nombres.contains($0) }) else { return .ausente }
        guard i + 1 < restantes.count, !restantes[i + 1].hasPrefix("--") else {
            return .sinValor(nombre: String(restantes.remove(at: i).dropFirst(2)))
        }
        let valor = restantes[i + 1]
        restantes.removeSubrange(i...(i + 1))
        return .valor(valor)
    }

    /// Quita una opción con un número (`--voces 2`): `porDefecto` si no está, y `nil` si le falta el número
    /// o no está en `rango`.
    mutating func quitarNumero(_ nombres: String..., en rango: ClosedRange<Int>, porDefecto: Int) -> Int? {
        guard let i = restantes.firstIndex(where: { nombres.contains($0) }) else { return porDefecto }
        guard i + 1 < restantes.count, let n = Int(restantes[i + 1]), rango.contains(n) else { return nil }
        restantes.removeSubrange(i...(i + 1))
        return n
    }

    /// Quita `--en <tonalidad>` (o `--in`), que va al final y se lleva todo lo que lo sigue: `--en La menor`.
    /// `nil` dentro si no está, y `nil` si no lo sigue nada. Lanza un error de lectura si la tonalidad no se
    /// puede leer.
    mutating func quitarTonalidad() throws -> Tonalidad?? {
        guard let i = restantes.firstIndex(where: { $0 == "--en" || $0 == "--in" }) else { return .some(nil) }
        guard i + 1 < restantes.count else { return nil }
        let tonalidad = try Tonalidad(leyendo: restantes[(i + 1)...].joined(separator: " "))
        restantes.removeSubrange(i...)
        return .some(tonalidad)
    }
}
