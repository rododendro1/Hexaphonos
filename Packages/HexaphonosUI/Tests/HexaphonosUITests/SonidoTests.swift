import XCTest
import Foundation
import Armonia
@testable import HexaphonosPresentacion

// Lo que suena al pulsar «Escuchar». No usa AVFoundation: se ejecuta también en Linux.

final class SonidoTests: XCTestCase {
    func testUnAcordeSuenaDesdeSuBajoEnPosicionCerrada() throws {
        let sonido = Sonido.acorde(try Acorde(leyendo: "Sol7/Si"))
        XCTAssertEqual(sonido.eventos.map(\.midi), [59, 62, 65, 67])
        XCTAssertEqual(Sonido.acorde(try Acorde(leyendo: "Do")).eventos.map(\.midi), [48, 52, 55])
        // Arpegiado: cada nota empieza después de la anterior, y todas terminan a la vez.
        XCTAssertEqual(sonido.eventos.map(\.inicio), sonido.eventos.map(\.inicio).sorted())
        XCTAssertEqual(Set(sonido.eventos.map { ($0.inicio + $0.duracion).rounded(toPlaces: 6) }).count, 1)
    }

    func testUnaEscalaSubeHastaLaOctava() throws {
        let sonido = Sonido.escala(try Escala(leyendo: "Re dórico"))
        XCTAssertEqual(sonido.eventos.map(\.midi), [62, 64, 65, 67, 69, 71, 72, 74])
    }

    func testLosCambiosVanEnOrdenYTerminanAntesDeEmpezar() {
        let sonido = Sonido(eventos: [Sonido.Evento(midi: 60, inicio: 0, duracion: 1),
                                      Sonido.Evento(midi: 60, inicio: 1, duracion: 1)])
        XCTAssertEqual(sonido.cambios.map(\.tiempo), [0, 1, 1, 2])
        XCTAssertEqual(sonido.cambios.map(\.empieza), [true, false, true, false])
        XCTAssertEqual(sonido.duracion, 2)
        // Fuera del rango MIDI o sin duración, no suena.
        XCTAssertTrue(Sonido(eventos: [Sonido.Evento(midi: 200, inicio: 0, duracion: 1),
                                       Sonido.Evento(midi: 60, inicio: 0, duracion: 0)]).eventos.isEmpty)
    }

    func testElAnalisisYElCoralSuenan() throws {
        let analisis = try PresentacionDeAnalisis.analizar("Do Fa Sol7 Do", notacion: .espanol)
        XCTAssertEqual(Set(analisis.sonido.eventos.map(\.inicio)), [0, 1, 2, 3])
        let coral = try PresentacionDeCoral.presentar(.realizar, "Do Fa Sol7 Do", notacion: .espanol)
        XCTAssertEqual(coral.sonido.eventos.count, 16)
        let sinOctavas = try PresentacionDeCoral.presentar(.armonizar, "Mi Re Do", notacion: .espanol)
        XCTAssertTrue(sinOctavas.sonido.eventos.isEmpty)
    }
}

private extension Double {
    func rounded(toPlaces lugares: Int) -> Double {
        let factor = pow(10, Double(lugares))
        return (self * factor).rounded() / factor
    }
}
