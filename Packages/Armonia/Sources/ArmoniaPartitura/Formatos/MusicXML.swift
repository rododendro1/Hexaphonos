import ArmoniaNucleo
import ArmoniaTeoria
// Exportación a MusicXML 4.0 (score-partwise), para abrir melodías y corales en MuseScore,
// Finale, Sibelius, Dorico o cualquier editor de partituras.
//
// Se escribe la grafía de cada voz (`Voz.grafia`): las notas ya divididas y ligadas según el
// compás. La ortografía se conserva tal cual (un Sol♯ es G con alter 1, nunca A♭) y la armadura
// es la de la tonalidad: en MusicXML, `<fifths>` es exactamente `Tonalidad.armadura`.
// MusicXML solo admite las octavas de 0 a 9: una altura fuera de ellas da un documento que los
// editores pueden rechazar.
//
// `Exportacion`, más abajo, reúne lo que comparten MusicXML y MIDI (MIDI.swift): la tonalidad
// estimada, las divisiones del tiempo y las voces de un coral y de una progresión.

extension Voz {
    /// La voz como partitura MusicXML de un solo pentagrama.
    ///
    ///     let voz = try Voz(leyendo: "Do4:4 Re4:8 Mi4:8 Fa4:2", compas: "3/4")
    ///     let xml = voz.musicXML(titulo: "Escala")
    ///
    /// - Parameters:
    ///   - tonalidad: da la armadura; si es `nil`, se estima a partir de las notas.
    ///   - clave: si es `nil`, la de sol o la de fa, según el registro de las notas.
    ///   - tempo: si se da, se escribe la indicación metronómica.
    ///   - titulo: el título de la obra.
    ///   - parte: el nombre del pentagrama.
    public func musicXML(tonalidad: Tonalidad? = nil, clave: Clave? = nil, tempo: Tempo? = nil,
                         titulo: String? = nil, parte: String = "Voz") -> String {
        let tonalidad = tonalidad ?? Exportacion.tonalidad(de: self)
        let clave = clave ?? Clave.masAdecuada(para: eventos.flatMap(\.alturas)) ?? .sol
        var escritor = EscritorMusicXML(compas: compas, anacrusa: anacrusa, tonalidad: tonalidad,
                                        tempo: tempo, titulo: titulo, parte: parte, claves: [clave])
        escritor.anadir(self, pentagrama: 1, numero: 1, plica: nil)
        return escritor.documento
    }
}

