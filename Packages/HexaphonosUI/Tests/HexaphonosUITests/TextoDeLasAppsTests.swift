import XCTest
import Armonia
@testable import HexaphonosUI
@testable import HexaphonosPresentacion

// Los textos de la interfaz de las apps y la notación inicial. No usan SwiftUI: se ejecutan también en Linux.

final class TextoDeLasAppsTests: XCTestCase {
    /// Una muestra de cada caso.
    static let todos: [TextoDeLasApps] = [
        .acordes, .escalas, .analisis, .coral, .acorde, .campoDeCifrado, .informacion, .nombre, .cifrado, .notas,
        .digitaciones, .instrumentoYAfinacion, .sinDigitaciones, .calculando, .dedos(1, cejilla: nil),
        .dedos(4, cejilla: 3), .escala, .tonica, .tipo, .habituales, .otrasTradiciones, .acordesDeLaEscala,
        .mastilDeGuitarra, .progresion, .campoDeProgresion, .resultado, .acordeAAcorde, .cadencias, .tarea,
        .campoDeTonalidad, .tonalidad, .armonizaciones, .aCuatroVoces, .conduccionDeLasVoces, .avisos,
        .recorridoPLR, .modo, .red, .noSeDibuja, .campoDeTriadaInicial, .reiniciar, .deshacer, .campoDeAcorde,
        .campoDeEscala, .textos, .comoLasNotas, .exportar, .escuchar,
    ]

    func testCadaTextoEstaEnCadaIdioma() {
        for idioma in Idioma.traducidos {
            let notacion = Nomenclatura.espanol.conTextos(en: idioma)
            for texto in Self.todos {
                XCTAssertFalse(notacion.texto(texto).isEmpty, "\(texto) en \(idioma)")
            }
        }
        XCTAssertEqual(Nomenclatura.ingles.texto(.digitaciones), "Fingerings")
        XCTAssertEqual(Nomenclatura.euskera.texto(.acordes), "Akordeak")
        // El alemán no tiene textos propios: van en inglés.
        XCTAssertEqual(Nomenclatura.aleman.texto(.escalas), "Scales")
    }

    func testLosEjemplosVanEnLaNotacion() {
        XCTAssertEqual(Nomenclatura.espanol.texto(.campoDeCifrado), "Cifrado, por ejemplo Sol7/Si")
        XCTAssertEqual(Nomenclatura.ingles.texto(.campoDeCifrado), "Chord symbol, for example G7/B")
        XCTAssertEqual(Nomenclatura.ingles.texto(.campoDeTriadaInicial), "Starting triad (C, Am…)")
        XCTAssertEqual(PresentacionDeCoral.Tarea.armonizar.indicacion(en: .ingles),
                       "Melody (E4 F4 D4 C4, or without octaves)")
        XCTAssertEqual(PresentacionDeCoral.Tarea.revisar.indicacion(en: .espanol),
                       "Voces de grave a agudo (Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4)")
        XCTAssertEqual(PresentacionDeCoral.Tarea.realizar.indicacion(en: .ingles), "Chords (C F G7 C)")
    }

    func testLosDedosYLaCejilla() {
        XCTAssertEqual(Nomenclatura.espanol.texto(.dedos(1, cejilla: nil)), "1 dedo")
        XCTAssertEqual(Nomenclatura.espanol.texto(.dedos(4, cejilla: 1)), "4 dedos, cejilla en el traste 1")
        XCTAssertEqual(Nomenclatura.ingles.texto(.dedos(3, cejilla: 5)), "3 fingers, barre at fret 5")
    }

    func testLasTareasLosFormatosYLasRedesTienenNombreEnCadaIdioma() {
        for idioma in Idioma.traducidos {
            let notacion = Nomenclatura.espanol.conTextos(en: idioma)
            let tareas = PresentacionDeCoral.Tarea.allCases.map { $0.titulo(en: notacion) }
            XCTAssertEqual(Set(tareas).count, tareas.count, "\(idioma)")
            let formatos = FicheroParaExportar.Formato.allCases.map { $0.titulo(en: notacion) }
            XCTAssertEqual(Set(formatos).count, formatos.count, "\(idioma)")
            let redes = RedDeNotas.allCases.map { $0.nombre(en: notacion) }
            XCTAssertEqual(Set(redes).count, redes.count, "\(idioma)")
        }
        XCTAssertEqual(RedDeNotas.tablaArmonica.nombre(en: .ingles), "Harmonic table")
    }

    func testLaNotacionInicialEsLaDelSistema() {
        XCTAssertEqual(Nomenclatura.delSistema(idiomas: ["ca-ES", "es-ES"]), .catalan)
        XCTAssertEqual(Nomenclatura.delSistema(idiomas: ["en-GB"]), .ingles)
        XCTAssertEqual(Nomenclatura.delSistema(idiomas: ["eu"]), .euskera)
        XCTAssertEqual(Nomenclatura.delSistema(idiomas: ["pt_BR"]), .portugues)
        // Un idioma sin notación se salta; si no queda ninguno, el español.
        XCTAssertEqual(Nomenclatura.delSistema(idiomas: ["ja-JP", "fr-CA"]), .frances)
        XCTAssertEqual(Nomenclatura.delSistema(idiomas: ["ja-JP"]), .espanol)
        XCTAssertEqual(Nomenclatura.delSistema(idiomas: []), .espanol)
    }
}
