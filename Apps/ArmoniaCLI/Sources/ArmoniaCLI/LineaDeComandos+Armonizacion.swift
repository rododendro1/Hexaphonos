import Armonia
import HexaphonosPresentacion

// MARK: - Armonización y realización a cuatro voces

extension LineaDeComandos {
    /// `armonizar Mi4 Re4 Do4`: las mejores armonizaciones y, si las notas llevan octava, el coral a
    /// cuatro voces con la melodía en el soprano.
    static func armonizar(_ argumentos: [String], _ notacion: Notacion) throws -> ResultadoDeOrden {
        var argumentos = Argumentos(argumentos)
        guard let propuestas = argumentos.quitarNumero("--propuestas", "--proposals", en: 1...20, porDefecto: 3) else {
            return uso(.propuestasFueraDeRango, notacion)
        }
        guard let dada = try argumentos.quitarTonalidad() else { return uso(.faltaTonalidadTrasEn, notacion) }
        guard !argumentos.restantes.isEmpty else { return uso(.faltanNotasDeLaArmonizacion, notacion) }
        let coral = try PresentacionDeCoral.armonizar(argumentos.unidos, en: dada,
                                                      propuestas: propuestas, notacion: notacion)
        guard !coral.avisos.contains(.sinArmonizacion) else { return bien(CoralPresentado.Aviso.sinArmonizacion.texto(en: notacion)) }
        var lineas = [coral.titulo]
        for (n, propuesta) in coral.propuestas.enumerated() {
            lineas.append("  \(n + 1). " + propuesta)
        }
        // Sin octavas no hay coral, y no se dice nada más.
        if !coral.avisos.contains(.faltanOctavas) {
            lineas.append(Mensaje.aCuatroVoces.texto(en: notacion))
            if coral.filas.isEmpty {
                lineas.append("  " + CoralPresentado.Aviso.sinRealizacion.texto(en: notacion))
            } else {
                lineas += describir(coral.filas)
            }
        }
        return bien(lineas.joined(separator: "\n"))
    }

    /// `realizar Do Fa Sol7 Do`: los acordes escritos a cuatro voces, sin faltas.
    static func realizar(_ argumentos: [String], _ notacion: Notacion) throws -> ResultadoDeOrden {
        var argumentos = Argumentos(argumentos)
        guard let tonalidad = try argumentos.quitarTonalidad() else { return uso(.faltaTonalidadTrasEn, notacion) }
        guard !argumentos.restantes.isEmpty else { return uso(.faltanAcordesDeLaRealizacion, notacion) }
        let coral = try PresentacionDeCoral.realizar(argumentos.unidos, en: tonalidad, notacion: notacion)
        guard !coral.avisos.contains(.sinRealizacion) else { return bien(CoralPresentado.Aviso.sinRealizacion.texto(en: notacion)) }
        return bien(([coral.titulo] + describir(coral.filas)).joined(separator: "\n"))
    }

    /// `revisar Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4`: las faltas de conducción, una por línea.
    static func revisar(_ argumentos: [String], _ notacion: Notacion) throws -> ResultadoDeOrden {
        guard !argumentos.isEmpty else { return uso(.faltanAcordesDeLasVoces, notacion) }
        let coral = try PresentacionDeCoral.revisar(argumentos.joined(separator: " "), notacion: notacion)
        return bien(coral.avisos.map { $0.texto(en: notacion) }.joined(separator: "\n"))
    }

    /// Una línea por acorde: el cifrado, el grado y las alturas de grave a agudo
    /// («Do        I         Do3 Mi4 Sol4 Do5»), que se pueden copiar en `revisar` o `musicxml coral`.
    static func describir(_ filas: [CoralPresentado.Fila]) -> [String] {
        let ancho1 = max(10, (filas.map(\.cifrado.count).max() ?? 0) + 2)
        let ancho2 = max(10, (filas.map(\.grado.count).max() ?? 0) + 2)
        return filas.map { "  " + $0.cifrado.padding(hasta: ancho1) + $0.grado.padding(hasta: ancho2) + $0.voces }
    }
}