extension Coral {
    /// Los acordes como coral en dos pentagramas: las voces agudas (soprano y contralto) en
    /// clave de sol y las graves (tenor y bajo) en clave de fa, con las plicas de la voz de
    /// arriba hacia arriba y las de la de abajo hacia abajo. El último acorde se alarga hasta la
    /// barra si no llega a ella.
    ///
    ///     let coral = try Coral(leyendo: "Do3 Mi4 Sol4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5")
    ///     let xml = coral.musicXML(duracion: .blanca, compas: "3/2", titulo: "Cadencia")
    ///
    /// Con `cifrados`, cada acorde lleva su cifrado americano encima del soprano; con `analisis`,
    /// su cifrado romano y su función debajo del bajo, y la tonalidad al principio. Los acordes
    /// se identifican por sus notas (con el bajo) entre los tipos de `TipoDeAcorde.todos`; los
    /// que no forman ninguno (por ejemplo, por una nota de paso) se quedan sin cifrar.
    ///
    /// - Parameters:
    ///   - duracion: lo que dura cada acorde.
    ///   - tonalidad: da la armadura y la tonalidad del análisis; si es `nil`, se estima (a partir
    ///     de los acordes si se analiza, si no, de las notas).
    ///   - notacion: la de los cifrados y la tonalidad.
    public func musicXML(duracion: Duracion = .negra, compas: Compas = .compasillo,
                         tonalidad: Tonalidad? = nil, tempo: Tempo? = nil,
                         titulo: String? = nil, parte: String = "Coro",
                         cifrados: Bool = false, analisis: Bool = false,
                         notacion: Notacion = .espanol) -> String {
        let todas = acordes.flatMap { $0 }
        // Los acordes que se pueden identificar, con su posición en el coral.
        var identificados: [(indice: Int, acorde: Acorde)] = []
        if cifrados || analisis {
            for (i, alturas) in acordes.enumerated() {
                // Solo los tipos del catálogo: un acorde con notas de paso no se cifra como «add♭9».
                if let acorde = Acorde.candidatos(alturas).first(where: { TipoDeAcorde.todos.contains($0.valor.tipo) })?.valor {
                    identificados.append((i, acorde))
                }
            }
        }
        let analizado: AnalisisArmonico? = analisis
            ? (tonalidad.map { $0.analizar(identificados.map(\.acorde)) } ?? AnalisisArmonico.analizar(identificados.map(\.acorde)))
            : nil
        let tonalidad = tonalidad ?? analizado?.tonalidad ?? Tonalidad.identificar(alturas: todas).first
        var arriba: [Duracion: EscritorMusicXML.Anotacion] = [:]
        var abajo: [Duracion: EscritorMusicXML.Anotacion] = [:]
        for (k, (i, acorde)) in identificados.enumerated() {
            if cifrados {
                arriba[duracion * i] = EscritorMusicXML.Anotacion(armonia: EscritorMusicXML.armonia(acorde, notacion, pentagrama: 1))
            }
            if let analizado, k < analizado.acordes.count {
                abajo[duracion * i] = EscritorMusicXML.Anotacion(letras: EscritorMusicXML.letras(analizado.acordes[k]))
            }
        }
        var escritor = EscritorMusicXML(compas: compas, anacrusa: .cero, tonalidad: tonalidad,
                                        tempo: tempo, titulo: titulo, parte: parte, claves: [.sol, .fa])
        if let analizado { escritor.rotulo = (analizado.tonalidad.nombre(en: notacion) + ":", 2) }
        // Las voces de la mitad aguda van arriba; en cada pentagrama se numeran de agudo a grave.
        let n = numeroDeVoces
        let agudas = Array((n / 2..<n).reversed())
        let graves = Array((0..<n / 2).reversed())
        let final = Exportacion.hastaLaBarra(duracion, acordes.count, compas)
        var numero = 1
        for (pentagrama, voces) in [(1, agudas), (2, graves)] {
            for (k, v) in voces.enumerated() {
                let plica: String? = voces.count == 1 ? nil : (k == 0 ? "up" : "down")
                let linea = Voz(Exportacion.eventos(de: voz(v), duracion: duracion, final: final), compas: compas)
                // Los cifrados, con la voz más aguda; el análisis, con la más grave.
                let anotaciones = v == n - 1 ? arriba : (v == 0 ? abajo : [:])
                escritor.anadir(linea, pentagrama: pentagrama, numero: numero, plica: plica, anotaciones: anotaciones)
                numero += 1
            }
        }
        return escritor.documento
    }
}

extension AnalisisArmonico {
    /// La progresión como partitura MusicXML en dos pentagramas: los acordes en posición cerrada
    /// en clave de sol, con su cifrado americano encima, y el bajo en clave de fa, con el cifrado
    /// romano y la función debajo. Al principio, debajo del bajo, la tonalidad.
    ///
    ///     let analisis = try AnalisisArmonico.analizar(leyendo: "Do Lam Re7 Sol7 Do")
    ///     let xml = analisis.musicXML(titulo: "Progresión")
    ///
    /// - Parameters:
    ///   - duracion: lo que dura cada acorde; el último se alarga hasta la barra.
    ///   - cifrados: si se escriben los cifrados americanos.
    ///   - analisis: si se escriben los cifrados romanos y las funciones.
    ///   - notacion: la de los cifrados americanos y la tonalidad.
    public func musicXML(duracion: Duracion = .blanca, compas: Compas = .compasillo, tempo: Tempo? = nil,
                         titulo: String? = nil, parte: String = "Piano", cifrados: Bool = true,
                         analisis: Bool = true, notacion: Notacion = .espanol) -> String {
        let (superior, grave) = Exportacion.progresion(acordes.map(\.acorde), duracion: duracion,
                                                       final: Exportacion.hastaLaBarra(duracion, acordes.count, compas))
        var arriba: [Duracion: EscritorMusicXML.Anotacion] = [:]
        var abajo: [Duracion: EscritorMusicXML.Anotacion] = [:]
        for (i, analizado) in acordes.enumerated() {
            let acorde = analizado.acorde
            if cifrados { arriba[duracion * i] = EscritorMusicXML.Anotacion(armonia: EscritorMusicXML.armonia(acorde, notacion, pentagrama: 1)) }
            if analisis { abajo[duracion * i] = EscritorMusicXML.Anotacion(letras: EscritorMusicXML.letras(analizado)) }
        }
        var escritor = EscritorMusicXML(compas: compas, anacrusa: .cero, tonalidad: tonalidad, tempo: tempo,
                                        titulo: titulo, parte: parte, claves: [.sol, .fa])
        if analisis { escritor.rotulo = (tonalidad.nombre(en: notacion) + ":", 2) }
        escritor.anadir(Voz(superior, compas: compas), pentagrama: 1, numero: 1, plica: nil, anotaciones: arriba)
        escritor.anadir(Voz(grave, compas: compas), pentagrama: 2, numero: 2, plica: nil, anotaciones: abajo)
        return escritor.documento
    }
}

