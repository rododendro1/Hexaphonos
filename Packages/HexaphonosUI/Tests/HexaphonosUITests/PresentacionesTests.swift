import XCTest
import Foundation
import Armonia
import Hexagonos
@testable import HexaphonosUI
@testable import HexaphonosPresentacion

// Las presentaciones de las vistas de análisis, coral y redes, y los ficheros que exportan. No usan
// SwiftUI: se ejecutan también en Linux.

final class FicheroParaExportarTests: XCTestCase {
    func testElNombreLlevaLaExtensionYNoLlevaBarras() {
        XCTAssertEqual(FicheroParaExportar.midi(Data(), nombre: "Sol7/Si").nombreDeFichero, "Sol7-Si.mid")
        XCTAssertEqual(FicheroParaExportar.musicXML("", nombre: "Coral").nombreDeFichero, "Coral.musicxml")
        XCTAssertEqual(FicheroParaExportar.svg("", nombre: "  ").nombreDeFichero, "Hexaphonos.svg")
        XCTAssertEqual(FicheroParaExportar.svg("", nombre: String(repeating: "a", count: 200)).nombreDeFichero.count,
                       80 + ".svg".count)
    }

    func testSeEscribeEnLaCarpetaDeExportaciones() throws {
        let carpeta = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: carpeta) }
        let fichero = FicheroParaExportar.svg("<svg/>", nombre: "Dibujo")
        let url = try fichero.escribir(en: carpeta)
        XCTAssertEqual(url.lastPathComponent, "Dibujo.svg")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "Exportaciones")
        XCTAssertEqual(try Data(contentsOf: url), Data("<svg/>".utf8))
        // Escribir otra vez sustituye el fichero.
        try FicheroParaExportar.svg("<svg></svg>", nombre: "Dibujo").escribir(en: carpeta)
        XCTAssertEqual(try Data(contentsOf: url), Data("<svg></svg>".utf8))
    }

    func testCadaFormatoTieneExtensionTituloEIconoDistintos() {
        let formatos = FicheroParaExportar.Formato.allCases
        XCTAssertEqual(Set(formatos.map(\.extensionDeFichero)).count, formatos.count)
        XCTAssertEqual(Set(formatos.map(\.titulo)).count, formatos.count)
        XCTAssertEqual(Set(formatos.map(\.icono)).count, formatos.count)
    }
}

final class PresentacionDeAnalisisTests: XCTestCase {
    func testUnaProgresionSinModulaciones() throws {
        let analisis = try PresentacionDeAnalisis.analizar("Do Lam Re7 Sol7 Do", notacion: .espanol)
        XCTAssertEqual(analisis.tramos.count, 1)
        XCTAssertNil(analisis.tramos[0].cabecera)
        XCTAssertEqual(analisis.tramos[0].filas.map(\.cifrado), ["Do", "Lam", "Re7", "Sol7", "Do"])
        XCTAssertEqual(analisis.tramos[0].filas.first?.grado, "I")
        XCTAssertFalse(analisis.cadencias.isEmpty)
    }

    func testLasModulacionesAbrenUnTramo() throws {
        let analisis = try PresentacionDeAnalisis.analizar("Do Fa Sol7 Do Lam Re7 Sol", notacion: .espanol)
        XCTAssertEqual(analisis.tramos.count, 2)
        XCTAssertNotNil(analisis.tramos[1].cabecera)
        XCTAssertEqual(analisis.tramos.flatMap(\.filas).count, 7)
    }

    func testExportaPartituraYMIDI() throws {
        let analisis = try PresentacionDeAnalisis.analizar("Do Fa Sol7 Do", notacion: .espanol)
        XCTAssertEqual(analisis.ficheros.map(\.formato), [.musicXML, .midi])
        XCTAssertTrue(String(decoding: analisis.ficheros[0].datos, as: UTF8.self).contains("score-partwise"))
        XCTAssertEqual(analisis.ficheros[1].datos.prefix(4), Data("MThd".utf8))
    }

