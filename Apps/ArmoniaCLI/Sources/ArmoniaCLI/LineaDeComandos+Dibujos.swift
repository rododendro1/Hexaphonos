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
    static func leerDibujo(_ argumentos: [String], orden: String, _ notacion: Notacion) throws -> Lectura {
        var lectura = Argumentos(argumentos)
        var margen: Int?
        switch lectura.quitarOpcion("--margen") {
        case .ausente:
            break
        case .sinValor:
            return .error(uso(.margenFueraDeRango, notacion))
        case .valor(let texto):
            guard let n = Int(texto), (0...6).contains(n) else { return .error(uso(.margenFueraDeRango, notacion)) }
            margen = n
        }
        let argumentos = lectura.restantes
        guard let primero = argumentos.first else { return .error(uso(.faltanNotasDelDibujo(orden: orden), notacion)) }
        let resto = argumentos.dropFirst().joined(separator: " ")
        let dibujo: Dibujo
        switch primero {
        case "--acorde", "--chord":
            guard !resto.isEmpty else { return .error(uso(.faltaAcordeDelDibujo(orden: orden), notacion)) }
            dibujo = .acorde(try Acorde(leyendo: resto))
        case "--escala", "--scale":
            guard !resto.isEmpty else { return .error(uso(.faltaEscalaDelDibujo(orden: orden), notacion)) }
            dibujo = .escala(try Escala(leyendo: resto))
        case "--clases", "--conjunto", "--pcs":
            let numeros = resto.split(whereSeparator: { $0 == " " || $0 == "," }).map { Int($0) }
            guard !numeros.isEmpty, numeros.allSatisfy({ $0.map { (0...11).contains($0) } ?? false }) else {
                return .error(uso(.clasesFueraDeRango(orden: orden), notacion))
            }
            dibujo = .clases(ConjuntoDeClases(numeros.map { $0! }))
        case "--recorrido", "--sequence", "--progresion", "--path":
            let acordes = try argumentos.dropFirst().map { try Acorde(leyendo: $0) }
            guard !acordes.isEmpty else { return .error(uso(.faltanTriadasDelRecorrido(orden: orden), notacion)) }
            dibujo = .recorrido(acordes)
        case "--camino", "--shortest":
            let acordes = try argumentos.dropFirst().map { try Acorde(leyendo: $0) }
            guard acordes.count == 2 else { return .error(errorDeCamino(orden, notacion)) }
            dibujo = .camino(acordes[0], acordes[1])
        case "--ciclo", "--cycle":
            let partes = Array(argumentos.dropFirst())
            guard partes.count >= 2, let ciclo = CicloNeorriemanniano(leyendo: partes.dropLast().joined(separator: " ")) else {
                return .error(uso(.cicloMalEscrito(orden: orden), notacion))
            }
            dibujo = .ciclo(ciclo, try Acorde(leyendo: partes.last!))
        default:
            if primero.hasPrefix("--") { return .error(uso(.opcionDesconocida(primero), notacion)) }
            dibujo = .notas(argumentos)
        }
        return .dibujo(dibujo, margen: margen)
    }

    static func errorDeRecorrido(_ orden: String, _ notacion: Notacion) -> ResultadoDeOrden {
        uso(.recorridoSoloTriadas(orden: orden), notacion)
    }

    static func errorDeCamino(_ orden: String, _ notacion: Notacion) -> ResultadoDeOrden {
        uso(.caminoSoloTriadas(orden: orden), notacion)
    }

    static func errorDeCiclo(_ orden: String, _ notacion: Notacion) -> ResultadoDeOrden {
        uso(.cicloSoloTriadas(orden: orden), notacion)
    }

    /// `tonnetz Do Mi Sol`, `tonnetz --acorde Domaj7`, `tonnetz --ciclo hexatonico Do`…
    static func tonnetz(_ argumentos: [String], _ notacion: Notacion) throws -> ResultadoDeOrden {
        let (dibujo, margen): (Dibujo, Int?)
        switch try leerDibujo(argumentos, orden: "tonnetz", notacion) {
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
            guard let recorrido = Tonnetz(recorrido: acordes) else { return errorDeRecorrido("tonnetz", notacion) }
            tonnetz = recorrido
        case .camino(let origen, let destino):
            guard let camino = Tonnetz(caminoDesde: origen, hasta: destino) else { return errorDeCamino("tonnetz", notacion) }
            tonnetz = camino
        case .ciclo(let ciclo, let acorde):
            guard let dibujo = Tonnetz(ciclo: ciclo, desde: acorde) else { return errorDeCiclo("tonnetz", notacion) }
            tonnetz = dibujo
        }
        return bien(tonnetz.svg(notacion: notacion, margen: margen).trimmingCharacters(in: "\n"))
    }

    /// `tabla Do Mi Sol`, `tabla Do3 Sol3 Mi4` (con octava, alturas), `tabla --acorde Domaj7`,
    /// `tabla --ciclo octatonico Do`…
    static func tablaArmonica(_ argumentos: [String], _ notacion: Notacion) throws -> ResultadoDeOrden {
        let (dibujo, margen): (Dibujo, Int?)
        switch try leerDibujo(argumentos, orden: "tabla", notacion) {
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
            guard let recorrido = TablaArmonica(recorrido: acordes) else { return errorDeRecorrido("tabla", notacion) }
            tabla = recorrido
        case .camino(let origen, let destino):
            guard let camino = TablaArmonica(caminoDesde: origen, hasta: destino) else { return errorDeCamino("tabla", notacion) }
            tabla = camino
        case .ciclo(let ciclo, let acorde):
            guard let dibujo = TablaArmonica(ciclo: ciclo, desde: acorde) else { return errorDeCiclo("tabla", notacion) }
            tabla = dibujo
        }
        return bien(tabla.svg(notacion: notacion, margen: margen).trimmingCharacters(in: "\n"))
    }
}
