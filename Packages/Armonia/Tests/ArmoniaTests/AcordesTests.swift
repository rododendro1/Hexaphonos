import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class AcordeTests: XCTestCase {
    func testNotas() {
        XCTAssertEqual(Acorde(.do, .mayor).notas, [.do, .mi, .sol])
        XCTAssertEqual(Acorde("Sol7").notas.map(\.nombre), ["Sol", "Si", "Re", "Fa"])
        XCTAssertEqual(Acorde("Fa#m7b5").notas.map(\.nombre), ["Fa♯", "La", "Do", "Mi"])
        XCTAssertEqual(Acorde("Mib°7").notas.map(\.nombre), ["Mi♭", "Sol♭", "Si♭♭", "Re♭♭"])
        XCTAssertEqual(Acorde("Do6/9").notas.map(\.nombre), ["Do", "Mi", "Sol", "La", "Re"])
        XCTAssertEqual(Acorde("Do6/9").bajo, .do)
        XCTAssertEqual(Acorde("Rem11").notas.count, 6)
    }

    func testCifrado() {
        XCTAssertEqual(Acorde("Rem7").cifrado, "Rem7")
        XCTAssertEqual(Acorde("Dm7").cifrado, "Rem7")
        XCTAssertEqual(Acorde("G7(b9,#11)").cifrado, "Sol7(♭9,♯11)")
        XCTAssertEqual(Acorde("Sol7/Si").inversion, 1)
        XCTAssertEqual(Acorde("Sol7/Si").bajo, .si)
        XCTAssertEqual(Acorde("Sol7/Si").cifrado, "Sol7/Si")
        XCTAssertEqual(Acorde("Do6/9/Mi").cifrado, "Do6/9/Mi")
        XCTAssertNil(Acorde(texto: "Doxyz"))
    }

    func testBajoAjeno() {
        let acorde = Acorde("Do/Re")
        XCTAssertTrue(acorde.tieneBajoAjeno)
        XCTAssertNil(acorde.inversion)
        XCTAssertEqual(acorde.cifrado, "Do/Re")
        XCTAssertEqual(acorde.posicionCerrada(octava: 3).map(\.description), ["Re3", "Do4", "Mi4", "Sol4"])
        XCTAssertEqual(acorde.transponer(.segundaMayor).cifrado, "Re/Mi")
    }

    func testDisposicion() {
        XCTAssertEqual(Acorde("Do/Mi").posicionCerrada(octava: 4).map(\.description),
                       ["Mi4", "Sol4", "Do5"])
        XCTAssertEqual(Acorde("Do9").posicionCerrada(octava: 3).map(\.description),
                       ["Do3", "Mi3", "Sol3", "Si♭3", "Re4"])
    }

    func testIdentificacion() {
        XCTAssertEqual(Acorde.identificar([.mi, .sol, .do]).first, Acorde(.do, .mayor, inversion: 1))

        let ambiguo = Acorde.identificar([Nota.la, .do, .mi, .sol]).map(\.cifrado)
        XCTAssertEqual(ambiguo.first, "Lam7")
        XCTAssertTrue(ambiguo.contains("Do6/La"))

        let porAltura = Acorde.identificar([Altura("Fa4"), Altura("Si3"), Altura("Re4"), Altura("Sol3")])
        XCTAssertEqual(porAltura.first?.cifrado, "Sol7")

        // La ortografía importa: Do–Mi–Sol♯ es Do aumentado; Do–Mi–La♭ es La♭ aumentado sobre Do.
        XCTAssertEqual(Acorde.identificar([.do, .mi, Nota("Sol#")]).first, Acorde(.do, .aumentado))
        XCTAssertEqual(Acorde.identificar([.do, .mi, Nota("Lab")]).first,
                       Acorde(Nota("Lab"), .aumentado, inversion: 1))
    }

    func testSextasAumentadas() throws {
        let italiana = try Acorde(leyendo: "Lab(#6,omit5)")
        XCTAssertEqual(italiana.notas, ["La♭", "Do", "Fa♯"])
        XCTAssertEqual(italiana.tipo.nombre, "sexta aumentada italiana")
        XCTAssertEqual(italiana.tipo.estructura.papel(de: .sextaAumentada), .sexta)
        XCTAssertEqual(Acorde.identificar(["La♭", "Do", "Fa♯"] as [Nota]).first?.description, "La♭(♯6,omit5)")
        XCTAssertEqual(Acorde.identificar(["La♭", "Do", "Mi♭", "Fa♯"] as [Nota]).first?.description, "La♭(♯6)")
        XCTAssertEqual(Acorde.identificar(["La♭", "Do", "Mi♭", "Fa♯"] as [Nota]).first?.tipo.nombre(en: .ingles),
                       "German augmented sixth")
        let francesa = Acorde.identificar(["La♭", "Do", "Re", "Fa♯"] as [Nota])
        XCTAssertTrue(francesa.contains { $0.description == "La♭(♯6,♯11,omit5)" && $0.tipo.nombre == "sexta aumentada francesa" })
    }

    func testIdentificacionTolerante() {
        // Quinta omitida.
        let sinQuinta = Acorde.candidatos([.do, .mi, Nota("Sib")]).first
        XCTAssertEqual(sinQuinta?.valor.cifrado, "Do7")
        XCTAssertEqual(sinQuinta?.omitidas, [.sol])

        // Notas duplicadas.
        XCTAssertEqual(Acorde.identificar([.do, .mi, .sol, .do, .mi]).first?.cifrado, "Do")

        // Tensiones alteradas.
        XCTAssertEqual(Acorde.identificar([.do, .mi, Nota("Sib"), Nota("Reb")]).first?.cifrado,
                       "Do7(♭9)")

        // Bajo ajeno al acorde.
        let conBajo = Acorde.identificar([.re, .do, .mi, .sol]).map(\.cifrado)
        XCTAssertTrue(conBajo.contains("Do/Re"))

        // Los costes salen ordenados.
        let costes = Acorde.candidatos([.re, .do, .mi, .sol]).map(\.coste)
        XCTAssertEqual(costes, costes.sorted())

        XCTAssertTrue(Acorde.identificar([.do, Nota("Do#")]).isEmpty)
    }

    func testTransposicion() {
        XCTAssertEqual(Acorde("Sol7").transponer(.cuartaJusta).cifrado, "Do7")
        XCTAssertEqual(Acorde("Rem").transponer(.segundaMenor).cifrado, "Mi♭m")
    }
}

