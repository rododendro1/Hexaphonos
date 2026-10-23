import Armonia
import Foundation

// MARK: - Consultas: acordes, notas, escalas, tonalidades y análisis

extension LineaDeComandos {
    static func describir(acorde: Acorde, _ notacion: Nomenclatura) -> String {
        var lineas = ["\(acorde.cifrado(en: notacion)): \(acorde.tipo.nombre(en: notacion))"]
        let notas = acorde.notas.map { $0.nombre(en: notacion) }.joined(separator: " ")
        let t = { (mensaje: Mensaje) in mensaje.texto(en: notacion) }
        if acorde.bajo != acorde.fundamental {
            let bajo = t(.bajo(acorde.bajo.nombre(en: notacion)))
            let inversion = acorde.inversion.map { t(.inversion($0)) } ?? t(.bajoAjeno)
            lineas.append("  \(t(.notas)): \(notas)  (\(bajo), \(inversion))")
        } else {
            lineas.append("  \(t(.notas)): \(notas)")
        }
        lineas.append("  " + acorde.componentes.map { "\($0.nota.nombre(en: notacion)) \($0.papel.nombre(en: notacion))" }
            .joined(separator: " · "))
        return lineas.joined(separator: "\n")
    }

    static func identificar(_ textos: [String], _ notacion: Nomenclatura) throws -> String {
        // Con octava se tiene en cuenta el bajo; sin ella, solo las notas.
        let candidatos: [Candidato<Acorde>]
        if let alturas = try? textos.map({ try Altura(leyendo: $0) }) {
            candidatos = Acorde.candidatos(alturas)
        } else {
            candidatos = Acorde.candidatos(try textos.map { try Nota(leyendo: $0) })
        }
        guard !candidatos.isEmpty else { return Mensaje.sinAcordes.texto(en: notacion) }
        return candidatos.prefix(5).map { candidato in
            var linea = "\(candidato.valor.cifrado(en: notacion))  \(candidato.valor.tipo.nombre(en: notacion))"
            if !candidato.omitidas.isEmpty {
                let omitidas = candidato.omitidas.map { $0.nombre(en: notacion) }.joined(separator: ", ")
                linea += "  (\(Mensaje.sin(omitidas).texto(en: notacion)))"
            }
            return linea
        }.joined(separator: "\n")
    }

    static func intervalo(_ a: String, _ b: String, _ notacion: Nomenclatura) throws -> String {
        let intervalo: Intervalo
        if let grave = try? Altura(leyendo: a), let aguda = try? Altura(leyendo: b) {
            intervalo = aguda - grave
        } else {
            intervalo = try Nota(leyendo: a).intervalo(hasta: try Nota(leyendo: b))
        }
        let semitonos = Mensaje.semitonos(intervalo.semitonos).texto(en: notacion)
        return "\(intervalo.nombre(en: notacion)) (\(intervalo.texto(notacion)), \(semitonos))"
    }

    static func describir(escala: Escala, _ notacion: Nomenclatura) -> String {
        let t = { (mensaje: Mensaje) in mensaje.texto(en: notacion) }
        var lineas = [escala.nombre(en: notacion),
                      "  \(t(.notas)): " + escala.notas.map { $0.nombre(en: notacion) }.joined(separator: " ")]
        // Los acordes de cada grado, si la escala es heptatónica y todos forman un acorde conocido.
        let acordes = escala.armonizar(cuatriadas: true).compactMap { $0 }
        let romanos = escala.cifradosRomanos(cuatriadas: true).compactMap { $0 }
        if acordes.count == escala.notas.count, romanos.count == acordes.count {
            let pares = zip(romanos, acordes).map { "\($0) \($1.cifrado(en: notacion))" }
            lineas.append("  \(t(.acordes)): " + pares.joined(separator: " · "))
        }
        return lineas.joined(separator: "\n")
    }

    static func describir(tonalidad: Tonalidad, _ notacion: Nomenclatura) -> String {
        let t = { (mensaje: Mensaje) in mensaje.texto(en: notacion) }
        let armadura: String
        switch tonalidad.armadura {
        case 0: armadura = t(.sinAlteraciones)
        default:
            let signos = tonalidad.notasDeLaArmadura.map { $0.nombre(en: notacion) }.joined(separator: " ")
            armadura = "\(signos) (\(t(.alteraciones(abs(tonalidad.armadura), sostenidos: tonalidad.armadura > 0))))"
        }
        let acordes = zip(tonalidad.cifradosRomanos(cuatriadas: true), tonalidad.armonizar(cuatriadas: true))
            .map { "\($0) \($1.cifrado(en: notacion))" }.joined(separator: " · ")
        return [
            tonalidad.nombre(en: notacion),
            "  \(t(.armadura)): " + armadura,
            "  \(t(.relativa)): " + tonalidad.relativa.nombre(en: notacion)
                + " · \(t(.homonima)): " + tonalidad.homonima.nombre(en: notacion),
            "  \(t(.acordes)): " + acordes,
        ].joined(separator: "\n")
    }

    static func analizar(_ argumentos: [String], _ notacion: Nomenclatura) throws -> ResultadoDeOrden {
        var acordes = argumentos
        var tonalidad: Tonalidad?
        if let i = acordes.firstIndex(where: { $0 == "--en" || $0 == "--in" }) {
            guard i + 1 < acordes.count else { return uso(.faltaTonalidadTrasEn, notacion) }
            tonalidad = try Tonalidad(leyendo: acordes[(i + 1)...].joined(separator: " "))
            acordes = Array(acordes[..<i])
        }
        guard !acordes.isEmpty else { return uso(.faltanAcordesDelAnalisis, notacion) }
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
            return Mensaje.sinFaltasDeConduccion.texto(en: notacion)
        }
        return problemas.map { $0.descripcion(en: notacion) }.joined(separator: "\n")
    }
}
