import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura
@testable import ArmoniaTrastes

final class MastilTests: XCTestCase {
    func testAlturasAlAireDeLaGuitarra() {
        let mastil = Mastil(.guitarra)
        let midis = (0..<6).map { mastil.midi(en: PosicionEnElMastil(cuerda: $0, traste: 0)) }
        XCTAssertEqual(midis, [40, 45, 50, 55, 59, 64])   // Mi2 La2 Re3 Sol3 Si3 Mi4
    }

    func testAlturaEnUnTraste() {
        let mastil = Mastil(.guitarra)
        // Cuerda de La, traste 3: Do3.
        XCTAssertEqual(mastil.altura(en: PosicionEnElMastil(cuerda: 1, traste: 3)), Altura(.do, octava: 3))
        // Cuerda de Mi grave, traste 1: Fa2.
        XCTAssertEqual(mastil.altura(en: PosicionEnElMastil(cuerda: 0, traste: 1)), Altura(.fa, octava: 2))
    }

    func testBemolesSiSePide() {
        let mastil = Mastil(.guitarra)
        let posicion = PosicionEnElMastil(cuerda: 1, traste: 1)   // Si♭2 / La♯2
        XCTAssertEqual(mastil.altura(en: posicion, preferirBemoles: true).nota.nombre, "Si♭")
        XCTAssertEqual(mastil.altura(en: posicion).nota.nombre, "La♯")
    }

    func testPosicionesDeUnaAltura() {
        let mastil = Mastil(.guitarra, trastes: 12)
        // El Mi4 suena al aire en la cuerda aguda, en el traste 5 de la Si y en el 9 de la Sol;
        // en las demás cuerdas está más allá del traste 12.
        let posiciones = mastil.posiciones(de: Altura(.mi, octava: 4))
        XCTAssertEqual(posiciones, [
            PosicionEnElMastil(cuerda: 5, traste: 0), PosicionEnElMastil(cuerda: 4, traste: 5), PosicionEnElMastil(cuerda: 3, traste: 9),
        ])
    }

    func testPosicionesDeUnaNotaEnCualquierOctava() {
        let mastil = Mastil(.guitarra, trastes: 12)
        // Mi: 0 y 12 en las dos cuerdas de Mi, 7 en La, 2 en Re, 9 en Sol y 5 en Si.
        XCTAssertEqual(mastil.posiciones(de: Nota.mi).count, 8)
    }

    func testEnarmonicosDanLasMismasPosiciones() {
        let mastil = Mastil(.guitarra)
        XCTAssertEqual(mastil.posiciones(de: Nota("Fa#")), mastil.posiciones(de: Nota("Solb")))
    }

    func testPosicionesFueraDelMastilNoExisten() {
        let mastil = Mastil(.guitarra, trastes: 12)
        XCTAssertFalse(mastil.contiene(PosicionEnElMastil(cuerda: 6, traste: 0)))
        XCTAssertFalse(mastil.contiene(PosicionEnElMastil(cuerda: 0, traste: 13)))
        XCTAssertTrue(mastil.contiene(PosicionEnElMastil(cuerda: 0, traste: 12)))
    }

    func testEscalaEnUnRangoDeTrastes() {
        let mastil = Mastil(.guitarra)
        let doMayor = Escala(.do, .mayor)
        let primera = mastil.posiciones(de: doMayor, trastes: 0...4)
        XCTAssertFalse(primera.isEmpty)
        XCTAssertTrue(primera.allSatisfy { (0...4).contains($0.traste) })
        // Todas suenan una nota de la escala.
        let clases = Set(doMayor.notas.map(\.claseDeAltura))
        XCTAssertTrue(primera.allSatisfy { clases.contains(Mastil.clase(mastil.midi(en: $0))) })
    }

    func testOtrosEncordados() {
        XCTAssertEqual(Encordado.bajo.numeroDeCuerdas, 4)
        XCTAssertEqual(Encordado.guitarraDeSieteCuerdas.numeroDeCuerdas, 7)
        XCTAssertEqual(Encordado.guitarraEnReGrave.cuerdas.first, Altura(.re, octava: 2))
        // El ukelele es reentrante: la primera cuerda (Sol4) está más aguda que la segunda (Do4).
        XCTAssertGreaterThan(Encordado.ukelele.cuerdas[0].midi, Encordado.ukelele.cuerdas[1].midi)
    }

