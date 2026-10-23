import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class NotaTests: XCTestCase {
    func testLineaDeQuintas() {
        XCTAssertEqual(Nota(pasosDeQuinta: 0).nombre, "Do")
        XCTAssertEqual(Nota(pasosDeQuinta: -1).nombre, "Fa")
        XCTAssertEqual(Nota(pasosDeQuinta: 5).nombre, "Si")
        XCTAssertEqual(Nota(pasosDeQuinta: 6).nombre, "Fa♯")
        XCTAssertEqual(Nota(pasosDeQuinta: -2).nombre, "Si♭")
        XCTAssertEqual(Nota(pasosDeQuinta: -9).nombre, "Si♭♭")
        XCTAssertEqual(Nota(pasosDeQuinta: 13).nombre, "Fa♯♯")
    }

    func testLetraYAlteracion() {
        XCTAssertEqual(Nota(.fa, 1).pasosDeQuinta, 6)
        XCTAssertEqual(Nota(.mi, -1).pasosDeQuinta, -3)
        XCTAssertEqual(Nota(pasosDeQuinta: -3).natural, .mi)
        XCTAssertEqual(Nota(pasosDeQuinta: -3).alteracion, -1)
    }

    func testAnalisisDeTexto() {
        XCTAssertEqual(Nota("Sib"), Nota(.si, -1))
        XCTAssertEqual(Nota("fa#"), Nota(.fa, 1))
        XCTAssertEqual(Nota("Solx"), Nota(.sol, 2))
        XCTAssertEqual(Nota("Mi♭♭"), Nota(.mi, -2))
        XCTAssertEqual(Nota("Bb"), Nota(.si, -1))
        XCTAssertEqual(Nota("C#"), Nota(.do, 1))
        XCTAssertNil(Nota(texto: "Xa"))
    }

    func testEnarmonia() {
        let faSostenido = Nota("Fa#"), solBemol = Nota("Solb")
        XCTAssertNotEqual(faSostenido, solBemol)
        XCTAssertTrue(faSostenido.esEnarmonica(de: solBemol))
        XCTAssertEqual(faSostenido.claseDeAltura, 6)
        XCTAssertEqual(Nota("Mi#").enarmonicaMasSimple, .fa)
        XCTAssertEqual(Nota("Dob").enarmonicaMasSimple, .si)
    }

    func testIntervaloEntreNombres() {
        XCTAssertEqual(Nota.do.intervalo(hasta: .mi), .terceraMayor)
        XCTAssertEqual(Nota.mi.intervalo(hasta: .do), .sextaMenor)
        XCTAssertEqual(Nota.si.intervalo(hasta: .fa), .quintaDisminuida)
        XCTAssertEqual(Nota.fa.intervalo(hasta: .si), .cuartaAumentada)
        XCTAssertEqual(Nota.re + .terceraMayor, Nota("Fa#"))
    }
}

final class AlteracionTests: XCTestCase {
    func testValoresYNombres() {
        XCTAssertEqual(Alteracion.sostenido.semitonos, 1)
        XCTAssertEqual(Alteracion.dobleBemol, -2)
        XCTAssertEqual(Alteracion(3).nombre, "triple sostenido")
        XCTAssertEqual(Alteracion(-2).nombre, "doble bemol")
        XCTAssertEqual(Alteracion(-5).nombre, "5 bemoles")
        XCTAssertEqual(Alteracion.natural.nombre, "natural")
        XCTAssertEqual(Alteracion(2).nombre(en: .ingles), "double sharp")
        XCTAssertEqual(Alteracion(-1).nombre(en: .ingles), "flat")
        XCTAssertEqual(Alteracion(2).simbolo, "♯♯")
        XCTAssertEqual(Alteracion(-2).simboloASCII, "bb")
        XCTAssertEqual(Alteracion(3).simboloCompacto, "𝄪♯")
        XCTAssertEqual(Alteracion(-2).simboloCompacto, "𝄫")
        XCTAssertEqual(Alteracion.natural.simboloCompacto, "♮")
        XCTAssertEqual(Alteracion(-2).cantidad, 2)
        XCTAssertEqual(Alteracion.sostenido.pasosDeQuinta, 7)
        XCTAssertTrue(Alteracion.bemol.esBemol)
        XCTAssertTrue(Alteracion.natural.esNatural)
        XCTAssertEqual(Alteracion.sostenido + .sostenido, .dobleSostenido)
        XCTAssertEqual(-Alteracion.sostenido, .bemol)
        XCTAssertLessThan(Alteracion.bemol, .natural)
    }

