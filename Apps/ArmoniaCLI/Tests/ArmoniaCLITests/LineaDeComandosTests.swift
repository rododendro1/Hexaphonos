import XCTest
@testable import ArmoniaCLI

final class LineaDeComandosTests: XCTestCase {
    /// La salida de una orden escrita como en la terminal: `"acorde Sol7"`.
    private func salida(_ orden: String, file: StaticString = #filePath, line: UInt = #line) -> String {
        let resultado = LineaDeComandos.ejecutar(orden.split(separator: " ").map(String.init))
        XCTAssertEqual(resultado.codigo, 0, resultado.error, file: file, line: line)
        XCTAssertEqual(resultado.error, "", file: file, line: line)
        return resultado.salida
    }

    func testAyuda() {
        for orden in ["", "ayuda", "--help", "help"] {
            XCTAssertTrue(salida(orden).hasPrefix("armonia: teoría musical"), orden)
        }
    }

    func testAcorde() {
        XCTAssertEqual(salida("acorde Sol7/Si"), """
            Sol7/Si: séptima de dominante
              notas: Sol Si Re Fa  (bajo Si, inversión 1)
              Sol fundamental · Si tercera · Re quinta · Fa séptima

            """)
        XCTAssertEqual(salida("acorde Do Lam").components(separatedBy: "\n\n").count, 2)
        XCTAssertTrue(salida("acorde Do/Re").contains("bajo ajeno al acorde"))
    }

    func testIdentificar() {
        XCTAssertTrue(salida("identificar Do Mi Sol Sib").hasPrefix("Do7  séptima de dominante\n"))
        // Con octavas cuenta el bajo.
        XCTAssertTrue(salida("identificar Mi3 Sol3 Do4").hasPrefix("Do/Mi  mayor\n"))
        XCTAssertTrue(salida("identificar Do Mi Sib").contains("Do7  séptima de dominante  (sin Sol)"))
    }

    func testIntervaloEscalaYTonalidad() {
        XCTAssertEqual(salida("intervalo Do4 Mi5"), "10ª mayor (10M, 16 semitonos)\n")
        XCTAssertEqual(salida("intervalo Fa Si"), "4ª aumentada (4A, 6 semitonos)\n")
        XCTAssertTrue(salida("escala Re dórico").contains("notas: Re Mi Fa Sol La Si Do"))
        XCTAssertTrue(salida("escala Re dórico").contains("i7 Rem7 · ii7 Mim7"))
        // Sin acordes cuando la escala no es heptatónica.
        XCTAssertFalse(salida("escala Do pentatónica mayor").contains("acordes"))
        XCTAssertTrue(salida("tonalidad Mib mayor").contains("armadura: Si♭ Mi♭ La♭ (3 bemoles)"))
        XCTAssertTrue(salida("tonalidad Sol mayor").contains("armadura: Fa♯ (1 sostenido)"))
        XCTAssertTrue(salida("tonalidad La menor").contains("relativa: Do mayor · homónima: La mayor"))
        XCTAssertTrue(salida("tonalidad La menor").contains("V7 Mi7"))
    }

    func testAnalizar() {
        XCTAssertEqual(salida("analizar Do Lam Re7 Sol7 Do"), """
            I–vi–V7/V–V7–I en Do mayor
              Do        I         tónica
              Lam       vi        tónica
              Re7       V7/V      dominante
              Sol7      V7        dominante
              Do        I         tónica

            """)
        XCTAssertTrue(salida("analizar Lam Rem Mi7 La --en La menor").hasPrefix("i–iv–V7–I en La menor\n"))
    }

    func testVoces() {
        XCTAssertEqual(salida("voces Do3 Sol3 Mi4 Do5, Re3 La3 Fa4 Re5"), """
            Quintas paralelas entre bajo y tenor (acordes 1 → 2)
            Octavas paralelas entre bajo y soprano (acordes 1 → 2)

            """)
        XCTAssertEqual(salida("voces Do3 Mi4 Sol4 Do5 | Sol2 Re4 Sol4 Si4"), "Sin faltas de conducción.\n")
    }

