import Foundation

let ayuda = """
    Mide cuánto tarda el motor. Compílalo con optimización, o los tiempos no dicen nada:

        swift run -c release RendimientoArmonia [opciones]

    Opciones:
        --filtro <texto>      solo los casos cuyo nombre contiene el texto («armonizar», «digitaciones»…)
        --tiempo <segundos>   cuánto se repite cada caso (0.5 por defecto)
        --json <fichero>      guarda los tiempos, para compararlos después
        --comparar <fichero>  añade los tiempos guardados y el cambio de la mediana

    Escribe una tabla en Markdown.
    """

func fallar(_ mensaje: String) -> Never {
    FileHandle.standardError.write(Data("\(mensaje)\n\nUso: swift run -c release RendimientoArmonia --ayuda\n".utf8))
    exit(2)
}

var presupuesto = 0.5
var filtro: String?
var rutaJSON: String?
var rutaAnterior: String?

var restantes = Array(CommandLine.arguments.dropFirst())
while !restantes.isEmpty {
    let opcion = restantes.removeFirst()
    if ["--ayuda", "--help", "-h"].contains(opcion) {
        print(ayuda)
        exit(0)
    }
    guard ["--filtro", "--tiempo", "--json", "--comparar"].contains(opcion) else { fallar("Opción desconocida: \(opcion)") }
    guard !restantes.isEmpty else { fallar("Falta el valor de \(opcion)") }
    let valor = restantes.removeFirst()
    switch opcion {
    case "--filtro": filtro = valor.lowercased()
    case "--tiempo":
        guard let segundos = Double(valor), segundos > 0 else { fallar("--tiempo necesita un número de segundos") }
        presupuesto = segundos
    case "--json": rutaJSON = valor
    default: rutaAnterior = valor
    }
}

var anteriores: [String: Resultado] = [:]
if let rutaAnterior {
    do {
        let datos = try Data(contentsOf: URL(fileURLWithPath: rutaAnterior))
        let leidos = try JSONDecoder().decode([Resultado].self, from: datos)
        anteriores = Dictionary(leidos.map { ($0.caso, $0) }, uniquingKeysWith: { a, _ in a })
    } catch {
        fallar("No se puede leer \(rutaAnterior): \(error)")
    }
}

let casos = Casos.todos().filter { caso in filtro.map { caso.titulo.lowercased().contains($0) } ?? true }
guard !casos.isEmpty else { fallar("Ningún caso contiene «\(filtro ?? "")»") }

#if DEBUG
print("> **Aviso:** compilado sin optimización (`-c debug`); los tiempos no se parecen a los de las apps.\n")
#endif

let comparando = !anteriores.isEmpty
print("| Caso | Primera vez | Mediana | Mínimo | Veces |" + (comparando ? " Antes | Cambio |" : ""))
print("|---|--:|--:|--:|--:|" + (comparando ? "--:|--:|" : ""))

var comprobacion = 0
var resultados: [Resultado] = []
for caso in casos {
    let r = Medicion.medir(caso, presupuesto: presupuesto, comprobacion: &comprobacion)
    resultados.append(r)
    var fila = "| \(r.caso) | \(Medicion.texto(r.primera)) | \(Medicion.texto(r.mediana)) | \(Medicion.texto(r.minimo)) | \(r.repeticiones) |"
    if comparando {
        if let antes = anteriores[r.caso] {
            fila += " \(Medicion.texto(antes.mediana)) | \(Medicion.cambio(r.mediana, antes: antes.mediana)) |"
        } else {
            fila += " – | – |"
        }
    }
    print(fila)
    fflush(stdout)
}

if let rutaJSON {
    let codificador = JSONEncoder()
    codificador.outputFormatting = [.prettyPrinted, .sortedKeys]
    do {
        try codificador.encode(resultados).write(to: URL(fileURLWithPath: rutaJSON))
    } catch {
        fallar("No se puede escribir \(rutaJSON): \(error)")
    }
}

// Para que el optimizador no quite ningún cálculo: el resultado de todos sale del programa.
FileHandle.standardError.write(Data("Comprobación: \(comprobacion)\n".utf8))