final class TipoDeAcordeTests: XCTestCase {
    func testCifradoGenerativo() {
        let casos: [(String, String)] = [
            ("", ""), ("M", ""), ("m", "m"), ("min", "m"), ("dim", "°"), ("aug", "+"),
            ("5", "5"), ("sus", "sus4"), ("sus2", "sus2"),
            ("7", "7"), ("maj7", "maj7"), ("M7", "maj7"), ("Δ", "maj7"), ("7M", "maj7"),
            ("m7", "m7"), ("-7", "m7"), ("m7b5", "m7(♭5)"), ("ø", "m7(♭5)"),
            ("dim7", "°7"), ("°7", "°7"), ("mMaj7", "m(maj7)"), ("m(maj7)", "m(maj7)"),
            ("+7", "+7"), ("7#5", "+7"), ("7b5", "7(♭5)"), ("+maj7", "+maj7"),
            ("6", "6"), ("m6", "m6"), ("6/9", "6/9"), ("69", "6/9"), ("m6/9", "m6/9"),
            ("9", "9"), ("maj9", "maj9"), ("m9", "m9"), ("m(maj9)", "m(maj9)"),
            ("11", "11"), ("m11", "m11"), ("13", "13"), ("m13", "m13"), ("maj13", "maj13"),
            ("7sus4", "7sus4"), ("9sus4", "9sus4"), ("13sus4", "13sus4"),
            ("add9", "(add9)"), ("add2", "(add9)"), ("madd9", "m(add9)"), ("sus4add9", "sus4(add9)"),
            ("m(add♭13)", "m(add♭13)"),
            ("7(b9)", "7(♭9)"), ("7b9", "7(♭9)"), ("7-9", "7(♭9)"), ("7+9", "7(♯9)"),
            ("7b9#11", "7(♭9,♯11)"), ("7(♭9, ♯11)", "7(♭9,♯11)"), ("maj7#11", "maj7(♯11)"),
            ("13(b9)", "13(♭9)"), ("7alt", "7(♭9,♯9,♯11,♭13)"),
            ("7(omit5)", "7(omit5)"), ("7no3", "7(omit3)"), ("m(omit5)", "m(omit5)"),
        ]
        for (entrada, esperado) in casos {
            guard let tipo = TipoDeAcorde(texto: entrada) else {
                XCTFail("No se pudo leer «\(entrada)»")
                continue
            }
            XCTAssertEqual(tipo.cifrado, esperado, "«\(entrada)»")
            // Lo que se genera se vuelve a leer igual.
            XCTAssertEqual(TipoDeAcorde(texto: tipo.cifrado), tipo, "ida y vuelta de «\(entrada)»")
        }
    }

