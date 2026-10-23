import Armonia
import Foundation

// MARK: - Dibujos: Tonnetz y tabla armónica

extension LineaDeComandos {
    /// Lo que piden dibujar `tonnetz` y `tabla`.
    enum Dibujo {
        case notas([String])
        case acorde(Acorde)
        case escala(Escala)
        case clases(ConjuntoDeClases)
        case recorrido([Acorde])
        case camino(Acorde, Acorde)
        case ciclo(CicloNeorriemanniano, Acorde)
    }

    /// Lo leído: qué se dibuja y con qué margen, o el error que se responde.
    enum Lectura {
        case dibujo(Dibujo, margen: Int?)
        case error(ResultadoDeOrden)
    }

    /// Lee los argumentos comunes de `tonnetz` y `tabla`: `--margen N` y lo que se dibuja
    /// (notas, `--acorde`, `--escala`, `--clases`, `--recorrido`, `--camino` o `--ciclo`).
    static func leerDibujo(_ argumentos: [String], orden: String) throws -> Lectura {
        var argumentos = argumentos
        var margen: Int?
        if let i = argumentos.firstIndex(of: "--margen") {
            guard i + 1 < argumentos.count, let n = Int(argumentos[i + 1]), (0...6).contains(n) else {
                return .error(uso("el margen es un número de 0 a 6: --margen 2"))
            }
            margen = n
            argumentos.removeSubrange(i...(i + 1))
        }
        guard let primero = argumentos.first else { return .error(uso("faltan las notas: armonia \(orden) Do Mi Sol")) }
        let resto = argumentos.dropFirst().joined(separator: " ")
        let dibujo: Dibujo
        switch primero {
        case "--acorde", "--chord":
            guard !resto.isEmpty else { return .error(uso("falta el acorde: armonia \(orden) --acorde Sol7")) }
            dibujo = .acorde(try Acorde(leyendo: resto))
        case "--escala", "--scale":
            guard !resto.isEmpty else { return .error(uso("falta la escala: armonia \(orden) --escala Re dórico")) }
            dibujo = .escala(try Escala(leyendo: resto))
        case "--clases", "--conjunto", "--pcs":
            let numeros = resto.split(whereSeparator: { $0 == " " || $0 == "," }).map { Int($0) }
            guard !numeros.isEmpty, numeros.allSatisfy({ $0.map { (0...11).contains($0) } ?? false }) else {
                return .error(uso("las clases de altura son números de 0 a 11: armonia \(orden) --clases 0 4 7"))
            }
            dibujo = .clases(ConjuntoDeClases(numeros.map { $0! }))
        case "--recorrido", "--progresion", "--path":
            let acordes = try argumentos.dropFirst().map { try Acorde(leyendo: $0) }
            guard !acordes.isEmpty else { return .error(uso("faltan las tríadas: armonia \(orden) --recorrido Do Lam Fa Rem")) }
            dibujo = .recorrido(acordes)
        case "--camino", "--shortest":
            let acordes = try argumentos.dropFirst().map { try Acorde(leyendo: $0) }
            guard acordes.count == 2 else { return .error(errorDeCamino(orden)) }
            dibujo = .camino(acordes[0], acordes[1])
        case "--ciclo", "--cycle":
            let partes = Array(argumentos.dropFirst())
            guard partes.count >= 2, let ciclo = CicloNeorriemanniano(leyendo: partes.dropLast().joined(separator: " ")) else {
                return .error(uso("el ciclo es hexatónico, octatónico o LR, desde una tríada: armonia \(orden) --ciclo hexatonico Do"))
            }
            dibujo = .ciclo(ciclo, try Acorde(leyendo: partes.last!))
        default:
            if primero.hasPrefix("--") { return .error(uso("opción desconocida: \(primero)")) }
            dibujo = .notas(argumentos)
        }
        return .dibujo(dibujo, margen: margen)
    }

    static func errorDeRecorrido(_ orden: String) -> ResultadoDeOrden {
        uso("el recorrido es de tríadas mayores y menores: armonia \(orden) --recorrido Do Lam Fa Rem")
    }

