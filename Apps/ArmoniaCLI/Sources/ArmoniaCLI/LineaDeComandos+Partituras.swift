import Armonia
import Foundation

// MARK: - Partituras: MusicXML y MIDI

extension LineaDeComandos {
    enum Formato { case musicXML, midi }

    /// `musicxml melodia …` y `midi melodia …`: las mismas opciones, salvo la clave (solo MusicXML)
    /// y el instrumento (solo MIDI).
    static func partitura(_ argumentos: [String], _ notacion: Nomenclatura, formato: Formato) throws -> ResultadoDeOrden {
        let orden = formato == .midi ? "midi" : "musicxml"
        let ejemplo = "armonia \(orden) melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4"
        guard let tipo = argumentos.first?.lowercased() else { return uso("falta «melodia», «coral» o «acordes»: \(ejemplo)") }
        // Los argumentos hasta la primera opción son la música; cada opción toma lo que la sigue.
        var musica: [String] = []
        var opciones: [String: String] = [:]
        var opcion: String?
        var marcas: Set<String> = []
        let sinValor: Set = ["cifrados", "analisis", "análisis"]
        for argumento in argumentos.dropFirst() {
            if argumento.hasPrefix("--") {
                let nombre = String(argumento.dropFirst(2)).lowercased()
                if sinValor.contains(nombre) {
                    marcas.insert(nombre == "análisis" ? "analisis" : nombre)
                    opcion = nil
                    continue
                }
                opcion = nombre
                opciones[nombre] = ""
            } else if let actual = opcion {
                opciones[actual] = opciones[actual]!.isEmpty ? argumento : opciones[actual]! + " " + argumento
            } else {
                musica.append(argumento)
            }
        }
        let conocidas: Set = formato == .midi
            ? ["compas", "anacrusa", "tonalidad", "tempo", "titulo", "duracion", "instrumento"]
            : ["compas", "anacrusa", "tonalidad", "clave", "tempo", "titulo", "duracion"]
        if let desconocida = opciones.keys.sorted().first(where: { !conocidas.contains($0) }) {
            return uso("opción desconocida: --\(desconocida)")
        }
        var instrumento: Int?
        if let texto = opciones["instrumento"] {
            guard let n = Int(texto), (0...127).contains(n) else {
                return uso("el instrumento es un programa General MIDI de 0 a 127: --instrumento 52")
            }
            instrumento = n
        }
        if formato == .midi && !marcas.isEmpty { return uso("--cifrados y --analisis son para MusicXML") }
        if let vacia = opciones.keys.sorted().first(where: { opciones[$0]!.isEmpty }) {
            return uso("falta el valor de --\(vacia)")
        }
        let compas = try opciones["compas"].map { try Compas(leyendo: $0) } ?? .compasillo
        let tonalidad = try opciones["tonalidad"].map { try Tonalidad(leyendo: $0) }
        var tempo: Tempo?
        if let texto = opciones["tempo"] {
            let partes = texto.split(separator: " ").map(String.init)
            guard let bpm = Double(partes[0].replacingComa()), bpm > 0, partes.count <= 2 else {
                return uso("el tempo se escribe «--tempo 90» o «--tempo 60 4.»")
            }
            tempo = Tempo(bpm, unidad: try partes.dropFirst().first.map { try Duracion(leyendo: $0) } ?? .negra)
        }
        let titulo = opciones["titulo"]

        switch tipo {
        case "melodia", "melodía", "melody":
            guard !musica.isEmpty else { return uso("faltan las notas: \(ejemplo)") }
            if !marcas.isEmpty { return uso("--cifrados y --analisis son para «coral»") }
            if opciones["duracion"] != nil { return uso("--duracion es solo para «coral»") }
            var clave: Clave?
            if let texto = opciones["clave"] {
                guard let leida = leerClave(texto) else {
                    return uso("clave desconocida: «\(texto)» (sol, fa, do1, do2, do3, do4, sol8b, sol8a, fa3)")
                }
                clave = leida
            }
            let anacrusa = try opciones["anacrusa"].map { try Duracion(leyendo: $0) } ?? .cero
            let voz = try Voz(leyendo: musica.joined(separator: " "), compas: compas, anacrusa: anacrusa)
            if formato == .midi {
                return binario(voz.midi(tonalidad: tonalidad, tempo: tempo, titulo: titulo, instrumento: instrumento ?? 0))
            }
            return bien(voz.musicXML(tonalidad: tonalidad, clave: clave, tempo: tempo, titulo: titulo)
                .trimmingCharacters(in: "\n"))
        case "coral", "chorale":
            guard !musica.isEmpty else {
                return uso("faltan los acordes: armonia \(orden) coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4")
            }
            for opcion in ["clave", "anacrusa"] where opciones[opcion] != nil {
                return uso("--\(opcion) es solo para «melodia»")
            }
            let duracion = try opciones["duracion"].map { try Duracion(leyendo: $0) } ?? .negra
            let coral = try ConduccionDeVoces(leyendo: musica.joined(separator: " "))
            if formato == .midi {
                return binario(coral.midi(duracion: duracion, compas: compas, tonalidad: tonalidad, tempo: tempo,
                                          titulo: titulo, instrumento: instrumento ?? 52, notacion: notacion))
            }
            return bien(coral.musicXML(duracion: duracion, compas: compas, tonalidad: tonalidad, tempo: tempo,
                                       titulo: titulo, cifrados: marcas.contains("cifrados"),
                                       analisis: marcas.contains("analisis"), notacion: notacion)
                .trimmingCharacters(in: "\n"))
        case "acordes", "progresion", "progresión", "chords":
            guard !musica.isEmpty else { return uso("faltan los acordes: armonia \(orden) acordes Do Lam Re7 Sol7 Do") }
            for opcion in ["clave", "anacrusa"] where opciones[opcion] != nil {
                return uso("--\(opcion) es solo para «melodia»")
            }
            if !marcas.isEmpty { return uso("los acordes llevan siempre cifrados y análisis") }
            let duracion = try opciones["duracion"].map { try Duracion(leyendo: $0) } ?? .blanca
            let analisis = try AnalisisArmonico.analizar(leyendo: musica.joined(separator: " "), en: tonalidad)
            if formato == .midi {
                return binario(analisis.midi(duracion: duracion, compas: compas, tempo: tempo, titulo: titulo,
                                             instrumento: instrumento ?? 0, notacion: notacion))
            }
            return bien(analisis.musicXML(duracion: duracion, compas: compas, tempo: tempo, titulo: titulo,
                                          notacion: notacion).trimmingCharacters(in: "\n"))
        default:
            return uso("«\(tipo)»: se exporta una «melodia», un «coral» o unos «acordes»")
        }
    }

    /// "sol", "fa", "do3", "do en tercera", "clave de fa", "treble", "bass", "alto"…
    static func leerClave(_ texto: String) -> Clave? {
        let abreviaturas: [String: Clave] = [
            "sol": .sol, "fa": .fa, "do1": .doEnPrimera, "do2": .doEnSegunda, "do3": .doEnTercera,
            "do4": .doEnCuarta, "sol8b": .solOctavaBaja, "sol8a": .solOctavaAlta, "fa3": .faEnTercera,
            "g": .sol, "f": .fa, "treble": .sol, "bass": .fa, "alto": .doEnTercera, "tenor": .doEnCuarta,
        ]
        let limpio = texto.lowercased()
        if let clave = abreviaturas[limpio] { return clave }
        return Clave.allCases.first { clave in
            [clave.nombre, clave.nombre(en: .ingles)].contains { nombre in
                nombre == limpio || nombre.hasPrefix("clave de ") && String(nombre.dropFirst(9)) == limpio
            }
        }
    }
}
