import Armonia

// MARK: - Armonización y realización a cuatro voces

extension LineaDeComandos {
    /// Quita `--en <tonalidad>` del final de los argumentos. `nil` dentro si no está; lanza un
    /// error de lectura si la tonalidad no se puede leer.
    static func leerTonalidad(_ argumentos: inout [String]) throws -> Tonalidad?? {
        guard let i = argumentos.firstIndex(where: { $0 == "--en" || $0 == "--in" }) else { return .some(nil) }
        guard i + 1 < argumentos.count else { return nil }
        let tonalidad = try Tonalidad(leyendo: argumentos[(i + 1)...].joined(separator: " "))
        argumentos.removeSubrange(i...)
        return .some(tonalidad)
    }

    /// `armonizar Mi4 Re4 Do4`: las mejores armonizaciones y, si las notas llevan octava, el coral a
    /// cuatro voces con la melodía en el soprano.
    static func armonizar(_ argumentos: [String], _ notacion: Nomenclatura) throws -> ResultadoDeOrden {
        var argumentos = argumentos
        var propuestas = 3
        if let i = argumentos.firstIndex(where: { $0 == "--propuestas" || $0 == "--proposals" }) {
            guard i + 1 < argumentos.count, let n = Int(argumentos[i + 1]), (1...20).contains(n) else {
                return uso(.propuestasFueraDeRango, notacion)
            }
            propuestas = n
            argumentos.removeSubrange(i...(i + 1))
        }
        guard let dada = try leerTonalidad(&argumentos) else { return uso(.faltaTonalidadTrasEn, notacion) }
        guard !argumentos.isEmpty else { return uso(.faltanNotasDeLaArmonizacion, notacion) }
        // Con octava, alturas (y coral); sin ella, notas.
        let alturas = argumentos.map { Altura(texto: $0) }
        let notas = try alturas.allSatisfy({ $0 != nil }) ? alturas.map { $0!.nota } : argumentos.map { try Nota(leyendo: $0) }
        let tonalidad = dada ?? Tonalidad.candidatos(notas: notas).first!.valor

        let candidatos = tonalidad.armonizar(melodia: notas, propuestas: propuestas)
        guard !candidatos.isEmpty else { return bien(Mensaje.sinArmonizacion.texto(en: notacion)) }
        var lineas = [tonalidad.nombre(en: notacion)]
        for (n, candidato) in candidatos.enumerated() {
            lineas.append("  \(n + 1). " + candidato.valor.texto(notacion))
        }
        if alturas.allSatisfy({ $0 != nil }) {
            lineas.append(Mensaje.aCuatroVoces.texto(en: notacion))
            if let coral = tonalidad.armonizarACuatroVoces(alturas.map { $0! }) {
                lineas += describir(coral.armonizacion.analisis, voces: coral.voces, notacion)
            } else {
                lineas.append("  " + Mensaje.sinRealizacion.texto(en: notacion))
            }
        }
        return bien(lineas.joined(separator: "\n"))
    }

    /// `realizar Do Fa Sol7 Do`: los acordes escritos a cuatro voces, sin faltas.
    static func realizar(_ argumentos: [String], _ notacion: Nomenclatura) throws -> ResultadoDeOrden {
        var argumentos = argumentos
        guard let tonalidad = try leerTonalidad(&argumentos) else { return uso(.faltaTonalidadTrasEn, notacion) }
        guard !argumentos.isEmpty else { return uso(.faltanAcordesDeLaRealizacion, notacion) }
        let analisis = try AnalisisArmonico.analizar(leyendo: argumentos.joined(separator: " "), en: tonalidad)
        guard let voces = ConduccionDeVoces.realizar(analisis.acordes.map(\.acorde), en: analisis.tonalidad) else {
            return bien(Mensaje.sinRealizacion.texto(en: notacion))
        }
        return bien(([analisis.tonalidad.nombre(en: notacion)] + describir(analisis, voces: voces, notacion)).joined(separator: "\n"))
    }

    /// Una línea por acorde: el cifrado, el grado y las alturas de grave a agudo
    /// («Do        I         Do3 Mi4 Sol4 Do5»), que se pueden copiar en `revisar` o `musicxml coral`.
    static func describir(_ analisis: AnalisisArmonico, voces: ConduccionDeVoces, _ notacion: Nomenclatura) -> [String] {
        let ancho1 = max(10, (analisis.acordes.map { $0.acorde.cifrado(en: notacion).count }.max() ?? 0) + 2)
        let ancho2 = max(10, (analisis.cifrados.map(\.count).max() ?? 0) + 2)
        return zip(analisis.acordes, voces.acordes).map { analizado, alturas in
            "  " + analizado.acorde.cifrado(en: notacion).padding(hasta: ancho1) + analizado.cifrado.padding(hasta: ancho2)
                + alturas.map { $0.nombre(en: notacion) }.joined(separator: " ")
        }
    }
}
