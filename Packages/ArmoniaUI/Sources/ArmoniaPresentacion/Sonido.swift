import Armonia

/// Lo que suena al pulsar «Escuchar» en las apps: notas MIDI con su inicio y su duración, en segundos. Aquí solo
/// se decide qué suena y cuándo; el reproductor de ArmoniaUI lo toca con el sintetizador del sistema.
///
///     Sonido.acorde(Acorde("Sol7/Si")).notas.map(\.midi)   // [59, 62, 65, 67]: Si3 Re4 Fa4 Sol4
public struct Sonido: Hashable, Sendable {
    /// Una nota que suena: su número MIDI, cuándo empieza y cuánto dura.
    public struct NotaMIDI: Hashable, Sendable {
        public let midi: Int
        public let inicio: Double
        public let duracion: Double

        public init(midi: Int, inicio: Double, duracion: Double) {
            self.midi = midi
            self.inicio = inicio
            self.duracion = duracion
        }
    }

    /// Una nota que empieza o termina, en orden de tiempo para el reproductor.
    public struct Cambio: Hashable, Sendable {
        public let tiempo: Double
        public let midi: Int
        public let empieza: Bool
    }

    public let notas: [NotaMIDI]

    public init(notas: [NotaMIDI]) {
        self.notas = notas.filter { (0...127).contains($0.midi) && $0.duracion > 0 }
    }

    /// Nada que tocar.
    public static let silencio = Sonido(notas: [])

    /// Cuánto dura todo, en segundos.
    public var duracion: Double { notas.map { $0.inicio + $0.duracion }.max() ?? 0 }

    /// Los comienzos y finales de las notas, por orden de tiempo. A un mismo tiempo, los finales van antes,
    /// para que una nota repetida vuelva a sonar.
    public var cambios: [Cambio] {
        notas.flatMap { [Cambio(tiempo: $0.inicio, midi: $0.midi, empieza: true),
                           Cambio(tiempo: $0.inicio + $0.duracion, midi: $0.midi, empieza: false)] }
            .sorted { ($0.tiempo, $0.empieza ? 1 : 0) < ($1.tiempo, $1.empieza ? 1 : 0) }
    }

    // MARK: Lo que tocan las apps

    /// Una nota sola: la que se toca en un dibujo.
    public static func nota(_ midi: Int, duracion: Double = 0.8) -> Sonido {
        Sonido(notas: [NotaMIDI(midi: midi, inicio: 0, duracion: duracion)])
    }

    /// Un acorde desde su bajo, en posición cerrada a partir de Do3: primero arpegiado y luego junto.
    public static func acorde(_ acorde: Acorde) -> Sonido {
        let midis = cerrada(acorde.notasDesdeElBajo, desde: 48)
        let paso = 0.12
        let final = paso * Double(midis.count)
        return Sonido(notas: midis.enumerated().map { i, midi in
            NotaMIDI(midi: midi, inicio: paso * Double(i), duracion: final - paso * Double(i) + 1.2)
        })
    }

    /// Una escala de la tónica a su octava, desde la tónica en la octava 4, y vuelta a la tónica.
    public static func escala(_ escala: Escala) -> Sonido {
        let subida = cerrada(escala.notas, desde: 60)
        guard let tonica = subida.first else { return .silencio }
        let midis = subida + [tonica + 12]
        let paso = 0.3
        return Sonido(notas: midis.enumerated().map { i, midi in
            NotaMIDI(midi: midi, inicio: paso * Double(i), duracion: paso * 0.9)
        })
    }

    /// Una progresión, un acorde detrás de otro, cada uno desde su bajo a partir de Do3.
    public static func acordes(_ acordes: [Acorde], duracion: Double = 1) -> Sonido {
        grupos(acordes.map { cerrada($0.notasDesdeElBajo, desde: 48) }, duracion: duracion)
    }

    /// Acordes con sus alturas escritas (un coral a cuatro voces), uno detrás de otro.
    public static func coral(_ acordes: [[Altura]], duracion: Double = 1) -> Sonido {
        grupos(acordes.map { $0.map(\.midi) }, duracion: duracion)
    }

    /// El tempo de lo que tiene ritmo, si no se da otro: negra a 72.
    public static let tempo = Tempo(72)

    /// Una voz con su ritmo: los silencios callan y las notas ligadas suenan como una sola.
    ///
    ///     Sonido.voz(try Voz(leyendo: "Do4:4 Re4:8 -:8 Mi4:2")).notas.map(\.inicio)   // [0, 0.83, 1.67]
    public static func voz(_ voz: Voz, tempo: Tempo = Sonido.tempo) -> Sonido {
        Sonido(notas: notas(de: voz, tempo: tempo).flatMap { nota in
            nota.alturas.map { NotaMIDI(midi: $0.midi, inicio: nota.inicio, duracion: nota.duracion * 0.95) }
        })
    }

    /// Acordes con sus alturas escritas que empiezan y duran lo que las notas de una voz: el coral de una
    /// melodía con ritmo. Si hay más acordes que notas, los que sobran no suenan.
    public static func coral(_ acordes: [[Altura]], conElRitmoDe voz: Voz, tempo: Tempo = Sonido.tempo) -> Sonido {
        Sonido(notas: zip(acordes, notas(de: voz, tempo: tempo)).flatMap { acorde, nota in
            acorde.map { NotaMIDI(midi: $0.midi, inicio: nota.inicio, duracion: nota.duracion * 0.95) }
        })
    }

    /// Las notas de una voz con su comienzo y su duración en segundos, sin los silencios; una nota ligada
    /// se alarga con la siguiente en lugar de volver a empezar.
    static func notas(de voz: Voz, tempo: Tempo) -> [(alturas: [Altura], inicio: Double, duracion: Double)] {
        var notas: [(alturas: [Altura], inicio: Double, duracion: Double)] = []
        var tiempo = 0.0
        var ligadaALaAnterior = false
        for evento in voz.eventos {
            let segundos = tempo.segundos(de: evento.duracion)
            if ligadaALaAnterior, !notas.isEmpty {
                notas[notas.count - 1].duracion += segundos
            } else if !evento.alturas.isEmpty {
                notas.append((evento.alturas, tiempo, segundos))
            }
            tiempo += segundos
            ligadaALaAnterior = evento.ligada
        }
        return notas
    }

    static func grupos(_ grupos: [[Int]], duracion: Double) -> Sonido {
        Sonido(notas: grupos.enumerated().flatMap { i, midis in
            midis.map { NotaMIDI(midi: $0, inicio: duracion * Double(i), duracion: duracion * 0.92) }
        })
    }

    /// Las notas en posición cerrada: la primera en la octava que empieza en `base` y cada una por encima de
    /// la anterior. Do Mi Sol desde 48 → 48 52 55.
    static func cerrada(_ notas: [Nota], desde base: Int) -> [Int] {
        var midis: [Int] = []
        for nota in notas {
            let suelo = (midis.last.map { $0 + 1 }) ?? base
            midis.append(suelo + ((nota.claseDeAltura - suelo) % 12 + 12) % 12)
        }
        return midis
    }
}