    func testIngles() {
        XCTAssertTrue(salida("acorde G7/B --ingles").hasPrefix("G7/B: dominant seventh\n  notes: G B D F  (bass B, inversion 1)"))
        XCTAssertTrue(salida("analizar C Am D7 G7 C --ingles").hasPrefix("I–vi–V7/V–V7–I in C major\n  C         I         tonic"))
        XCTAssertEqual(salida("voces C3 E4 G4 C5, G2 D4 G4 B4 --ingles"), "No voice-leading errors.\n")
        XCTAssertTrue(salida("tonalidad D major --ingles").contains("key signature: F# C# (2 sharps)"))
    }

    func testMIDI() throws {
        func datos(_ orden: String) throws -> [UInt8] {
            let resultado = LineaDeComandos.ejecutar(orden.split(separator: " ").map(String.init))
            XCTAssertEqual(resultado.codigo, 0, resultado.error)
            XCTAssertEqual(resultado.salida, "")
            return [UInt8](try XCTUnwrap(resultado.datos, orden))
        }
        let melodia = try datos("midi melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4 --tempo 90 --titulo Escala --instrumento 40")
        XCTAssertEqual(Array(melodia.prefix(4)), Array("MThd".utf8))
        XCTAssertTrue(melodia.count > 60)
        // El instrumento: cambio de programa 40 (violín) en la pista de la voz.
        XCTAssertNotNil(zip(melodia, melodia.dropFirst()).first { $0 == (0xC0, 40) })
        XCTAssertEqual(try datos("midi coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 --duracion 2").filter { $0 == 0x4D }.count, 6)   // MThd + 5 MTrk
        XCTAssertFalse(try datos("midi acordes Do Lam Re7 Sol7 Do --tempo 80").isEmpty)
        XCTAssertNil(LineaDeComandos.ejecutar(["musicxml", "melodia", "Do4:4"]).datos)
        for orden in ["midi", "midi melodia", "midi melodia Do4:4 --clave fa", "midi coral Do3 Do5 --cifrados",
                      "midi melodia Do4:4 --instrumento 200", "midi melodia Do4:4 --instrumento piano",
                      "musicxml melodia Do4:4 --instrumento 3"] {
            let resultado = LineaDeComandos.ejecutar(orden.split(separator: " ").map(String.init))
            XCTAssertEqual(resultado.codigo, 2, orden)
            XCTAssertNil(resultado.datos, orden)
        }
    }

    func testMusicXML() {
        let melodia = salida("musicxml melodia Sol4:4 Do5:2 Re5:4 Mi5:2 --compas 3/4 --anacrusa 4 --tonalidad Sol mayor --tempo 60 4. --titulo Mi canción --clave sol8b")
        XCTAssertTrue(melodia.hasPrefix("<?xml"))
        XCTAssertTrue(melodia.hasSuffix("</score-partwise>\n"))
        for fragmento in ["<work-title>Mi canción</work-title>", "<fifths>1</fifths>", "<beats>3</beats>",
                          "<measure number=\"0\" implicit=\"yes\">", "<beat-unit-dot/>", "<per-minute>60</per-minute>",
                          "<clef-octave-change>-1</clef-octave-change>"] {
            XCTAssertTrue(melodia.contains(fragmento), fragmento)
        }
        let coral = salida("musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4, Do3 Mi4 Sol4 Do5 --duracion 2 --compas 3/2")
        for fragmento in ["<staves>2</staves>", "<type>half</type>", "<beats>3</beats>", "<beat-type>2</beat-type>",
                          "<voice>4</voice>", "<staff>2</staff>"] {
            XCTAssertTrue(coral.contains(fragmento), fragmento)
        }
        let acordes = salida("musicxml acordes Do Lam Re7 Sol7 Do --duracion 4 --titulo Progresión")
        for fragmento in ["<harmony print-frame=\"no\">", "<kind text=\"7\">dominant</kind>", "<text>V7/V</text>",
                          "<words>Do mayor:</words>", "<type>quarter</type>"] {
            XCTAssertTrue(acordes.contains(fragmento), fragmento)
        }
        XCTAssertTrue(salida("musicxml acordes Am Dm E7 Am --ingles").contains("<words>A minor:</words>"))
        XCTAssertTrue(salida("musicxml acordes Re Sol La7 Re --tonalidad Sol mayor").contains("<text>V</text>"))
        let analizado = salida("musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 --cifrados --analisis")
        XCTAssertTrue(analizado.contains("<harmony") && analizado.contains("<lyric"))
        let soloCifrados = salida("musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 --cifrados")
        XCTAssertTrue(soloCifrados.contains("<harmony") && !soloCifrados.contains("<lyric"))
        XCTAssertEqual(LineaDeComandos.leerClave("do en tercera"), .doEnTercera)
        XCTAssertEqual(LineaDeComandos.leerClave("Clave de Fa"), .fa)
        XCTAssertEqual(LineaDeComandos.leerClave("bass"), .fa)
        XCTAssertEqual(LineaDeComandos.leerClave("baritone clef"), .faEnTercera)
        XCTAssertNil(LineaDeComandos.leerClave("re"))

        for orden in ["musicxml", "musicxml partitura Do4:4", "musicxml melodia", "musicxml coral",
                      "musicxml melodia Do4:4 --color rojo", "musicxml melodia Do4:4 --compas",
                      "musicxml melodia Do4:4 --tempo rápido", "musicxml melodia Do4:4 --clave re",
                      "musicxml melodia Do4:4 --duracion 2", "musicxml coral Do3 Do5 --clave fa",
                      "musicxml melodia Do4:4 --cifrados", "musicxml acordes", "musicxml acordes Do Sol --analisis",
                      "musicxml acordes Do Sol --clave fa"] {
            let resultado = LineaDeComandos.ejecutar(orden.split(separator: " ").map(String.init))
            XCTAssertEqual(resultado.codigo, 2, orden)
            XCTAssertEqual(resultado.salida, "", orden)
        }
        for orden in ["musicxml melodia Do4:3", "musicxml melodia Do4:4 --compas 3/5", "musicxml coral Do3 Mi4, Sol2",
                      "musicxml acordes Do Hm"] {
            XCTAssertEqual(LineaDeComandos.ejecutar(orden.split(separator: " ").map(String.init)).codigo, 1, orden)
        }
    }