    func testCifradosNoValidos() {
        for texto in ["xyz", "7(b3)", "dimø", "7 9", "add", "omit"] {
            XCTAssertNil(TipoDeAcorde(texto: texto), texto)
        }
    }

    func testIdaYVueltaDeLosPredefinidos() {
        for tipo in TipoDeAcorde.todos {
            XCTAssertEqual(TipoDeAcorde(texto: tipo.cifrado), tipo, tipo.nombre)
        }
    }

    func testIgualdadPorContenido() {
        XCTAssertEqual(TipoDeAcorde("add2"), TipoDeAcorde("add9"))
        XCTAssertEqual(TipoDeAcorde(intervalos: [.unisono, .terceraMayor, .quintaJusta, .segundaMayor]),
                       .mayorNovenaAnadida)
        XCTAssertEqual(TipoDeAcorde("m7b5"), .semidisminuido)
        XCTAssertEqual(Set([TipoDeAcorde("Δ"), TipoDeAcorde("maj7"), TipoDeAcorde.mayorSeptimaMayor]).count, 1)
        XCTAssertNotEqual(TipoDeAcorde.mayorSexta, TipoDeAcorde.menorSeptima)
    }

    func testDisposicionYNombres() {
        XCTAssertEqual(TipoDeAcorde("9").intervalos,
                       [.unisono, .terceraMayor, .quintaJusta, .septimaMenor, .novenaMayor])
        XCTAssertEqual(TipoDeAcorde("7(b9,#11)").tensiones, [.novenaMenor, .undecimaAumentada])
        XCTAssertEqual(TipoDeAcorde("7(b9)").nombre, "séptima con novena menor")
        XCTAssertEqual(TipoDeAcorde("7(b9,#11)").nombre, "acorde 7(♭9,♯11)")
        XCTAssertEqual(TipoDeAcorde.dominanteSeptima.anadir(.novenaMayor), .dominanteNovena)
        XCTAssertEqual(TipoDeAcorde.dominanteNovena.quitar(.quintaJusta)?.cifrado, "9(omit5)")
    }

