import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

// Lo que atraviesa todo el motor: literales, Codable, convenciones de nombres y nombres
// anteriores. Lo de cada área está en su archivo (FundamentosTests, AcordesTests…).

final class ComodidadesTests: XCTestCase {
    func testLiterales() {
        let nota: Nota = "Fa#"
        let alta: Altura = "Sib3"
        let intervalo: Intervalo = "3M"
        let acorde: Acorde = "Sol7/Si"
        let tipo: TipoDeAcorde = "m7(b5)"
        let escala: Escala = "Re dórico"
        XCTAssertEqual(nota, Nota(.fa, 1))
        XCTAssertEqual(alta.midi, 58)
        XCTAssertEqual(intervalo, .terceraMayor)
        XCTAssertEqual(acorde.bajo, .si)
        XCTAssertEqual(tipo, .semidisminuido)
        XCTAssertEqual(escala.tipo, .dorico)
        XCTAssertEqual(Nota.re + "3M", "Fa#")
        XCTAssertEqual(Acorde(.do, "7(b9)").cifrado, "Do7(♭9)")
    }

    func testCodable() throws {
        let codificador = JSONEncoder()
        let decodificador = JSONDecoder()

        let acordes: [Acorde] = ["Sol7(b9)/Si", "Fa#m7b5", "Do/Re", "Mib6/9"]
        let datosAcordes = try codificador.encode(acordes)
        XCTAssertEqual(try decodificador.decode([Acorde].self, from: datosAcordes), acordes)
        XCTAssertTrue(String(decoding: datosAcordes, as: UTF8.self).contains("Fa♯m7(♭5)"))

        let notas: [Altura] = ["Do4", "Fa#3", "Sibb-1"]
        XCTAssertEqual(try decodificador.decode([Altura].self, from: codificador.encode(notas)), notas)

        let intervalos: [Intervalo] = ["3M", "-5d", "9m", "4AA"]
        XCTAssertEqual(try decodificador.decode([Intervalo].self, from: codificador.encode(intervalos)), intervalos)

        let escalas = [Escala("Re dórico"), Escala(.do, TipoDeEscala.pentatonicaMayor.rotacion(2))]
        XCTAssertEqual(try decodificador.decode([Escala].self, from: codificador.encode(escalas)), escalas)

        XCTAssertThrowsError(try decodificador.decode([Acorde].self, from: Data("[\"Doxyz\"]".utf8)))
    }
}

final class TerminologiaTests: XCTestCase {
    func testConvencionVerbal() {
        // Operaciones: infinitivo.
        XCTAssertEqual(Acorde("Do7").invertir(1).cifrado, "Do7/Mi")
        XCTAssertEqual(Acorde("Do").cambiarBajo(.re).cifrado, "Do/Re")
        XCTAssertEqual(TipoDeAcorde.dominanteSeptima.anadir(.novenaMenor)?.cifrado, "7(♭9)")
        XCTAssertEqual(TipoDeAcorde.dominanteNovena.quitar(.quintaJusta)?.cifrado, "9(omit5)")
        XCTAssertEqual(TemperamentoRegular.igual.afinar(la4: 415).frecuencia(de: "La4"), 415, accuracy: 1e-9)
        XCTAssertEqual(ConjuntoDeClases([0, 4]).unir(con: [7]), [0, 4, 7])
        XCTAssertEqual(ConjuntoDeClases([0, 4, 7]).intersecar(con: [4, 5]), [4])
        // Valores derivados con nombre propio: sustantivo o adjetivo.
        XCTAssertEqual(Intervalo.terceraMayor.inversion, .sextaMenor)
        XCTAssertEqual(Nota("Dob").enarmonicaMasSimple, .si)
        XCTAssertEqual(Intervalo.novenaMayor.simple, .segundaMayor)
    }

