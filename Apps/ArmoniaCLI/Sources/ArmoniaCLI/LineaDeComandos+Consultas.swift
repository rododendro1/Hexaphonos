import Armonia
import Foundation

// MARK: - Consultas: acordes, notas, escalas, tonalidades y análisis

extension LineaDeComandos {
    static func describir(acorde: Acorde, _ notacion: Nomenclatura) -> String {
        var lineas = ["\(acorde.cifrado(en: notacion)): \(acorde.tipo.nombre(en: notacion))"]
        let notas = acorde.notas.map { $0.nombre(en: notacion) }.joined(separator: " ")
        let ingles = notacion.vocabulario == .ingles
        if acorde.bajo != acorde.fundamental {
            let bajo = acorde.bajo.nombre(en: notacion)
            let inversion = acorde.inversion.map { ingles ? "inversion \($0)" : "inversión \($0)" }
                ?? (ingles ? "bass not in the chord" : "bajo ajeno al acorde")
            lineas.append((ingles ? "  notes: " : "  notas: ") + notas + (ingles ? "  (bass \(bajo), " : "  (bajo \(bajo), ") + inversion + ")")
        } else {
            lineas.append((ingles ? "  notes: " : "  notas: ") + notas)
        }
        lineas.append("  " + acorde.componentes.map { "\($0.nota.nombre(en: notacion)) \($0.papel.nombre(en: notacion))" }
            .joined(separator: " · "))
        return lineas.joined(separator: "\n")
    }

    static func identificar(_ textos: [String], _ notacion: Nomenclatura) throws -> String {
        let ingles = notacion.vocabulario == .ingles
        // Con octava se tiene en cuenta el bajo; sin ella, solo las notas.
        let candidatos: [Candidato<Acorde>]
        if let alturas = try? textos.map({ try Altura(leyendo: $0) }) {
            candidatos = Acorde.candidatos(alturas)
        } else {
            candidatos = Acorde.candidatos(try textos.map { try Nota(leyendo: $0) })
        }
        guard !candidatos.isEmpty else { return ingles ? "No chord found." : "No forman ningún acorde conocido." }
        return candidatos.prefix(5).map { candidato in
            var linea = "\(candidato.valor.cifrado(en: notacion))  \(candidato.valor.tipo.nombre(en: notacion))"
            if !candidato.omitidas.isEmpty {
                let omitidas = candidato.omitidas.map { $0.nombre(en: notacion) }.joined(separator: ", ")
                linea += ingles ? "  (omits \(omitidas))" : "  (sin \(omitidas))"
            }
            return linea
        }.joined(separator: "\n")
    }

    static func intervalo(_ a: String, _ b: String, _ notacion: Nomenclatura) throws -> String {
        let ingles = notacion.vocabulario == .ingles
        let intervalo: Intervalo
        if let grave = try? Altura(leyendo: a), let aguda = try? Altura(leyendo: b) {
            intervalo = aguda - grave
        } else {
            intervalo = try Nota(leyendo: a).intervalo(hasta: try Nota(leyendo: b))
        }
        let semitonos = ingles ? "\(intervalo.semitonos) semitones" : "\(intervalo.semitonos) semitonos"
        return "\(intervalo.nombre(en: notacion)) (\(intervalo.texto(notacion)), \(semitonos))"
    }

    static func describir(escala: Escala, _ notacion: Nomenclatura) -> String {
        let ingles = notacion.vocabulario == .ingles
        var lineas = [escala.nombre(en: notacion),
                      (ingles ? "  notes: " : "  notas: ") + escala.notas.map { $0.nombre(en: notacion) }.joined(separator: " ")]
        // Los acordes de cada grado, si la escala es heptatónica y todos forman un acorde conocido.
        let acordes = escala.armonizar(cuatriadas: true).compactMap { $0 }
        let romanos = escala.cifradosRomanos(cuatriadas: true).compactMap { $0 }
        if acordes.count == escala.notas.count, romanos.count == acordes.count {
            let pares = zip(romanos, acordes).map { "\($0) \($1.cifrado(en: notacion))" }
            lineas.append((ingles ? "  chords: " : "  acordes: ") + pares.joined(separator: " · "))
        }
        return lineas.joined(separator: "\n")
    }