    static func errorDeCamino(_ orden: String) -> ResultadoDeOrden {
        uso("el camino va de una tríada mayor o menor a otra: armonia \(orden) --camino Do Mibm")
    }

    static func errorDeCiclo(_ orden: String) -> ResultadoDeOrden {
        uso("el ciclo empieza en una tríada mayor o menor: armonia \(orden) --ciclo hexatonico Do")
    }

    /// `tonnetz Do Mi Sol`, `tonnetz --acorde Domaj7`, `tonnetz --ciclo hexatonico Do`…
    static func tonnetz(_ argumentos: [String], _ notacion: Nomenclatura) throws -> ResultadoDeOrden {
        let (dibujo, margen): (Dibujo, Int?)
        switch try leerDibujo(argumentos, orden: "tonnetz") {
        case .error(let error): return error
        case .dibujo(let leido, let n): (dibujo, margen) = (leido, n)
        }
        let tonnetz: Tonnetz
        switch dibujo {
        case .notas(let textos): tonnetz = Tonnetz(try textos.map { try Nota(leyendo: $0) })
        case .acorde(let acorde): tonnetz = Tonnetz(acorde)
        case .escala(let escala): tonnetz = Tonnetz(escala)
        case .clases(let conjunto): tonnetz = Tonnetz(conjunto)
        case .recorrido(let acordes):
            guard let recorrido = Tonnetz(recorrido: acordes) else { return errorDeRecorrido("tonnetz") }
            tonnetz = recorrido
        case .camino(let origen, let destino):
            guard let camino = Tonnetz(caminoDesde: origen, hasta: destino) else { return errorDeCamino("tonnetz") }
            tonnetz = camino
        case .ciclo(let ciclo, let acorde):
            guard let dibujo = Tonnetz(ciclo: ciclo, desde: acorde) else { return errorDeCiclo("tonnetz") }
            tonnetz = dibujo
        }
        return bien(tonnetz.svg(notacion: notacion, margen: margen).trimmingCharacters(in: "\n"))
    }

    /// `tabla Do Mi Sol`, `tabla Do3 Sol3 Mi4` (con octava, alturas), `tabla --acorde Domaj7`,
    /// `tabla --ciclo octatonico Do`…
    static func tablaArmonica(_ argumentos: [String], _ notacion: Nomenclatura) throws -> ResultadoDeOrden {
        let (dibujo, margen): (Dibujo, Int?)
        switch try leerDibujo(argumentos, orden: "tabla") {
        case .error(let error): return error
        case .dibujo(let leido, let n): (dibujo, margen) = (leido, n)
        }
        let tabla: TablaArmonica
        switch dibujo {
        case .notas(let textos):
            // Con un número de octava, alturas; sin él, notas.
            if textos.contains(where: { $0.contains(where: \.isNumber) }) {
                tabla = TablaArmonica(try textos.map { try Altura(leyendo: $0) })
            } else {
                tabla = TablaArmonica(try textos.map { try Nota(leyendo: $0) })
            }
        case .acorde(let acorde): tabla = TablaArmonica(acorde)
        case .escala(let escala): tabla = TablaArmonica(escala)
        case .clases(let conjunto): tabla = TablaArmonica(conjunto)
        case .recorrido(let acordes):
            guard let recorrido = TablaArmonica(recorrido: acordes) else { return errorDeRecorrido("tabla") }
            tabla = recorrido
        case .camino(let origen, let destino):
            guard let camino = TablaArmonica(caminoDesde: origen, hasta: destino) else { return errorDeCamino("tabla") }
            tabla = camino
        case .ciclo(let ciclo, let acorde):
            guard let dibujo = TablaArmonica(ciclo: ciclo, desde: acorde) else { return errorDeCiclo("tabla") }
            tabla = dibujo
        }
        return bien(tabla.svg(notacion: notacion, margen: margen).trimmingCharacters(in: "\n"))
    }
}
