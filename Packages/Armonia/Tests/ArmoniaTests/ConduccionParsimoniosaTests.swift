import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class ConduccionParsimoniosaTests: XCTestCase {
    private func vecinos(_ cifrado: String, voces: Int = 1) -> [String] {
        Acorde(texto: cifrado)!.vecinosParsimoniosos(voces: voces).map(\.description)
    }

    func testVecinosDeSeptimas() {
        XCTAssertEqual(vecinos("Sol7"), ["Sol♯°7 (Sol→Sol♯)", "Solm7 (Si→Si♭)", "Mim7 (Fa→Mi)"])
        XCTAssertEqual(vecinos("Rem7"), ["Fa7 (Re→Mi♭)", "Re7 (Fa→Fa♯)", "Rem7(♭5) (La→La♭)", "Sim7(♭5) (Do→Si)"])
        XCTAssertEqual(vecinos("Sim7b5"), ["Rem7 (Si→Do)", "Sim7 (Fa→Fa♯)", "Si°7 (La→La♭)"])
        // La ortografía: Re♭7 pasa a Re♭m7, no a Do♯m7; Si°7, a Mi7 y no a Fa♭7.
        XCTAssertEqual(vecinos("Reb7"), ["Re°7 (Re♭→Re)", "Re♭m7 (Fa→Fa♭)", "Si♭m7 (Do♭→Si♭)"])
        XCTAssertTrue(vecinos("Sio7").contains("Mi7 (Fa→Mi)"))
        // Las «Power Towers»: cada séptima de dominante tiene 3 vecinos; la menor, 4; la
        // semidisminuida, 3; la disminuida, 8 (cuatro de dominante y cuatro semidisminuidas).
        var cuentas: [TipoDeAcorde: Set<Int>] = [:]
        for n in -7...7 {
            for tipo in TipoDeAcorde.familiaDeSeptimas {
                let pasos = Acorde(Nota(pasosDeQuinta: n), tipo).vecinosParsimoniosos()
                cuentas[tipo, default: []].insert(pasos.count)
                for paso in pasos {
                    XCTAssertEqual(paso.movimientos.count, 1)
                    XCTAssertEqual(abs(paso.movimientos[0].semitonos), 1)
                    XCTAssertTrue(TipoDeAcorde.familiaDeSeptimas.contains(paso.acorde.tipo))
                    // Las notas que no se mueven siguen sonando.
                    let quedan = Set(Acorde(Nota(pasosDeQuinta: n), tipo).notas.map(\.claseDeAltura))
                        .subtracting([paso.movimientos[0].desde.claseDeAltura])
                    XCTAssertTrue(quedan.isSubset(of: paso.acorde.notas.map(\.claseDeAltura)))
                }
            }
        }
        XCTAssertEqual(cuentas[.dominanteSeptima], [3])
        XCTAssertEqual(cuentas[.menorSeptima], [4])
        XCTAssertEqual(cuentas[.semidisminuido], [3])
        XCTAssertEqual(cuentas[.disminuidoSeptima], [8])
        XCTAssertTrue(Acorde("Do6").vecinosParsimoniosos().isEmpty)
        XCTAssertTrue(Acorde("Sol7").vecinosParsimoniosos(voces: 3).isEmpty)
    }

    func testSeptimasConMaj7() {
        // Un maj7 va por la familia ampliada; las demás séptimas, por las «Power Towers».
        XCTAssertEqual(vecinos("Domaj7"), ["Do♯m7(♭5) (Do→Do♯)", "Do7 (Si→Si♭)"])
        XCTAssertEqual(vecinos("Sol7").count, 3)
        let ampliada = Acorde("Sol7").vecinosParsimoniosos(tipos: TipoDeAcorde.familiaDeSeptimasAmpliada)
        XCTAssertTrue(ampliada.map(\.description).contains("Solmaj7 (Fa→Fa♯)"))
        var cuentas: [TipoDeAcorde: Set<Int>] = [:]
        for n in -7...7 {
            for tipo in TipoDeAcorde.familiaDeSeptimasAmpliada {
                let pasos = Acorde(Nota(pasosDeQuinta: n), tipo).vecinosParsimoniosos(tipos: TipoDeAcorde.familiaDeSeptimasAmpliada)
                cuentas[tipo, default: []].insert(pasos.count)
            }
        }
        XCTAssertEqual(cuentas[.dominanteSeptima], [4])
        XCTAssertEqual(cuentas[.menorSeptima], [4])
        XCTAssertEqual(cuentas[.semidisminuido], [4])
        XCTAssertEqual(cuentas[.disminuidoSeptima], [8])
        XCTAssertEqual(cuentas[.mayorSeptimaMayor], [2])
        // El camino entre una séptima y un maj7 elige la familia que tiene a los dos.
        XCTAssertEqual(Tonnetz.caminoParsimonioso(desde: "Do7", hasta: "Domaj7")?.map(\.description), ["Domaj7 (Si♭→Si)"])
        XCTAssertEqual(Tonnetz.caminoParsimonioso(desde: "Domaj7", hasta: "Sol7")?.map(\.description),
                       ["Do♯m7(♭5) (Do→Do♯)", "Mim7 (Do♯→Re)", "Sol7 (Mi→Fa)"])
    }

    func testDosVoces() {
        // P₂,₀: Sol7 llega a Re♭7, a un tritono, moviendo dos voces (la sustitución tritonal).
        let pasos = Acorde("Sol7").vecinosParsimoniosos(voces: 2)
        XCTAssertTrue(pasos.contains { $0.acorde == Acorde("Reb7") })
        XCTAssertTrue(pasos.allSatisfy { $0.movimientos.count == 2 && $0.movimientos.allSatisfy { abs($0.semitonos) == 1 } })
        // Childs: entre séptimas de dominante y semidisminuidas.
        let childs = Acorde("Sol7").vecinosParsimoniosos(voces: 2, tipos: [.dominanteSeptima, .semidisminuido])
        XCTAssertEqual(Set(childs.map(\.acorde.tipo)), [.dominanteSeptima, .semidisminuido])
    }

    func testTriadas() {
        // El «Cube Dance»: cada tríada mayor o menor, 3 vecinos; la aumentada, 6.
        XCTAssertEqual(vecinos("Do"), ["Mim (Do→Si)", "Dom (Mi→Mi♭)", "Do+ (Sol→Sol♯)"])
        XCTAssertEqual(vecinos("Doaug"), ["Mi (Do→Si)", "Do♯m (Do→Do♯)", "La♭ (Mi→Mi♭)", "Fam (Mi→Fa)", "Do (Sol♯→Sol)", "Lam (Sol♯→La)"])
        // P y L son movimientos de una voz; R no (la quinta sube un tono).
        let do_ = Acorde("Do").vecinosParsimoniosos().map(\.acorde)
        XCTAssertTrue(do_.contains(Acorde("Do").transformar(.p)!))
        XCTAssertTrue(do_.contains(Acorde("Do").transformar(.l)!))
        XCTAssertFalse(do_.contains(Acorde("Do").transformar(.r)!))
    }

    func testCamino() throws {
        let camino = try XCTUnwrap(Tonnetz.caminoParsimonioso(desde: "Sol7", hasta: "Rem7"))
        XCTAssertEqual(camino.map(\.acorde.cifrado), ["Sol♯°7", "Sim7(♭5)", "Rem7"])
        XCTAssertEqual(Tonnetz.caminoParsimonioso(desde: "Sol7", hasta: "Reb7", voces: 2)?.map(\.acorde), [Acorde("Reb7")])
        XCTAssertEqual(Tonnetz.caminoParsimonioso(desde: "Sol7", hasta: "Sol7"), [])
        // Sin ortografía en la meta, y el último paso con la del destino.
        XCTAssertEqual(Tonnetz.caminoParsimonioso(desde: "Do", hasta: "Mibm")?.last?.acorde, Acorde("Mibm"))
        XCTAssertEqual(Tonnetz.caminoParsimonioso(desde: "Do", hasta: "Mibm")?.count, 4)
        XCTAssertNil(Tonnetz.caminoParsimonioso(desde: "Do", hasta: "Sol7"))
        XCTAssertNil(Tonnetz.caminoParsimonioso(desde: "Do6", hasta: "Sol7"))
        // Las «Power Towers» están conectadas: de Do7 se llega a las 12 × 3 + 3 séptimas.
        for n in -5...6 {
            for tipo in TipoDeAcorde.familiaDeSeptimas {
                let destino = Acorde(Nota(pasosDeQuinta: n), tipo)
                let camino = try XCTUnwrap(Tonnetz.caminoParsimonioso(desde: "Do7", hasta: destino), destino.cifrado)
                XCTAssertEqual(Set(camino.last?.acorde.notas.map(\.claseDeAltura) ?? Acorde("Do7").notas.map(\.claseDeAltura)),
                               Set(destino.notas.map(\.claseDeAltura)))
                XCTAssertLessThanOrEqual(camino.count, 6)
            }
        }
    }

    func testConduccionMinima() {
        let resolucion = Acorde("Sol7").conduccionMinima(hasta: "Do")
        XCTAssertEqual(resolucion.total, 4)
        XCTAssertEqual("\(resolucion)", "Sol→Sol, Si→Do (+1), Re→Do (−2), Fa→Mi (−1): 4 semitonos")
        XCTAssertEqual(resolucion.vocesQueSeMueven.count, 3)
        XCTAssertEqual(Acorde("Rem7").conduccionMinima(hasta: "Sol7").total, 3)
        XCTAssertEqual(Acorde("Do").conduccionMinima(hasta: "Lam").total, 2)       // R: Sol→La
        XCTAssertEqual(Acorde("Do").conduccionMinima(hasta: "Do").total, 0)
        XCTAssertEqual(Acorde("Do").conduccionMinima(hasta: "Sol7").movimientos.count, 4)
        XCTAssertEqual(Acorde("Do").conduccionMinima(hasta: "Fa#").total, 6)
        XCTAssertEqual(Acorde("Sol7").conduccionMinima(hasta: "Do").texto(.ingles), "G→G, B→C (+1), D→C (−2), F→E (−1): 4 semitones")
        // Simétrica en el total.
        for (a, b) in [("Sol7", "Do"), ("Rem7", "Solmaj7"), ("Do", "Fa#m"), ("Sio7", "Do")] {
            XCTAssertEqual(Acorde(texto: a)!.conduccionMinima(hasta: Acorde(texto: b)!).total,
                           Acorde(texto: b)!.conduccionMinima(hasta: Acorde(texto: a)!).total, "\(a) \(b)")
        }
        XCTAssertEqual(MovimientoDeVoz(desde: .do, hasta: Nota(.fa, .sostenido)).semitonos, 6)
        XCTAssertEqual(MovimientoDeVoz(desde: .do, hasta: .si).semitonos, -1)
    }
}