    static func describir(tonalidad: Tonalidad, _ notacion: Nomenclatura) -> String {
        let ingles = notacion.vocabulario == .ingles
        let armadura: String
        switch tonalidad.armadura {
        case 0: armadura = ingles ? "no sharps or flats" : "sin alteraciones"
        default:
            let signos = tonalidad.notasDeLaArmadura.map { $0.nombre(en: notacion) }.joined(separator: " ")
            let cantidad = abs(tonalidad.armadura)
            let sostenidos = tonalidad.armadura > 0
            let nombre = ingles ? (sostenidos ? "sharp" : "flat") + (cantidad == 1 ? "" : "s")
                                : (sostenidos ? "sostenido" : "bemol") + (cantidad == 1 ? "" : (sostenidos ? "s" : "es"))
            armadura = "\(signos) (\(cantidad) \(nombre))"
        }
        let acordes = zip(tonalidad.cifradosRomanos(cuatriadas: true), tonalidad.armonizar(cuatriadas: true))
            .map { "\($0) \($1.cifrado(en: notacion))" }.joined(separator: " · ")
        return [
            tonalidad.nombre(en: notacion),
            (ingles ? "  key signature: " : "  armadura: ") + armadura,
            (ingles ? "  relative: " : "  relativa: ") + tonalidad.relativa.nombre(en: notacion)
                + (ingles ? " · parallel: " : " · homónima: ") + tonalidad.homonima.nombre(en: notacion),
            (ingles ? "  chords: " : "  acordes: ") + acordes,
        ].joined(separator: "\n")
    }

    static func analizar(_ argumentos: [String], _ notacion: Nomenclatura) throws -> ResultadoDeOrden {
        var acordes = argumentos
        var tonalidad: Tonalidad?
        if let i = acordes.firstIndex(where: { $0 == "--en" || $0 == "--in" }) {
            guard i + 1 < acordes.count else { return uso("falta la tonalidad tras --en") }
            tonalidad = try Tonalidad(leyendo: acordes[(i + 1)...].joined(separator: " "))
            acordes = Array(acordes[..<i])
        }
        guard !acordes.isEmpty else { return uso("faltan los acordes: armonia analizar Do Fa Sol7 Do") }
        let analisis = try AnalisisArmonico.analizar(leyendo: acordes.joined(separator: " "), en: tonalidad)
        var lineas = [analisis.nombre(en: notacion)]
        // Columnas de al menos 10 caracteres, más anchas si un cifrado no cabe.
        let ancho1 = max(10, (analisis.acordes.map { $0.acorde.cifrado(en: notacion).count }.max() ?? 0) + 2)
        let ancho2 = max(10, (analisis.acordes.map(\.cifrado.count).max() ?? 0) + 2)
        for analizado in analisis.acordes {
            let funcion = analizado.funcion?.nombre(en: notacion) ?? "–"
            let cifrado = analizado.acorde.cifrado(en: notacion)
            lineas.append("  " + cifrado.padding(hasta: ancho1) + analizado.cifrado.padding(hasta: ancho2) + funcion)
        }
        return bien(lineas.joined(separator: "\n"))
    }

    static func describir(conduccion: ConduccionDeVoces, _ notacion: Nomenclatura) -> String {
        let problemas = conduccion.problemas
        guard !problemas.isEmpty else {
            return notacion.vocabulario == .ingles ? "No voice-leading errors." : "Sin faltas de conducción."
        }
        return problemas.map { $0.descripcion(en: notacion) }.joined(separator: "\n")
    }
}
