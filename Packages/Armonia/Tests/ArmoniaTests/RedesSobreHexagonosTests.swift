import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura
import Hexagonos

/// El Tonnetz, la tabla armónica y los teclados isomórficos sobre la rejilla de `Hexagonos`.
final class RedesSobreHexagonosTests: XCTestCase {
    private func punto(_ a: Int, _ b: Int) -> PuntoDeLaRed { PuntoDeLaRed(quintas: a, terceras: b) }
    private let region = FormasDeMapa.hexagono(radio: 5)

    // MARK: Tonnetz

    func testUnPuntoEsUnaCasilla() {
        XCTAssertEqual(punto(2, -1).coordenada, CoordenadaAxial(q: 2, r: -1))
        XCTAssertEqual(PuntoDeLaRed(CoordenadaAxial(q: 0, r: 1)).nota, Nota.mi)
        for casilla in region {
            XCTAssertEqual(PuntoDeLaRed(casilla).coordenada, casilla)
        }
    }

    func testLosVecinosDelTonnetzSonLosDeLaRejilla() {
        let p = punto(1, 2)
        XCTAssertEqual(Set(p.vecinos.map(\.coordenada)), Set(p.coordenada.vecinos))
    }

    func testLaDistanciaEsLaDeLaRejilla() {
        // La fórmula de antes, para comprobar que no cambia.
        func distanciaAnterior(_ p: PuntoDeLaRed, _ o: PuntoDeLaRed) -> Int {
            let x = o.quintas - p.quintas, y = o.terceras - p.terceras
            return (x >= 0) == (y >= 0) ? abs(x) + abs(y) : max(abs(x), abs(y))
        }
        let centro = punto(1, -2)
        for casilla in region {
            let p = PuntoDeLaRed(casilla)
            XCTAssertEqual(centro.distancia(hasta: p), distanciaAnterior(centro, p), "\(p)")
        }
    }

    func testElTrazadoDelTonnetzEsElDelDibujo() {
        for paso in [64.0, 88, 50] {
            let d = Tonnetz.trazado(paso: paso)
            for casilla in region {
                let p = PuntoDeLaRed(casilla)
                let centro = d.centro(de: p.coordenada)
                // Las fórmulas que usaba el dibujo: x = (a + b/2)·paso, y = −b·(√3/2)·paso.
                XCTAssertEqual(centro.x, (Double(p.quintas) + Double(p.terceras) / 2) * paso, accuracy: 1e-9)
                XCTAssertEqual(centro.y, -Double(p.terceras) * paso * 0.8660254037844386, accuracy: 1e-9)
                XCTAssertEqual(Tonnetz.punto(en: centro, paso: paso), p)
                // Cerca de la nota (a menos de medio paso) sigue siendo la misma.
                XCTAssertEqual(Tonnetz.punto(en: Punto(x: centro.x + paso * 0.3, y: centro.y - paso * 0.2), paso: paso), p)
            }
        }
        // La quinta, a la derecha; la tercera mayor, arriba a la derecha (y hacia abajo en SVG).
        let d = Tonnetz.trazado(paso: 64)
        XCTAssertGreaterThan(d.centro(de: punto(1, 0).coordenada).x, 0)
        XCTAssertLessThan(d.centro(de: punto(0, 1).coordenada).y, 0)
    }

    // MARK: Tabla armónica

    func testLaTablaEsElTonnetzGirado() {
        XCTAssertEqual(TablaArmonica.coordenada(de: punto(1, 0)), CoordenadaAxial(q: 0, r: -1))   // la quinta, arriba
        XCTAssertEqual(TablaArmonica.coordenada(de: punto(0, 1)), CoordenadaAxial(q: 1, r: -1))   // la tercera mayor
        for casilla in region {
            let p = PuntoDeLaRed(casilla)
            XCTAssertEqual(TablaArmonica.punto(de: TablaArmonica.coordenada(de: p)), p)
            // Girar no cambia las distancias: dos hexágonos vecinos siguen siéndolo.
            XCTAssertEqual(TablaArmonica.coordenada(de: p).longitud, p.coordenada.longitud)
        }
    }

    func testElTrazadoDeLaTablaEsElDelDibujo() {
        for paso in [56.0, 72] {
            let d = TablaArmonica.trazado(paso: paso)
            XCTAssertEqual(d.orientacion, .plana)
            XCTAssertEqual(d.tamano.x, paso / (2 * 0.8660254037844386), accuracy: 1e-9)
            for casilla in region {
                let p = PuntoDeLaRed(casilla)
                let centro = d.centro(de: TablaArmonica.coordenada(de: p))
                // Las fórmulas que usaba el dibujo: x = b·cos 30°·paso, y = −(a + b/2)·paso.
                XCTAssertEqual(centro.x, Double(p.terceras) * 0.8660254037844386 * paso, accuracy: 1e-9)
                XCTAssertEqual(centro.y, -(Double(p.quintas) + Double(p.terceras) / 2) * paso, accuracy: 1e-9)
                XCTAssertEqual(TablaArmonica.punto(en: centro, paso: paso), p)
            }
        }
    }

