import Armonia

/// Lo que suena al pulsar «Escuchar» en las apps: notas MIDI con su inicio y su duración, en segundos. Aquí solo
/// se decide qué suena y cuándo; el reproductor de HexaphonosUI lo toca con el sintetizador del sistema.
///
///     Sonido.acorde(Acorde("Sol7/Si")).eventos.map(\.midi)   // [59, 62, 65, 67]: Si3 Re4 Fa4 Sol4
public struct Sonido: Hashable, Sendable {
    /// Una nota que suena: su número MIDI, cuándo empieza y cuánto dura.
    public struct Evento: Hashable, Sendable {
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

    public let eventos: [Evento]

    public init(eventos: [Evento]) {
        self.eventos = eventos.filter { (0...127).contains($0.midi) && $0.duracion > 0 }
    }

    /// Nada que tocar.
    public static let silencio = Sonido(eventos: [])

    /// Cuánto dura todo, en segundos.
    public var duracion: Double { eventos.map { $0.inicio + $0.duracion }.max() ?? 0 }

    /// Los comienzos y finales de las notas, por orden de tiempo. A un mismo tiempo, los finales van antes,
    /// para que una nota repetida vuelva a sonar.
    public var cambios: [Cambio] {
        eventos.flatMap { [Cambio(tiempo: $0.inicio, midi: $0.midi, empieza: true),
                           Cambio(tiempo: $0.inicio + $0.duracion, midi: $0.midi, empieza: false)] }
            .sorted { ($0.tiempo, $0.empieza ? 1 : 0) < ($1.tiempo, $1.empieza ? 1 : 0) }
    }

    // MARK: Lo que tocan las apps

    /// Un acorde desde su bajo, en posición cerrada a partir de Do3: primero arpegiado y luego junto.
    public static func acorde(_ acorde: Acorde) -> Sonido {
        let midis = cerrada(acorde.notasDesdeElBajo, desde: 48)
        let paso = 0.12
        let final = paso * Double(midis.count)
        return Sonido(eventos: midis.enumerated().map { i, midi in
            Evento(midi: midi, inicio: paso * Double(i), duracion: final - paso * Double(i) + 1.2)
        })
    }

    /// Una escala de la tónica a su octava, desde la tónica en la octava 4, y vuelta a la tónica.
    public static func escala(_ escala: Escala) -> Sonido {
        let subida = cerrada(escala.notas, desde: 60)
        guard let tonica = subida.first else { return .silencio }
        let midis = subida + [tonica + 12]
        let paso = 0.3
        return Sonido(eventos: midis.enumerated().map { i, midi in
            Evento(midi: midi, inicio: paso * Double(i), duracion: paso * 0.9)
        })
    }

    /// Una progresión, un acorde detrás de otro, cada uno desde su bajo a partir de Do3.
    public static func acordes(_ acordes: [Acorde], duracion: Double = 1) -> Sonido {
        grupos(acordes.map { cerrada($0.notasDesdeElBajo, desde: 48) }, duracion: duracion)
    }

    /// Acordes con sus alturas escritas (un coral a cuatro voces), uno detrás de otro.
    public static func alturas(_ acordes: [[Altura]], duracion: Double = 1) -> Sonido {
        grupos(acordes.map { $0.map(\.midi) }, duracion: duracion)
    }

    static func grupos(_ grupos: [[Int]], duracion: Double) -> Sonido {
        Sonido(eventos: grupos.enumerated().flatMap { i, midis in
            midis.map { Evento(midi: $0, inicio: duracion * Double(i), duracion: duracion * 0.92) }
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