    func testConstantesDeTipoDeAcorde() {
        let cifrados: [(TipoDeAcorde, String)] = [
            (.dominanteSeptima, "7"), (.mayorSeptimaMayor, "maj7"), (.menorSeptima, "m7"),
            (.menorSeptimaMayor, "m(maj7)"), (.sus4Septima, "7sus4"), (.mayorSexta, "6"), (.menorSexta, "m6"),
            (.mayorSextaNovena, "6/9"), (.dominanteNovena, "9"), (.mayorSeptimaMayorNovena, "maj9"),
            (.menorSeptimaNovena, "m9"), (.mayorNovenaAnadida, "(add9)"), (.dominanteUndecima, "11"),
            (.menorSeptimaUndecima, "m11"), (.dominanteDecimotercera, "13"),
        ]
        for (tipo, cifrado) in cifrados {
            XCTAssertEqual(tipo, TipoDeAcorde(texto: cifrado), cifrado)
            XCTAssertTrue(TipoDeAcorde.todos.contains(tipo), cifrado)
        }
        XCTAssertEqual(TipoDeAcorde.todos.count, Set(TipoDeAcorde.todos).count)
    }
}

final class EstructuraTests: XCTestCase {
    func testEstructuraDeTipo() {
        let e = TipoDeAcorde("13(b9)").estructura
        XCTAssertEqual(e.tercera, .terceraMayor)
        XCTAssertEqual(e.quintasDelAcorde, [.quintaJusta])
        XCTAssertEqual(e.septima, .septimaMenor)
        XCTAssertEqual(e.tensiones, [.novenaMenor, .decimoterceraMayor])
        XCTAssertEqual(e.calidadDeTriada, .mayor)
        XCTAssertNil(e.suspension)
        XCTAssertNil(e.sexta)
        XCTAssertEqual(e.papel(de: .novenaMenor), .tension(9))
        XCTAssertEqual(e.papel(de: .segundaMenor), .tension(9))
        XCTAssertNil(e.papel(de: .cuartaJusta))
    }

    func testCalidadesDeTriada() {
        let casos: [(TipoDeAcorde, CalidadDeTriada)] = [
            ("", .mayor), ("m7", .menor), ("°7", .disminuida), ("m7b5", .disminuida),
            ("+maj7", .aumentada), ("7sus4", .suspendida), ("sus2", .suspendida),
            ("5", .potencia), ("7(omit3)", .sinTercera), ("7(b5)", .mayor),
        ]
        for (tipo, calidad) in casos {
            XCTAssertEqual(tipo.estructura.calidadDeTriada, calidad, tipo.cifrado)
        }
        XCTAssertTrue(TipoDeAcorde("7(omit3)").estructura.omiteTercera)
        XCTAssertTrue(TipoDeAcorde("7(omit5)").estructura.omiteQuinta)
        XCTAssertEqual(TipoDeAcorde("7sus4").estructura.suspension, .cuartaJusta)
        XCTAssertEqual(TipoDeAcorde("m6").estructura.sexta, .sextaMayor)
        XCTAssertEqual(TipoDeAcorde("°7").estructura.septima, .septimaDisminuida)
        XCTAssertEqual(TipoDeAcorde(pasosDeQuinta: [0, 4, 1, -6])!.estructura.quintasDelAcorde, [.quintaDisminuida, .quintaJusta])
    }

    func testComponentesDeAcorde() {
        let acorde: Acorde = "Sol7(b9)"
        XCTAssertEqual(acorde.componentes.map(\.papel), [.fundamental, .tercera, .quinta, .septima, .tension(9)])
        XCTAssertEqual(acorde.componentes.map(\.nota.nombre), ["Sol", "Si", "Re", "Fa", "La♭"])
        XCTAssertEqual(acorde.tercera, .si)
        XCTAssertEqual(acorde.quinta, .re)
        XCTAssertEqual(acorde.septima, .fa)
        XCTAssertEqual(acorde.tensiones, ["Lab"])
        XCTAssertEqual(acorde.papel(de: "Lab"), .tension(9))
        XCTAssertEqual(acorde.papel(de: .re), .quinta)
        XCTAssertNil(acorde.papel(de: .do))
        XCTAssertEqual(acorde.notas(conPapel: .septima), [.fa])
        XCTAssertEqual(PapelEnAcorde.tension(11).nombre, "undécima")
        XCTAssertEqual(PapelEnAcorde.tension(13).nombre, "decimotercera")

        let alterado = Acorde(.do, TipoDeAcorde(pasosDeQuinta: [0, 4, 1, -6])!)
        XCTAssertEqual(alterado.quinta, .sol)
        XCTAssertNil(Acorde("Do5").tercera)
    }
}