    func testLectura() {
        let casos: [(String, Int)] = [("#", 1), ("♯", 1), ("x", 2), ("𝄪", 2), ("##", 2), ("#x", 3), ("b", -1),
                                      ("bb", -2), ("𝄫", -2), ("♭♭♭", -3), ("", 0), ("♮", 0), ("n", 0),
                                      ("sostenido", 1), ("doble bemol", -2), ("Triple Sharp", 3), ("natural", 0)]
        for (texto, semitonos) in casos {
            XCTAssertEqual(Alteracion(texto: texto)?.semitonos, semitonos, texto)
        }
        XCTAssertThrowsError(try Alteracion(leyendo: "#?")) { error in
            XCTAssertEqual((error as? ErrorDeLectura)?.motivo, .alteracionNoReconocida("?"))
            XCTAssertEqual((error as? ErrorDeLectura)?.posicion, 1)
        }
        let literal: Alteracion = "bb"
        XCTAssertEqual(literal, -2)
        for n in -4...4 {
            let a = Alteracion(n)
            for notacion in Nomenclatura.allCases {
                XCTAssertEqual(Alteracion(texto: a.texto(notacion)), a, "\(n) \(notacion)")
            }
        }
    }

    func testEnLosNombresDeNota() {
        XCTAssertEqual(Nota(.fa, .sostenido), Nota("Fa#"))
        XCTAssertEqual(Nota(.si, -2).nombre, "Si♭♭")
        XCTAssertEqual(Nota("Mibb").alteracion, .dobleBemol)
        XCTAssertEqual(Nota.re.alteracion, .natural)
        XCTAssertEqual(Clave.sol.posicion(de: "Fa#4").alteracion, .sostenido)
        XCTAssertEqual(Clave.sol.altura(lugar: 4, alteracion: .bemol), Altura("Sib4"))
    }
}

final class AlturaTests: XCTestCase {
    func testCoordenadasYMidi() {
        XCTAssertEqual(Altura.doCentral.midi, 60)
        XCTAssertEqual(Altura("La4"), Altura(pasosDeQuinta: 3, pasosDeOctava: -1))
        XCTAssertEqual(Altura("La4").midi, 69)
        XCTAssertEqual(Altura("Re4"), Altura(pasosDeQuinta: 2, pasosDeOctava: -1))
        XCTAssertEqual(Altura("Sib3").midi, 58)
        XCTAssertEqual(Altura("Do-1").midi, 0)
    }

    func testOctavaCientifica() {
        XCTAssertEqual(Altura("Dob4").midi, 59)
        XCTAssertEqual(Altura("Dob4").octava, 4)
        XCTAssertEqual(Altura("Si#3").midi, 60)
        XCTAssertEqual(Altura("Si#3").octava, 3)
        XCTAssertEqual(Altura("Si3").description, "Si3")
        XCTAssertLessThan(Altura("Si#3"), Altura("Do4"))
    }

    func testDesdeMidi() {
        XCTAssertEqual(Altura(midi: 61).description, "Do♯4")
        XCTAssertEqual(Altura(midi: 61, preferirBemoles: true).description, "Re♭4")
        XCTAssertEqual(Altura(midi: 65).description, "Fa4")
        XCTAssertEqual(Altura(midi: 71, preferirBemoles: true).description, "Si4")
        for midi in 0...127 {
            XCTAssertEqual(Altura(midi: midi).midi, midi)
            XCTAssertEqual(Altura(midi: midi, preferirBemoles: true).midi, midi)
        }
    }