    func testLaNotacionSeUsaEnLosCifrados() throws {
        let analisis = try PresentacionDeAnalisis.analizar("Do Sol7 Do", notacion: .ingles)
        XCTAssertEqual(analisis.tramos[0].filas.map(\.cifrado), ["C", "G7", "C"])
    }

    func testUnTextoQueNoSeLeeEsUnError() {
        XCTAssertThrowsError(try PresentacionDeAnalisis.analizar("Do Xyz", notacion: .espanol))
    }

    func testConUnaTonalidadDadaNoModula() throws {
        let analisis = try PresentacionDeAnalisis.analizar("Do Fa Sol7 Do Lam Re7 Sol", en: Tonalidad(leyendo: "Do mayor"),
                                                          notacion: .espanol)
        XCTAssertEqual(analisis.tramos.count, 1)
        XCTAssertTrue(analisis.titulo.hasSuffix("Do mayor"), analisis.titulo)
        XCTAssertEqual(analisis.tramos[0].filas.count, 7)
        XCTAssertEqual(analisis.ficheros.count, 2)
    }
}

final class PresentacionDeCoralTests: XCTestCase {
    func testArmonizarConOctavasDaElCoral() throws {
        let coral = try PresentacionDeCoral.presentar(.armonizar, "Mi4 Fa4 Re4 Do4", notacion: .espanol)
        XCTAssertEqual(coral.titulo, "Do mayor")
        XCTAssertEqual(coral.propuestas.first, "Do Fa Sol Do (I–IV–V–I)")
        XCTAssertEqual(coral.filas.map(\.grado), ["I", "IV", "V", "I"])
        XCTAssertEqual(coral.filas.first?.voces, "Do3 Sol3 Do4 Mi4")
        XCTAssertTrue(coral.avisos.isEmpty, "\(coral.avisos)")
        XCTAssertEqual(coral.ficheros.map(\.formato), [.musicXML, .midi])
    }

    func testArmonizarSinOctavasNoDaCoral() throws {
        let coral = try PresentacionDeCoral.presentar(.armonizar, "Mi Re Do", propuestas: 1, notacion: .espanol)
        XCTAssertEqual(coral.propuestas, ["Do Sol Do (I–V–I)"])
        XCTAssertTrue(coral.filas.isEmpty)
        XCTAssertTrue(coral.ficheros.isEmpty)
        XCTAssertEqual(coral.avisos, [.faltanOctavas])
        XCTAssertEqual(coral.avisos[0].texto(en: .espanol),
                       "Escribe las notas con su octava (Mi4 Re4 Do4) para verlas a cuatro voces.")
        XCTAssertEqual(coral.avisos[0].texto(en: .ingles),
                       "Write the notes with their octave (E4 D4 C4) to see them in four parts.")
    }

    func testLaTonalidadDadaManda() throws {
        let coral = try PresentacionDeCoral.presentar(.armonizar, "Do Si La Sol# La", tonalidad: "La menor",
                                                      notacion: .espanol)
        XCTAssertEqual(coral.titulo, "La menor")
        XCTAssertThrowsError(try PresentacionDeCoral.presentar(.armonizar, "Do", tonalidad: "Xyz", notacion: .espanol))
    }

    func testRealizarEscribeCuatroVocesSinFaltas() throws {
        let coral = try PresentacionDeCoral.presentar(.realizar, "Do Fa Sol7 Do", notacion: .espanol)
        XCTAssertEqual(coral.filas.map(\.cifrado), ["Do", "Fa", "Sol7", "Do"])
        XCTAssertTrue(coral.filas.allSatisfy { $0.voces.split(separator: " ").count == 4 })
        XCTAssertTrue(coral.avisos.isEmpty, "\(coral.avisos)")
        XCTAssertEqual(coral.ficheros.count, 2)
    }