final class EstilosTests: XCTestCase {
    func testEstilosPredefinidos() {
        let dominante: Acorde = "Sib7(b9)/Re"
        XCTAssertEqual(dominante.cifrado, "Si♭7(♭9)/Re")
        XCTAssertEqual(dominante.cifrado(estilo: .ascii), "Sib7(b9)/Re")
        XCTAssertEqual(dominante.cifrado(estilo: .ingles), "Bb7(b9)/D")

        XCTAssertEqual(Acorde("Dom7b5").cifrado(estilo: .jazz), "Cø7")
        XCTAssertEqual(Acorde("Dom9b5").cifrado(estilo: .jazz), "Cø9")
        XCTAssertEqual(Acorde("Domaj7").cifrado(estilo: .jazz), "CΔ7")
        XCTAssertEqual(Acorde("Dom(maj7)").cifrado(estilo: .jazz), "Cm(Δ7)")
        XCTAssertEqual(Acorde("Rem7").cifrado(estilo: .palabras), "Remin7")
        XCTAssertEqual(Acorde("Si°").cifrado(estilo: .palabras), "Sidim")
        XCTAssertEqual(Acorde("Fa+").cifrado(estilo: .palabras), "Faaug")
        XCTAssertEqual(Acorde("Do#m(add9)").cifrado(estilo: .ascii), "Do#m(add9)")
    }

    func testLaFundamentalFNoSeConfundeConFa() {
        let estilo = EstiloDeCifrado(notacion: .ingles, aumentado: .aug)
        let acorde = Acorde(.fa, .aumentado)
        XCTAssertEqual(acorde.cifrado(estilo: estilo), "Faug")
        XCTAssertEqual(Acorde("Faug"), acorde)
        XCTAssertEqual(Acorde("Faaug"), acorde)
    }

    func testAdicionesEntreParentesis() {
        XCTAssertEqual(TipoDeAcorde.mayorNovenaAnadida.cifrado, "(add9)")
        XCTAssertEqual(Acorde("Do(add9)").cifrado, "Do(add9)")
        XCTAssertEqual(Acorde("Doadd9").cifrado, "Do(add9)")
        XCTAssertEqual(TipoDeAcorde(pasosDeQuinta: [0, -3, 1, -4])!.cifrado, "m(add♭13)")
    }

    func testCifradoDelTipoDeAcorde() {
        XCTAssertEqual(TipoDeAcorde.semidisminuido.cifrado, "m7(♭5)")
        XCTAssertEqual(TipoDeAcorde.semidisminuido.cifrado(estilo: .jazz), "ø7")
        XCTAssertEqual(TipoDeAcorde("7(b9,#11)").cifrado(en: .ingles), "7(b9,#11)")
        XCTAssertEqual(Acorde("Sib7(b9)/Re").cifrado(en: .ingles), "Bb7(b9)/D")
    }
}

final class IdentificacionPorAlturaTests: XCTestCase {
    private func primero(_ midi: [Int], tonalidad: Tonalidad? = nil) -> String? {
        Acorde.identificar(midi: midi, tonalidad: tonalidad).first?.cifrado
    }