    func testFrecuencias() {
        XCTAssertEqual(Altura("La4").frecuencia(), 440, accuracy: 1e-9)
        XCTAssertEqual(Altura("La5").frecuencia(), 880, accuracy: 1e-9)
        XCTAssertEqual(Altura("Mi5").frecuencia(en: TemperamentoRegular.pitagorico), 660, accuracy: 1e-9)
        XCTAssertEqual(Altura("Do4").frecuencia(en: TemperamentoRegular.pitagorico), 440 * 16 / 27, accuracy: 1e-9)
    }

    func testTransposicion() {
        XCTAssertEqual(Altura("Do4") + .novenaMayor, Altura("Re5"))
        XCTAssertEqual(Altura("Do4") - .terceraMenor, Altura("La3"))
        XCTAssertEqual(Altura("Re5") - Altura("Do4"), .novenaMayor)
    }

    func testOctavaCientificaYNombreDeNota() {
        let la4: Altura = "La4"
        XCTAssertEqual(la4.octava, 4)
        XCTAssertEqual(la4.pasosDeOctava, -1)           // la coordenada, que no es la octava científica
        XCTAssertEqual(la4.nota, .la)
        XCTAssertEqual(Altura("Si#3").octava, 3)
        XCTAssertEqual(Altura(.do, octava: 5).octava, 5)
    }
}

final class IntervaloTests: XCTestCase {
    func testCoordenadas() {
        XCTAssertEqual(Intervalo.quintaJusta.pasosDeQuinta, 1)
        XCTAssertEqual(Intervalo.quintaJusta.pasosDeOctava, 0)
        XCTAssertEqual(Intervalo.segundaMayor.pasosDeQuinta, 2)
        XCTAssertEqual(Intervalo.segundaMayor.pasosDeOctava, -1)
        XCTAssertEqual(Intervalo.terceraMenor.pasosDeQuinta, -3)
        XCTAssertEqual(Intervalo.terceraMenor.pasosDeOctava, 2)
        XCTAssertEqual(Intervalo.octava.pasosDeQuinta, 0)
        XCTAssertEqual(Intervalo.octava.pasosDeOctava, 1)
    }

    func testSemitonosYCalidad() {
        let esperados: [(Intervalo, Int, String)] = [
            (.unisono, 0, "1J"), (.segundaMenor, 1, "2m"), (.segundaMayor, 2, "2M"),
            (.terceraMenor, 3, "3m"), (.terceraMayor, 4, "3M"), (.cuartaJusta, 5, "4J"),
            (.cuartaAumentada, 6, "4A"), (.quintaDisminuida, 6, "5d"), (.quintaJusta, 7, "5J"),
            (.sextaMenor, 8, "6m"), (.sextaMayor, 9, "6M"), (.septimaDisminuida, 9, "7d"),
            (.septimaMenor, 10, "7m"), (.septimaMayor, 11, "7M"), (.octava, 12, "8J"),
            (.novenaMayor, 14, "9M"), (.decimoterceraMayor, 21, "13M"),
        ]
        for (intervalo, semitonos, abreviatura) in esperados {
            XCTAssertEqual(intervalo.semitonos, semitonos, abreviatura)
            XCTAssertEqual(intervalo.abreviatura, abreviatura)
            XCTAssertEqual(Intervalo(texto: abreviatura), intervalo)
        }
    }

    func testMultiplesAlteraciones() {
        let dobleAumentada = Intervalo(numero: 4, calidad: .aumentada(2))!
        XCTAssertEqual(dobleAumentada.semitonos, 7)
        XCTAssertEqual(dobleAumentada.calidad.nombre, "doble aumentada")
        XCTAssertNil(Intervalo(numero: 5, calidad: .mayor))
        XCTAssertNil(Intervalo(numero: 3, calidad: .justa))
    }

