import ArmoniaNucleo
import ArmoniaTeoria
// Exportación a MIDI: ficheros MIDI estándar (SMF, formato 1), que se oyen en cualquier
// reproductor, secuenciador o editor de partituras.
//
// La primera pista lleva el título, el tempo, el compás y la armadura; cada una de las demás,
// una voz con su nombre. Las notas ligadas suenan como una sola. Las alturas fuera del rango
// MIDI (0…127) se omiten. Los textos van en Latin-1, que es lo que esperan casi todos los
// programas, con las alteraciones en ASCII (Mib, F#).

import Foundation

extension Voz {
    /// La voz como fichero MIDI estándar.
    ///
    ///     let voz = try Voz(leyendo: "Do4:4 Re4:8 Mi4:8 Fa4:2", compas: "3/4")
    ///     let datos = voz.midi(tempo: Tempo(90), titulo: "Escala")
    ///     try datos.write(to: URL(fileURLWithPath: "escala.mid"))
    ///
    /// - Parameters:
    ///   - tonalidad: la armadura que se escribe en el fichero; si es `nil`, se estima.
    ///   - tempo: si es `nil`, negra = 120 (el de MIDI por omisión).
    ///   - titulo: el nombre de la secuencia.
    ///   - parte: el nombre de la pista.
    ///   - instrumento: el programa General MIDI (0 = piano de cola … 127).
    public func midi(tonalidad: Tonalidad? = nil, tempo: Tempo? = nil, titulo: String? = nil,
                     parte: String = "Voz", instrumento: Int = 0) -> Data {
        let tonalidad = tonalidad ?? Exportacion.tonalidad(de: self)
        var archivo = ArchivoMIDI(compas: compas, tonalidad: tonalidad, tempo: tempo, titulo: titulo)
        archivo.anadir(eventos, nombre: parte, instrumento: instrumento)
        return archivo.datos
    }
}

extension Coral {
    /// El coral como fichero MIDI estándar, con una pista por voz (de agudo a grave: soprano,
    /// contralto, tenor y bajo si son cuatro).
    ///
    ///     let coral = try Coral(leyendo: "Do3 Mi4 Sol4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5")
    ///     let datos = coral.midi(duracion: .blanca, tempo: Tempo(72))
    ///
    /// - Parameters:
    ///   - duracion: lo que dura cada acorde.
    ///   - tonalidad: la armadura que se escribe en el fichero; si es `nil`, se estima.
    ///   - instrumento: el programa General MIDI de todas las voces (52 = coro «aahs»).
    public func midi(duracion: Duracion = .negra, compas: Compas = .compasillo, tonalidad: Tonalidad? = nil,
                     tempo: Tempo? = nil, titulo: String? = nil, instrumento: Int = 52,
                     notacion: Notacion = .espanol) -> Data {
        let tonalidad = tonalidad ?? Tonalidad.identificar(alturas: acordes.flatMap { $0 }).first
        var archivo = ArchivoMIDI(compas: compas, tonalidad: tonalidad, tempo: tempo, titulo: titulo)
        for v in (0..<numeroDeVoces).reversed() {
            let eventos = Exportacion.eventos(de: voz(v), duracion: duracion, final: duracion)
            archivo.anadir(eventos, nombre: Coral.nombreDeVoz(v, de: numeroDeVoces, en: notacion),
                           instrumento: instrumento)
        }
        return archivo.datos
    }
}

extension AnalisisArmonico {
    /// La progresión como fichero MIDI estándar: una pista con los acordes en posición cerrada
    /// y otra con el bajo, como en `musicXML()`. Cada acorde lleva un marcador con su cifrado
    /// americano y su cifrado romano («Re7 · V7/V»), que los secuenciadores muestran al sonar.
    ///
    ///     let analisis = try AnalisisArmonico.analizar(leyendo: "Do Lam Re7 Sol7 Do")
    ///     let datos = analisis.midi(tempo: Tempo(80))
    ///
    /// - Parameters:
    ///   - duracion: lo que dura cada acorde.
    ///   - instrumento: el programa General MIDI (0 = piano de cola).
    ///   - notacion: la de los cifrados americanos de los marcadores.
    public func midi(duracion: Duracion = .blanca, compas: Compas = .compasillo, tempo: Tempo? = nil,
                     titulo: String? = nil, instrumento: Int = 0, notacion: Notacion = .espanol) -> Data {
        var archivo = ArchivoMIDI(compas: compas, tonalidad: tonalidad, tempo: tempo, titulo: titulo)
        let (superior, grave) = Exportacion.progresion(acordes.map(\.acorde), duracion: duracion, final: duracion)
        let marcas = acordes.map { $0.acorde.cifrado(en: notacion) + " · " + $0.cifrado }
        let pistaDeAcordes = Traduccion("acordes", "chords", ca: "acords", gl: "acordes", eu: "akordeak",
                                        pt: "acordes", fr: "accords", it: "accordi").en(notacion)
        let pistaDelBajo = Traduccion("bajo", "bass", ca: "baix", gl: "baixo", eu: "baxua",
                                      pt: "baixo", fr: "basse", it: "basso").en(notacion)
        archivo.anadir(superior, nombre: pistaDeAcordes, instrumento: instrumento, marcadores: marcas)
        archivo.anadir(grave, nombre: pistaDelBajo, instrumento: instrumento)
        return archivo.datos
    }
}