    func testTonnetz() {
        for orden in ["tonnetz Do Mi Sol", "tonnetz --acorde Sol7", "tonnetz --escala Re dórico", "tonnetz --clases 0 4 7",
                      "tonnetz --clases 0,3,6,9 --margen 2", "tonnetz C E G --ingles"] {
            let svg = salida(orden)
            XCTAssertTrue(svg.hasPrefix("<svg") && svg.hasSuffix("</svg>\n"), orden)
        }
        XCTAssertTrue(salida("tonnetz --acorde Do").contains(">Mi</text>"))
        XCTAssertTrue(salida("tonnetz C E G --ingles").contains(">E</text>"))
        for orden in ["tonnetz", "tonnetz --clases 0 12", "tonnetz --clases", "tonnetz --acorde", "tonnetz --escala",
                      "tonnetz --color Do", "tonnetz Do --margen 9"] {
            XCTAssertEqual(LineaDeComandos.ejecutar(orden.split(separator: " ").map(String.init)).codigo, 2, orden)
        }
        XCTAssertEqual(LineaDeComandos.ejecutar(["tonnetz", "Do", "Hm"]).codigo, 1)
        XCTAssertTrue(salida("tonnetz --recorrido Do Lam Fa Rem").contains("Do –R→ Lam –L→ Fa –R→ Rem"))
        XCTAssertTrue(salida("tonnetz --camino Do Mibm").contains("Do –P→ Dom –R→ Mi♭ –P→ Mi♭m"))
        for orden in ["tonnetz --recorrido", "tonnetz --recorrido Do Sol7", "tonnetz --camino Do", "tonnetz --camino Do Sol7"] {
            XCTAssertEqual(LineaDeComandos.ejecutar(orden.split(separator: " ").map(String.init)).codigo, 2, orden)
        }
    }

