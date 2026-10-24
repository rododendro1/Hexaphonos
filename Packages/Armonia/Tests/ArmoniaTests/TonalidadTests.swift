import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class TonalidadTests: XCTestCase {
    private func escrito(_ escala: Escala, _ midi: [Int]) -> [String] {
        escala.ortografiar(midi: midi).map(\.nota.nombre)
    }

    func testOrtografiaCromaticaSegunLaDireccion() {
        let doMayor = Escala(.do)
        XCTAssertEqual(escrito(doMayor, [60, 61, 62]), ["Do", "Do♯", "Re"])
        XCTAssertEqual(escrito(doMayor, [62, 61, 60]), ["Re", "Re♭", "Do"])
        XCTAssertEqual(escrito(doMayor, [67, 68, 69]), ["Sol", "Sol♯", "La"])
        XCTAssertEqual(escrito(doMayor, [69, 68, 67]), ["La", "La♭", "Sol"])
        XCTAssertEqual(escrito(doMayor, [69, 70, 71]), ["La", "La♯", "Si"])
        XCTAssertEqual(escrito(doMayor, [71, 70, 69]), ["Si", "Si♭", "La"])
        XCTAssertEqual(escrito(doMayor, [60, 61, 61, 62]), ["Do", "Do♯", "Do♯", "Re"])
    }

    func testOrtografiaSinContexto() {
        let doMayor = Escala(.do)
        // Cada nota por separado (sin nota siguiente que indique dirección).
        XCTAssertEqual([61, 63, 66, 68, 70].map { escrito(doMayor, [$0])[0] }, ["Do♯", "Mi♭", "Fa♯", "La♭", "Si♭"])
        // En una línea ascendente suben con sostenido (la última, sin siguiente, vuelve a Si♭).
        XCTAssertEqual(escrito(doMayor, [61, 63, 66, 68, 70]), ["Do♯", "Re♯", "Fa♯", "Sol♯", "Si♭"])
        XCTAssertEqual(escrito(Escala(.fa), [70]), ["Si♭"])
        XCTAssertEqual(escrito(Escala(.la, .menorNatural), [68]), ["Sol♯"])
        XCTAssertEqual(escrito(Escala(.la, .menorArmonica), [68]), ["Sol♯"])
        XCTAssertEqual(escrito(Escala("Fa# mayor"), [65, 60]), ["Mi♯", "Si♯"])
        XCTAssertEqual(Altura(midi: 70, escala: Escala(.fa)).description, "Si♭4")
        XCTAssertEqual(Escala(.do).ortografiar(midi: [60, 61, 62]).map(\.midi), [60, 61, 62])
    }

    func testDeteccionDeTonalidad() {
        let doMayor = Tonalidad.candidatos(midi: [60, 62, 64, 65, 67, 69, 71, 72])
        XCTAssertEqual(doMayor.count, 24)
        XCTAssertEqual(doMayor.first?.valor, Tonalidad(.do))
        XCTAssertEqual(doMayor.map(\.correlacion), doMayor.map(\.correlacion).sorted(by: >))

        let laMenor = Tonalidad.candidatos(midi: [69, 71, 72, 74, 76, 77, 80, 81, 69, 76, 69])
        XCTAssertEqual(laMenor.first?.valor, Tonalidad(.la, .menor))

        XCTAssertEqual(Tonalidad.candidatos(midi: [61, 63, 65, 66, 68, 70, 72, 73]).first?.valor.nombre,
                       "Re♭ mayor")
        XCTAssertEqual(Tonalidad.candidatos(midi: [66, 68, 70, 71, 73, 75, 77, 78]).first?.valor.nombre,
                       "Fa♯ mayor")
        let solBemol: [Nota] = ["Solb", "Lab", "Sib", "Dob", "Reb", "Mib", "Fa"]
        XCTAssertEqual(Tonalidad.candidatos(notas: solBemol).first?.valor.nombre, "Sol♭ mayor")

        let ponderada = Tonalidad.candidatos(midi: [60, 64, 67, 72, 67, 64, 60],
                                                duraciones: [2, 1, 1, 2, 1, 1, 2])
        XCTAssertEqual(ponderada.first?.valor, Tonalidad(.do))
        XCTAssertTrue(Tonalidad.candidatos(midi: []).isEmpty)
    }
}

final class TonalidadTipoTests: XCTestCase {
    let laMenor: Tonalidad = "La menor"

    func testEscalasYArmadura() {
        XCTAssertEqual(laMenor.escala, Escala(.la, .menorNatural))
        XCTAssertEqual(laMenor.escalaDeReferencia, Escala(.la, .menorArmonica))
        XCTAssertEqual(laMenor.notasPropias.map(\.nombre), ["La", "Si", "Do", "Re", "Mi", "Fa", "Sol", "Fa♯", "Sol♯"])
        XCTAssertEqual(laMenor.armadura, 0)
        XCTAssertEqual(Tonalidad("Mib mayor").armadura, -3)
        XCTAssertEqual(Tonalidad("Mib mayor").notasDeLaArmadura, ["Sib", "Mib", "Lab"])
        XCTAssertEqual(Tonalidad(armadura: 3), Tonalidad(.la))
        XCTAssertEqual(Tonalidad(armadura: -2, modo: .menor), Tonalidad(.sol, .menor))
        XCTAssertEqual(Tonalidad.circuloDeQuintas().count, 15)
        XCTAssertEqual(Tonalidad.circuloDeQuintas(.menor)[7], laMenor)
    }

