#if canImport(SwiftUI) && canImport(AVFoundation)
import AVFoundation
import SwiftUI
import Armonia
import ArmoniaPresentacion

/// Toca un `Sonido` con el sintetizador del sistema (un `AVAudioUnitSampler`). En macOS usa el piano del banco
/// General MIDI del sistema; en iOS, que no lo trae, el sonido básico del sampler. Tocar algo corta lo que
/// estuviera sonando.
@MainActor
public final class Reproductor {
    public static let compartido = Reproductor()

    private let motor = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var preparado = false
    private var tarea: Task<Void, Never>?

    private init() {}

    public func tocar(_ sonido: Sonido) {
        detener()
        guard !sonido.eventos.isEmpty, preparar() else { return }
        let cambios = sonido.cambios
        tarea = Task {
            var ahora = 0.0
            for cambio in cambios {
                if cambio.tiempo > ahora {
                    try? await Task.sleep(nanoseconds: UInt64((cambio.tiempo - ahora) * 1_000_000_000))
                    ahora = cambio.tiempo
                }
                guard !Task.isCancelled else { return }
                if cambio.empieza {
                    sampler.startNote(UInt8(cambio.midi), withVelocity: 90, onChannel: 0)
                } else {
                    sampler.stopNote(UInt8(cambio.midi), onChannel: 0)
                }
            }
        }
    }

    /// Corta lo que esté sonando.
    public func detener() {
        tarea?.cancel()
        tarea = nil
        guard preparado else { return }
        for midi in UInt8(0)...UInt8(127) {
            sampler.stopNote(midi, onChannel: 0)
        }
    }

    /// Conecta el sampler y arranca el motor la primera vez. Dice si se puede tocar.
    private func preparar() -> Bool {
        if preparado { return true }
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        motor.attach(sampler)
        motor.connect(sampler, to: motor.mainMixerNode, format: nil)
        #if os(macOS)
        let banco = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
        if FileManager.default.fileExists(atPath: banco.path) {
            try? sampler.loadSoundBankInstrument(at: banco, program: 0, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                 bankLSB: UInt8(kAUSampler_DefaultBankLSB))
        }
        #endif
        do {
            try motor.start()
        } catch {
            return false
        }
        preparado = true
        return true
    }
}

/// Un botón «Escuchar» que toca `sonido`. Se desactiva si no hay nada que tocar.
public struct BotonDeEscuchar: View {
    public let sonido: Sonido
    @Environment(\.notacion) private var notacion

    public init(_ sonido: Sonido) {
        self.sonido = sonido
    }

    public var body: some View {
        Button {
            Reproductor.compartido.tocar(sonido)
        } label: {
            Label(notacion.texto(.escuchar), systemImage: "play.circle")
        }
        .disabled(sonido.eventos.isEmpty)
    }
}
#endif
