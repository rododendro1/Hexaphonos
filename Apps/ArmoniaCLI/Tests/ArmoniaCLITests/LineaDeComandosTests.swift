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
              notas: Sol Si Re Fa  (bajo Si, primera inversión)
              Sol fundamental · Si tercera · Re quinta · Fa séptima

            """)
        XCTAssertEqual(salida("acorde Do Lam").components(separatedBy: "\n\n").count, 2)
        XCTAssertTrue(salida("acorde Do/Re").contains("bajo ajeno al acorde"))
        XCTAssertTrue(salida("acorde Do/Sol").contains("(bajo Sol, segunda inversión)"))
        XCTAssertTrue(salida("acorde Sol7/Fa").contains("(bajo Fa, tercera inversión)"))
        XCTAssertTrue(salida("acorde C/G --ingles").contains("(bass G, second inversion)"))
    }

    /// Los nombres de órdenes y opciones, en español y en inglés; los de antes ya no se aceptan.
    func testNombresDeOrdenesYOpciones() {
        let coral = "Do3 Sol3 Mi4 Do5, Re3 La3 Fa4 Re5"
        XCTAssertEqual(salida("revisar " + coral), salida("check " + coral))
        XCTAssertEqual(salida("conduccion-parsimoniosa Sol7 Rem7"), salida("smooth-path Sol7 Rem7"))
        for orden in ["tonnetz", "tabla"] {
            XCTAssertEqual(salida(orden + " --sequence Do Lam Fa Rem"), salida(orden + " --recorrido Do Lam Fa Rem"))
            XCTAssertNotEqual(LineaDeComandos.ejecutar([orden, "--path", "Do", "Lam"]).codigo, 0)
        }
        for antigua in ["voces", "voices", "camino", "path"] {
            XCTAssertNotEqual(LineaDeComandos.ejecutar([antigua, "Do", "Fa"]).codigo, 0, antigua)
        }
        let programa = LineaDeComandos.ejecutar(["midi", "melodia", "Do4:4", "--programa", "40"])
        XCTAssertEqual(programa.codigo, 0, programa.error)
        XCTAssertNotNil(programa.datos)
        XCTAssertEqual(programa.datos, LineaDeComandos.ejecutar(["midi", "melodia", "Do4:4", "--program", "40"]).datos)
        XCTAssertEqual(LineaDeComandos.ejecutar(["midi", "melodia", "Do4:4", "--instrumento", "40"]).codigo, 2)
        XCTAssertEqual(LineaDeComandos.ejecutar(["musicxml", "melodia", "Do4:4", "--programa", "40"]).codigo, 2)
        XCTAssertEqual(LineaDeComandos.ejecutar(["midi", "melodia", "Do4:4", "--programa", "200"]).codigo, 2)

        let ayuda = salida("ayuda"), help = salida("help --ingles")
        for nombre in ["revisar <acordes>", "conduccion-parsimoniosa <acorde>", "--programa 0…127"] {
            XCTAssertTrue(ayuda.contains(nombre), nombre)
        }
        for nombre in ["check <chords>", "smooth-path <chord>", "--sequence <triads>", "--program 0…127"] {
            XCTAssertTrue(help.contains(nombre), nombre)
        }
        for antiguo in ["voces <acordes>", "camino <acorde>", "--instrumento 0…127"] {
            XCTAssertFalse(ayuda.contains(antiguo), antiguo)
        }
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
            Cadencia auténtica V7–I (acordes 4 → 5)

            """)
        XCTAssertTrue(salida("analizar Lam Rem Mi7 La --en La menor").hasPrefix("i–iv–V7–I en La menor\n"))
        XCTAssertTrue(salida("analizar Do Lam Fa Sol").hasSuffix("Semicadencia IV–V (acordes 3 → 4)\n"))
    }

    func testAnalizarModulaciones() {
        XCTAssertEqual(salida("analizar Do Fa Sol7 Do Lam Re7 Sol"), """
            I–IV–V7–I en Do mayor → ii–V7–I en Sol mayor
              Do        I         tónica
              Fa        IV        subdominante
              Sol7      V7        dominante
              Do        I         tónica
            De Do mayor a Sol mayor en el acorde 5 (pivote: Lam = vi en Do mayor = ii en Sol mayor)
              Lam       ii        subdominante
              Re7       V7        dominante
              Sol       I         tónica
            Cadencia auténtica V7–I (acordes 3 → 4)
            Cadencia auténtica V7–I (acordes 6 → 7)

            """)
        XCTAssertTrue(salida("analyze C G C F Dm E7 Am --ingles")
            .contains("From C major to A minor at chord 5 (pivot: Dm = ii in C major = iv in A minor)"))
        // Con la tonalidad dada no se buscan modulaciones.
        XCTAssertFalse(salida("analizar Do Fa Sol7 Do Lam Re7 Sol --en Do mayor").contains("De Do mayor a"))
    }

    func testArmonizar() {
        XCTAssertEqual(salida("armonizar Mi4 Fa4 Re4 Do4"), """
            Do mayor
              1. Do Fa Sol Do (I–IV–V–I)
              2. Do Fa Sol7 Do (I–IV–V7–I)
              3. Do Rem Sol Do (I–ii–V–I)
            A cuatro voces (bajo, tenor, contralto, soprano):
              Do        I         Do3 Sol3 Do4 Mi4
              Fa        IV        Fa2 La3 Do4 Fa4
              Sol       V         Sol2 Sol3 Si3 Re4
              Do        I         Do3 Mi3 Do4 Do4

            """)
        // Sin octavas, solo los acordes; con --propuestas, cuántos.
        XCTAssertEqual(salida("armonizar Mi Re Do --propuestas 1"), "Do mayor\n  1. Do Sol Do (I–V–I)\n")
        XCTAssertTrue(salida("armonizar Do Si La Sol# La --en La menor").hasPrefix("La menor\n  1. Lam Mi Lam Mi Lam (i–V–i–V–i)"))
        XCTAssertTrue(salida("harmonize E D C --ingles").hasPrefix("C major\n  1. C G C (I–V–I)"))
        // El coral lleva la melodía en el soprano y pasa la revisión.
        let lineas = salida("armonizar Do5 Si4 La4 Sol4 Fa4 Mi4 Re4 Do4").split(separator: "\n")
        let voces = lineas.drop { !$0.hasPrefix("A cuatro voces") }.dropFirst()
            .map { $0.split(separator: " ").suffix(4).joined(separator: " ") }
        XCTAssertEqual(voces.count, 8)
        XCTAssertEqual(voces.map { $0.split(separator: " ").last! }, ["Do5", "Si4", "La4", "Sol4", "Fa4", "Mi4", "Re4", "Do4"])
        XCTAssertEqual(salida("revisar " + voces.joined(separator: ", ")), "Sin faltas de conducción.\n")
        // Fuera de la tesitura del soprano no hay coral.
        XCTAssertTrue(salida("armonizar Do6 Si5 Do6").hasSuffix("No hay ninguna realización sin faltas de conducción.\n"))
    }

    func testRealizar() {
        XCTAssertEqual(salida("realizar Do Fa Sol7 Do"), """
            Do mayor
              Do        I         Do3 Mi4 Sol4 Do5
              Fa        IV        Fa3 Fa4 La4 Do5
              Sol7      V7        Sol3 Fa4 Sol4 Si4
              Do        I         Do4 Mi4 Sol4 Do5

            """)
        XCTAssertTrue(salida("realize C F G7 C --ingles").hasPrefix("C major\n  C         I         C3 E4 G4 C5"))
        XCTAssertTrue(salida("realizar Lam Rem Mi7 Lam --en La menor").contains("V7"))
        XCTAssertEqual(salida("realizar Do7(9,13)"), "No hay ninguna realización sin faltas de conducción.\n")
    }

    func testVoces() {
        XCTAssertEqual(salida("revisar Do3 Sol3 Mi4 Do5, Re3 La3 Fa4 Re5"), """
            Quintas paralelas entre bajo y tenor (acordes 1 → 2)
            Octavas paralelas entre bajo y soprano (acordes 1 → 2)

            """)
        XCTAssertEqual(salida("revisar Do3 Mi4 Sol4 Do5 | Sol2 Re4 Sol4 Si4"), "Sin faltas de conducción.\n")
    }

    func testIngles() {
        XCTAssertTrue(salida("acorde G7/B --ingles").hasPrefix("G7/B: dominant seventh\n  notes: G B D F  (bass B, first inversion)"))
        XCTAssertTrue(salida("analizar C Am D7 G7 C --ingles").hasPrefix("I–vi–V7/V–V7–I in C major\n  C         I         tonic"))
        XCTAssertEqual(salida("revisar C3 E4 G4 C5, G2 D4 G4 B4 --ingles"), "No voice-leading errors.\n")
        XCTAssertTrue(salida("tonalidad D major --ingles").contains("key signature: F# C# (2 sharps)"))
    }

    /// Órdenes que terminan en un error de uso.
    private static let ordenesMalEscritas = [
        "foo", "acorde", "identificar", "intervalo C", "escala", "tonalidad", "analizar", "analizar C --en",
        "armonizar", "armonizar C --en", "armonizar C --propuestas 0", "realizar", "realizar C --en",
        "revisar", "conduccion-minima G7", "digitaciones", "digitaciones C --instrumento arpa", "digitaciones C --limite 0",
        "digitaciones C --dedos 9", "digitaciones C --traste 99", "digitaciones C --capo", "vecinos",
        "vecinos C7 --voces 3", "conduccion-parsimoniosa G7", "plr", "plr G7 P", "musicxml", "musicxml coral",
        "musicxml melodia C4:4 --foo 1", "midi acordes C --cifrados", "tonnetz", "tonnetz --clases 13",
        "tonnetz --camino C", "tabla --ciclo C", "tabla --margen 9 C",
    ]

    /// Con --ingles no se cuela nada en español: ni en la salida, ni en los errores, ni en la ayuda.
    func testConInglesNadaEnEspanol() {
        let enEspanol = ["«", "»", "á", "é", "í", "ó", "ú", "ñ", "notas", "acordes", "paso", "dedo", "cejilla",
                         "guitarra", "tríada", "Prueba", "falta"]
        func comprobar(_ texto: String, _ orden: String, file: StaticString = #filePath, line: UInt = #line) {
            for palabra in enEspanol where texto.contains(palabra) {
                XCTFail("«\(palabra)» en la salida de «\(orden)»:\n\(texto)", file: file, line: line)
            }
        }
        for orden in ["help", "acorde C/E", "acorde G7/B", "identificar C E Bb", "intervalo C4 E5", "escala Re dórico",
                      "tonalidad Re mayor", "tonalidad Mib mayor", "tonalidad Do mayor", "analizar C Am D7 G7 C",
                      "analizar C F G7 C Am D7 G", "armonizar E4 F4 D4 C4", "armonizar C6 B5 C6", "realizar C F G7 C",
                      "realizar C7(9,13)",
                      "revisar C3 E4 G4 C5, G2 D4 G4 B4", "plr C PLR", "plr C C", "plr C hexatonico",
                      "conduccion-parsimoniosa G7 Dm7", "vecinos G7", "digitaciones F --diagrama", "digitaciones C --instrumento ukelele",
                      "digitaciones C --instrumento bajo --dedos 1 --traste 0"] {
            let resultado = LineaDeComandos.ejecutar((orden + " --ingles").split(separator: " ").map(String.init))
            XCTAssertEqual(resultado.codigo, 0, "\(orden): \(resultado.error)")
            comprobar(resultado.salida, orden)
        }
        for orden in Self.ordenesMalEscritas {
            let resultado = LineaDeComandos.ejecutar((orden + " --ingles").split(separator: " ").map(String.init))
            XCTAssertEqual(resultado.codigo, 2, orden)
            XCTAssertTrue(resultado.error.hasSuffix("Try \"armonia help\".\n"), "\(orden): \(resultado.error)")
            comprobar(resultado.error, orden)
        }
    }

    func testAyudaEnIngles() {
        for orden in ["--ingles", "ayuda --ingles", "help --english"] {
            XCTAssertTrue(salida(orden).hasPrefix("armonia: music theory"), orden)
        }
        XCTAssertTrue(salida("help --ingles").contains("fingerings <symbol>"))
        XCTAssertTrue(LineaDeComandos.ayuda(en: .espanol).hasPrefix("armonia: teoría musical"))
    }

    func testIdiomas() {
        XCTAssertEqual(salida("acorde Sol7/Si --idioma eu"), """
            Sol7/Si: dominanteko zazpigarrena
              notak: sol si re fa  (baxua si, lehen inbertsioa)
              sol oinarria · si hirugarrena · re bosgarrena · fa zazpigarrena

            """)
        XCTAssertTrue(salida("acorde Sol7/Si --idioma ca").contains("notes: sol si re fa  (baix si, primera inversió)"))
        XCTAssertTrue(salida("acorde Sol7/Si --idioma galego").contains("sol fundamental · si terceira"))
        XCTAssertTrue(salida("tonalidad Mib mayor --idioma gl").contains("(3 bemois)"))
        XCTAssertEqual(salida("--idioma en acorde C/G"), salida("acorde C/G --ingles"))
        XCTAssertEqual(salida("acorde Do --language es"), salida("acorde Do"))
        // La ayuda, en los ocho idiomas.
        XCTAssertTrue(salida("ayuda --idioma ca").hasPrefix("armonia: "))
        XCTAssertEqual(salida("ayuda --idioma ca"), LineaDeComandos.ajuda + "\n")
        XCTAssertEqual(salida("ayuda --idioma gl"), LineaDeComandos.axuda + "\n")
        XCTAssertEqual(salida("ayuda --idioma eu"), LineaDeComandos.laguntza + "\n")
        XCTAssertEqual(salida("ayuda --idioma pt"), LineaDeComandos.ajudaEmPortugues + "\n")
        XCTAssertEqual(salida("ayuda --idioma fr"), LineaDeComandos.aide + "\n")
        XCTAssertEqual(salida("ayuda --idioma italiano"), LineaDeComandos.aiuto + "\n")
        XCTAssertTrue(salida("acorde Sol7/Si --idioma fr").hasPrefix("Sol7/Si: septième de dominante\n"))
        XCTAssertTrue(salida("acorde Sol7/Si --idioma it").contains("(basso si, primo rivolto)"))
        XCTAssertTrue(salida("tonalidad Mib mayor --idioma pt").contains("(3 bemóis)"))
        XCTAssertTrue(salida("escala Re dórico --idioma fr").hasPrefix("ré dorien"))
        XCTAssertTrue(salida("help --idioma en").hasPrefix("armonia: music theory"))
        XCTAssertTrue(salida("acorde Sol7/Si --idioma ca").hasPrefix("Sol7/Si: sèptima de dominant\n"))
        XCTAssertTrue(salida("escala Re dórico --idioma eu").hasPrefix("re doriarra"))
        // Los errores de lectura los traduce el motor.
        XCTAssertTrue(resultado("acorde", "Do7(b3)", "--idioma", "eu").error.hasPrefix("Ezin da «Do7(b3)» irakurri"))
        XCTAssertEqual(resultado("digitaciones", "C", "--limite", "0", "--idioma", "eu").error,
                       "armonia: muga 1etik 200era bitarteko zenbaki bat da: --limite 5\nProbatu «armonia ayuda».\n")
        XCTAssertEqual(resultado("acorde", "Do", "--idioma", "de").codigo, 2)
        XCTAssertTrue(resultado("acorde", "Do", "--idioma", "de").error
                        .hasPrefix("armonia: idioma desconocido: «de» (es, en, ca, gl, eu, pt, fr o it)"))
        XCTAssertEqual(resultado("acorde", "Do", "--idioma").error,
                       "armonia: falta el valor de --idioma\nPrueba «armonia ayuda».\n")
        // Notas y textos por separado.
        XCTAssertTrue(salida("acorde Sol7/Si --idioma en --textos es").hasPrefix("G7/B: séptima de dominante\n"))
        XCTAssertTrue(salida("acorde Sol7/Si --textos fr").hasPrefix("Sol7/Si: septième de dominante\n"))
        XCTAssertTrue(salida("ayuda --idioma fr --textos es").contains("--textos"))
        XCTAssertEqual(resultado("acorde", "Do", "--textos", "xx").codigo, 2)
        XCTAssertEqual(resultado("acorde", "Do", "--textos").codigo, 2)
    }

    /// Con --idioma ca, gl, eu, pt, fr o it, los errores de uso no dejan nada en español.
    func testErroresEnCatalanGallegoEuskera() {
        let enEspanol = ["Prueba", "hace falta", "hacen falta", "desconocid", " es un", " sin ", " las ", " los "]
        for (idioma, ayuda) in [("ca", "Prova «armonia ayuda».\n"), ("gl", "Proba «armonia ayuda».\n"),
                                ("eu", "Probatu «armonia ayuda».\n"), ("pt", "Experimente «armonia ayuda».\n"),
                                ("fr", "Essayez « armonia ayuda ».\n"), ("it", "Prova «armonia ayuda».\n")] {
            for orden in Self.ordenesMalEscritas {
                let resultado = LineaDeComandos.ejecutar((orden + " --idioma " + idioma).split(separator: " ").map(String.init))
                XCTAssertEqual(resultado.codigo, 2, "\(orden) \(idioma)")
                XCTAssertTrue(resultado.error.hasSuffix(ayuda), "\(orden) \(idioma): \(resultado.error)")
                for palabra in enEspanol where resultado.error.contains(palabra) {
                    XCTFail("«\(palabra)» en «\(orden) --idioma \(idioma)»: \(resultado.error)")
                }
            }
        }
    }

    func testErroresEnIngles() {
        let error = resultado("digitaciones", "C", "--limite", "0", "--ingles").error
        XCTAssertEqual(error, "armonia: the limit is a number from 1 to 200: --limit 5\nTry \"armonia help\".\n")
        XCTAssertEqual(resultado("digitaciones", "C", "--limite", "0").error,
                       "armonia: el límite es un número de 1 a 200: --limite 5\nPrueba «armonia ayuda».\n")
        XCTAssertTrue(salida("digitaciones C --limite 1 --ingles").hasPrefix("C · guitar\n"))
        XCTAssertTrue(salida("tonalidad F major --ingles").contains("(1 flat)"))
        XCTAssertTrue(salida("tonalidad Fa mayor").contains("(1 bemol)"))
        XCTAssertTrue(salida("tonalidad Mib mayor").contains("(3 bemoles)"))
    }

    func testMIDI() throws {
        func datos(_ orden: String) throws -> [UInt8] {
            let resultado = LineaDeComandos.ejecutar(orden.split(separator: " ").map(String.init))
            XCTAssertEqual(resultado.codigo, 0, resultado.error)
            XCTAssertEqual(resultado.salida, "")
            return [UInt8](try XCTUnwrap(resultado.datos, orden))
        }
        let melodia = try datos("midi melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4 --tempo 90 --titulo Escala --programa 40")
        XCTAssertEqual(Array(melodia.prefix(4)), Array("MThd".utf8))
        XCTAssertTrue(melodia.count > 60)
        // El instrumento: cambio de programa 40 (violín) en la pista de la voz.
        XCTAssertNotNil(zip(melodia, melodia.dropFirst()).first { $0 == (0xC0, 40) })
        XCTAssertEqual(try datos("midi coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 --duracion 2").filter { $0 == 0x4D }.count, 6)   // MThd + 5 MTrk
        XCTAssertFalse(try datos("midi acordes Do Lam Re7 Sol7 Do --tempo 80").isEmpty)
        XCTAssertNil(LineaDeComandos.ejecutar(["musicxml", "melodia", "Do4:4"]).datos)
        for orden in ["midi", "midi melodia", "midi melodia Do4:4 --clave fa", "midi coral Do3 Do5 --cifrados",
                      "midi melodia Do4:4 --programa 200", "midi melodia Do4:4 --programa piano",
                      "midi melodia Do4:4 --instrumento 40",
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
        XCTAssertEqual(salida("conduccion-parsimoniosa Sol7 Rem7"), "Sol7 –Sol→Sol♯→ Sol♯°7 –Sol♯→La→ Sim7(♭5) –Si→Do→ Rem7\n3 pasos\n")
        XCTAssertEqual(salida("conduccion-parsimoniosa Sol7 Reb7 --voces 2"), "Sol7 –Sol→La♭, Re→Re♭→ Re♭7\n1 paso\n")
        XCTAssertEqual(salida("conduccion-minima Sol7 Do"), "Sol→Sol, Si→Do (+1), Re→Do (−2), Fa→Mi (−1): 4 semitonos\n")
        XCTAssertEqual(salida("vecinos Domaj7"), "Do♯m7(♭5) (Do→Do♯)\nDo7 (Si→Si♭)\n")
        XCTAssertTrue(salida("vecinos Sol7 --ampliada").contains("Solmaj7 (Fa→Fa♯)"))
        XCTAssertEqual(salida("conduccion-parsimoniosa Do7 Domaj7"), "Do7 –Si♭→Si→ Domaj7\n1 paso\n")
        for orden in ["vecinos", "vecinos Do6", "vecinos Do --ampliada", "vecinos Sol7 --voces 3", "conduccion-parsimoniosa Sol7", "conduccion-parsimoniosa Do Sol7", "conduccion-minima Sol7"] {
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
        XCTAssertEqual(salida("plr C Am --ingles"), "C –R→ Am\nR, 1 step\n")
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

        for orden in [["foo"], ["intervalo", "Do"], ["acorde"], ["analizar"], ["analizar", "Do", "--en"], ["revisar"]] {
            let resultado = LineaDeComandos.ejecutar(orden)
            XCTAssertEqual(resultado.codigo, 2, "\(orden)")
            XCTAssertTrue(resultado.error.hasSuffix("Prueba «armonia ayuda».\n"), "\(orden)")
        }
        XCTAssertEqual(LineaDeComandos.ejecutar(["revisar", "Do3", "Mi4,", "Sol2"]).codigo, 1)
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

    func testDigitacionesConDiagrama() {
        let lineas = salida("digitaciones Do --limite 1 --diagrama").split(separator: "\n").map(String.init)
        // Encabezado, la forma y una línea por cuerda.
        XCTAssertEqual(lineas.count, 1 + 1 + 6, lineas.joined(separator: "\n"))
        XCTAssertTrue(lineas.dropFirst(2).allSatisfy { $0.contains("|-") })
        // La cuerda más aguda va arriba.
        XCTAssertTrue(lineas[2].contains("Mi"), lineas[2])
    }

    func testTabSigueSiendoElDiagrama() {
        XCTAssertEqual(salida("digitaciones Do --limite 1 --tab"), salida("digitaciones Do --limite 1 --diagrama"))
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
        XCTAssertTrue(salida("digitaciones Do7 --limite 200").contains("  x32310"))
        XCTAssertFalse(salida("digitaciones Do7 --limite 200 --completo").contains("  x32310"))
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