    func testPosicionesFueraDelMastilSinDetenerElPrograma() {
        let mastil = Mastil(.guitarra, trastes: 12)
        XCTAssertNil(mastil.midiSiExiste(en: PosicionEnElMastil(cuerda: 0, traste: 13)))
        XCTAssertNil(mastil.midiSiExiste(en: PosicionEnElMastil(cuerda: 6, traste: 0)))
        XCTAssertNil(mastil.midiSiExiste(en: PosicionEnElMastil(cuerda: -1, traste: 0)))
        XCTAssertNil(mastil.alturaSiExiste(en: PosicionEnElMastil(cuerda: 0, traste: -1)))
        XCTAssertEqual(mastil.midiSiExiste(en: PosicionEnElMastil(cuerda: 0, traste: 0)), Altura(.mi, octava: 2).midi)
        let tercer = PosicionEnElMastil(cuerda: 1, traste: 3)
        XCTAssertEqual(mastil.alturaSiExiste(en: tercer), mastil.altura(en: tercer))
        XCTAssertEqual(mastil.midiSiExiste(en: tercer), mastil.midi(en: tercer))
    }

    func testUnNumeroNegativoDeTrastesSeTomaComoCero() {
        let mastil = Mastil(.guitarra, trastes: -5)
        XCTAssertEqual(mastil.trastes, 0)
        // Solo cuerdas al aire: el Mi está en la primera cuerda (Mi2) y en la última (Mi4).
        XCTAssertEqual(mastil.posiciones(de: Nota.mi).map(\.cuerda), [0, 5])
    }
}

final class DigitacionTests: XCTestCase {
    private let guitarra = Mastil(.guitarra)

    func testDoMayorAbierto() throws {
        let formas = guitarra.digitaciones(de: try Acorde(leyendo: "Do"), limite: 100)
        XCTAssertTrue(formas.map(\.tablatura).contains("x32010"), formas.map(\.tablatura).joined(separator: " "))
    }

    func testMiMenorAbierto() throws {
        let formas = guitarra.digitaciones(de: try Acorde(leyendo: "Mim"), limite: 100)
        XCTAssertTrue(formas.map(\.tablatura).contains("022000"))
    }

    func testElBajoEsLaNotaMasGrave() throws {
        // En Do/Mi la nota más grave es Mi, no Do.
        let acorde = try Acorde(leyendo: "Do/Mi")
        let formas = guitarra.digitaciones(de: acorde, limite: 50)
        XCTAssertFalse(formas.isEmpty)
        for forma in formas {
            let grave = try XCTUnwrap(forma.alturas.map(\.midi).min())
            XCTAssertEqual(Mastil.clase(grave), Nota.mi.claseDeAltura, forma.tablatura)
        }
    }

    func testTodasLasFormasTocanElAcordeEntero() throws {
        let acorde = try Acorde(leyendo: "Sol7")
        let clases = Set(acorde.notas.map(\.claseDeAltura))
        for forma in guitarra.digitaciones(de: acorde) {
            let tocadas = Set(forma.alturas.map { $0.nota.claseDeAltura })
            XCTAssertEqual(tocadas, clases, forma.tablatura)
            XCTAssertLessThanOrEqual(forma.abertura, 4, forma.tablatura)
            XCTAssertGreaterThanOrEqual(forma.cuerdasQueSuenan, 4, forma.tablatura)
        }
    }

    func testLasCuerdasQueSuenanSonSeguidas() throws {
        for forma in guitarra.digitaciones(de: try Acorde(leyendo: "La7"), limite: 100) {
            let suenan = forma.trastes.map { $0 != nil }
            let primera = try XCTUnwrap(suenan.firstIndex(of: true))
            let ultima = try XCTUnwrap(suenan.lastIndex(of: true))
            XCTAssertTrue(suenan[primera...ultima].allSatisfy { $0 }, forma.tablatura)
        }
    }

    func testElLimiteSeRespeta() throws {
        XCTAssertLessThanOrEqual(guitarra.digitaciones(de: try Acorde(leyendo: "Do"), limite: 3).count, 3)
    }

    func testCifraConTrastesAltos() {
        let forma = Digitacion(mastil: guitarra, trastes: [nil, 10, 12, 12, 11, 10])
        XCTAssertEqual(forma.tablatura, "x-10-12-12-11-10")
        XCTAssertEqual(forma.abertura, 3)
        XCTAssertEqual(forma.posicion, 10)
    }

