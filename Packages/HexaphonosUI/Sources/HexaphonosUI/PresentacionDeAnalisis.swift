import Armonia

/// El análisis de una progresión tal como lo enseña la app: en tramos (uno por tonalidad, con la
/// modulación que lo abre), las cadencias y los ficheros para exportar.
public struct AnalisisPresentado: Hashable, Sendable {
    public struct Fila: Hashable, Sendable {
        /// El cifrado americano («Re7»).
        public let cifrado: String
        /// El cifrado romano («V7/V»).
        public let grado: String
        /// La función tonal, o "" si no tiene.
        public let funcion: String
    }

    public struct Tramo: Hashable, Sendable {
        /// La modulación que abre el tramo; `nil` en el primero.
        public let cabecera: String?
        public let filas: [Fila]
    }

    /// La tonalidad, o el recorrido de tonalidades si modula («Do mayor → Sol mayor»).
    public let titulo: String
    public let tramos: [Tramo]
    public let cadencias: [String]
    public let ficheros: [FicheroParaExportar]
}

/// La parte de la vista de análisis que no es dibujo. No usa SwiftUI, así que se prueba en Linux.
public enum PresentacionDeAnalisis {
    /// Analiza «Do Lam Re7 Sol7 Do», con las modulaciones y sus acordes pivote.
    ///
    /// La partitura y el MIDI se escriben en una sola tonalidad, la que mejor explica toda la
    /// progresión, porque los dos formatos solo anotan una.
    public static func analizar(_ texto: String, notacion: Nomenclatura) throws -> AnalisisPresentado {
        let recorrido = try RecorridoTonal(leyendo: texto)
        let cabeceras = [nil] + recorrido.modulaciones.map { Optional($0.descripcion(en: notacion)) }
        let tramos = zip(cabeceras, recorrido.tramos).map { cabecera, tramo in
            AnalisisPresentado.Tramo(cabecera: cabecera, filas: tramo.analisis.acordes.map { fila($0, notacion) })
        }
        let analisis = try AnalisisArmonico.analizar(leyendo: texto)
        let nombre = "Progresión"
        return AnalisisPresentado(
            titulo: recorrido.nombre(en: notacion),
            tramos: tramos,
            cadencias: recorrido.cadencias.map { $0.descripcion(en: notacion) },
            ficheros: [
                .musicXML(analisis.musicXML(titulo: nombre, notacion: notacion), nombre: nombre),
                .midi(analisis.midi(titulo: nombre, notacion: notacion), nombre: nombre),
            ])
    }

    static func fila(_ analizado: AcordeAnalizado, _ notacion: Nomenclatura) -> AnalisisPresentado.Fila {
        AnalisisPresentado.Fila(cifrado: analizado.acorde.cifrado(en: notacion), grado: analizado.cifrado,
                                funcion: analizado.funcion?.nombre(en: notacion) ?? "")
    }
}