    func testTerminosMusicales() {
        // «Menor es mejor» se llama coste.
        let costes = Acorde.candidatos([.mi, .sol, .do]).map(\.coste)
        XCTAssertEqual(costes, costes.sorted())
        XCTAssertEqual(Acorde.candidatos([.do, .mi, .sol]).first?.coste, 0)
        // Número de Forte, aunque el valor sea texto.
        XCTAssertEqual(Acorde("Do°7").numeroDeForte, "4-28")
        XCTAssertEqual(ConjuntoDeClases([0, 1, 4, 6]).numeroDeForte, "4-Z15")
        // Temperamentos iguales con cualquier número de divisiones; 12 es `.igual`.
        XCTAssertEqual(TemperamentoRegular.igual(divisiones: 12).quinta, TemperamentoRegular.igual.quinta, accuracy: 1e-9)
        XCTAssertEqual(TemperamentoRegular.igual(divisiones: 19, la4: 415).frecuencia(de: "La4"), 415, accuracy: 1e-9)
        // Posición cerrada.
        XCTAssertEqual(Acorde("Sol7/Si").posicionCerrada(octava: 3).map(\.description), ["Si3", "Re4", "Fa4", "Sol4"])
        // Escalas que contienen unas notas.
        XCTAssertTrue(Escala.identificar([.do, .mi, .sol, .si, "Fa#"]).contains(Escala(.sol)))
        // Lugar en el pentagrama.
        XCTAssertEqual(Clave.doEnTercera.posicion(de: "Do4").lugar, 4)
        XCTAssertEqual(PosicionEnPentagrama(lugar: 9).descripcion, "encima de la 5.ª línea")
    }

    func testCandidatoGenerico() {
        // Acordes y tonalidades comparten el mismo tipo de lectura, ordenada por coste.
        let acordes = Acorde.candidatos([.do, .mi, "Sib"])
        XCTAssertEqual(acordes.first?.valor, Acorde("Do7"))
        XCTAssertEqual(acordes.first?.coste, 1)
        XCTAssertEqual(acordes.first?.omitidas, [.sol])
        XCTAssertEqual(acordes.map(\.coste), acordes.map(\.coste).sorted())

        let tonalidades = Tonalidad.candidatos(midi: [60, 62, 64, 65, 67, 69, 71, 72])
        XCTAssertEqual(tonalidades.first?.valor, Tonalidad(.do))
        XCTAssertEqual(tonalidades.map(\.coste), tonalidades.map(\.coste).sorted())
        XCTAssertEqual(tonalidades.map(\.correlacion), tonalidades.map(\.correlacion).sorted(by: >))
        if let mejor = tonalidades.first {
            XCTAssertEqual(mejor.correlacion + mejor.coste, 1, accuracy: 1e-12)
        }
    }

    func testNombresDeTipos() {
        let tipo: TipoDeAcorde = "m7"
        let escala: TipoDeEscala = .dorico
        let nombre: Nota = "Fa#"
        let calidad: CalidadDeIntervalo = Intervalo.terceraMenor.calidad
        XCTAssertEqual(tipo.estructura.calidadDeTriada, .menor)
        XCTAssertEqual(tipo.estructura.componentes.map(\.papel).first, PapelEnAcorde.fundamental)
        XCTAssertEqual(escala.nombre, "dórico")
        XCTAssertEqual(nombre.nombre, "Fa♯")
        XCTAssertEqual(calidad, .menor)
        XCTAssertEqual(Acorde("Do7").cifrado(estilo: EstiloDeCifrado.ingles), "C7")
        // La rotación de una escala (sus modos) no se confunde con el modo de una tonalidad.
        XCTAssertEqual(Escala(.do).rotacion(2), Escala(.re, .dorico))
        XCTAssertEqual(TipoDeEscala.mayor.rotacion(6), .menorNatural)
        XCTAssertEqual(Tonalidad("La menor").modo, .menor)
        // Todos los tipos con nombre lo tienen también como texto.
        XCTAssertEqual(Altura("Fa#4").nombre, "Fa♯4")
    }
}