    func testDireccion() {
        let i = Altura("Mi4").intervalo(hasta: Altura("Do4"))
        XCTAssertEqual(i.direccion, .descendente)
        XCTAssertEqual(i.ascendente, .terceraMayor)
        XCTAssertEqual(i.semitonosConSigno, -4)
        XCTAssertEqual(i, -Intervalo.terceraMayor)
        XCTAssertEqual(Intervalo("-3M"), i)
    }

    func testInversionYReduccion() {
        XCTAssertEqual(Intervalo.terceraMayor.inversion, .sextaMenor)
        XCTAssertEqual(Intervalo.cuartaAumentada.inversion, .quintaDisminuida)
        XCTAssertEqual(Intervalo.segundaMenor.inversion, .septimaMayor)
        XCTAssertEqual(Intervalo.unisono.inversion, .octava)
        XCTAssertEqual(Intervalo.octava.inversion, .unisono)
        XCTAssertEqual(Intervalo.novenaMayor.simple, .segundaMayor)
        XCTAssertTrue(Intervalo.novenaMayor.esCompuesto)
        XCTAssertFalse(Intervalo.octava.esCompuesto)
    }

    func testAritmetica() {
        XCTAssertEqual(Intervalo.terceraMayor + .terceraMenor, .quintaJusta)
        XCTAssertEqual(Intervalo.quintaJusta - .terceraMayor, .terceraMenor)
        XCTAssertEqual(Intervalo.cuartaJusta + .quintaJusta, .octava)
        XCTAssertEqual(Intervalo.quintaJusta - .octava, -Intervalo.cuartaJusta)
        XCTAssertEqual(2 * Intervalo.quintaJusta, .novenaMayor)
        XCTAssertTrue(Intervalo.cuartaAumentada.esEnarmonico(de: .quintaDisminuida))
    }

    func testIntervalosComparables() {
        XCTAssertEqual([Intervalo.quintaJusta, .terceraMayor, .quintaDisminuida, .cuartaAumentada].sorted(),
                       [.terceraMayor, .cuartaAumentada, .quintaDisminuida, .quintaJusta])
        XCTAssertLessThan(-Intervalo.segundaMayor, .unisono)
        XCTAssertLessThan(Intervalo.septimaMayor, .octava)
    }
}

final class IntervalosYConsonanciaTests: XCTestCase {
    func testUnisonoDisminuidoNoExiste() {
        XCTAssertNil(Intervalo(numero: 1, calidad: .disminuida(1)))
        XCTAssertNil(Intervalo(texto: "1d"))
        XCTAssertNotNil(Intervalo(numero: 8, calidad: .disminuida(1)))
        XCTAssertThrowsError(try Intervalo(leyendo: "1d")) { error in
            XCTAssertTrue("\(error)".contains("unísono aumentado descendente"), "\(error)")
        }
        // De Do a Do♭ hay un unísono aumentado descendente.
        XCTAssertEqual(Altura("Do4").intervalo(hasta: Altura("Dob4")).abreviatura, "-1A")
    }

    func testClaseIntervalica() {
        let casos: [(Intervalo, Int)] = [
            (.terceraMayor, 4), (.sextaMenor, 4), (.cuartaAumentada, 6), (.quintaDisminuida, 6),
            (.novenaMenor, 1), (.septimaMayor, 1), (.octava, 0), (.unisono, 0), (-Intervalo.terceraMayor, 4),
        ]
        for (intervalo, clase) in casos {
            XCTAssertEqual(intervalo.claseIntervalica, clase, intervalo.nombre)
        }
    }