    func testRevisarEncuentraLasParalelas() throws {
        let coral = try PresentacionDeCoral.presentar(.revisar, "Do3 Sol3 Mi4 Do5, Re3 La3 Fa4 Re5", notacion: .espanol)
        XCTAssertEqual(coral.filas.map(\.voces), ["Do3 Sol3 Mi4 Do5", "Re3 La3 Fa4 Re5"])
        XCTAssertEqual(coral.filas.map(\.cifrado), ["Do", "Rem"])
        XCTAssertFalse(coral.avisos.isEmpty)
        XCTAssertFalse(coral.avisos.contains(.sinFaltasDeConduccion))
        XCTAssertTrue(coral.avisos.allSatisfy { !$0.texto(en: .espanol).isEmpty })
    }

    func testRevisarUnBuenEnlace() throws {
        let coral = try PresentacionDeCoral.presentar(.revisar, "Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4", notacion: .espanol)
        XCTAssertEqual(coral.avisos, [.sinFaltasDeConduccion])
        XCTAssertEqual(coral.avisos[0].texto(en: .espanol), "Sin faltas de conducción.")
        XCTAssertEqual(coral.avisos[0].texto(en: .euskera), "Ez dago ahots-eramate akatsik.")
    }

    func testUnTextoVacioEsUnError() {
        for tarea in PresentacionDeCoral.Tarea.allCases {
            XCTAssertThrowsError(try PresentacionDeCoral.presentar(tarea, "  ", notacion: .espanol), "\(tarea)")
        }
    }

    func testLosEjemplosFuncionan() throws {
        for tarea in PresentacionDeCoral.Tarea.allCases {
            XCTAssertNoThrow(try PresentacionDeCoral.presentar(tarea, tarea.ejemplo, notacion: .espanol), "\(tarea)")
        }
    }
}

final class PresentacionDeRedesTests: XCTestCase {
    func testCadaRedDibujaCadaContenido() throws {
        let contenidos: [ContenidoDeRed] = [
            .acorde(try Acorde(leyendo: "Dom7")),
            .escala(try Escala(leyendo: "Re dórico")),
            .recorrido([try Acorde(leyendo: "Do"), try Acorde(leyendo: "Lam"), try Acorde(leyendo: "Fa")]),
            .recorrido([try Acorde(leyendo: "Do")]),
        ]
        for red in RedDeNotas.allCases {
            for contenido in contenidos {
                let svg = try XCTUnwrap(PresentacionDeRedes.svg(contenido, en: red, notacion: .espanol), "\(red)")
                XCTAssertTrue(svg.contains("<svg"), "\(red) \(contenido)")
            }
        }
    }

    func testUnRecorridoVacioNoSeDibuja() {
        XCTAssertNil(PresentacionDeRedes.svg(.recorrido([]), en: .tonnetz, notacion: .espanol))
    }

    func testLosTecladosMarcanLasNotasEnTodasLasOctavas() throws {
        let svg = try XCTUnwrap(PresentacionDeRedes.svg(.acorde(try Acorde(leyendo: "Do")), en: .wickiHayden,
                                                        notacion: .espanol))
        XCTAssertTrue(svg.contains(">Do4<"))
        XCTAssertTrue(svg.contains(">Do5<"))
        XCTAssertEqual(PresentacionDeRedes.casillasDelTeclado.count, 12 * 7)
        XCTAssertTrue(PresentacionDeRedes.casillasDelTeclado.contains(.origen))
    }

    func testLasNotasNoSeRepiten() throws {
        let recorrido = ContenidoDeRed.recorrido([try Acorde(leyendo: "Do"), try Acorde(leyendo: "Lam")])
        XCTAssertEqual(recorrido.notas.count, 4)
    }

    func testElNombreDiceLaRedYElContenido() throws {
        let acorde = try Acorde(leyendo: "Dom7")
        XCTAssertEqual(PresentacionDeRedes.nombre(.acorde(acorde), en: .tablaArmonica, notacion: .espanol),
                       "Tabla armónica · " + acorde.cifrado(en: .espanol))
    }
}
