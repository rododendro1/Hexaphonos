import Foundation
import Armonia

/// Un coral a cuatro voces tal como lo enseña la app: las propuestas de armonización, si se armoniza
/// una melodía, un acorde por fila con sus alturas, los avisos y los ficheros para exportar.
public struct CoralPresentado: Hashable, Sendable {
    public struct Fila: Hashable, Sendable {
        /// El cifrado americano, o "–" si las notas no forman un acorde conocido.
        public let cifrado: String
        /// El cifrado romano, o "" si no se ha analizado.
        public let grado: String
        /// Las alturas de grave a agudo («Do3 Mi4 Sol4 Do5»).
        public let voces: String
    }

    /// La tonalidad, o "" al revisar.
    public let titulo: String
    /// Las armonizaciones de la melodía, de mejor a peor; vacío si no se armoniza.
    public let propuestas: [String]
    public let filas: [Fila]
    /// Las faltas de conducción, o por qué no hay coral.
    public let avisos: [String]
    public let ficheros: [FicheroParaExportar]
}

/// La parte de la vista de corales que no es dibujo. No usa SwiftUI, así que se prueba en Linux.
public enum PresentacionDeCoral {
    public enum Tarea: String, CaseIterable, Identifiable, Hashable, Sendable {
        case armonizar = "Armonizar"
        case realizar = "Realizar"
        case revisar = "Revisar"
        public var id: Self { self }

        /// Qué se escribe en el campo de texto.
        public var indicacion: String {
            switch self {
            case .armonizar: return "Melodía (Mi4 Fa4 Re4 Do4, o sin octavas)"
            case .realizar: return "Acordes (Do Fa Sol7 Do)"
            case .revisar: return "Voces de grave a agudo (Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4)"
            }
        }

        /// Un texto de ejemplo para empezar.
        public var ejemplo: String {
            switch self {
            case .armonizar: return "Mi4 Fa4 Re4 Do4"
            case .realizar: return "Do Fa Sol7 Do"
            case .revisar: return "Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4, La2 Do4 Mi4 Do5"
            }
        }

        /// Si admite una tonalidad («en Sol mayor»); si no se da, se estima.
        public var usaTonalidad: Bool { self != .revisar }
    }

    /// Hace la tarea con el texto y, si no está vacía, la tonalidad («La menor»).
    public static func presentar(_ tarea: Tarea, _ texto: String, tonalidad: String = "", propuestas: Int = 3,
                                 notacion: Nomenclatura) throws -> CoralPresentado {
        let dada = tonalidad.trimmingCharacters(in: .whitespaces)
        let leida: Tonalidad? = try dada.isEmpty ? nil : Tonalidad(leyendo: dada)
        switch tarea {
        case .armonizar: return try armonizar(texto, en: leida, propuestas: propuestas, notacion: notacion)
        case .realizar: return try realizar(texto, en: leida, notacion: notacion)
        case .revisar: return try revisar(texto, notacion: notacion)
        }
    }

    /// Las mejores armonizaciones de una melodía y, si las notas llevan octava, el coral a cuatro voces
    /// con la melodía en el soprano.
    static func armonizar(_ texto: String, en tonalidad: Tonalidad?, propuestas: Int,
                          notacion: Nomenclatura) throws -> CoralPresentado {
        let partes = texto.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !partes.isEmpty else { throw ErrorDeLectura(texto: texto, posicion: nil, motivo: .textoVacio) }
        let alturas = partes.compactMap { Altura(texto: $0) }
        let conOctavas = alturas.count == partes.count
        let notas = try conOctavas ? alturas.map(\.nota) : partes.map { try Nota(leyendo: $0) }
        guard let tonalidad = tonalidad ?? Tonalidad.candidatos(notas: notas).first?.valor else {
            throw ErrorDeLectura(texto: texto, posicion: nil, motivo: .textoVacio)
        }
        let candidatos = tonalidad.armonizar(melodia: notas, propuestas: propuestas)
        var avisos: [String] = []
        if candidatos.isEmpty { avisos.append("No hay ninguna armonización para esta melodía en esta tonalidad.") }

        var filas: [CoralPresentado.Fila] = []
        var ficheros: [FicheroParaExportar] = []
        if !conOctavas {
            avisos.append("Escribe las notas con su octava (Mi4 Re4 Do4) para verlas a cuatro voces.")
        } else if let coral = tonalidad.armonizarACuatroVoces(alturas) {
            filas = self.filas(coral.armonizacion.analisis, coral.voces, notacion)
            ficheros = self.ficheros(coral.voces, tonalidad, notacion, nombre: "Armonización")
        } else {
            avisos.append("No hay coral a cuatro voces sin faltas para esta melodía (el soprano va de Do4 a Sol5).")
        }
        return CoralPresentado(titulo: tonalidad.nombre(en: notacion),
                               propuestas: candidatos.map { $0.valor.texto(notacion) },
                               filas: filas, avisos: avisos, ficheros: ficheros)
    }

