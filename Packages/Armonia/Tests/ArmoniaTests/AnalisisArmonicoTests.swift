import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class AnalisisArmonicoTests: XCTestCase {
    private func cifrados(_ texto: String, en tonalidad: Tonalidad? = nil,
                          file: StaticString = #filePath, line: UInt = #line) -> [String] {
        do {
            return try AnalisisArmonico.analizar(leyendo: texto, en: tonalidad).cifrados
        } catch {
            XCTFail("«\(texto)»: \(error)", file: file, line: line)
            return []
        }
    }

    private func tonalidad(_ texto: String) -> Tonalidad? {
        try? AnalisisArmonico.analizar(leyendo: texto).tonalidad
    }

    func testDiatonicos() {
        XCTAssertEqual(cifrados("Do Fa Sol7 Do"), ["I", "IV", "V7", "I"])
        XCTAssertEqual(cifrados("Rem7 Sol7 Domaj7"), ["ii7", "V7", "Imaj7"])
        XCTAssertEqual(cifrados("Re La Sim Fa#m Sol Re Sol La"), ["I", "V", "vi", "iii", "IV", "I", "IV", "V"])
        XCTAssertEqual(cifrados("Do Sim° Do"), ["I", "vii°", "I"])
        XCTAssertEqual(cifrados("Do Sim7(b5) Do"), ["I", "viiø7", "I"])
    }

    func testMenor() {
        // En menor, la sensible es propia: V y vii° son diatónicos, sin alteración en el numeral.
        XCTAssertEqual(cifrados("Lam Rem Mi7 Lam"), ["i", "iv", "V7", "i"])
        XCTAssertEqual(cifrados("Sim7(b5) Mi7 Lam"), ["iiø7", "V7", "i"])
        XCTAssertEqual(cifrados("Lam Sol#°7 Lam"), ["i", "vii°7", "i"])
        XCTAssertEqual(cifrados("Lam Fa Do Sol"), ["i", "VI", "III", "VII"])
        XCTAssertEqual(tonalidad("Lam Fa Do Sol"), Tonalidad(.la, .menor))
    }

    func testInversiones() {
        XCTAssertEqual(cifrados("Do Fa/La Sol7/Si Do"), ["I", "IV6", "V65", "I"])
        XCTAssertEqual(cifrados("Do/Sol Sol7/Re Do/Mi", en: Tonalidad(.do)), ["I64", "V43", "I6"])
        XCTAssertEqual(cifrados("Sol7/Fa Do/Mi", en: Tonalidad(.do)), ["V42", "I6"])
        // La sexta añadida no se confunde con la primera inversión.
        XCTAssertEqual(cifrados("Mim6 Do6 Fa6/La Lam", en: Tonalidad(.do)), ["iii(add6)", "I(add6)", "IV(add6)643", "vi"])
        XCTAssertEqual(cifrados("Mim Mim/Sol", en: Tonalidad(.do)), ["iii", "iii6"])
        // Invertidos, con todos los intervalos sobre el bajo.
        XCTAssertEqual(cifrados("Fa6/La Fa6/Do Fa6/Re", en: Tonalidad(.do)), ["IV(add6)643", "IV(add6)642", "IV(add6)753"])
        XCTAssertEqual(cifrados("Dosus4/Fa Do(add9)/Mi", en: Tonalidad(.do)), ["Isus452", "I(add9)763"])
        XCTAssertEqual(cifrados("Sim7(b5)/Re Mi7 Lam", en: Tonalidad(.la, .menor)), ["iiø65", "V7", "i"])
    }

    func testDominantesSecundarias() {
        XCTAssertEqual(cifrados("Do Lam Re7 Sol7 Do"), ["I", "vi", "V7/V", "V7", "I"])
        XCTAssertEqual(cifrados("Do La7 Rem Sol7 Do"), ["I", "V7/ii", "ii", "V7", "I"])
        XCTAssertEqual(cifrados("Do Do7 Fa Sol Do"), ["I", "V7/IV", "IV", "V", "I"])
        XCTAssertEqual(cifrados("Do Mi Lam Sol Do"), ["I", "V/vi", "vi", "V", "I"])
        XCTAssertEqual(cifrados("Do Re7/Fa# Sol", en: Tonalidad(.do)), ["I", "V65/V", "V"])

        let analisis = try! AnalisisArmonico.analizar(leyendo: "Do Lam Re7 Sol7 Do")
        XCTAssertEqual(analisis.acordes[2].categoria, .dominanteSecundaria(de: 5))
        XCTAssertEqual(analisis.acordes[2].funcion, .dominante)
        XCTAssertEqual(analisis.acordes[2].grado, 2)
    }

    func testSensiblesSecundarias() {
        XCTAssertEqual(cifrados("Do Fa#°7 Sol Do"), ["I", "vii°7/V", "V", "I"])
        XCTAssertEqual(cifrados("Do Do#° Rem Sol Do"), ["I", "vii°/ii", "ii", "V", "I"])
        let analisis = try! AnalisisArmonico.analizar(leyendo: "Do Fa#°7 Sol Do")
        XCTAssertEqual(analisis.acordes[1].categoria, .sensibleSecundaria(de: 5))
    }

    func testNapolitanaYPrestamos() {
        XCTAssertEqual(cifrados("Do Reb/Fa Sol7 Do"), ["I", "♭II6", "V7", "I"])
        XCTAssertEqual(cifrados("Lam Sib/Re Mi7 Lam"), ["i", "♭II6", "V7", "i"])
        XCTAssertEqual(cifrados("Do Fam Do"), ["I", "iv", "I"])
        XCTAssertEqual(cifrados("Do Lab Sib Do"), ["I", "♭VI", "♭VII", "I"])
        XCTAssertEqual(cifrados("Do Mib Fa Do"), ["I", "♭III", "IV", "I"])
        XCTAssertEqual(tonalidad("Do Lab Sib Do"), Tonalidad(.do))
        // Tercera de picardía: el I mayor al final de una obra en menor.
        let picardia = try! AnalisisArmonico.analizar(leyendo: "Lam Rem/Fa Mi7 La")
        XCTAssertEqual(picardia.tonalidad, Tonalidad(.la, .menor))
        XCTAssertEqual(picardia.cifrados, ["i", "iv6", "V7", "I"])
        XCTAssertEqual(picardia.acordes[3].categoria, .prestamo)
        XCTAssertEqual(picardia.acordes[3].funcion, .tonica)
    }

    func testNapolitanaInvertida() {
        XCTAssertEqual(cifrados("Do Reb Sol7 Do"), ["I", "♭II", "V7", "I"])
        XCTAssertEqual(cifrados("Do Reb/Lab Sol7 Do"), ["I", "♭II64", "V7", "I"])
        XCTAssertEqual(cifrados("Lam Sib/Re Mi7 Lam", en: Tonalidad(.la, .menor)), ["i", "♭II6", "V7", "i"])
    }

    func testSextasAumentadas() {
        XCTAssertEqual(cifrados("Do Lab(#6,omit5) Sol Do"), ["I", "It+6", "V", "I"])
        XCTAssertEqual(cifrados("Do Lab(#6,#11,omit5) Sol Do"), ["I", "Fr+6", "V", "I"])
        XCTAssertEqual(cifrados("Do Lab(#6) Do/Sol Sol7 Do"), ["I", "Ger+6", "I64", "V7", "I"])
        XCTAssertEqual(cifrados("Lam Fa(#6,omit5) Mi Lam"), ["i", "It+6", "V", "i"])
        // La francesa escrita desde el Re (Re7(♭5) con La♭ en el bajo) es el mismo acorde.
        XCTAssertEqual(cifrados("Do Fa Re7(b5)/Lab Sol Do"), ["I", "IV", "Fr+6", "V", "I"])
        // La alemana escrita como La♭7 sólo lo es si va a la dominante.
        XCTAssertEqual(cifrados("Do Lab7 Sol Do"), ["I", "Ger+6", "V", "I"])
        XCTAssertEqual(cifrados("Do Lab7 Do", en: Tonalidad(.do)), ["I", "♭VI7", "I"])
        let analisis = try! AnalisisArmonico.analizar(leyendo: "Do Lab(#6) Sol Do")
        XCTAssertEqual(analisis.acordes[1].categoria, .sextaAumentada)
        XCTAssertEqual(analisis.acordes[1].funcion, .subdominante)
        // Las comas de dentro del paréntesis no separan acordes.
        XCTAssertEqual(cifrados("Do7(b9,#11), Fa", en: Tonalidad(.fa)), ["V7(♭9,♯11)", "I"])
    }

    func testCromaticos() {
        let analisis = Tonalidad(.do).analizar(["Do", "Fa#", "Do"])
        XCTAssertEqual(analisis.cifrados, ["I", "♯IV", "I"])
        XCTAssertEqual(analisis.acordes[1].categoria, .cromatico)
        XCTAssertNil(analisis.acordes[1].funcion)
    }

    func testFunciones() {
        let analisis = try! AnalisisArmonico.analizar(leyendo: "Do Lam Rem Sol7 Mim Sim° Do")
        XCTAssertEqual(analisis.funciones, [.tonica, .tonica, .subdominante, .dominante, .tonica, .dominante, .tonica])
        XCTAssertEqual(analisis.funciones.map { $0!.abreviatura }.joined(), "TTSDTDT")
        XCTAssertEqual(FuncionTonal.subdominante.nombre(en: .ingles), "subdominant")
    }

    func testDeteccionDeTonalidad() {
        XCTAssertEqual(tonalidad("Do Fa Sol7 Do"), Tonalidad(.do))
        XCTAssertEqual(tonalidad("Sol Re/Fa# Mim Do Re7 Sol"), Tonalidad(.sol))
        XCTAssertEqual(tonalidad("Am | Dm | E7 | Am"), Tonalidad(.la, .menor))
        XCTAssertEqual(tonalidad("Sol7 Do"), Tonalidad(.do))
        XCTAssertEqual(tonalidad("Fa Sol Lam"), Tonalidad(.la, .menor))
        XCTAssertEqual(tonalidad("Mib Lab Sib7 Mib"), Tonalidad(Nota(.mi, .bemol)))
    }

    func testTextoYNotaciones() throws {
        let analisis = try AnalisisArmonico.analizar(leyendo: "C, F, G7, C")
        XCTAssertEqual("\(analisis)", "I–IV–V7–I en Do mayor")
        XCTAssertEqual(analisis.nombre(en: .ingles), "I–IV–V7–I in C major")
        XCTAssertEqual(try AnalisisArmonico.analizar(leyendo: "Do–Fa–Sol7–Do").cifrados, ["I", "IV", "V7", "I"])
        XCTAssertEqual(try AnalisisArmonico.analizar(leyendo: "Lam | Rem | Mi7 | Lam", en: "La menor").cifrados,
                       ["i", "iv", "V7", "i"])
    }

    func testErrores() {
        XCTAssertThrowsError(try AnalisisArmonico.analizar(leyendo: "Do Fa Hm Do")) { error in
            let error = error as? ErrorDeLectura
            XCTAssertEqual(error?.texto, "Do Fa Hm Do")
            XCTAssertEqual(error?.posicion, 6)
            guard case .notaNoReconocida? = error?.motivo else { return XCTFail("\(String(describing: error))") }
        }
        XCTAssertThrowsError(try AnalisisArmonico.analizar(leyendo: "  | ")) { error in
            guard case .textoVacio? = (error as? ErrorDeLectura)?.motivo else { return XCTFail("\(error)") }
        }
        XCTAssertNil(AnalisisArmonico.analizar([]))
    }

    /// La progresión transportada se analiza igual en la tonalidad transportada.
    func testTransposicion() {
        let progresion: [Acorde] = ["Do", "Lam", "Re7", "Sol7", "Do", "Fam", "Reb", "Sol7", "Do"]
        let original = Tonalidad(.do).analizar(progresion).cifrados
        for tonica in Escala.circuloDeQuintas().map(\.tonica) {
            let intervalo = Nota.do.intervalo(hasta: tonica)
            let transportada = progresion.map { $0 + intervalo }
            XCTAssertEqual(Tonalidad(tonica).analizar(transportada).cifrados, original, "\(tonica)")
        }
    }
}