    func testTablaArmonica() {
        for orden in ["tabla Do Mi Sol", "tabla Do3 Sol3 Mi4", "tabla --acorde Domaj7", "tabla --escala Re dórico",
                      "tabla --clases 0,4,7 --margen 3", "tabla C E G --ingles"] {
            let svg = salida(orden)
            XCTAssertTrue(svg.hasPrefix("<svg") && svg.hasSuffix("</svg>\n"), orden)
        }
        XCTAssertTrue(salida("tabla Do3 Sol3 Mi4").contains(">Sol3</text>"))
        for orden in ["tabla", "tabla --acorde", "tabla --clases 13", "tabla --foo", "tabla Do --margen 7"] {
            XCTAssertEqual(LineaDeComandos.ejecutar(orden.split(separator: " ").map(String.init)).codigo, 2, orden)
        }
        XCTAssertEqual(LineaDeComandos.ejecutar(["tabla", "Do4", "Hm4"]).codigo, 1)
        XCTAssertTrue(salida("tabla --recorrido Do Lam Fa Rem").contains("<title>Do –R→ Lam –L→ Fa –R→ Rem</title>"))
        XCTAssertTrue(salida("tabla --camino Do Mibm").contains("<title>Do –P→ Dom –R→ Mi♭ –P→ Mi♭m</title>"))
        for orden in ["tabla --recorrido", "tabla --recorrido Do Sol7", "tabla --camino Do", "tabla --camino Do Sol7"] {
            XCTAssertEqual(LineaDeComandos.ejecutar(orden.split(separator: " ").map(String.init)).codigo, 2, orden)
        }
    }

    func testConduccionParsimoniosa() {
        XCTAssertEqual(salida("vecinos Sol7"), "Sol♯°7 (Sol→Sol♯)\nSolm7 (Si→Si♭)\nMim7 (Fa→Mi)\n")
        XCTAssertTrue(salida("vecinos Sol7 --voces 2").contains("Re♭7 (Sol→La♭, Re→Re♭)"))
        XCTAssertEqual(salida("vecinos G7 --ingles"), "G#°7 (G→G#)\nGm7 (B→Bb)\nEm7 (F→E)\n")
        XCTAssertEqual(salida("camino Sol7 Rem7"), "Sol7 –Sol→Sol♯→ Sol♯°7 –Sol♯→La→ Sim7(♭5) –Si→Do→ Rem7\n3 pasos\n")
        XCTAssertEqual(salida("camino Sol7 Reb7 --voces 2"), "Sol7 –Sol→La♭, Re→Re♭→ Re♭7\n1 paso\n")
        XCTAssertEqual(salida("conduccion Sol7 Do"), "Sol→Sol, Si→Do (+1), Re→Do (−2), Fa→Mi (−1): 4 semitonos\n")
        XCTAssertEqual(salida("vecinos Domaj7"), "Do♯m7(♭5) (Do→Do♯)\nDo7 (Si→Si♭)\n")
        XCTAssertTrue(salida("vecinos Sol7 --ampliada").contains("Solmaj7 (Fa→Fa♯)"))
        XCTAssertEqual(salida("camino Do7 Domaj7"), "Do7 –Si♭→Si→ Domaj7\n1 paso\n")
        for orden in ["vecinos", "vecinos Do6", "vecinos Do --ampliada", "vecinos Sol7 --voces 3", "camino Sol7", "camino Do Sol7", "conduccion Sol7"] {
            XCTAssertEqual(LineaDeComandos.ejecutar(orden.split(separator: " ").map(String.init)).codigo, 2, orden)
        }
    }

    func testPLR() {
        XCTAssertEqual(salida("plr Do PLR"), "Do –P→ Dom –L→ La♭ –R→ Fam\nPLR, 3 pasos\n")
        XCTAssertEqual(salida("plr Do P L"), "Do –P→ Dom –L→ La♭\nPL, 2 pasos\n")
        XCTAssertEqual(salida("plr Do H"), "Do –L→ Mim –P→ Mi –L→ Sol♯m\nLPL, 3 pasos\n")
        XCTAssertEqual(salida("plr Do Mibm"), "Do –P→ Dom –R→ Mi♭ –P→ Mi♭m\nPRP, 3 pasos\n")
        XCTAssertEqual(salida("plr Do Lam"), "Do –R→ Lam\nR, 1 paso\n")
        XCTAssertEqual(salida("plr Do Do"), "Do\nningún paso\n")
        XCTAssertEqual(salida("plr C Am --ingles"), "C –R→ Am\nR, 1 paso\n")
        XCTAssertEqual(salida("plr Do hexatonico"), "Do –P→ Dom –L→ La♭ –P→ La♭m –L→ Mi –P→ Mim –L→ Do\nciclo hexatónico, 6 tríadas\n")
        XCTAssertTrue(salida("plr Do ciclo LR").hasSuffix("–R→ Do\nciclo LR, 24 tríadas\n"))
        XCTAssertTrue(salida("plr C octatonic --ingles").hasSuffix("octatonic cycle, 8 triads\n"))
        XCTAssertTrue(salida("tonnetz --ciclo hexatonico Do").contains("La♭m –L→ Mi"))
        XCTAssertEqual(LineaDeComandos.ejecutar(["tonnetz", "--ciclo", "Do"]).codigo, 2)
        XCTAssertEqual(LineaDeComandos.ejecutar(["tonnetz", "--ciclo", "hexatonico", "Do7"]).codigo, 2)
        XCTAssertTrue(salida("tabla --ciclo octatonico Do").contains("Sol♭ –P→ Fa♯m"))
        XCTAssertEqual(LineaDeComandos.ejecutar(["tabla", "--ciclo", "LR", "Sol7"]).codigo, 2)
        for orden in ["plr", "plr Do", "plr Sol7 P", "plr Do Sol7"] {
            XCTAssertEqual(LineaDeComandos.ejecutar(orden.split(separator: " ").map(String.init)).codigo, 2, orden)
        }
        XCTAssertEqual(LineaDeComandos.ejecutar(["plr", "Do", "Xq"]).codigo, 1)
    }

