import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria

final class ArmonizacionTests: XCTestCase {
    // MARK: Acordes para una nota

    func testAcordesParaUnaNota() {
        let doMayor = Tonalidad(.do)
        XCTAssertEqual(doMayor.acordes(para: .sol).prefix(3).map(\.valor), ["Sol", "Do", "Sol7"])
        XCTAssertEqual(doMayor.acordes(para: .do).first?.valor, "Do")
        // Ordenados por coste.
        let costes = doMayor.acordes(para: .re).map(\.coste)
        XCTAssertEqual(costes, costes.sorted())
        // Una nota cromática: la dominante secundaria que la tiene.
        XCTAssertTrue(doMayor.acordes(para: "Fa#").map(\.valor).contains("Re7"))
        // Ninguno de la tonalidad tiene La♭: los del modo homónimo (iv y ♭VI).
        XCTAssertEqual(doMayor.acordes(para: "Lab").prefix(2).map(\.valor), ["Fam", "Lab"])
        XCTAssertEqual(doMayor.acordes(para: "Do#").map(\.valor), ["La", "La7"])
    }

    // MARK: Armonizar

    private func cifrados(_ tonalidad: Tonalidad, _ melodia: String) -> [String] {
        let notas = melodia.split(separator: " ").map { Nota(texto: String($0))! }
        return tonalidad.armonizar(melodia: notas).first?.valor.cifrados ?? []
    }

    func testArmonizar() {
        XCTAssertEqual(cifrados(Tonalidad(.do), "Mi Re Do"), ["I", "V", "I"])
        XCTAssertEqual(cifrados(Tonalidad(.do), "Do Re Mi Fa Re Si Do"), ["I", "V", "I", "IV", "ii", "V", "I"])
        XCTAssertEqual(cifrados(Tonalidad(.la, .menor), "Do Si La Sol# La"), ["i", "V", "i", "V", "i"])
        XCTAssertEqual(cifrados(Tonalidad(.sol), "Si La Sol"), ["I", "V", "I"])
    }

    func testPropuestasOrdenadasYDistintas() {
        let propuestas = Tonalidad(.do).armonizar(melodia: ["Mi", "Re", "Do"], propuestas: 4)
        XCTAssertEqual(propuestas.count, 4)
        XCTAssertEqual(propuestas.map(\.coste), propuestas.map(\.coste).sorted())
        XCTAssertEqual(Set(propuestas.map(\.valor.acordes)).count, 4)
        XCTAssertEqual(propuestas[0].valor.description, "Do Sol Do (I–V–I)")
        XCTAssertEqual(propuestas[0].valor.texto(en: .ingles), "C G C (I–V–I)")
        XCTAssertEqual(propuestas[0].valor.melodia, ["Mi", "Re", "Do"])
    }

    func testTerminaEnCadencia() {
        // Termina en el I precedido de la dominante, o en la dominante si la nota no es del I.
        for melodia in ["Sol La Si Do", "Mi Fa Sol La Sol Fa Mi Re Do", "Do Mi Re Si Do"] {
            let analisis = Tonalidad(.do).armonizar(melodia: melodia.split(separator: " ").map { Nota(texto: String($0))! })[0].valor.analisis
            XCTAssertEqual(analisis.cadencias.last?.tipo, .autentica, melodia)
        }
        let semicadencia = cifrados(Tonalidad(.do), "Do Mi Fa Re")
        XCTAssertEqual(semicadencia.last, "V")
    }

    func testSecundariaVaASuDestino() {
        // Fa♯ pide Re (V/V), que tiene que ir a Sol.
        let propuesta = Tonalidad(.do).armonizar(melodia: ["Mi", "Fa#", "Sol", "Do"])[0].valor
        XCTAssertEqual(propuesta.cifrados.prefix(3), ["I", "V/V", "V"])
        for candidato in Tonalidad(.do).armonizar(melodia: ["Mi", "Fa#", "Sol", "Do"], propuestas: 10) {
            for (i, a) in candidato.valor.analisis.acordes.enumerated() {
                if case .dominanteSecundaria(let destino) = a.categoria {
                    XCTAssertEqual(candidato.valor.analisis.acordes[i + 1].grado, destino, "\(candidato.valor)")
                }
            }
        }
    }

    func testArmonizarVacio() {
        XCTAssertEqual(Tonalidad(.do).armonizar(melodia: []), [])
        XCTAssertEqual(Tonalidad(.do).armonizar(melodia: ["Do"], propuestas: 0), [])
        XCTAssertEqual(Tonalidad(.do).armonizar(melodia: ["Do"]).first?.valor.acordes, ["Do"])
    }

    // MARK: Realizar a cuatro voces

    private func comprobarRealizacion(_ texto: String, en tonalidad: Tonalidad? = nil,
                                      file: StaticString = #filePath, line: UInt = #line) {
        let acordes = texto.split(separator: " ").map { Acorde(texto: String($0))! }
        guard let coral = Coral.realizar(acordes, en: tonalidad) else {
            return XCTFail("«\(texto)» no se realiza", file: file, line: line)
        }
        XCTAssertEqual(coral.faltas, [], texto, file: file, line: line)
        XCTAssertEqual(coral.acordes.count, acordes.count, file: file, line: line)
        for (acorde, voces) in zip(acordes, coral.acordes) {
            let notas = voces.map(\.nota)
            XCTAssertEqual(notas[0], acorde.bajo, "bajo de \(acorde)", file: file, line: line)
            XCTAssertTrue(notas.allSatisfy { acorde.notas.contains($0) || $0 == acorde.bajo }, "\(acorde): \(voces)", file: file, line: line)
            for nota in acorde.notas where nota != acorde.quinta {
                XCTAssertTrue(notas.contains(nota), "falta \(nota) en \(acorde): \(voces)", file: file, line: line)
            }
            if let septima = acorde.septima {
                XCTAssertLessThanOrEqual(notas.filter { $0 == septima }.count, 1, "\(acorde): \(voces)", file: file, line: line)
            }
        }
    }