    /// Los acordes escritos a cuatro voces, sin faltas de conducción.
    static func realizar(_ texto: String, en tonalidad: Tonalidad?, notacion: Nomenclatura) throws -> CoralPresentado {
        let analisis = try AnalisisArmonico.analizar(leyendo: texto, en: tonalidad)
        let titulo = analisis.tonalidad.nombre(en: notacion)
        guard let voces = ConduccionDeVoces.realizar(analisis.acordes.map(\.acorde), en: analisis.tonalidad) else {
            return CoralPresentado(titulo: titulo, propuestas: [], filas: [],
                                   avisos: ["No hay forma de escribir estos acordes a cuatro voces sin faltas."],
                                   ficheros: [])
        }
        return CoralPresentado(titulo: titulo, propuestas: [], filas: filas(analisis, voces, notacion), avisos: [],
                               ficheros: ficheros(voces, analisis.tonalidad, notacion, nombre: "Coral"))
    }

    /// Las faltas de conducción (quintas y octavas paralelas, cruzamientos…) de unas voces escritas a mano.
    static func revisar(_ texto: String, notacion: Nomenclatura) throws -> CoralPresentado {
        let coral = try ConduccionDeVoces(leyendo: texto)
        let filas = coral.acordes.map { alturas in
            CoralPresentado.Fila(cifrado: Acorde.identificar(alturas).first?.cifrado(en: notacion) ?? "–", grado: "",
                                 voces: voces(alturas, notacion))
        }
        let problemas = coral.problemas.map { $0.descripcion(en: notacion) }
        return CoralPresentado(titulo: "", propuestas: [], filas: filas,
                               avisos: problemas.isEmpty ? ["Sin faltas de conducción."] : problemas,
                               ficheros: ficheros(coral, nil, notacion, nombre: "Coral"))
    }

    static func filas(_ analisis: AnalisisArmonico, _ coral: ConduccionDeVoces,
                      _ notacion: Nomenclatura) -> [CoralPresentado.Fila] {
        zip(analisis.acordes, coral.acordes).map { analizado, alturas in
            CoralPresentado.Fila(cifrado: analizado.acorde.cifrado(en: notacion), grado: analizado.cifrado,
                                 voces: voces(alturas, notacion))
        }
    }

    static func voces(_ alturas: [Altura], _ notacion: Nomenclatura) -> String {
        alturas.map { $0.nombre(en: notacion) }.joined(separator: " ")
    }

    /// La partitura, con los cifrados encima y el análisis debajo, y el MIDI.
    static func ficheros(_ coral: ConduccionDeVoces, _ tonalidad: Tonalidad?, _ notacion: Nomenclatura,
                         nombre: String) -> [FicheroParaExportar] {
        [
            .musicXML(coral.musicXML(tonalidad: tonalidad, titulo: nombre, cifrados: true, analisis: true,
                                     notacion: notacion), nombre: nombre),
            .midi(coral.midi(tonalidad: tonalidad, titulo: nombre, notacion: notacion), nombre: nombre),
        ]
    }
}