    func testErrores() {
        let lectura = LineaDeComandos.ejecutar(["acorde", "Hm"])
        XCTAssertEqual(lectura.codigo, 1)
        XCTAssertEqual(lectura.salida, "")
        XCTAssertTrue(lectura.error.hasPrefix("No se puede leer «Hm»"))
        XCTAssertTrue(LineaDeComandos.ejecutar(["acorde", "Hm", "--ingles"]).error.hasPrefix("Cannot read"))

        for orden in [["foo"], ["intervalo", "Do"], ["acorde"], ["analizar"], ["analizar", "Do", "--en"], ["voces"]] {
            let resultado = LineaDeComandos.ejecutar(orden)
            XCTAssertEqual(resultado.codigo, 2, "\(orden)")
            XCTAssertTrue(resultado.error.hasSuffix("Prueba «armonia ayuda».\n"), "\(orden)")
        }
        XCTAssertEqual(LineaDeComandos.ejecutar(["voces", "Do3", "Mi4,", "Sol2"]).codigo, 1)
    }

    // MARK: Digitaciones

    /// El resultado de una orden con los argumentos tal cual (un valor puede llevar espacios).
    private func resultado(_ argumentos: String...) -> ResultadoDeOrden {
        LineaDeComandos.ejecutar(argumentos)
    }

    func testDigitacionesDeDoEnLaGuitarra() {
        let texto = salida("digitaciones Do --limite 100")
        XCTAssertTrue(texto.hasPrefix("Do · guitarra\n"), texto)
        XCTAssertTrue(texto.contains("  x32010"), texto)
        XCTAssertTrue(texto.contains("Do Mi Sol Do Mi"), texto)
    }

    func testDigitacionesRespetanElLimite() {
        // Un encabezado y una línea por forma.
        XCTAssertEqual(salida("digitaciones Do --limite 3").split(separator: "\n").count, 4)
        XCTAssertEqual(salida("digitaciones Do").split(separator: "\n").count, 6)   // cinco por defecto
    }

    func testDigitacionesEnElUkelele() {
        let texto = salida("digitaciones Do --limite 100 --instrumento ukelele")
        XCTAssertTrue(texto.hasPrefix("Do · ukelele\n"), texto)
        XCTAssertTrue(texto.contains("  0003"), texto)
        XCTAssertTrue(salida("digitaciones Do --instrumento Ukulele").hasPrefix("Do · ukelele\n"))
    }

    func testElInstrumentoPuedeLlevarEspacios() {
        let orden = resultado("digitaciones", "Mi", "--instrumento", "bajo de 5 cuerdas")
        XCTAssertEqual(orden.codigo, 0, orden.error)
        XCTAssertTrue(orden.salida.hasPrefix("Mi · bajo de cinco cuerdas\n"), orden.salida)
    }

    func testLasNotasSeEscribenComoElAcorde() {
        let texto = salida("digitaciones Sib --limite 100")
        XCTAssertTrue(texto.contains("Si♭"), texto)
        XCTAssertFalse(texto.contains("La♯"), texto)
        // Con --ingles, la notación inglesa.
        XCTAssertTrue(salida("digitaciones C --limite 100 --ingles").contains("C E G C E"))
    }