    func testOrtografiaSegunElAcorde() {
        XCTAssertEqual(primero([60, 64, 67]), "Do")
        XCTAssertEqual(primero([60, 64, 68]), "Do+")
        XCTAssertEqual(primero([60, 63, 66, 69]), "Do°7")
        XCTAssertEqual(primero([61, 65, 68]), "Re♭")
        XCTAssertEqual(primero([66, 70, 73]), "Fa♯")
        XCTAssertEqual(primero([64, 68, 71]), "Mi")
        XCTAssertEqual(primero([59, 62, 65, 69]), "Sim7(♭5)")
        XCTAssertEqual(primero([55, 59, 62, 65, 68]), "Sol7(♭9)")
        XCTAssertEqual(primero([58, 62, 65, 68, 72]), "Si♭9")
        XCTAssertEqual(primero([60, 64, 70, 73]), "Do7(♭9)")
        XCTAssertEqual(primero([60, 65, 67]), "Dosus4")
        XCTAssertEqual(primero([60, 67]), "Do5")
    }

    func testBajoInversionesYDuplicados() {
        XCTAssertEqual(primero([64, 67, 72]), "Do/Mi")
        XCTAssertEqual(primero([48, 60, 64, 67, 72, 76]), "Do")
        XCTAssertEqual(primero([57, 60, 64, 67]), "Lam7")
        let conBajoAjeno = Acorde.identificar(midi: [62, 72, 76, 79]).map(\.cifrado)
        XCTAssertEqual(conBajoAjeno.first, "Re9sus4")
        XCTAssertTrue(conBajoAjeno.contains("Do/Re"))

        let sinQuinta = Acorde.candidatos(midi: [60, 64, 70]).first
        XCTAssertEqual(sinQuinta?.valor.cifrado, "Do7")
        XCTAssertEqual(sinQuinta?.omitidas, [.sol])

        XCTAssertEqual(Acorde.identificar(clasesDeAltura: [4, 7, 0]).first?.cifrado, "Do/Mi")
        XCTAssertTrue(Acorde.identificar(midi: [60, 61]).isEmpty)
        XCTAssertTrue(Acorde.identificar(midi: [60]).isEmpty)
    }

    func testTonalidad() {
        XCTAssertEqual(primero([66, 70, 73], tonalidad: Tonalidad("Solb mayor")), "Sol♭")
        XCTAssertEqual(primero([66, 70, 73], tonalidad: Tonalidad("Si mayor")), "Fa♯")
        XCTAssertEqual(primero([60, 64, 68], tonalidad: Tonalidad("La menor")), "Do+")
        XCTAssertEqual(primero([61, 65, 68], tonalidad: Tonalidad("Fa# menor")), "Do♯")
    }

    func testOrtografiarMidi() {
        let acorde = Acorde.identificar(midi: [60, 64, 68]).first!
        XCTAssertEqual(acorde.ortografiar(midi: [60, 64, 68]).map(\.description), ["Do4", "Mi4", "Sol♯4"])
        XCTAssertEqual(Acorde("Do°7").ortografiar(midi: [57, 60, 63, 66]).map(\.description),
                       ["Si♭♭3", "Do4", "Mi♭4", "Sol♭4"])
        XCTAssertEqual(Acorde("Do").ortografiar(midi: [61]).map(\.description), ["Do♯4"])
        XCTAssertEqual(Altura(Nota("Sol#"), midi: 68)?.description, "Sol♯4")
        XCTAssertNil(Altura(.la, midi: 68))
    }

    /// Lo que dice la versión con nombres no cambia al quitar la ortografía, cuando la
    /// ortografía de partida es la habitual.
    func testCoincideConLaIdentificacionPorNombres() {
        let ejemplos: [[Nota]] = [["Do", "Mi", "Sol"], ["Sol", "Si", "Re", "Fa"], ["La", "Do", "Mi", "Sol"],
                                         ["Do", "Mib", "Solb", "Sibb"], ["Re", "Fa", "La", "Do"]]
        for nombres in ejemplos {
            let alturas = nombres.map(\.claseDeAltura)
            XCTAssertEqual(Acorde.identificar(clasesDeAltura: alturas).first, Acorde.identificar(nombres).first,
                           nombres.map(\.nombre).joined(separator: " "))
        }
    }
}