    func testElDibujoSigueIgual() throws {
        // Un hexágono por punto de la ventana, y los vértices del de Do donde estaban.
        let svg = TablaArmonica(Acorde("Do")).svg(leyenda: false)
        let raiz = try XCTUnwrap(ElementoXML.leer(svg))
        XCTAssertFalse(raiz.todos("polygon").isEmpty)
        let paso = 56.0, radio = paso / (2 * 0.8660254037844386)
        let esperados = stride(from: 0.0, to: 360, by: 60).map { angulo in
            "\(DibujoSVG.f(radio * cos(angulo * .pi / 180))),\(DibujoSVG.f(radio * sin(angulo * .pi / 180)))"
        }.joined(separator: " ")
        XCTAssertTrue(svg.contains("points=\"\(esperados)\""), "No está el hexágono de Do en (0, 0)")
        XCTAssertNotNil(ElementoXML.leer(Tonnetz(Acorde("Do")).svg()))
    }

    // MARK: Teclados isomórficos

    func testLaTablaArmonicaComoTeclado() {
        let teclado = TecladoIsomorfico.tablaArmonica
        for casilla in region {
            let p = PuntoDeLaRed(casilla)
            XCTAssertEqual(teclado.midi(en: TablaArmonica.coordenada(de: p)), TablaArmonica.midi(de: p))
        }
        // Arriba (el norte de los planos), una quinta; arriba a la derecha, una tercera mayor; arriba a la izquierda, una menor.
        XCTAssertEqual(teclado.semitonos(hacia: DireccionHexagonal(.norte, .plana)!), 7)
        XCTAssertEqual(teclado.semitonos(hacia: DireccionHexagonal(.noreste, .plana)!), 4)
        XCTAssertEqual(teclado.semitonos(hacia: DireccionHexagonal(.noroeste, .plana)!), 3)
    }

    func testWickiHaydenYJanko() {
        let wh = TecladoIsomorfico.wickiHayden
        XCTAssertEqual(wh.semitonos(hacia: DireccionHexagonal(.este, .puntiaguda)!), 2)
        XCTAssertEqual(wh.semitonos(hacia: DireccionHexagonal(.noreste, .puntiaguda)!), 7)
        XCTAssertEqual(wh.semitonos(hacia: DireccionHexagonal(.noroeste, .puntiaguda)!), 5)
        let janko = TecladoIsomorfico.janko
        XCTAssertEqual(janko.semitonos(hacia: DireccionHexagonal(.este, .puntiaguda)!), 2)
        XCTAssertEqual(janko.semitonos(hacia: DireccionHexagonal(.noreste, .puntiaguda)!), 1)
        XCTAssertEqual(janko.semitonos(hacia: DireccionHexagonal(.sureste, .puntiaguda)!), 1)
        for teclado in [wh, janko, .tablaArmonica] {
            for d in DireccionHexagonal.allCases {
                XCTAssertEqual(teclado.semitonos(hacia: d), -teclado.semitonos(hacia: d.opuesta))
            }
        }
    }

    func testIsomorfico() {
        // La misma forma suena al mismo acorde transportado: una tríada mayor desde cualquier casilla.
        let teclado = TecladoIsomorfico.wickiHayden
        let forma = [CoordenadaAxial.origen, CoordenadaAxial(q: 2, r: 0), CoordenadaAxial(q: 1, r: -1)]   // Do, Mi, Sol
        XCTAssertEqual(forma.map { teclado.midi(en: $0) }, [60, 64, 67])
        for desplazamiento in region {
            let midis = forma.map { teclado.midi(en: $0 + desplazamiento) }
            XCTAssertEqual(midis.map { $0 - midis[0] }, [0, 4, 7])
        }
    }

    func testAlturasYCasillas() {
        let teclado = TecladoIsomorfico.wickiHayden
        XCTAssertEqual(teclado.midi(en: .origen), 60)
        XCTAssertEqual(teclado.casillas(de: 67, en: FormasDeMapa.hexagono(radio: 3)), [CoordenadaAxial(q: 1, r: -1)])
        XCTAssertEqual(teclado.casillas(de: Altura("Sol4"), en: FormasDeMapa.hexagono(radio: 3)), [CoordenadaAxial(q: 1, r: -1)])
        XCTAssertEqual(teclado.altura(en: CoordenadaAxial(q: 0, r: -1)).midi, 65)
        XCTAssertEqual(teclado.altura(en: CoordenadaAxial(q: 1, r: 0), preferirBemoles: true).nota.nombre(en: .espanol), "Re")
        XCTAssertEqual(teclado.altura(en: CoordenadaAxial(q: 0, r: 1), preferirBemoles: true).nota.nombre(en: .espanol), "Sol")
        XCTAssertEqual("\(teclado)", "Wicki-Hayden: q +2, r -5")
        let otro = TecladoIsomorfico(nombre: "Prueba", orientacion: .plana, semitonosEnQ: 1, semitonosEnR: 3, midiDelOrigen: 48)
        XCTAssertEqual(otro.midi(en: CoordenadaAxial(q: 2, r: 1)), 53)
    }

    func testSVGDelTeclado() throws {
        let teclado = TecladoIsomorfico.janko
        let casillas = FormasDeMapa.rectangulo(columnas: 6, filas: 2, .filasImpares)
        let svg = teclado.svg(casillas, marcadas: [60, 64, 67])
        let raiz = try XCTUnwrap(ElementoXML.leer(svg))
        XCTAssertEqual(raiz.todos("polygon").count, 12)
        XCTAssertTrue(svg.contains(">Do4<"))
        XCTAssertTrue(svg.contains(DibujoSVG.Color.nota))
        XCTAssertTrue(svg.contains("#bbbbbb"))
        XCTAssertTrue(teclado.svg(casillas, notacion: .ingles).contains(">C4<"))
    }
}