    func testUkeleleDoMayor() throws {
        // Do mayor en el ukelele soprano: 0003.
        let ukelele = Mastil(.ukelele, trastes: 12)
        let formas = ukelele.digitaciones(de: try Acorde(leyendo: "Do"), limite: 100)
        XCTAssertTrue(formas.map(\.tablatura).contains("0003"), formas.map(\.tablatura).joined(separator: " "))
    }
}

extension DigitacionTests {
    func testComprobandoLosTrastes() {
        let guitarra = Mastil(.guitarra)
        XCTAssertNotNil(Digitacion(comprobando: [nil, 3, 2, 0, 1, 0], en: guitarra))
        XCTAssertNil(Digitacion(comprobando: [nil, 3, 2, 0, 1], en: guitarra))          // falta una cuerda
        XCTAssertNil(Digitacion(comprobando: [nil, 3, 2, 0, 1, -1], en: guitarra))      // traste negativo
        XCTAssertNil(Digitacion(comprobando: [nil, 3, 2, 0, 1, 25], en: guitarra))      // más allá del último (24)
    }

    func testLeyendoLaCifra() {
        let guitarra = Mastil(.guitarra)
        XCTAssertEqual(Digitacion(leyendo: "x32010", en: guitarra)?.tablatura, "x32010")
        XCTAssertEqual(Digitacion(leyendo: "X32010", en: guitarra)?.tablatura, "x32010")
        XCTAssertEqual(Digitacion(leyendo: "x-10-12-12-11-10", en: guitarra)?.tablatura, "x-10-12-12-11-10")
        XCTAssertNil(Digitacion(leyendo: "x3201", en: guitarra))                 // faltan cuerdas
        XCTAssertNil(Digitacion(leyendo: "x32a10", en: guitarra))                // «a» no es un traste
        XCTAssertNil(Digitacion(leyendo: "x-10--12-12-11-10", en: guitarra))     // hueco vacío
        XCTAssertNil(Digitacion(leyendo: "", en: guitarra))
    }

    func testLaCifraVuelveALaMismaDigitacion() throws {
        let guitarra = Mastil(.guitarra)
        for cifrado in ["Do", "Sol7/Si", "Rem7", "Fa"] {
            for forma in guitarra.digitaciones(de: try Acorde(leyendo: cifrado), limite: 20) {
                XCTAssertEqual(Digitacion(leyendo: forma.tablatura, en: guitarra), forma, forma.tablatura)
            }
        }
    }

    func testLasNotasSeEscribenComoElAcorde() throws {
        let acorde = try Acorde(leyendo: "Sib")
        let forma = try XCTUnwrap(Mastil(.guitarra).digitaciones(de: acorde, limite: 1).first)
        let nombres = forma.notas(para: acorde).map { $0.nombre(en: .espanol) }
        XCTAssertEqual(nombres.count, forma.cuerdasQueSuenan)
        XCTAssertTrue(nombres.contains("Si♭"), nombres.joined(separator: " "))
        XCTAssertFalse(nombres.contains("La♯"), nombres.joined(separator: " "))
    }
}

final class EncordadoNombreTests: XCTestCase {
    func testBuscarUnInstrumentoPorNombre() {
        XCTAssertEqual(Encordado(nombre: "Guitarra"), .guitarra)
        XCTAssertEqual(Encordado(nombre: "UKULELE"), .ukelele)
        XCTAssertEqual(Encordado(nombre: "bajo de 5 cuerdas"), .bajoDeCincoCuerdas)
        XCTAssertEqual(Encordado(nombre: "Drop-D"), .guitarraEnReGrave)
        XCTAssertEqual(Encordado(nombre: "guitarra en re grave"), .guitarraEnReGrave)
        XCTAssertEqual(Encordado(nombre: "mandolin"), .mandolina)
    }

    func testUnNombreDesconocidoNoEsNingunInstrumento() {
        XCTAssertNil(Encordado(nombre: "arpa"))
        XCTAssertNil(Encordado(nombre: ""))
    }

    func testTodosSeEncuentranPorSuNombre() {
        for encordado in Encordado.todos {
            XCTAssertEqual(Encordado(nombre: encordado.nombre), encordado, encordado.nombre)
        }
    }
}

// MARK: - Dedos, cejilla y orden de comodidad

final class DedosYOrdenTests: XCTestCase {
    private let guitarra = Mastil(.guitarra)
    private let ukelele = Mastil(.ukelele)

