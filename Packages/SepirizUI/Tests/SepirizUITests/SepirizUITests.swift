import XCTest
import Armonia
@testable import SepirizUI

#if canImport(SwiftUI) && canImport(WebKit)
final class SVGViewTests: XCTestCase {
    func testLaPaginaIncluyeElSVG() {
        let pagina = SVGView.pagina("<svg id=\"dibujo\"></svg>")
        XCTAssertTrue(pagina.contains("<svg id=\"dibujo\"></svg>"))
        XCTAssertTrue(pagina.hasPrefix("<!doctype html>"))
    }
}
#endif

// Lo que sigue no usa SwiftUI: se ejecuta también en Linux.

final class NotacionTests: XCTestCase {
    func testCadaNotacionTieneTituloYClaveDistintos() {
        let todas = Nomenclatura.allCases
        XCTAssertEqual(Set(todas.map(\.titulo)).count, todas.count)
        XCTAssertEqual(Set(todas.map(\.clave)).count, todas.count)
    }

    func testLaClaveVuelveALaNotacion() {
        for notacion in Nomenclatura.allCases {
            XCTAssertEqual(Nomenclatura.desde(clave: notacion.clave), notacion)
        }
    }

    func testUnaClaveDesconocidaDaElEspanol() {
        XCTAssertEqual(Nomenclatura.desde(clave: ""), .espanol)
        XCTAssertEqual(Nomenclatura.desde(clave: "klingon"), .espanol)
        // Un ajuste antiguo guardado como índice no rompe nada.
        XCTAssertEqual(Nomenclatura.desde(clave: "3"), .espanol)
    }

    func testElMensajeDeUnErrorAjenoEsSuDescripcion() {
        struct Falla: LocalizedError { var errorDescription: String? { "falla de prueba" } }
        XCTAssertEqual(Nomenclatura.espanol.mensaje(de: Falla()), "falla de prueba")
    }

    func testElMensajeDeUnErrorDeLecturaNoEstaVacio() {
        do {
            _ = try Acorde(leyendo: "xyz!")
            XCTFail("«xyz!» no es un cifrado")
        } catch {
            XCTAssertFalse(Nomenclatura.espanol.mensaje(de: error).isEmpty)
            XCTAssertFalse(Nomenclatura.ingles.mensaje(de: error).isEmpty)
        }
    }
}

final class PresentacionDeMastilTests: XCTestCase {
    private let guitarra = Mastil(.guitarra)

    private func digitacion(_ trastes: [Int?]) -> Digitacion {
        Digitacion(mastil: guitarra, trastes: trastes)
    }

    // MARK: Rango

    func testCercaDeLaCejillaSeVeDesdeElCero() {
        XCTAssertEqual(PresentacionDeMastil.rango(de: digitacion([nil, 3, 2, 0, 1, 0])), 0...5)   // Do
        XCTAssertEqual(PresentacionDeMastil.rango(de: digitacion([1, 3, 3, 2, 1, 1])), 0...5)     // Fa con cejilla
    }

    func testSinTrastesPisadosSeVeDesdeElCero() {
        XCTAssertEqual(PresentacionDeMastil.rango(de: digitacion([nil, nil, 0, 0, nil, nil])), 0...5)
    }

    func testLejosDeLaCejillaHayUnaVentanaConMargen() {
        XCTAssertEqual(PresentacionDeMastil.rango(de: digitacion([nil, 7, 9, 9, 8, 7])), 6...10)
    }

    func testLaVentanaTieneAlMenosCuatroTrastes() {
        XCTAssertEqual(PresentacionDeMastil.rango(de: digitacion([nil, 0, 7, 7, 7, 7])), 6...9)
        XCTAssertEqual(PresentacionDeMastil.rango(de: digitacion([nil, 5, 5, 5, 5, nil])), 4...7)
    }

    func testTodaPosicionPisadaCabeEnElRango() throws {
        for cifrado in ["Do", "Sol7/Si", "Rem7", "Fa#m7b5", "Mib", "Sib"] {
            let acorde = try Acorde(leyendo: cifrado)
            for forma in guitarra.digitaciones(de: acorde, maximoTraste: 15) {
                let rango = PresentacionDeMastil.rango(de: forma)
                for posicion in forma.posiciones where posicion.traste > 0 {
                    XCTAssertTrue(rango.contains(posicion.traste), "\(cifrado) \(forma.cifra): \(rango)")
                }
            }
        }
    }

    // MARK: Cuerdas apagadas

    func testLasCuerdasApagadas() {
        XCTAssertEqual(PresentacionDeMastil.apagadas(de: digitacion([nil, 3, 2, 0, 1, 0])), [0])
        XCTAssertEqual(PresentacionDeMastil.apagadas(de: digitacion([nil, nil, 0, 0, nil, 1])), [0, 1, 4])
        XCTAssertEqual(PresentacionDeMastil.apagadas(de: digitacion([3, 2, 0, 0, 0, 3])), [])
    }

    // MARK: Ortografía

    func testLaOrtografiaEsLaDeLaEscala() {
        // Con `Altura(midi:)` el Si♭ saldría como La♯.
        let ortografia = PresentacionDeMastil.ortografia(de: Escala(.fa, .mayor).notas)
        XCTAssertEqual(ortografia[10]?.nombre(en: .espanol), "Si♭")
        XCTAssertEqual(ortografia[5]?.nombre(en: .espanol), "Fa")
        XCTAssertNil(ortografia[1])   // Do♯ no está en Fa mayor
    }

    func testLaOrtografiaDelAcordeConBemoles() throws {
        let ortografia = PresentacionDeMastil.ortografia(de: try Acorde(leyendo: "Mib").notas)
        XCTAssertEqual(ortografia[3]?.nombre(en: .espanol), "Mi♭")
        XCTAssertEqual(ortografia[10]?.nombre(en: .espanol), "Si♭")
    }

    func testSiDosNotasComparteClaveGanaLaPrimera() {
        let notas = [Nota(pasosDeQuinta: 6), Nota(pasosDeQuinta: -6)]   // Fa♯ y Sol♭
        XCTAssertEqual(PresentacionDeMastil.ortografia(de: notas)[6]?.nombre(en: .espanol), "Fa♯")
    }

    func testSinNotasNoHayOrtografia() {
        XCTAssertTrue(PresentacionDeMastil.ortografia(de: []).isEmpty)
    }

    // MARK: Descripción

    func testLaDescripcionVaDeGraveAAgudo() {
        let marcas = [Posicion(cuerda: 1, traste: 3), Posicion(cuerda: 0, traste: 0)]
        XCTAssertEqual(PresentacionDeMastil.descripcion(marcas: marcas, apagadas: []),
                       "cuerda 1, traste 0; cuerda 2, traste 3")
        XCTAssertEqual(PresentacionDeMastil.descripcion(marcas: marcas, apagadas: [5]),
                       "cuerda 1, traste 0; cuerda 2, traste 3; cuerdas apagadas: 6")
    }

    func testLaDescripcionSeAcortaSiHayMuchasMarcas() {
        let muchas = (0...12).map { Posicion(cuerda: 0, traste: $0) }
        XCTAssertEqual(PresentacionDeMastil.descripcion(marcas: muchas, apagadas: []), "13 marcas")
    }

    func testSinMarcas() {
        XCTAssertEqual(PresentacionDeMastil.descripcion(marcas: [], apagadas: []), "Sin marcas")
    }
}