// MARK: - Escritor

/// Un fichero MIDI estándar de formato 1: una pista de control y una por voz.
package struct ArchivoMIDI {
    package let compas: Compas
    package let tonalidad: Tonalidad?
    package let tempo: Tempo?
    package let titulo: String?
    private var pistas: [(eventos: [Evento], nombre: String, instrumento: Int, marcadores: [String])] = []

    package init(compas: Compas, tonalidad: Tonalidad?, tempo: Tempo?, titulo: String?) {
        self.compas = compas
        self.tonalidad = tonalidad
        self.tempo = tempo
        self.titulo = titulo
    }

    /// Una pista con los eventos, en el canal siguiente (sin usar el 10, el de percusión).
    /// `marcadores`, si se dan, uno por evento.
    package mutating func anadir(_ eventos: [Evento], nombre: String, instrumento: Int, marcadores: [String] = []) {
        precondition((0...127).contains(instrumento), "el instrumento General MIDI va de 0 a 127")
        pistas.append((eventos, nombre, instrumento, marcadores))
    }

    /// Pulsos de reloj por negra: 480 o 960, como es habitual, si con ellos todas las duraciones
    /// son enteras; si no, el primer múltiplo de los justos que llegue a 480.
    package var divisiones: Int {
        let base = Exportacion.divisiones(pistas.flatMap { $0.eventos.map(\.duracion) })
        if let habitual = [480, 960].first(where: { $0 % base == 0 }) { return habitual }
        guard base <= 32767 else { return 960 }   // grupos muy raros: se redondea
        let multiplo = base * ((480 + base - 1) / base)
        return multiplo <= 32767 ? multiplo : base
    }

    package var datos: Data {
        let divisiones = self.divisiones
        func pulsos(_ duracion: Duracion) -> Int {
            Int(((duracion / .negra).enRedondas * Double(divisiones)).rounded())
        }
        var bytes: [UInt8] = []
        // Cabecera: formato 1, número de pistas, divisiones por negra.
        bytes += Array("MThd".utf8) + ArchivoMIDI.entero(6, bytes: 4)
        bytes += ArchivoMIDI.entero(1, bytes: 2) + ArchivoMIDI.entero(pistas.count + 1, bytes: 2)
        bytes += ArchivoMIDI.entero(divisiones, bytes: 2)

        // La pista de control.
        var control: [(Int, [UInt8])] = []
        if let titulo { control.append((0, ArchivoMIDI.meta(0x03, ArchivoMIDI.texto(titulo)))) }
        let microsegundos = tempo.map { Int((60_000_000 / $0.negrasPorMinuto).rounded()) } ?? 500_000
        control.append((0, ArchivoMIDI.meta(0x51, ArchivoMIDI.entero(microsegundos, bytes: 3))))
        // Compás: numerador, denominador como potencia de 2, relojes por pulso y fusas por negra.
        let reloj = compas.tipo == .compuesto ? 36 * 8 / compas.denominador : 24 * 4 / compas.denominador
        control.append((0, ArchivoMIDI.meta(0x58, [UInt8(compas.numerador),
                                                   UInt8(compas.denominador.trailingZeroBitCount),
                                                   UInt8(max(1, min(255, reloj))), 8])))
        if let tonalidad, abs(tonalidad.armadura) <= 7 {
            control.append((0, ArchivoMIDI.meta(0x59, [UInt8(bitPattern: Int8(tonalidad.armadura)),
                                                       tonalidad.modo == .menor ? 1 : 0])))
        }
        bytes += ArchivoMIDI.pista(control)

        for (i, pista) in pistas.enumerated() {
            let canal = UInt8(i < 9 ? i : (i + 1) % 16)
            var mensajes: [(Int, [UInt8])] = [(0, ArchivoMIDI.meta(0x03, ArchivoMIDI.texto(pista.nombre))),
                                               (0, [0xC0 | canal, UInt8(pista.instrumento)])]
            // Las notas: las ligadas siguen sonando mientras la siguiente nota las repita.
            var inicio = 0
            var sonando: [Int: Int] = [:]   // altura MIDI → cuándo empezó
            var notas: [(clave: Int, desde: Int, hasta: Int)] = []
            var ligadas: Set<Int> = []
            for (k, evento) in pista.eventos.enumerated() {
                let claves = Set(evento.alturas.map(\.midi).filter { (0...127).contains($0) })
                // Las que venían ligadas y no siguen, terminan aquí.
                for clave in sonando.keys.sorted() where !(ligadas.contains(clave) && claves.contains(clave)) {
                    notas.append((clave, sonando[clave]!, inicio))
                    sonando[clave] = nil
                }
                for clave in claves where sonando[clave] == nil { sonando[clave] = inicio }
                if k < pista.marcadores.count, !pista.marcadores[k].isEmpty {
                    mensajes.append((inicio, ArchivoMIDI.meta(0x06, ArchivoMIDI.texto(pista.marcadores[k]))))
                }
                inicio += pulsos(evento.duracion)
                ligadas = evento.ligada ? claves : []
            }
            for clave in sonando.keys.sorted() { notas.append((clave, sonando[clave]!, inicio)) }
            for nota in notas {
                mensajes.append((nota.desde, [0x90 | canal, UInt8(nota.clave), 80]))
                mensajes.append((nota.hasta, [0x80 | canal, UInt8(nota.clave), 64]))
            }
            bytes += ArchivoMIDI.pista(mensajes)
        }
        return Data(bytes)
    }

    /// Una pista: los mensajes ordenados por tiempo (a igual tiempo, los finales de nota
    /// antes que los comienzos), con el tiempo delta delante de cada uno y el fin de pista.
    package static func pista(_ mensajes: [(Int, [UInt8])]) -> [UInt8] {
        func orden(_ m: [UInt8]) -> Int {
            switch m[0] & 0xF0 {
            case 0x80: return 1
            case 0x90: return 2
            default: return 0       // meta y cambio de programa, primero
            }
        }
        let ordenados = mensajes.enumerated().sorted {
            ($0.element.0, orden($0.element.1), $0.offset) < ($1.element.0, orden($1.element.1), $1.offset)
        }.map(\.element)
        var cuerpo: [UInt8] = []
        var ahora = 0
        for (tiempo, mensaje) in ordenados {
            cuerpo += cantidadVariable(tiempo - ahora) + mensaje
            ahora = tiempo
        }
        cuerpo += [0x00, 0xFF, 0x2F, 0x00]
        return Array("MTrk".utf8) + entero(cuerpo.count, bytes: 4) + cuerpo
    }

    /// Un texto en Latin-1, con las alteraciones en ASCII ("Mi♭ · ♭VI" → "Mib · bVI") y "?" en
    /// lo que no se puede escribir.
    package static func texto(_ texto: String) -> [UInt8] {
        let ascii: [Character: String] = ["♭": "b", "♯": "#", "𝄫": "bb", "𝄪": "x", "♮": "", "–": "-", "—": "-", "→": "->", "Δ": "maj"]
        let limpio = texto.map { ascii[$0] ?? String($0) }.joined()
        return limpio.unicodeScalars.map { $0.value <= 0xFF ? UInt8($0.value) : UInt8(ascii: "?") }
    }

    /// Un metaevento: FF, tipo, longitud y datos.
    package static func meta(_ tipo: UInt8, _ datos: [UInt8]) -> [UInt8] {
        [0xFF, tipo] + cantidadVariable(datos.count) + datos
    }

    /// Un entero sin signo, de mayor a menor peso.
    package static func entero(_ valor: Int, bytes: Int) -> [UInt8] {
        (0..<bytes).reversed().map { UInt8(truncatingIfNeeded: valor >> (8 * $0)) }
    }

    /// Cantidad de longitud variable: 7 bits por byte, con el bit alto en todos menos el último.
    package static func cantidadVariable(_ valor: Int) -> [UInt8] {
        var resto = valor >> 7
        var resultado: [UInt8] = [UInt8(valor & 0x7F)]
        while resto > 0 {
            resultado.insert(UInt8(resto & 0x7F) | 0x80, at: 0)
            resto >>= 7
        }
        return resultado
    }
}