    func testRealizar() {
        comprobarRealizacion("Do Fa Sol7 Do")
        comprobarRealizacion("Do Lam Rem Sol7 Do")
        comprobarRealizacion("Do Fa/La Sol7/Si Do")
        comprobarRealizacion("Do Sol7/Fa Do/Mi Fa Sol Do")
        comprobarRealizacion("Do Re7 Sol Do Lam Fa Sol7 Do")
        comprobarRealizacion("Lam Rem/Fa Mi7 Lam")
        comprobarRealizacion("Lam Sol#°7 Lam Sim7(b5) Mi7 Lam")
        comprobarRealizacion("Do Fa Do/Sol Sol7 Do")
        comprobarRealizacion("Sol Do Re7 Sol Mim Do Re Sol")
    }

    func testRealizarConSoprano() throws {
        let soprano: [Altura] = ["Mi4", "Fa4", "Re4", "Do4"]
        let coral = try XCTUnwrap(Coral.realizar(["Do", "Fa", "Sol", "Do"], soprano: soprano))
        XCTAssertEqual(coral.voz(3), soprano)
        XCTAssertTrue(coral.esCorrecta)
        XCTAssertEqual(coral.voz(0).map(\.nota), ["Do", "Fa", "Sol", "Do"])
        // Do–Rem con el soprano Sol4–La4 obliga a quintas paralelas con el bajo: no hay realización.
        XCTAssertNil(Coral.realizar(["Do", "Rem"], soprano: ["Sol4", "La4"]))
    }

    func testLaSensibleSubeEnElSoprano() throws {
        let coral = try XCTUnwrap(Coral.realizar(["Do", "Sol", "Do"], soprano: ["Mi4", "Si4", "Do5"]))
        XCTAssertTrue(coral.esCorrecta)
        // Y no se duplica.
        for voces in coral.acordes {
            XCTAssertLessThanOrEqual(voces.filter { $0.nota == .si }.count, 1)
        }
    }

    func testRealizarImposible() {
        XCTAssertNil(Coral.realizar([]))
        // El soprano no tiene tantas notas, o una no es del acorde, o está fuera de tesitura.
        XCTAssertNil(Coral.realizar(["Do", "Sol"], soprano: ["Do5"]))
        XCTAssertNil(Coral.realizar(["Do", "Sol"], soprano: ["Do5", "Do5"]))
        XCTAssertNil(Coral.realizar(["Do", "Sol"], soprano: ["Do6", "Si5"]))
        // Más de cuatro notas obligatorias.
        XCTAssertNil(Coral.realizar(["Do7(9,13)"]))
    }

    func testDisposicionesSinFaltas() {
        let disposiciones = Coral.disposiciones(de: "Sol7", soprano: nil, sensible: .si)
        XCTAssertFalse(disposiciones.isEmpty)
        for d in disposiciones {
            XCTAssertTrue(Coral([d.alturas])!.esCorrecta)
            XCTAssertEqual(d.alturas[0].nota, .sol)
            XCTAssertLessThanOrEqual(d.alturas.filter { $0.nota == .si }.count, 1)
        }
    }

    // MARK: Armonizar a cuatro voces

    func testArmonizarACuatroVoces() throws {
        let melodia: [Altura] = ["Do5", "Si4", "La4", "Sol4", "Fa4", "Mi4", "Re4", "Do4"]
        let armonizada = try XCTUnwrap(Tonalidad(.do).armonizarACuatroVoces(melodia))
        XCTAssertEqual(armonizada.coral.voz(3), melodia)
        XCTAssertTrue(armonizada.coral.esCorrecta)
        XCTAssertEqual(armonizada.armonizacion.melodia, melodia.map(\.nota))
        XCTAssertEqual(armonizada.armonizacion.cifrados.last, "I")
        XCTAssertNil(Tonalidad(.do).armonizarACuatroVoces(["Do6", "Si5", "Do6"]))
    }

    func testArmonizarMelodiasAlAzar() {
        // Cualquier melodía de la escala en la tesitura del soprano y sin saltos aumentados ni de más
        // de una octava: si sale un coral, no tiene faltas y lleva la melodía arriba. Y casi siempre sale.
        var generador = GeneradorConSemilla(semilla: 8)
        let tonalidad = Tonalidad(.re)
        let alturas = (0..<8).map { Altura(tonalidad.escala.grado($0 + 1), octava: $0 >= 6 ? 5 : 4) }
        var probadas = 0, realizadas = 0
        while probadas < 20 {
            let melodia = (0..<Int.random(in: 3...7, using: &generador)).map { _ in alturas.randomElement(using: &generador)! }
            let saltos = zip(melodia, melodia.dropFirst()).map { $1 - $0 }
            func alterado(_ salto: Intervalo) -> Bool {
                switch salto.calidad {
                case .aumentada, .disminuida: return true
                default: return salto.semitonos > 12
                }
            }
            guard !saltos.contains(where: alterado) else { continue }
            probadas += 1
            guard let armonizada = tonalidad.armonizarACuatroVoces(melodia) else { continue }
            realizadas += 1
            XCTAssertEqual(armonizada.coral.voz(3), melodia)
            XCTAssertEqual(armonizada.coral.faltas, [], "\(melodia)")
        }
        XCTAssertGreaterThanOrEqual(realizadas, 18)
    }
}