    func testRelaciones() {
        XCTAssertEqual(laMenor.relativa, Tonalidad(.do))
        XCTAssertEqual(laMenor.homonima, Tonalidad(.la))
        XCTAssertEqual(Tonalidad(.do).distancia(hasta: Tonalidad(.mi)), 4)
        XCTAssertEqual(Tonalidad("Do# mayor").enarmonicaMasSimple, Tonalidad("Reb mayor"))
        XCTAssertEqual(Set(laMenor.vecinas),
                       [Tonalidad(.do), Tonalidad(.mi, .menor), Tonalidad(.sol), Tonalidad(.re, .menor), Tonalidad(.fa)])
    }

    func testFuncionesYArmonia() {
        XCTAssertEqual(laMenor.nombreDeGrado(7), .sensible)
        XCTAssertEqual(laMenor.nombreDeGrado(de: .sol), .subtonica)
        XCTAssertEqual(laMenor.nombreDeGrado(de: "Sol#"), .sensible)
        XCTAssertEqual(laMenor.nombreDeGrado(de: "Fa#"), .superdominante)
        XCTAssertNil(laMenor.nombreDeGrado(de: "Sib"))
        XCTAssertEqual(Tonalidad(.do).nombreDeGrado(de: .si), .sensible)

        XCTAssertEqual(laMenor.armonizar().map(\.cifrado), ["Lam", "Si°", "Do", "Rem", "Mi", "Fa", "Sol♯°"])
        XCTAssertEqual(laMenor.armonizar(cuatriadas: true).map(\.cifrado),
                       ["Lam7", "Sim7(♭5)", "Domaj7", "Rem7", "Mi7", "Famaj7", "Sol♯°7"])
        XCTAssertEqual(laMenor.cifradosRomanos(), ["i", "ii°", "III", "iv", "V", "VI", "vii°"])
        XCTAssertEqual(laMenor.cifradosRomanos(cuatriadas: true),
                       ["i7", "iiø7", "IIImaj7", "iv7", "V7", "VImaj7", "vii°7"])
        XCTAssertEqual(Tonalidad(.do).cifradosRomanos(), ["I", "ii", "iii", "IV", "V", "vi", "vii°"])
    }

    func testOrtografiaEIdentificacion() {
        XCTAssertEqual(laMenor.ortografiar(midi: [69, 68, 69]).map(\.description), ["La4", "Sol♯4", "La4"])
        XCTAssertEqual(laMenor.ortografiar(midi: [76, 77, 78, 80, 81]).map(\.description),
                       ["Mi5", "Fa5", "Fa♯5", "Sol♯5", "La5"])
        XCTAssertEqual(Altura(midi: 68, tonalidad: laMenor).description, "Sol♯4")
        XCTAssertEqual(Acorde.identificar(midi: [60, 64, 68], tonalidad: laMenor).first?.cifrado, "Do+")
        XCTAssertEqual(Acorde.identificar(midi: [66, 70, 73], escala: Escala("Solb mayor")).first?.cifrado, "Sol♭")
        XCTAssertEqual(Tonalidad.candidatos(midi: [69, 71, 72, 74, 76, 77, 80, 81]).first?.valor, laMenor)
    }

    func testTextoYProtocolos() throws {
        XCTAssertEqual(Tonalidad("A minor"), laMenor)
        XCTAssertEqual(Tonalidad("La menor armónica"), laMenor)
        XCTAssertEqual(laMenor.nombre, "La menor")
        XCTAssertEqual(laMenor.nombre(en: .ingles), "A minor")
        XCTAssertEqual(Tonalidad(Escala(.la, .menorMelodica)), laMenor)
        XCTAssertNil(Tonalidad(Escala(.re, .dorico)))
        XCTAssertThrowsError(try Tonalidad(leyendo: "Re dórico")) { error in
            XCTAssertEqual((error as? ErrorDeLectura)?.motivo, .modoNoReconocido("dórico"))
        }
        for tonalidad in Tonalidad.circuloDeQuintas() + Tonalidad.circuloDeQuintas(.menor) {
            for notacion in Notacion.allCases {
                XCTAssertEqual(Tonalidad(texto: tonalidad.texto(en: notacion)), tonalidad, tonalidad.texto(en: notacion))
            }
        }
        let datos = try JSONEncoder().encode([laMenor])
        XCTAssertEqual(String(decoding: datos, as: UTF8.self), "[\"La menor\"]")
        XCTAssertEqual(try JSONDecoder().decode([Tonalidad].self, from: datos), [laMenor])

        XCTAssertEqual(Tonalidad(.do) + .quintaJusta, Tonalidad(.sol))
        XCTAssertEqual(laMenor.numeroDeForte, "7-35")
        XCTAssertEqual(InstrumentoDePartitura.trompaEnFa.escritura(de: Tonalidad("Sib mayor")), Tonalidad(.fa))
    }
}