// MARK: - Común a MusicXML y MIDI

/// Lo que comparten las exportaciones a MusicXML y a MIDI: la tonalidad que se estima, las
/// divisiones del tiempo y cómo se preparan las voces de un coral y de una progresión.
package enum Exportacion {
    /// La tonalidad que se estima para una voz, por sus notas y lo que duran.
    package static func tonalidad(de voz: Voz) -> Tonalidad? {
        let alturas = voz.eventos.flatMap(\.alturas)
        let duraciones = voz.eventos.flatMap { e in e.alturas.map { _ in e.duracion.enRedondas } }
        return Tonalidad.identificar(alturas: alturas, duraciones: duraciones).first
    }

    /// Divisiones por negra: lo mínimo para que todas las duraciones sean enteras.
    package static func divisiones(_ duraciones: [Duracion]) -> Int {
        duraciones.reduce(1) { resultado, d in
            guard d.numerador > 0 else { return resultado }
            // d en negras = 4·num/den; hace falta que divisiones·4·num/den sea entero.
            let necesario = d.denominador / maximoComunDivisor(4 * d.numerador, d.denominador)
            return resultado / maximoComunDivisor(resultado, necesario) * necesario
        }
    }

    /// Lo que dura el último de `cuantos` acordes de `duracion` para que acabe en la barra.
    package static func hastaLaBarra(_ duracion: Duracion, _ cuantos: Int, _ compas: Compas) -> Duracion {
        let total = duracion * cuantos
        let enCompases = total / compas.duracion
        let resto = total - compas.duracion * (enCompases.numerador / enCompases.denominador)
        return resto.esCero ? duracion : duracion + compas.duracion - resto
    }

    /// Las notas apiladas en posición cerrada: la primera, en la primera octava en que su MIDI
    /// llegue a `minimo`, y cada una, en la primera octava por encima de la anterior.
    package static func posicionCerrada(_ notas: [Nota], desde minimo: Int) -> [Altura] {
        var alturas: [Altura] = []
        for nota in notas {
            let limite = alturas.last.map { $0.midi + 1 } ?? minimo
            var octava = 0
            while Altura(nota, octava: octava).midi < limite { octava += 1 }
            alturas.append(Altura(nota, octava: octava))
        }
        return alturas
    }

    /// Una voz de un coral: una nota por acorde, de `duracion`, y la última de `final`.
    package static func eventos(de alturas: [Altura], duracion: Duracion, final: Duracion) -> [Evento] {
        alturas.enumerated().map { Evento($1, $0 == alturas.count - 1 ? final : duracion) }
    }

    /// Las dos voces de una progresión: los acordes en posición cerrada desde La3 y el bajo
    /// desde Fa2, de `duracion` cada uno, y el último de `final`.
    package static func progresion(_ acordes: [Acorde], duracion: Duracion, final: Duracion) -> (acordes: [Evento], bajo: [Evento]) {
        var superior: [Evento] = []
        var grave: [Evento] = []
        for (i, acorde) in acordes.enumerated() {
            let figura = i == acordes.count - 1 ? final : duracion
            superior.append(Evento(alturas: posicionCerrada(acorde.notas, desde: 57), duracion: figura))
            grave.append(Evento(posicionCerrada([acorde.bajo], desde: 41)[0], figura))
        }
        return (superior, grave)
    }
}