    func testDigitacionesConTablatura() {
        let lineas = salida("digitaciones Do --limite 1 --tab").split(separator: "\n").map(String.init)
        // Encabezado, la forma y una línea por cuerda.
        XCTAssertEqual(lineas.count, 1 + 1 + 6, lineas.joined(separator: "\n"))
        XCTAssertTrue(lineas.dropFirst(2).allSatisfy { $0.contains("|-") })
        // La cuerda más aguda va arriba.
        XCTAssertTrue(lineas[2].contains("Mi"), lineas[2])
    }

    func testVariosAcordesSeparadosPorUnaLineaEnBlanco() {
        let texto = salida("digitaciones Do Sol --limite 1")
        XCTAssertEqual(texto.components(separatedBy: "\n\n").count, 2, texto)
    }

    func testDigitacionesConErrores() {
        let desconocido = resultado("digitaciones", "Do", "--instrumento", "arpa")
        XCTAssertEqual(desconocido.codigo, 2)
        XCTAssertTrue(desconocido.error.contains("instrumento desconocido: «arpa»"), desconocido.error)
        XCTAssertTrue(desconocido.error.contains("guitarra"), desconocido.error)

        XCTAssertEqual(resultado("digitaciones").codigo, 2)                                  // falta el acorde
        XCTAssertEqual(resultado("digitaciones", "Do", "--instrumento").codigo, 2)           // falta el valor
        XCTAssertEqual(resultado("digitaciones", "Do", "--limite", "0").codigo, 2)
        XCTAssertEqual(resultado("digitaciones", "Do", "--limite", "muchas").codigo, 2)
        XCTAssertEqual(resultado("digitaciones", "Do", "--traste", "30").codigo, 2)
        XCTAssertEqual(resultado("digitaciones", "Do", "--cejilla").codigo, 2)               // opción desconocida
        XCTAssertEqual(resultado("digitaciones", "Do").codigo, 0)

        // Un cifrado que no se lee es un error de lectura (código 1), como en `acorde`.
        let ilegible = resultado("digitaciones", "xyz!")
        XCTAssertEqual(ilegible.codigo, 1)
        XCTAssertFalse(ilegible.error.isEmpty)
    }

    func testDigitacionesIndicanLosDedosYLaCejilla() {
        XCTAssertTrue(salida("digitaciones Do --limite 1").contains("(3 dedos)"))
        let fa = salida("digitaciones Fa --limite 6")
        XCTAssertTrue(fa.contains("133211"), fa)
        XCTAssertTrue(fa.contains("(4 dedos, cejilla en el traste 1)"), fa)
        XCTAssertTrue(salida("digitaciones C --limite 1 --ingles").contains("(3 fingers)"))
        XCTAssertTrue(salida("digitaciones Mim --limite 100").contains("(1 dedo)"))
    }

    func testLaFormaDeManualVaPrimero() {
        // Antes iba por delante una forma en el traste 8.
        XCTAssertTrue(salida("digitaciones Do --limite 1").contains("  x32010"))
        XCTAssertTrue(salida("digitaciones Sol --instrumento ukelele --limite 1").contains("  0232"))
    }

    func testLaQuintaPuedeFaltarPorDefectoYConCompletoNo() {
        XCTAssertTrue(salida("digitaciones Do7 --limite 300").contains("  x32310"))
        XCTAssertFalse(salida("digitaciones Do7 --limite 300 --completo").contains("  x32310"))
    }

    func testElLimiteDeDedos() {
        let texto = salida("digitaciones Mim --dedos 1 --limite 50")
        let formas = texto.split(separator: "\n").dropFirst()
        XCTAssertFalse(formas.isEmpty)
        XCTAssertTrue(formas.allSatisfy { $0.contains("(1 dedo") }, texto)
        for malo in ["0", "5", "muchos"] {
            XCTAssertEqual(resultado("digitaciones", "Mim", "--dedos", malo).codigo, 2, malo)
        }
        XCTAssertEqual(resultado("digitaciones", "Mim", "--dedos").codigo, 2)
    }

    func testLaAyudaHablaDeLasDigitaciones() {
        XCTAssertTrue(salida("ayuda").contains("digitaciones <cifrado>"))
    }
}
