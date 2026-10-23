import Armonia
import Foundation

// MARK: - Digitaciones: cómo tocar un acorde en un instrumento de cuerda con trastes

extension LineaDeComandos {
    /// Quita una opción sin valor (`--tab`) de los argumentos y dice si estaba.
    static func quitarMarca(_ nombres: [String], de argumentos: inout [String]) -> Bool {
        guard let i = argumentos.firstIndex(where: { nombres.contains($0) }) else { return false }
        argumentos.remove(at: i)
        return true
    }

    /// Quita una opción con valor (`--limite 5`) de los argumentos. `.ausente` si no está, `.sinValor` si
    /// está pero no la sigue nada que no sea otra opción.
    enum Opcion: Equatable {
        case ausente
        case sinValor
        case valor(String)
    }

    static func quitarOpcion(_ nombres: [String], de argumentos: inout [String]) -> Opcion {
        guard let i = argumentos.firstIndex(where: { nombres.contains($0) }) else { return .ausente }
        guard i + 1 < argumentos.count, !argumentos[i + 1].hasPrefix("--") else {
            argumentos.remove(at: i)
            return .sinValor
        }
        let valor = argumentos[i + 1]
        argumentos.removeSubrange(i...(i + 1))
        return .valor(valor)
    }

    /// `digitaciones Sol7/Si --instrumento ukelele`: formas de tocar el acorde, de la más cómoda a la menos.
    static func digitaciones(_ argumentos: [String], _ notacion: Nomenclatura) throws -> ResultadoDeOrden {
        let ingles = notacion.vocabulario == .ingles
        var argumentos = argumentos
        let ejemplo = "armonia digitaciones Sol7/Si --instrumento ukelele"

        let conTab = quitarMarca(["--tab"], de: &argumentos)
        // Por defecto la quinta puede faltar en los acordes de cuatro notas o más (el Do7 `x32310`): es lo normal en
        // una guitarra. Con --completo se exigen todas las notas.
        let completo = quitarMarca(["--completo", "--complete"], de: &argumentos)

        var encordado = Encordado.guitarra
        switch quitarOpcion(["--instrumento", "--instrument"], de: &argumentos) {
        case .ausente:
            break
        case .sinValor:
            return uso("falta el instrumento: \(ejemplo)")
        case .valor(let nombre):
            guard let encontrado = Encordado(nombre: nombre) else {
                let conocidos = Encordado.todos.map(\.nombre).joined(separator: ", ")
                return uso("instrumento desconocido: «\(nombre)» (\(conocidos))")
            }
            encordado = encontrado
        }

        var limite = 5
        switch quitarOpcion(["--limite", "--limit"], de: &argumentos) {
        case .ausente:
            break
        case .sinValor:
            return uso("falta el número de digitaciones: --limite 5")
        case .valor(let texto):
            guard let n = Int(texto), (1...200).contains(n) else {
                return uso("el límite es un número de 1 a 200: --limite 5")
            }
            limite = n
        }

        var maximoDeDedos = 4
        switch quitarOpcion(["--dedos", "--fingers"], de: &argumentos) {
        case .ausente:
            break
        case .sinValor:
            return uso("falta el número de dedos: --dedos 3")
        case .valor(let texto):
            guard let n = Int(texto), (1...4).contains(n) else {
                return uso("los dedos son un número de 1 a 4: --dedos 3")
            }
            maximoDeDedos = n
        }

        var maximoTraste = 12
        switch quitarOpcion(["--traste", "--fret"], de: &argumentos) {
        case .ausente:
            break
        case .sinValor:
            return uso("falta el traste más alto: --traste 12")
        case .valor(let texto):
            guard let n = Int(texto), (0...24).contains(n) else {
                return uso("el traste más alto es un número de 0 a 24: --traste 12")
            }
            maximoTraste = n
        }

        if let desconocida = argumentos.first(where: { $0.hasPrefix("--") }) {
            return uso("opción desconocida: «\(desconocida)»")
        }
        guard !argumentos.isEmpty else { return uso("falta el cifrado: \(ejemplo)") }

        let mastil = Mastil(encordado)
        let bloques = try argumentos.map { texto -> String in
            let acorde = try Acorde(leyendo: texto)
            var lineas = ["\(acorde.cifrado(en: notacion)) · \(encordado.nombre)"]
            let formas = mastil.digitaciones(de: acorde, maximoDeDedos: maximoDeDedos, maximoTraste: maximoTraste,
                                             exigirQuinta: completo, limite: limite)
            guard !formas.isEmpty else {
                lineas.append(ingles ? "  no comfortable fingerings found" : "  no hay digitaciones cómodas")
                return lineas.joined(separator: "\n")
            }
            for forma in formas {
                let notas = forma.notas(para: acorde).map { $0.nombre(en: notacion) }.joined(separator: " ")
                lineas.append("  " + forma.cifra.padding(hasta: 17) + notas.padding(hasta: 18)
                              + descripcion(de: forma, ingles: ingles))
                if conTab { lineas += tab(de: forma, notacion) }
            }
            return lineas.joined(separator: "\n")
        }
        return bien(bloques.joined(separator: "\n\n"))
    }

    /// «(3 dedos)», o «(4 dedos, cejilla en el traste 1)».
    static func descripcion(de forma: Digitacion, ingles: Bool) -> String {
        let n = forma.dedos
        var texto = ingles ? "\(n) \(n == 1 ? "finger" : "fingers")" : "\(n) \(n == 1 ? "dedo" : "dedos")"
        if let cejilla = forma.cejilla {
            texto += ingles ? ", barre at fret \(cejilla)" : ", cejilla en el traste \(cejilla)"
        }
        return "(\(texto))"
    }

    /// La digitación como una tablatura: la cuerda más aguda arriba, el traste (o «x») de cada una.
    static func tab(de forma: Digitacion, _ notacion: Nomenclatura) -> [String] {
        let cuerdas = forma.mastil.encordado.cuerdas
        let nombres = cuerdas.map { $0.nota.nombre(en: notacion) }
        let ancho = nombres.map(\.count).max() ?? 0
        return cuerdas.indices.reversed().map { i in
            let traste = forma.trastes[i].map(String.init) ?? "x"
            let relleno = String(repeating: " ", count: max(0, 2 - traste.count))
            return "      " + nombres[i].padding(hasta: ancho + 1) + "|-" + relleno + traste + "-"
        }
    }
}