    private func forma(_ cifra: String) throws -> Digitacion {
        try XCTUnwrap(Digitacion(leyendo: cifra, en: guitarra), cifra)
    }

    // MARK: Dedos y cejilla

    func testLosDedosDeFormasConocidas() throws {
        let formas: [(String, Int, Int?)] = [
            ("x32010", 3, nil), ("xx0232", 3, nil), ("320003", 3, nil), ("022100", 3, nil),
            ("x02020", 2, nil), ("020100", 2, nil), ("xx3211", 3, nil), ("x32310", 4, nil),
            // Un dedo plano pisa cuerdas seguidas en el traste más bajo.
            ("x02220", 1, nil), ("022000", 1, nil),
            // Cejilla: cuatro cuerdas o más con el índice en el traste más bajo.
            ("133211", 4, 1), ("133111", 3, 1), ("x13331", 4, 1), ("x24432", 4, 2),
        ]
        for (cifra, dedos, cejilla) in formas {
            let digitacion = try forma(cifra)
            XCTAssertEqual(digitacion.dedos, dedos, "dedos de \(cifra)")
            XCTAssertEqual(digitacion.cejilla, cejilla, "cejilla de \(cifra)")
        }
    }

    func testSinTrastesPisadosNoHacenFaltaDedos() throws {
        XCTAssertEqual(try forma("000000").dedos, 0)
        XCTAssertEqual(try forma("xx0000").dedos, 0)
        XCTAssertNil(try forma("000000").cejilla)
    }

    func testUnaCuerdaAlAireEnMedioImpideLaCejilla() throws {
        // El Re (cuerda 2) al aire: el índice no puede cubrir del Mi al Mi agudo en el traste 1.
        XCTAssertEqual(try forma("1x0xx1").cejilla, nil)
        XCTAssertEqual(try forma("1x0xx1").dedos, 2)
    }

    func testElLimiteDeDedosSeRespeta() throws {
        let acorde = try Acorde(leyendo: "Mim")
        for tope in [4, 2, 1] {
            let formas = guitarra.digitaciones(de: acorde, maximoDeDedos: tope, limite: 200)
            XCTAssertFalse(formas.isEmpty, "tope \(tope)")
            XCTAssertTrue(formas.allSatisfy { $0.dedos <= tope }, "tope \(tope)")
        }
        // Con menos dedos hay menos formas, y el Mi menor abierto cabe en uno.
        let con1 = guitarra.digitaciones(de: acorde, maximoDeDedos: 1, limite: 200).map(\.tablatura)
        XCTAssertTrue(con1.contains("022000"))
        XCTAssertLessThan(con1.count, guitarra.digitaciones(de: acorde, limite: 200).count)
        XCTAssertTrue(guitarra.digitaciones(de: acorde, maximoDeDedos: 0, limite: 200).isEmpty)
    }

    func testNingunaFormaPorDefectoNecesitaMasDeCuatroDedos() throws {
        for cifrado in ["Do", "Sol7", "Fa", "Sib", "Rem7", "Fa#m7b5", "Do9"] {
            for forma in guitarra.digitaciones(de: try Acorde(leyendo: cifrado), limite: 200) {
                XCTAssertLessThanOrEqual(forma.dedos, 4, "\(cifrado) \(forma.tablatura)")
            }
        }
    }

    // MARK: Formas de manual

    /// Las formas que un guitarrista espera ver primero, con la quinta opcional (como las pide la aplicación).
    func testLasFormasDeManualSonLasPrimeras() throws {
        let manual: [(String, [String])] = [
            ("Do", ["x32010"]), ("Sol", ["320003", "320033"]), ("Re", ["xx0232"]), ("La", ["x02220"]),
            ("Mi", ["022100"]), ("Lam", ["x02210"]), ("Mim", ["022000"]), ("Rem", ["xx0231"]),
            ("Sol7", ["320001"]), ("Do7", ["x32310"]), ("Re7", ["xx0212"]), ("La7", ["x02020"]),
            ("Mi7", ["020100"]), ("Si7", ["x21202"]), ("Lam7", ["x02010"]), ("Mim7", ["020000", "022030"]),
            ("Domaj7", ["x32000"]), ("Famaj7", ["102210", "xx3210"]), ("Solmaj7", ["320002"]),
            ("Resus2", ["xx0230"]), ("Rem7", ["xx0211"]), ("Fam", ["133111"]),
        ]
        for (cifrado, esperadas) in manual {
            let primera = try XCTUnwrap(
                guitarra.digitaciones(de: try Acorde(leyendo: cifrado), exigirQuinta: false, limite: 1).first, cifrado)
            XCTAssertTrue(esperadas.contains(primera.tablatura), "\(cifrado): sale \(primera.tablatura), se esperaba \(esperadas)")
        }
    }