// MARK: - Escritor MusicXML

/// Reúne varias voces en una parte (con uno o más pentagramas) y escribe el documento.
package struct EscritorMusicXML {
    package struct Linea {
        package let voz: Voz
        package let pentagrama: Int
        package let numero: Int
        package let plica: String?
        /// Lo que se escribe con la nota que empieza en cada punto de la voz (contado desde su
        /// comienzo): un cifrado encima y textos debajo.
        package let anotaciones: [Duracion: Anotacion]
    }

    package struct Anotacion {
        /// El elemento `<harmony>` del cifrado, si lo hay.
        package var armonia: String?
        /// Una línea de texto debajo de la nota por elemento (cifrado romano, función…).
        package var letras: [String] = []
    }

    package let compas: Compas
    package let anacrusa: Duracion
    package let tonalidad: Tonalidad?
    package let tempo: Tempo?
    package let titulo: String?
    package let parte: String
    package let claves: [Clave]
    package var lineas: [Linea] = []

    package init(compas: Compas, anacrusa: Duracion, tonalidad: Tonalidad?, tempo: Tempo?,
         titulo: String?, parte: String, claves: [Clave]) {
        self.compas = compas
        self.anacrusa = anacrusa
        self.tonalidad = tonalidad
        self.tempo = tempo
        self.titulo = titulo
        self.parte = parte
        self.claves = claves
    }

    /// Un texto debajo del primer pentagrama de la línea, al principio (la tonalidad del análisis).
    package var rotulo: (texto: String, pentagrama: Int)?

    package mutating func anadir(_ voz: Voz, pentagrama: Int, numero: Int, plica: String?,
                         anotaciones: [Duracion: Anotacion] = [:]) {
        lineas.append(Linea(voz: voz, pentagrama: pentagrama, numero: numero, plica: plica, anotaciones: anotaciones))
    }

    package var documento: String {
        let grafias = lineas.map(\.voz.grafia)
        let barras = lineas.map(\.voz.barrasDeAgrupacion)
        let divisiones = Exportacion.divisiones(grafias.flatMap { $0.flatMap { $0.map(\.duracion) } })
        let numeroDeCompases = grafias.map(\.count).max() ?? 0

        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="no"?>
        <!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
        <score-partwise version="4.0">

        """
        if let titulo {
            xml += "  <work>\n    <work-title>\(escapar(titulo))</work-title>\n  </work>\n"
        }
        xml += """
          <identification>
            <encoding>
              <software>Armonia</software>
            </encoding>
          </identification>
          <part-list>
            <score-part id="P1">
              <part-name>\(escapar(parte))</part-name>
            </score-part>
          </part-list>
          <part id="P1">

        """
        // Una ligadura que viene del compás anterior, por línea.
        var ligadaDesde: [[Altura]] = Array(repeating: [], count: lineas.count)
        // Dónde va cada línea, desde su comienzo, para colocar las anotaciones.
        var posiciones = Array(repeating: Duracion.cero, count: lineas.count)
        for c in 0..<max(numeroDeCompases, 1) {
            let esAnacrusa = c == 0 && anacrusa > .cero
            let numero = anacrusa > .cero ? c : c + 1
            xml += "    <measure number=\"\(numero)\"\(esAnacrusa ? " implicit=\"yes\"" : "")>\n"
            if c == 0 { xml += atributos(divisiones) + metronomo + rotuloInicial }
            for (l, linea) in lineas.enumerated() where c < grafias[l].count {
                let eventos = grafias[l][c]
                if l > 0, c < grafias[l - 1].count {
                    let anterior = grafias[l - 1][c].map(\.duracion).sumar()
                    if !anterior.esCero {
                        xml += "      <backup><duration>\(ticks(anterior, divisiones))</duration></backup>\n"
                    }
                }
                var haciaBarra: [Int: String] = [:]
                for grupo in barras[l][c] {
                    for (k, i) in grupo.enumerated() {
                        haciaBarra[i] = k == 0 ? "begin" : (k == grupo.count - 1 ? "end" : "continue")
                    }
                }
                let compasEntero = eventos.count == 1 && eventos[0].esSilencio && !esAnacrusa
                    && eventos[0].duracion == compas.duracion
                var irregular = Duracion.cero   // lo acumulado del grupo irregular abierto
                for (i, evento) in eventos.enumerated() {
                    let figura = EscritorMusicXML.figura(de: evento.duracion)
                    var grupo: [String] = []
                    if figura.irregular != nil {
                        if irregular.esCero { grupo.append("start") }
                        irregular = irregular + evento.duracion
                        let cierra = irregular.denominador & (irregular.denominador - 1) == 0 || i == eventos.count - 1
                        if cierra { grupo.append("stop"); irregular = .cero }
                    }
                    let nota = NotaEscrita(evento: evento, figura: figura, divisiones: divisiones, linea: linea,
                                           variosPentagramas: claves.count > 1,
                                    medidaCompleta: compasEntero, barra: haciaBarra[i], grupo: grupo,
                                    ligadaDesde: ligadaDesde[l])
                    // Las anotaciones van con la primera nota escrita de cada evento, no con sus ligadas.
                    let anotacion = ligadaDesde[l].isEmpty || evento.alturas != ligadaDesde[l]
                        ? linea.anotaciones[posiciones[l]] : nil
                    if let armonia = anotacion?.armonia { xml += armonia }
                    xml += nota.xml(letras: anotacion?.letras ?? [])
                    ligadaDesde[l] = evento.ligada ? evento.alturas : []
                    posiciones[l] = posiciones[l] + evento.duracion
                }
            }
            if c == numeroDeCompases - 1 {
                xml += "      <barline location=\"right\">\n        <bar-style>light-heavy</bar-style>\n      </barline>\n"
            }
            xml += "    </measure>\n"
        }
        xml += "  </part>\n</score-partwise>\n"
        return xml
    }

    private func atributos(_ divisiones: Int) -> String {
        var xml = "      <attributes>\n        <divisions>\(divisiones)</divisions>\n"
        let fifths = tonalidad?.armadura ?? 0
        xml += "        <key>\n          <fifths>\(fifths)</fifths>\n"
        if let tonalidad { xml += "          <mode>\(tonalidad.modo == .mayor ? "major" : "minor")</mode>\n" }
        xml += "        </key>\n"
        let simbolo = compas == .compasillo ? " symbol=\"common\"" : (compas == .partido ? " symbol=\"cut\"" : "")
        let beats = compas.agrupacion.count > 1 && Set(compas.agrupacion).count > 1 && compas.tipo != .compuesto
            ? compas.agrupacion.map(String.init).joined(separator: "+") : "\(compas.numerador)"
        xml += "        <time\(simbolo)>\n          <beats>\(beats)</beats>\n          <beat-type>\(compas.denominador)</beat-type>\n        </time>\n"
        if claves.count > 1 { xml += "        <staves>\(claves.count)</staves>\n" }
        for (i, clave) in claves.enumerated() {
            let (signo, linea, cambio) = EscritorMusicXML.signo(de: clave)
            let numero = claves.count > 1 ? " number=\"\(i + 1)\"" : ""
            xml += "        <clef\(numero)>\n          <sign>\(signo)</sign>\n          <line>\(linea)</line>\n"
            if cambio != 0 { xml += "          <clef-octave-change>\(cambio)</clef-octave-change>\n" }
            xml += "        </clef>\n"
        }
        return xml + "      </attributes>\n"
    }

    private var rotuloInicial: String {
        guard let rotulo else { return "" }
        return """
              <direction placement="below">
                <direction-type>
                  <words>\(escapar(rotulo.texto))</words>
                </direction-type>
                <staff>\(rotulo.pentagrama)</staff>
              </direction>

        """
    }

    private var metronomo: String {
        guard let tempo else { return "" }
        let porMinuto = formatear(tempo.pulsacionesPorMinuto)
        var unidad = ""
        if let (figura, puntillos) = tempo.unidad.figuraYPuntillos {
            unidad = "            <beat-unit>\(EscritorMusicXML.tipo(figura))</beat-unit>\n"
                + String(repeating: "            <beat-unit-dot/>\n", count: puntillos)
        }
        guard !unidad.isEmpty else {
            return "      <sound tempo=\"\(formatear(tempo.negrasPorMinuto))\"/>\n"
        }
        return """
              <direction placement="above">
                <direction-type>
                  <metronome>
        \(unidad)            <per-minute>\(porMinuto)</per-minute>
                  </metronome>
                </direction-type>
                <sound tempo="\(formatear(tempo.negrasPorMinuto))"/>
              </direction>

        """
    }

    // MARK: Nota

    /// Un evento escrito como uno o más elementos `<note>` (uno por altura en un acorde).
    package struct NotaEscrita {
        package let evento: Evento
        package let figura: (tipo: String?, puntillos: Int, irregular: (reales: Int, normales: Int)?)
        package let divisiones: Int
        package let linea: Linea
        package let variosPentagramas: Bool
        package let medidaCompleta: Bool
        package let barra: String?
        package let grupo: [String]
        package let ligadaDesde: [Altura]

        package func xml(letras: [String]) -> String {
            let duracion = ticks(evento.duracion, divisiones)
            guard !evento.esSilencio else {
                var xml = "      <note>\n"
                xml += medidaCompleta ? "        <rest measure=\"yes\"/>\n" : "        <rest/>\n"
                xml += "        <duration>\(duracion)</duration>\n"
                xml += comun(incluirFigura: !medidaCompleta, plica: false, barra: nil)
                xml += notaciones(ligadura: [])
                return xml + "      </note>\n"
            }
            var xml = ""
            for (i, altura) in evento.alturas.enumerated() {
                xml += "      <note>\n"
                if i > 0 { xml += "        <chord/>\n" }
                let nota = altura.nota
                xml += "        <pitch>\n          <step>\(EscritorMusicXML.paso(nota.natural))</step>\n"
                if nota.alteracion.semitonos != 0 { xml += "          <alter>\(nota.alteracion.semitonos)</alter>\n" }
                xml += "          <octave>\(altura.octava)</octave>\n        </pitch>\n"
                xml += "        <duration>\(duracion)</duration>\n"
                var ligadura: [String] = []
                if ligadaDesde.contains(altura) { ligadura.append("stop") }
                if evento.ligada { ligadura.append("start") }
                for tipo in ligadura { xml += "        <tie type=\"\(tipo)\"/>\n" }
                xml += comun(incluirFigura: true, plica: i == 0, barra: i == 0 ? barra : nil)
                xml += notaciones(ligadura: ligadura, grupo: i == 0 ? grupo : [])
                if i == 0 {
                    for (k, letra) in letras.enumerated() where !letra.isEmpty {
                        xml += "        <lyric number=\"\(k + 1)\" placement=\"below\">\n"
                        xml += "          <syllabic>single</syllabic>\n          <text>\(escapar(letra))</text>\n        </lyric>\n"
                    }
                }
                xml += "      </note>\n"
            }
            return xml
        }

        private func comun(incluirFigura: Bool, plica: Bool, barra: String?) -> String {
            var xml = "        <voice>\(linea.numero)</voice>\n"
            if incluirFigura, let tipo = figura.tipo {
                xml += "        <type>\(tipo)</type>\n"
                xml += String(repeating: "        <dot/>\n", count: figura.puntillos)
            }
            if incluirFigura, let (reales, normales) = figura.irregular {
                xml += "        <time-modification>\n          <actual-notes>\(reales)</actual-notes>\n"
                xml += "          <normal-notes>\(normales)</normal-notes>\n        </time-modification>\n"
            }
            if let direccion = linea.plica, !evento.esSilencio { xml += "        <stem>\(direccion)</stem>\n" }
            if variosPentagramas { xml += "        <staff>\(linea.pentagrama)</staff>\n" }
            if let barra { xml += "        <beam number=\"1\">\(barra)</beam>\n" }
            return xml
        }

        private func notaciones(ligadura: [String], grupo: [String] = []) -> String {
            guard !ligadura.isEmpty || !grupo.isEmpty else { return "" }
            var xml = "        <notations>\n"
            for tipo in ligadura { xml += "          <tied type=\"\(tipo)\"/>\n" }
            for tipo in grupo {
                xml += tipo == "start" ? "          <tuplet type=\"start\" bracket=\"yes\"/>\n"
                                       : "          <tuplet type=\"stop\"/>\n"
            }
            return xml + "        </notations>\n"
        }
    }

    // MARK: Armonía

    /// Los textos de análisis de un acorde: el cifrado romano y la abreviatura de la función.
    package static func letras(_ analizado: AcordeAnalizado) -> [String] {
        [analizado.cifrado, analizado.funcion?.abreviatura ?? ""]
    }

    /// Las especies de acorde de MusicXML (`<kind>`), con sus intervalos como (número simple,
    /// semitonos dentro de la octava).
    package static let especies: [(nombre: String, intervalos: [(Int, Int)])] = [
        ("major", [(3, 4), (5, 7)]), ("minor", [(3, 3), (5, 7)]),
        ("augmented", [(3, 4), (5, 8)]), ("diminished", [(3, 3), (5, 6)]),
        ("dominant", [(3, 4), (5, 7), (7, 10)]), ("major-seventh", [(3, 4), (5, 7), (7, 11)]),
        ("minor-seventh", [(3, 3), (5, 7), (7, 10)]), ("diminished-seventh", [(3, 3), (5, 6), (7, 9)]),
        ("augmented-seventh", [(3, 4), (5, 8), (7, 10)]), ("half-diminished", [(3, 3), (5, 6), (7, 10)]),
        ("major-minor", [(3, 3), (5, 7), (7, 11)]),
        ("major-sixth", [(3, 4), (5, 7), (6, 9)]), ("minor-sixth", [(3, 3), (5, 7), (6, 9)]),
        ("dominant-ninth", [(3, 4), (5, 7), (7, 10), (2, 2)]), ("major-ninth", [(3, 4), (5, 7), (7, 11), (2, 2)]),
        ("minor-ninth", [(3, 3), (5, 7), (7, 10), (2, 2)]),
        ("dominant-11th", [(3, 4), (5, 7), (7, 10), (2, 2), (4, 5)]),
        ("major-11th", [(3, 4), (5, 7), (7, 11), (2, 2), (4, 5)]),
        ("minor-11th", [(3, 3), (5, 7), (7, 10), (2, 2), (4, 5)]),
        ("dominant-13th", [(3, 4), (5, 7), (7, 10), (2, 2), (4, 5), (6, 9)]),
        ("major-13th", [(3, 4), (5, 7), (7, 11), (2, 2), (4, 5), (6, 9)]),
        ("minor-13th", [(3, 3), (5, 7), (7, 10), (2, 2), (4, 5), (6, 9)]),
        ("suspended-second", [(2, 2), (5, 7)]), ("suspended-fourth", [(4, 5), (5, 7)]),
        ("power", [(5, 7)]),
        ("Italian", [(3, 4), (6, 10)]), ("French", [(3, 4), (4, 6), (6, 10)]),
        ("German", [(3, 4), (5, 7), (6, 10)]),
    ]

    /// El cifrado de un acorde como elemento `<harmony>`: fundamental, especie (con el texto del
    /// cifrado en `notacion`), bajo y los grados que se añaden o se quitan respecto a la especie.
    package static func armonia(_ acorde: Acorde, _ notacion: Notacion, pentagrama: Int?) -> String {
        let intervalos = acorde.tipo.intervalos.filter { $0.numero != 1 }
        let clave = { (i: Intervalo) in (i.numeroSimple, modulo(i.semitonos, 12)) }
        // La especie que más intervalos comparte con el acorde, penalizando los que le sobran.
        let puntuar = { (especie: [(Int, Int)]) -> Int in
            let comunes = especie.filter { e in intervalos.contains { clave($0) == e } }.count
            return comunes * 2 - (especie.count - comunes) * 3
        }
        var mejor = (nombre: "other", intervalos: [(Int, Int)]())
        var puntos = 0
        for especie in especies where puntuar(especie.intervalos) > puntos {
            mejor = especie
            puntos = puntuar(especie.intervalos)
        }
        var xml = "      <harmony print-frame=\"no\">\n        <root>\n"
        xml += "          <root-step>\(paso(acorde.fundamental.natural))</root-step>\n"
        if acorde.fundamental.alteracion.semitonos != 0 {
            xml += "          <root-alter>\(acorde.fundamental.alteracion.semitonos)</root-alter>\n"
        }
        xml += "        </root>\n"
        xml += "        <kind text=\"\(escapar(acorde.tipo.cifrado(en: notacion)))\">\(mejor.nombre)</kind>\n"
        if acorde.bajo != acorde.fundamental {
            xml += "        <bass>\n          <bass-step>\(paso(acorde.bajo.natural))</bass-step>\n"
            if acorde.bajo.alteracion.semitonos != 0 {
                xml += "          <bass-alter>\(acorde.bajo.alteracion.semitonos)</bass-alter>\n"
            }
            xml += "        </bass>\n"
        }
        // Grados respecto a la escala mayor de la fundamental: la novena menor es 9 con −1.
        let mayor = [0, 2, 4, 5, 7, 9, 11]
        func grado(_ numero: Int, _ semitonos: Int, _ tipo: String) -> String {
            let alteracion = semitonos - mayor[(numero - 1) % 7]
            return "        <degree>\n          <degree-value>\(numero)</degree-value>\n"
                + "          <degree-alter>\(alteracion)</degree-alter>\n"
                + "          <degree-type>\(tipo)</degree-type>\n        </degree>\n"
        }
        for intervalo in intervalos where !mejor.intervalos.contains(where: { $0 == clave(intervalo) }) {
            xml += grado(intervalo.numero, modulo(intervalo.semitonos, 12), "add")
        }
        for (numero, semitonos) in mejor.intervalos where !intervalos.contains(where: { clave($0) == (numero, semitonos) }) {
            xml += grado(numero, semitonos, "subtract")
        }
        if let pentagrama { xml += "        <staff>\(pentagrama)</staff>\n" }
        return xml + "      </harmony>\n"
    }

    // MARK: Auxiliares

    /// La figura con que se escribe una duración y, si es de un grupo irregular, la proporción:
    /// 1/12 → corchea de tresillo (3 en el tiempo de 2).
    package static func figura(de duracion: Duracion) -> (tipo: String?, puntillos: Int, irregular: (reales: Int, normales: Int)?) {
        if let (figura, puntillos) = duracion.figuraYPuntillos { return (tipo(figura), puntillos, nil) }
        var impar = duracion.denominador
        while impar % 2 == 0 { impar /= 2 }
        guard impar > 1 else { return (nil, 0, nil) }
        var normales = 1
        while normales * 2 < impar { normales *= 2 }
        if let (figura, puntillos) = (duracion * Duracion(impar, normales)).figuraYPuntillos {
            return (tipo(figura), puntillos, (impar, normales))
        }
        return (nil, 0, nil)
    }

    package static func tipo(_ figura: Figura) -> String {
        switch figura {
        case .cuadrada: return "breve"
        case .redonda: return "whole"
        case .blanca: return "half"
        case .negra: return "quarter"
        case .corchea: return "eighth"
        case .semicorchea: return "16th"
        case .fusa: return "32nd"
        case .semifusa: return "64th"
        case .garrapatea: return "128th"
        }
    }

    package static func paso(_ natural: NotaNatural) -> String {
        ["C", "D", "E", "F", "G", "A", "B"][natural.rawValue]
    }

    package static func signo(de clave: Clave) -> (signo: String, linea: Int, cambioDeOctava: Int) {
        switch clave {
        case .sol: return ("G", 2, 0)
        case .solOctavaBaja: return ("G", 2, -1)
        case .solOctavaAlta: return ("G", 2, 1)
        case .fa: return ("F", 4, 0)
        case .faEnTercera: return ("F", 3, 0)
        case .doEnPrimera: return ("C", 1, 0)
        case .doEnSegunda: return ("C", 2, 0)
        case .doEnTercera: return ("C", 3, 0)
        case .doEnCuarta: return ("C", 4, 0)
        }
    }
}

private func ticks(_ duracion: Duracion, _ divisiones: Int) -> Int {
    duracion.numerador * 4 * divisiones / duracion.denominador
}

private func formatear(_ valor: Double) -> String {
    valor == valor.rounded() ? String(Int(valor)) : String(valor)
}

private func escapar(_ texto: String) -> String {
    var resultado = ""
    for caracter in texto {
        switch caracter {
        case "&": resultado += "&amp;"
        case "<": resultado += "&lt;"
        case ">": resultado += "&gt;"
        case "\"": resultado += "&quot;"
        default: resultado.append(caracter)
        }
    }
    return resultado
}