    func testConsonancia() {
        let casos: [(Intervalo, Consonancia)] = [
            (.unisono, .perfecta), (.octava, .perfecta), (.quintaJusta, .perfecta), (.cuartaJusta, .perfecta),
            (.terceraMenor, .imperfecta), (.terceraMayor, .imperfecta), (.sextaMenor, .imperfecta),
            (.sextaMayor, .imperfecta), ("10M", .imperfecta), ("12J", .perfecta),
            (.segundaMayor, .disonancia), (.septimaMenor, .disonancia), (.cuartaAumentada, .disonancia),
            (.quintaDisminuida, .disonancia), (.terceraDisminuida, .disonancia),
            (.segundaAumentada, .disonancia), (.unisonoAumentado, .disonancia),
        ]
        for (intervalo, consonancia) in casos {
            XCTAssertEqual(intervalo.consonancia(), consonancia, intervalo.nombre)
        }
        XCTAssertEqual(Intervalo.cuartaJusta.consonancia(cuartaDisonante: true), .disonancia)
        XCTAssertTrue(Intervalo.sextaMayor.esConsonante)
        XCTAssertFalse(Intervalo.segundaAumentada.esConsonante)
        XCTAssertEqual(Consonancia.imperfecta.nombre(en: .ingles), "imperfect consonance")
    }
}

/// Pruebas de los protocolos comunes: cada una recorre varios tipos con el mismo código genérico.
final class ProtocolosTests: XCTestCase {
    private static let notaciones: [Nomenclatura] = [.espanol, .espanolASCII, .ingles, .inglesUnicode]

    private func comprobarIdaYVuelta<T: RepresentableComoTexto & Equatable>(
        _ valores: [T], file: StaticString = #filePath, line: UInt = #line
    ) {
        for valor in valores {
            for notacion in Self.notaciones {
                let texto = valor.texto(notacion)
                XCTAssertEqual(try? T(leyendo: texto), valor, "«\(texto)»", file: file, line: line)
            }
        }
    }

    func testRepresentableComoTexto() {
        comprobarIdaYVuelta((-14...14).map { Nota(pasosDeQuinta: $0) })
        comprobarIdaYVuelta(["Do4", "Fa#3", "Sibb-1", "Si#3", "C#5"] as [Altura])
        comprobarIdaYVuelta([Intervalo.terceraMayor, .quintaDisminuida, -Intervalo.novenaMenor, "4AA", .octava])
        comprobarIdaYVuelta(TipoDeAcorde.todos)
        comprobarIdaYVuelta(["Sol7(b9)/Si", "Fa#m7b5", "Do/Re", "Mib6/9", "Faug", "Sibmaj7#11"] as [Acorde])
        comprobarIdaYVuelta(TipoDeEscala.todos.map { Escala("Fa#", $0) })

        XCTAssertEqual(Acorde("Sib7(b9)/Re").texto(.ingles), "Bb7(b9)/D")
        XCTAssertEqual(Intervalo.terceraMayor.texto(.ingles), "M3")
        XCTAssertEqual(Intervalo.terceraMayor.texto, "3M")
        XCTAssertEqual(Altura("Fa#3").texto, "Fa♯3")
        XCTAssertEqual(Escala("Re dórico").texto(.inglesUnicode), "D dorian")
    }

    func testLoQueAportaElProtocolo() throws {
        // init?(_:) y el literal de texto vienen de RepresentableComoTexto.
        XCTAssertNil(Nota(texto: "Xa"))
        XCTAssertNil(TipoDeAcorde(texto: "7(b3)"))
        let nota: Nota = "Sol#"
        XCTAssertEqual(nota, Nota(.sol, 1))
        let tipo: TipoDeAcorde = "m7(b5)"
        XCTAssertEqual(tipo, .semidisminuido)

        // Codable también: cada tipo se codifica como su texto español.
        let valores: [Intervalo] = ["3M", "-5d"]
        let datos = try JSONEncoder().encode(valores)
        XCTAssertEqual(String(decoding: datos, as: UTF8.self), "[\"3M\",\"-5d\"]")
        XCTAssertEqual(try JSONDecoder().decode([Intervalo].self, from: datos), valores)
    }