    /// Otras formas de manual: antes de ellas puede haber alguna más fácil (Mi sus4 como `002200`), pero no muchas.
    func testLasDemasFormasDeManualEstanEntreLasPrimeras() throws {
        let manual: [(String, String)] = [
            ("Fa", "133211"), ("Sib", "x13331"), ("Resus4", "xx0233"), ("Lasus4", "x02230"), ("Misus4", "022200"),
            ("Doadd9", "x32030"), ("Sim", "x24432"), ("Fa#m", "244222"), ("Solm", "355333"), ("Dom", "x35543"),
        ]
        for (cifrado, esperada) in manual {
            let primeras = guitarra.digitaciones(de: try Acorde(leyendo: cifrado), exigirQuinta: false, limite: 6).map(\.tablatura)
            XCTAssertTrue(primeras.contains(esperada), "\(cifrado): \(primeras), se esperaba \(esperada)")
        }
    }

    func testLaCercaniaALaCejillaPesaMasQueTenerTodasLasCuerdas() throws {
        // Antes, `8-10-10-0-8-0` (seis cuerdas, en el traste 8) iba por delante de `x32010`.
        let formas = guitarra.digitaciones(de: try Acorde(leyendo: "Do"), limite: 3).map(\.tablatura)
        XCTAssertEqual(formas.first, "x32010", formas.joined(separator: " "))
    }

    func testLaQuintaPuedeFaltarSoloSiSePermite() throws {
        let acorde = try Acorde(leyendo: "Do7")
        // El Do7 de manual no tiene la quinta (Sol).
        XCTAssertFalse(guitarra.digitaciones(de: acorde, limite: 300).map(\.tablatura).contains("x32310"))
        XCTAssertTrue(guitarra.digitaciones(de: acorde, exigirQuinta: false, limite: 300).map(\.tablatura).contains("x32310"))
    }

    func testElMi7AbiertoEsLaPrimeraConLaQuintaOpcional() throws {
        let acorde = try Acorde(leyendo: "Mi7")
        let formas = guitarra.digitaciones(de: acorde, exigirQuinta: false, limite: 5)
        XCTAssertEqual(formas.first?.tablatura, "020100")
    }

    // MARK: Ukelele y otros instrumentos reentrantes

    func testQueInstrumentosSonReentrantes() {
        XCTAssertTrue(Encordado.ukelele.esReentrante)
        for encordado in [Encordado.guitarra, .guitarraDeSieteCuerdas, .guitarraEnReGrave, .bajo, .bajoDeCincoCuerdas, .mandolina] {
            XCTAssertFalse(encordado.esReentrante, encordado.nombre)
        }
    }

    func testLasFormasBasicasDelUkelele() throws {
        let manual: [(String, String)] = [
            ("Do", "0003"), ("Sol", "0232"), ("Fa", "2010"), ("Lam", "2000"), ("Rem", "2210"),
            ("Re", "2220"), ("La", "2100"), ("Sol7", "0212"), ("Do7", "0001"),
        ]
        for (cifrado, esperada) in manual {
            let primera = try XCTUnwrap(ukelele.digitaciones(de: try Acorde(leyendo: cifrado), exigirQuinta: false, limite: 1).first, cifrado)
            XCTAssertEqual(primera.tablatura, esperada, cifrado)
        }
        let mim = ukelele.digitaciones(de: try Acorde(leyendo: "Mim"), exigirQuinta: false, limite: 3).map(\.tablatura)
        XCTAssertTrue(mim.contains("0432"), mim.joined(separator: " "))
    }

    func testUnAcordeConBajoPropioExigeEseBajoTambienEnElUkelele() throws {
        let formas = ukelele.digitaciones(de: try Acorde(leyendo: "Do/Mi"), limite: 100)
        XCTAssertFalse(formas.isEmpty)
        for forma in formas {
            let grave = try XCTUnwrap(forma.alturas.map(\.midi).min())
            XCTAssertEqual(Mastil.clase(grave), Nota.mi.claseDeAltura, forma.tablatura)
        }
        XCTAssertFalse(formas.map(\.tablatura).contains("0003"))   // ahí el Do es lo más grave
    }
}