    func testNombrable() {
        let casos: [(any Nombrable, String, String)] = [
            (NotaNatural.re, "Re", "D"),
            (Nota("Fa#"), "Fa♯", "F#"),
            (Altura("Sib3"), "Si♭3", "Bb3"),
            (Intervalo.terceraMayor, "3ª mayor", "major third"),
            (CalidadDeIntervalo.justa, "justa", "perfect"),
            (Consonancia.perfecta, "consonancia perfecta", "perfect consonance"),
            (TipoDeAcorde.dominanteSeptima, "séptima de dominante", "dominant seventh"),
            (Acorde("Sol7/Si"), "Sol séptima de dominante, primera inversión", "G dominant seventh, first inversion"),
            (TipoDeEscala.dorico, "dórico", "dorian"),
            (Escala("Re dórico"), "Re dórico", "D dorian"),
            (NombreDeGrado.dominante, "dominante", "dominant"),
            (Clave.fa, "clave de fa", "bass clef"),
            (Instrumento.trompaEnFa, "trompa en fa", "horn in F"),
            (PapelEnAcorde.tension(9), "novena", "ninth"),
            (CalidadDeTriada.aumentada, "aumentada", "augmented"),
        ]
        for (valor, espanol, ingles) in casos {
            XCTAssertEqual(valor.nombre(en: .espanol), espanol)
            XCTAssertEqual(valor.nombre(en: .ingles), ingles)
            XCTAssertEqual(valor.nombre(en: .ingles), ingles)
        }
    }

    func testTransponible() {
        func subirQuinta<T: Transponible>(_ valor: T) -> T { valor + .quintaJusta }

        XCTAssertEqual(subirQuinta(Nota.do), .sol)
        XCTAssertEqual(subirQuinta(Altura("Do4")), Altura("Sol4"))
        XCTAssertEqual(subirQuinta(Acorde("Do7")).cifrado, "Sol7")
        XCTAssertEqual(subirQuinta(Escala(.do)), Escala(.sol))
        XCTAssertEqual(subirQuinta(Melodia(["Do4", "Mi4"])).description, "Sol4 Si4")
        XCTAssertEqual(subirQuinta(ConjuntoDeClases([0, 4, 7])), [7, 11, 2])

        XCTAssertEqual(Nota.do.secuencia(.quintaJusta, veces: 3), [.do, .sol, .re, .la])
        XCTAssertEqual(Nota.do.transponer(.quintaJusta, veces: 12), Nota("Si#"))
        XCTAssertEqual(Escala(.do) - .segundaMayor, Escala(Nota("Sib")))
        XCTAssertEqual(Acorde("Do/Mi") + .terceraMayor, Acorde("Mi/Sol#"))
    }

    func testConClasesDeAltura() {
        XCTAssertEqual(Acorde("Sol7").numeroDeForte, "4-27")
        XCTAssertEqual(Escala(.re).numeroDeForte, "7-35")
        XCTAssertEqual(Melodia(["Do4", "Mi4", "Sol4"]).numeroDeForte, "3-11")
        XCTAssertEqual(Acorde("Do").vectorIntervalico, [0, 0, 1, 1, 1, 0])
        XCTAssertTrue(Acorde("Do").esDeLaMismaClase(que: Acorde("Lam")))
        XCTAssertTrue(Acorde("Do").esDeLaMismaClase(que: Melodia(["La3", "Do4", "Mi4"])))
        XCTAssertFalse(Acorde("Do").esDeLaMismaClase(que: Acorde("Do+")))
        XCTAssertTrue(Escala(.do).esDeLaMismaClase(que: Escala(.la, .menorNatural)))
        XCTAssertTrue(ConjuntoDeClases([0, 4, 7]).esDeLaMismaClase(que: Acorde("Rem")))
    }
}
