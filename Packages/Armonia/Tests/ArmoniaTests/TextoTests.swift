import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class ErroresTests: XCTestCase {
    /// Comprueba que leer `texto` lanza el motivo indicado en la posición indicada.
    private func comprobar<T>(_ leer: @autoclosure () throws -> T, _ motivo: ErrorDeLectura.Motivo,
                              posicion: Int?, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try leer(), file: file, line: line) { error in
            guard let error = error as? ErrorDeLectura else {
                return XCTFail("Error inesperado: \(error)", file: file, line: line)
            }
            XCTAssertEqual(error.motivo, motivo, file: file, line: line)
            XCTAssertEqual(error.posicion, posicion, file: file, line: line)
        }
    }

    func testAcordes() {
        comprobar(try Acorde(leyendo: "Do7(b3)"), .tensionNoValida("b3"), posicion: 4)
        comprobar(try Acorde(leyendo: "Do7 9"), .numeroRepetido(9), posicion: 4)
        comprobar(try Acorde(leyendo: "Doxyz"), .simboloNoReconocido("yz"), posicion: 3)
        comprobar(try Acorde(leyendo: "Do/Xa"), .bajoNoValido("Xa"), posicion: 3)
        comprobar(try Acorde(leyendo: "Do8"), .numeroDeAcordeNoValido(8), posicion: 2)
        comprobar(try Acorde(leyendo: "Doomit1"), .gradoNoOmitible(1), posicion: 2)
        comprobar(try Acorde(leyendo: "Doadd3"), .tensionNoValida("3"), posicion: 5)
        comprobar(try Acorde(leyendo: "Hm7"), .notaNoReconocida, posicion: 0)
        comprobar(try Acorde(leyendo: "   "), .textoVacio, posicion: 0)
        XCTAssertThrowsError(try Acorde(leyendo: "Dodimø")) { error in
            guard case .calidadesIncompatibles = (error as? ErrorDeLectura)?.motivo else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertThrowsError(try Acorde(leyendo: "Dom5")) { error in
            XCTAssertNil((error as? ErrorDeLectura)?.posicion)
        }
    }

    func testConjuntosNoInterpretables() {
        XCTAssertThrowsError(try TipoDeAcorde(comprobandoPasosDeQuinta: [0, -3, 4])) { error in
            XCTAssertTrue("\(error)".contains("tercera mayor y menor"), "\(error)")
        }
        XCTAssertThrowsError(try TipoDeAcorde(comprobandoPasosDeQuinta: [0, 4, 7])) { error in
            XCTAssertTrue("\(error)".contains("1ª aumentada no tiene papel"), "\(error)")
        }
        XCTAssertThrowsError(try TipoDeAcorde(comprobandoPasosDeQuinta: [4, 1])) { error in
            XCTAssertTrue("\(error)".contains("falta la fundamental"), "\(error)")
        }
        XCTAssertNoThrow(try TipoDeAcorde(comprobandoPasosDeQuinta: [0, 4, 1]))
    }

    func testNotasIntervalosYEscalas() {
        comprobar(try Nota(leyendo: "Fa#4"), .caracteresSobrantes("4"), posicion: 3)
        comprobar(try Nota(leyendo: ""), .textoVacio, posicion: 0)
        comprobar(try Altura(leyendo: "Do"), .octavaNoValida(""), posicion: 2)
        comprobar(try Altura(leyendo: "Do4x"), .octavaNoValida("4x"), posicion: 2)
        comprobar(try Intervalo(leyendo: "5M"), .intervaloInexistente(numero: 5, calidad: .mayor), posicion: 0)
        comprobar(try Intervalo(leyendo: "3X"), .calidadNoValida("X"), posicion: 1)
        comprobar(try Intervalo(leyendo: "X3"), .numeroDeIntervaloNoValido("X3"), posicion: 0)
        comprobar(try Intervalo(leyendo: "M"), .numeroDeIntervaloNoValido(""), posicion: 1)
        comprobar(try Escala(leyendo: "Re dorian"), .tipoDeEscalaNoReconocido("dorian"), posicion: 3)
    }

    func testMensajes() {
        do {
            _ = try Acorde(leyendo: "Do7(b3)")
            XCTFail("Debería fallar")
        } catch {
            XCTAssertTrue("\(error)".hasPrefix("No se puede leer «Do7(b3)» (carácter 5): «b3» no es una tensión válida"),
                          "\(error)")
        }
        let error = ErrorDeLectura(texto: "5M", posicion: 0, motivo: .intervaloInexistente(numero: 5, calidad: .mayor))
        XCTAssertTrue(error.explicacion.contains("justas, aumentadas o disminuidas"))
    }

    func testDecodificacionConMensaje() {
        XCTAssertThrowsError(try JSONDecoder().decode([Acorde].self, from: Data("[\"Doxyz\"]".utf8))) { error in
            guard case DecodingError.dataCorrupted(let contexto) = error else { return XCTFail("\(error)") }
            XCTAssertTrue(contexto.debugDescription.contains("«yz»"), contexto.debugDescription)
        }
    }

    func testMensajesEnIngles() throws {
        XCTAssertThrowsError(try Acorde(leyendo: "Do7(b3)")) { error in
            let error = error as! ErrorDeLectura
            XCTAssertEqual(error.descripcion(en: .ingles),
                           "Cannot read \"Do7(b3)\" (character 5): \"b3\" is not a valid tension "
                           + "(♭/♯ go with 5, 9, 11 and 13, and add with 2, 4, 6, 9, 11 and 13)")
            XCTAssertEqual(error.descripcion(en: .espanol), error.description)
            // El idioma lo da la notación: el alemán usa el inglés.
            XCTAssertEqual(error.explicacion(en: .aleman), error.explicacion(en: .ingles))
            XCTAssertEqual(error.descripcion(en: .portugues),
                           "Não é possível ler «Do7(b3)» (caractere 5): «b3» não é uma tensão válida "
                           + "(admitem-se ♭/♯ com 5, 9, 11 e 13, e add com 2, 4, 6, 9, 11 e 13)")
            XCTAssertEqual(error.descripcion(en: .frances),
                           "Impossible de lire « Do7(b3) » (caractère 5) : « b3 » n'est pas une tension valide "
                           + "(♭/♯ s'emploient avec 5, 9, 11 et 13, et add avec 2, 4, 6, 9, 11 et 13)")
            XCTAssertEqual(error.descripcion(en: .italiano),
                           "Impossibile leggere «Do7(b3)» (carattere 5): «b3» non è una tensione valida "
                           + "(si ammettono ♭/♯ con 5, 9, 11 e 13, e add con 2, 4, 6, 9, 11 e 13)")
            XCTAssertEqual(error.descripcion(en: .catalan),
                           "No es pot llegir «Do7(b3)» (caràcter 5): «b3» no és una tensió vàlida "
                           + "(s'admeten ♭/♯ amb 5, 9, 11 i 13, i add amb 2, 4, 6, 9, 11 i 13)")
            XCTAssertEqual(error.descripcion(en: .gallego),
                           "Non se pode ler «Do7(b3)» (carácter 5): «b3» non é unha tensión válida "
                           + "(admítense ♭/♯ con 5, 9, 11 e 13, e add con 2, 4, 6, 9, 11 e 13)")
            XCTAssertEqual(error.descripcion(en: .euskera),
                           "Ezin da «Do7(b3)» irakurri (5. karakterea): «b3» ez da tentsio baliozkoa "
                           + "(♭/♯ 5, 9, 11 eta 13rekin onartzen dira, eta add 2, 4, 6, 9, 11 eta 13rekin)")
        }
        XCTAssertThrowsError(try Intervalo(leyendo: "5M")) { error in
            XCTAssertEqual((error as! ErrorDeLectura).explicacion(en: .ingles),
                           "there is no major 5th: unisons, 4ths, 5ths and octaves are perfect, augmented or diminished")
        }
        XCTAssertThrowsError(try TipoDeAcorde(comprobandoPasosDeQuinta: [0, 7])) { error in
            XCTAssertEqual((error as! ErrorDeLectura).explicacion(en: .ingles),
                           "the augmented unison has no role in a tertian chord")
        }
        XCTAssertEqual(ErrorDeLectura(texto: "", posicion: nil, motivo: .textoVacio).descripcion(en: .ingles),
                       "Invalid value: the text is empty")
        XCTAssertEqual([1, 2, 3, 4, 11, 12, 13, 21, 22].map(ErrorDeLectura.ordinalIngles),
                       ["1st", "2nd", "3rd", "4th", "11th", "12th", "13th", "21st", "22nd"])
    }

    private static let motivos: [ErrorDeLectura.Motivo] = [
            .textoVacio, .notaNoReconocida, .caracteresSobrantes("x"), .octavaNoValida(""), .octavaNoValida("x"),
            .numeroDeIntervaloNoValido(""), .numeroDeIntervaloNoValido("x"), .calidadNoValida(""),
            .calidadNoValida("X"), .intervaloInexistente(numero: 1, calidad: .disminuida(1)),
            .intervaloInexistente(numero: 3, calidad: .justa), .simboloNoReconocido("x"), .tensionNoValida("b3"),
            .numeroDeAcordeNoValido(8), .numeroRepetido(9), .calidadesIncompatibles(.disminuidoYSemidisminuido),
            .calidadesIncompatibles(.quintaConCalidad), .gradoNoOmitible(1), .gradoNoOmitible(2),
            .acordeNoInterpretable(.faltaLaFundamental), .acordeNoInterpretable(.intervaloSinPapel(.unisonoAumentado)),
            .acordeNoInterpretable(.terceraMayorYMenor), .acordeNoInterpretable(.variasSeptimas),
            .acordeNoInterpretable(.septimaDisminuidaFueraDelDisminuido), .acordeNoInterpretable(.noEsPorTerceras),
            .bajoNoValido("x"), .idiomasMezclados("B"), .tipoDeEscalaNoReconocido(""),
            .tipoDeEscalaNoReconocido("x"), .modoNoReconocido("dórico"), .alteracionNoReconocida("?"),
            .duracionNoValida("x"), .compasNoValido("x"), .vocesDistintas,
        ]

    /// Todos los motivos tienen explicación en inglés, y la inglesa no lleva texto en español.
    func testTodosLosMotivosEnLosDosIdiomas() {
        let motivos = Self.motivos
        let espanol = ["el ", "la ", " no ", "falta", "sobra", "se esperaba", "tiene", "texto"]
        for motivo in motivos {
            let error = ErrorDeLectura(texto: "x", posicion: 0, motivo: motivo)
            let ingles = error.explicacion(en: .ingles)
            XCTAssertFalse(ingles.isEmpty, "\(motivo)")
            XCTAssertNotEqual(ingles, error.explicacion, "\(motivo)")
            XCTAssertFalse(ingles.contains("«"), "\(motivo): \(ingles)")
            for palabra in espanol where ingles.hasPrefix(palabra) || ingles.contains(" " + palabra) {
                XCTFail("\(motivo): «\(palabra)» en «\(ingles)»")
            }
        }
    }

    /// Todos los motivos tienen explicación en catalán, gallego, euskera, portugués, francés e
    /// italiano, con los mismos datos entre comillas latinas que la española.
    func testTodosLosMotivosEnCatalanGallegoEuskera() throws {
        let comillas = try NSRegularExpression(pattern: "«[^»]*»")
        func citas(_ texto: String) -> [String] {
            comillas.matches(in: texto, range: NSRange(texto.startIndex..., in: texto))
                .map { String(texto[Range($0.range, in: texto)!]) }
                // En francés, las comillas llevan espacios: « x ».
                .map { "«" + $0.dropFirst().dropLast().trimmingCharacters(in: .whitespaces) + "»" }
        }
        for motivo in Self.motivos {
            let error = ErrorDeLectura(texto: "x", posicion: 0, motivo: motivo)
            let espanol = error.explicacion
            for notacion in [Nomenclatura.catalan, .gallego, .euskera, .portugues, .frances, .italiano] {
                let texto = error.explicacion(en: notacion)
                XCTAssertFalse(texto.isEmpty, "\(motivo) \(notacion)")
                XCTAssertEqual(Set(citas(texto)), Set(citas(espanol)), "\(motivo) \(notacion): \(texto)")
            }
            for notacion in [Nomenclatura.euskera, .frances, .italiano] {
                XCTAssertNotEqual(error.explicacion(en: notacion), espanol, "\(motivo) \(notacion)")
            }
        }
        XCTAssertEqual(ErrorDeLectura(texto: "", posicion: nil, motivo: .textoVacio).descripcion(en: .gallego),
                       "Valor non válido: o texto está baleiro")
        XCTAssertEqual(ErrorDeLectura(texto: "x", posicion: nil, motivo: .intervaloInexistente(numero: 5, calidad: .mayor))
                        .explicacion(en: .euskera),
                       "5. handia ez da existitzen: unisonoa, 4.a, 5.a eta 8.a justuak, gehituak edo gutxituak dira")
    }

    func testLosFallablesSiguenDevolviendoNil() {
        XCTAssertNil(Acorde(texto: "Do7(b3)"))
        XCTAssertNil(Nota(texto: "Fa#4"))
        XCTAssertNil(Intervalo(texto: "5M"))
        XCTAssertNil(Escala(texto: "Re dorian"))
    }

    func testLecturaYErrores() {
        XCTAssertNoThrow(try Acorde(leyendo: "Sol7"))
        XCTAssertThrowsError(try Acorde(leyendo: "Do7(b3)")) { error in
            XCTAssertEqual((error as? ErrorDeLectura)?.motivo, .tensionNoValida("b3"))
        }
    }
}

final class NotacionInternacionalTests: XCTestCase {
    func testNotas() {
        XCTAssertEqual(Nota("Fa#").nombre(en: .ingles), "F#")
        XCTAssertEqual(Nota("Fa#").nombre(en: .inglesUnicode), "F♯")
        XCTAssertEqual(Nota("Sibb").nombre(en: .inglesUnicode), "B♭♭")
        XCTAssertEqual(Nota("B♭"), Nota("Sib"))
        XCTAssertEqual(Altura("C#4"), Altura("Do#4"))
        XCTAssertEqual(Altura("Sib3").nombre(en: .ingles), "Bb3")
        XCTAssertEqual(Altura("Sib3").nombre(en: .inglesUnicode), "B♭3")
        XCTAssertEqual(Altura("B♭3"), Altura("Sib3"))
    }

    func testIntervalos() {
        XCTAssertEqual(Intervalo.terceraMayor.abreviatura(en: .ingles), "M3")
        XCTAssertEqual(Intervalo.quintaJusta.abreviatura(en: .ingles), "P5")
        XCTAssertEqual((-Intervalo.cuartaAumentada).abreviatura(en: .ingles), "-A4")
        XCTAssertEqual(Intervalo("M3"), .terceraMayor)
        XCTAssertEqual(Intervalo("P8"), .octava)
        XCTAssertEqual(Intervalo("-m3"), -Intervalo.terceraMenor)
        XCTAssertEqual(Intervalo("AA4"), Intervalo(numero: 4, calidad: .aumentada(2)))
        XCTAssertEqual(Intervalo("dd5"), Intervalo(numero: 5, calidad: .disminuida(2)))

        XCTAssertEqual(Intervalo.terceraMayor.nombre(en: .ingles), "major third")
        XCTAssertEqual(Intervalo.quintaJusta.nombre(en: .ingles), "perfect fifth")
        XCTAssertEqual(Intervalo.octava.nombre(en: .ingles), "perfect octave")
        XCTAssertEqual(Intervalo.unisonoAumentado.nombre(en: .ingles), "augmented unison")
        XCTAssertEqual(Intervalo.novenaMenor.nombre(en: .ingles), "minor ninth")
        XCTAssertEqual((-Intervalo.sextaMenor).nombre(en: .ingles), "descending minor sixth")
        XCTAssertEqual(Intervalo(numero: 4, calidad: .aumentada(2))!.nombre(en: .ingles), "doubly augmented fourth")
        XCTAssertEqual(Intervalo.ordinalEnIngles(21), "21st")
        XCTAssertEqual(Intervalo.ordinalEnIngles(22), "22nd")
        XCTAssertEqual(Intervalo.ordinalEnIngles(23), "23rd")
        XCTAssertEqual(Intervalo.ordinalEnIngles(111), "111th")
    }

    func testEscalas() {
        XCTAssertEqual(Escala("D dorian"), Escala("Re dórico"))
        XCTAssertEqual(Escala("Bb harmonic minor"), Escala(Nota("Sib"), .menorArmonica))
        XCTAssertEqual(Escala("A minor").tipo, .menorNatural)
        XCTAssertEqual(Escala("F# whole-tone").tipo, .tonosEnteros)
        XCTAssertEqual(Escala("C Major Pentatonic").tipo, .pentatonicaMayor)
        XCTAssertEqual(Escala(.re, .dorico).nombre(en: .ingles), "D dorian")
        XCTAssertEqual(Escala("Mib menor armónica").nombre(en: .inglesUnicode), "E♭ harmonic minor")
        XCTAssertEqual(Escala(.do, TipoDeEscala.pentatonicaMayor.rotacion(3)).nombre(en: .ingles),
                       "C pentatónica mayor, modo 3")
        XCTAssertEqual(Escala(.do, TipoDeEscala.pentatonicaMayor.rotacion(2)).nombre(en: .ingles), "C Egyptian")
        for tipo in TipoDeEscala.todos {
            let escala = Escala("F#", tipo)
            XCTAssertEqual(Escala(texto: escala.nombre(en: .ingles)), escala, escala.nombre(en: .ingles))
            XCTAssertEqual(Escala(texto: escala.nombre(en: .inglesUnicode)), escala)
        }
    }

    func testAcordes() {
        let acorde: Acorde = "Sol7/Si"
        XCTAssertEqual(acorde.cifrado(en: .ingles), "G7/B")
        XCTAssertEqual(acorde.nombre(en: .ingles), "G dominant seventh, first inversion")
        XCTAssertEqual(Acorde("Do/Re").nombre(en: .ingles), "C major over D")
        XCTAssertEqual(Acorde("Sib7(b9)/Re").cifrado(estilo: .inglesUnicode), "B♭7(♭9)/D")
        XCTAssertEqual(Acorde("B♭7(♭9)/D"), Acorde("Sib7(b9)/Re"))
        XCTAssertEqual(TipoDeAcorde.semidisminuido.nombre(en: .ingles), "half-diminished seventh")
        XCTAssertEqual(TipoDeAcorde("7(b9,#11)").nombre(en: .ingles), "7(b9,#11) chord")
        // " chord" solo lo añaden los tipos sin nombre conocido; "power chord" es el nombre propio.
        for tipo in TipoDeAcorde.todos where tipo != .potencia {
            XCTAssertFalse(tipo.nombre(en: .ingles).hasSuffix(" chord"), tipo.nombre)
        }
    }

    func testNotacionUnica() {
        XCTAssertEqual(Nomenclatura(idioma: .espanol, ascii: true), .espanolASCII)
        XCTAssertEqual(Nomenclatura(idioma: .ingles, ascii: false), .inglesUnicode)
        XCTAssertEqual(Nomenclatura.ingles.idioma, .ingles)
        XCTAssertTrue(Nomenclatura.ingles.usaASCII)
        XCTAssertFalse(Nomenclatura.espanol.usaASCII)

        let escala: Escala = "Fa# dórico"
        XCTAssertEqual(escala.nombre(en: .espanol), "Fa♯ dórico")
        XCTAssertEqual(escala.nombre(en: .espanolASCII), "Fa# dórico")
        XCTAssertEqual(escala.nombre(en: .ingles), "F# dorian")
        XCTAssertEqual(escala.nombre(en: .inglesUnicode), "F♯ dorian")
        XCTAssertEqual(Altura("Sib3").nombre(en: .inglesUnicode), "B♭3")
        XCTAssertEqual(Acorde("Sol7/Si").nombre(en: .inglesUnicode), "G dominant seventh, first inversion")
        XCTAssertEqual(Acorde("Fa#7").nombre(en: .inglesUnicode), "F♯ dominant seventh, root position")
        XCTAssertEqual(Intervalo.quintaJusta.abreviatura(en: .ingles), "P5")
        XCTAssertEqual(Intervalo.quintaJusta.abreviatura(en: .espanol), "5J")
    }
}

final class OtrasNotacionesTests: XCTestCase {
    func testAleman() {
        let casos: [(String, String)] = [("Do", "C"), ("Fa#", "Fis"), ("Dob", "Ces"), ("Mib", "Es"), ("Mibb", "Eses"),
                                         ("Lab", "As"), ("Labb", "Asas"), ("Sib", "B"), ("Sibb", "Heses"), ("Si", "H"),
                                         ("Si#", "His"), ("Rex", "Disis"), ("Solb", "Ges")]
        for (espanol, aleman) in casos {
            let nombre = Nota(texto: espanol)!
            XCTAssertEqual(nombre.nombre(en: .aleman), aleman, espanol)
            XCTAssertEqual(try Nota(leyendo: aleman, en: .aleman), nombre, aleman)
        }
        XCTAssertEqual(try Nota(leyendo: "fis", en: .aleman), Nota("Fa#"))
        XCTAssertEqual(Altura("Fa#4").nombre(en: .aleman), "Fis4")
        XCTAssertEqual(try Altura(leyendo: "B3", en: .aleman), Altura("Sib3"))
        XCTAssertEqual(Acorde("Sib7").cifrado(en: .aleman), "B7")
        XCTAssertEqual(Acorde("Sim7").cifrado(en: .aleman), "Hm7")
        XCTAssertEqual(Acorde("Fa#7(b9)").cifrado(en: .aleman), "Fis7(b9)")
        XCTAssertEqual(Tonalidad("Fa# mayor").nombre(en: .aleman), "Fis-Dur")
        XCTAssertEqual(Tonalidad("La menor").nombre(en: .aleman), "a-Moll")
        XCTAssertEqual(Tonalidad("Sib mayor").nombre(en: .aleman), "B-Dur")
        XCTAssertEqual(Tonalidad("Fis-Dur"), Tonalidad("Fa# mayor"))
        XCTAssertEqual(Tonalidad("es-Moll"), Tonalidad("Mib menor"))
        XCTAssertEqual(Alteracion(2).nombre(en: .aleman), "Doppelkreuz")
        XCTAssertEqual(Alteracion(-1).nombre(en: .aleman), "Be")
        XCTAssertThrowsError(try Nota(leyendo: "Xis", en: .aleman))
    }

    func testFrancesEItaliano() {
        XCTAssertEqual(Nota("Re").nombre(en: .frances), "ré")
        XCTAssertEqual(Nota("Mib").nombre(en: .frances), "mi bémol")
        XCTAssertEqual(Nota("Fa#").nombre(en: .frances), "fa dièse")
        XCTAssertEqual(Nota("Dox").nombre(en: .frances), "do double dièse")
        XCTAssertEqual(Nota("Mib").nombre(en: .italiano), "mi bemolle")
        XCTAssertEqual(Nota("Re#").nombre(en: .italiano), "re diesis")
        XCTAssertEqual(Nota("Sibb").nombre(en: .italiano), "si doppio bemolle")
        XCTAssertEqual(Nota("Reb").nombreCompacto(en: .frances), "Ré♭")
        XCTAssertEqual(Nota("Reb").nombreCompacto(en: .italiano), "Re♭")
        XCTAssertEqual(Altura("Fa#3").nombre(en: .frances), "fa dièse 3")
        XCTAssertEqual(Altura("Re4").nombre(en: .frances), "ré4")
        XCTAssertEqual(try Altura(leyendo: "fa dièse 3", en: .frances), Altura("Fa#3"))
        XCTAssertEqual(try Altura(leyendo: "re diesis 5", en: .italiano), Altura("Re#5"))
        XCTAssertEqual(try Nota(leyendo: "RE BEMOL", en: .frances), Nota("Reb"))
        XCTAssertEqual(try Nota(leyendo: "Ré♭", en: .frances), Nota("Reb"))
        XCTAssertEqual(Acorde("Fa#m7").cifrado(en: .frances), "Fa♯m7")
        XCTAssertEqual(Acorde("Rebmaj7").cifrado(en: .frances), "Ré♭maj7")
        XCTAssertEqual(Tonalidad("Reb mayor").nombre(en: .frances), "ré bémol majeur")
        XCTAssertEqual(Tonalidad("Fa# menor").nombre(en: .italiano), "fa diesis minore")
        XCTAssertEqual(Tonalidad("ré bémol majeur"), Tonalidad("Reb mayor"))
        XCTAssertEqual(Tonalidad("la minore"), Tonalidad("La menor"))
        XCTAssertEqual(Alteracion(-2).nombre(en: .frances), "double bémol")
        XCTAssertEqual(Alteracion(1).nombre(en: .italiano), "diesis")
        XCTAssertEqual(Alteracion.natural.nombre(en: .italiano), "bequadro")
        XCTAssertEqual(Alteracion("bémol"), .bemol)
        XCTAssertEqual(Alteracion("doppio diesis"), .dobleSostenido)
    }

    func testCatalanGallegoEuskera() {
        let casos: [(String, String, String, String)] = [
            ("Fa#", "fa sostingut", "fa sostido", "fa diesa"),
            ("Sib", "si bemoll", "si bemol", "si bemol"),
            ("Dox", "do doble sostingut", "do dobre sostido", "do diesa bikoitza"),
            ("Mibb", "mi doble bemoll", "mi dobre bemol", "mi bemol bikoitza"),
            ("Re", "re", "re", "re"),
        ]
        for (espanol, catalan, gallego, euskera) in casos {
            let nombre = Nota(texto: espanol)!
            XCTAssertEqual(nombre.nombre(en: .catalan), catalan)
            XCTAssertEqual(nombre.nombre(en: .gallego), gallego)
            XCTAssertEqual(nombre.nombre(en: .euskera), euskera)
            // Se leen también sin indicar la notación.
            for texto in [catalan, gallego, euskera] {
                XCTAssertEqual(Nota(texto: texto), nombre, texto)
            }
        }
        XCTAssertEqual(Nota("Reb").nombreCompacto(en: .catalan), "Re♭")
        XCTAssertEqual(Acorde("Fa#m7").cifrado(en: .gallego), "Fa♯m7")
        XCTAssertEqual(Altura("Fa#3").nombre(en: .catalan), "fa sostingut 3")
        XCTAssertEqual(Altura("fa sostido 3"), Altura("Fa#3"))
        XCTAssertEqual(Altura("si bemol bikoitza 2"), Altura("Sibb2"))
        XCTAssertEqual(Tonalidad("Reb mayor").nombre(en: .catalan), "re bemoll major")
        XCTAssertEqual(Tonalidad("Reb mayor").nombre(en: .gallego), "re bemol maior")
        XCTAssertEqual(Tonalidad("La menor").nombre(en: .euskera), "la minorra")
        XCTAssertEqual(Tonalidad("re bemoll major"), Tonalidad("Reb mayor"))
        XCTAssertEqual(Tonalidad("re bemol maior"), Tonalidad("Reb mayor"))
        XCTAssertEqual(Tonalidad("fa diesa minorra"), Tonalidad("Fa# menor"))
        // Las abreviaturas de los intervalos, como en español; los nombres de los catálogos, traducidos.
        XCTAssertEqual(Nomenclatura.catalan.vocabulario, .espanol)
        XCTAssertEqual(Escala(.re, .dorico).nombre(en: .euskera), "re doriarra")
        XCTAssertEqual(Escala("Reb dórico").nombre(en: .catalan), "re bemoll dòric")
        XCTAssertEqual(Escala("re bemoll dórico"), Escala("Reb dórico"))
        XCTAssertEqual(Escala("re bemoll dòric"), Escala("Reb dórico"))
        XCTAssertEqual(Escala("fa sostido menor armónica"), Escala("Fa# menor armónica"))
        XCTAssertEqual(Intervalo.terceraMayor.nombre(en: .gallego), "3ª maior")
        XCTAssertEqual(Alteracion(1).nombre(en: .catalan), "sostingut")
        XCTAssertEqual(Alteracion(-2).nombre(en: .gallego), "dobre bemol")
        XCTAssertEqual(Alteracion(2).nombre(en: .euskera), "diesa bikoitza")
        XCTAssertEqual(Alteracion("sostingut"), .sostenido)
        XCTAssertEqual(Alteracion("diesa bikoitza"), .dobleSostenido)
        // Los errores de siempre no cambian.
        XCTAssertNil(Nota(texto: "Fa#4"))
        XCTAssertNil(Altura(texto: "Do"))
    }

    /// Los textos del motor que no son nombres de nota, en catalán, gallego y euskera.
    func testTextosEnCatalanGallegoEuskera() throws {
        XCTAssertEqual(Nomenclatura.catalan.idiomaDeLosTextos, .catalan)
        XCTAssertEqual(Nomenclatura.aleman.idiomaDeLosTextos, .ingles)
        XCTAssertEqual(Nomenclatura.portugues.idiomaDeLosTextos, .portugues)
        XCTAssertEqual(Nomenclatura.espanolASCII.idiomaDeLosTextos, .espanol)

        let sexta = try Intervalo(leyendo: "-6m")
        XCTAssertEqual(sexta.nombre, "6ª menor descendente")
        XCTAssertEqual(sexta.nombre(en: .catalan), "6a menor descendent")
        XCTAssertEqual(sexta.nombre(en: .gallego), "6ª menor descendente")
        XCTAssertEqual(sexta.nombre(en: .euskera), "beheranzko 6. txikia")
        XCTAssertEqual(Intervalo.terceraMayor.nombre(en: .catalan), "3a major")
        XCTAssertEqual(Intervalo.terceraMayor.nombre(en: .euskera), "3. handia")
        XCTAssertEqual(CalidadDeIntervalo.aumentada(2).nombre(en: .euskera), "bi aldiz gehitua")
        XCTAssertEqual(CalidadDeIntervalo.disminuida(1).nombre(en: .catalan), "disminuïda")
        XCTAssertEqual(CalidadDeIntervalo.justa.nombre(en: .gallego), "xusta")
        XCTAssertEqual(Consonancia.imperfecta.nombre(en: .catalan), "consonància imperfecta")
        XCTAssertEqual(PapelEnAcorde.fundamental.nombre(en: .euskera), "oinarria")
        XCTAssertEqual(PapelEnAcorde.tension(11).nombre(en: .catalan), "onzena")
        XCTAssertEqual(CalidadDeTriada.disminuida.nombre(en: .gallego), "diminuída")
        XCTAssertEqual(NombreDeGrado.sensible.nombre(en: .euskera), "sentsiblea")
        XCTAssertEqual(FuncionTonal.dominante.nombre(en: .catalan), "dominant")
        XCTAssertEqual(Clave.fa.nombre(en: .gallego), "clave de fa")
        XCTAssertEqual(Clave.sol.nombre(en: .euskera), "sol giltza")
        XCTAssertEqual(Duracion(.negra, puntillos: 1).nombre(en: .catalan), "negra amb punt")
        XCTAssertEqual(Duracion(.corchea, puntillos: 1).nombre(en: .euskera), "kortxea puntuduna")
        XCTAssertEqual(Figura.blanca.nombre(en: .gallego), "branca")
        XCTAssertEqual(CorrespondenciaDeColores.circuloDeQuintas.nombre(en: .euskera), "bosgarrenen zirkulua")
        XCTAssertEqual(Cadencia.Tipo.semicadencia.nombre(en: .euskera), "erdi-kadentzia")
        XCTAssertEqual(ProblemaDeConduccion.Tipo.quintasParalelas.nombre(en: .catalan), "Quintes paral·leles")
        XCTAssertEqual(Tonalidad(.do).analizar(["Do", "Fa", "Sol7", "Do"]).nombre(en: .euskera), "I–IV–V7–I do maiorrean")
        XCTAssertEqual(Tonalidad(.la, .menor).analizar(["Lam", "Mi7", "Lam"]).nombre(en: .catalan),
                       "i–V7–i en la menor")
        // En alemán, en inglés.
        XCTAssertEqual(Intervalo.terceraMayor.nombre(en: .aleman), "major third")
        // Los catálogos también.
        XCTAssertEqual(Acorde("Sol7").nombre(en: .euskera), "sol dominanteko zazpigarrena, oinarrizko egoera")
        // Todas las traducciones tienen los ocho textos; el alemán, el occitano, el ruso y el griego
        // toman el inglés.
        let t = Traduccion("es", "en", ca: "ca", gl: "gl", eu: "eu", pt: "pt", fr: "fr", it: "it")
        XCTAssertEqual(Nomenclatura.allCases.map(t.en),
                       ["es", "es", "en", "en", "en", "fr", "it", "ca", "gl", "eu", "pt", "en", "en", "en"])
    }

    /// Los nombres de los catálogos (tipos de acorde y de escala, instrumentos, ciclos) en catalán,
    /// gallego y euskera.
    func testCatalogosEnCatalanGallegoEuskera() {
        XCTAssertEqual(TipoDeAcorde.dominanteSeptima.nombre(en: .catalan), "sèptima de dominant")
        XCTAssertEqual(TipoDeAcorde.dominanteSeptima.nombre(en: .gallego), "sétima de dominante")
        XCTAssertEqual(TipoDeAcorde.dominanteSeptima.nombre(en: .euskera), "dominanteko zazpigarrena")
        XCTAssertEqual(TipoDeAcorde.dominanteSeptima.nombre(en: .portugues), "sétima de dominante")
        XCTAssertEqual(Acorde("Sol7/Si").nombre(en: .catalan), "sol sèptima de dominant, primera inversió")
        XCTAssertEqual(Acorde("Sol7/Si").nombre(en: .gallego), "sol sétima de dominante, primeira inversión")
        XCTAssertEqual(Acorde("Do/Re").nombre(en: .euskera), "do maiorra, baxua re dela")
        XCTAssertEqual(Acorde("Do/Re").nombre(en: .catalan), "do major, amb el baix en re")
        XCTAssertEqual(Acorde("Sol7/Si").nombre(en: .aleman), "G dominant seventh, first inversion")
        // Todos los tipos conocidos tienen nombre propio en cada idioma.
        for (_, nombre) in TipoDeAcorde.nombresConocidos {
            XCTAssertFalse(nombre.catalan.isEmpty || nombre.gallego.isEmpty || nombre.euskera.isEmpty, nombre.espanol)
        }

        XCTAssertEqual(Escala(.re, .dorico).nombre(en: .catalan), "re dòric")
        XCTAssertEqual(Escala(.la, .menorArmonica).nombre(en: .gallego), "la menor harmónica")
        XCTAssertEqual(Escala("re doriarra"), Escala("Re dórico"))
        XCTAssertEqual(Escala("fa sostingut lidi"), Escala("Fa# lidio"))
        // Los nombres de otras tradiciones son los mismos en todos los idiomas.
        XCTAssertEqual(Escala(.re, .hirajoshi).nombre(en: .euskera), "re " + TipoDeEscala.hirajoshi.nombre)
        // Cada escala del catálogo tiene nombre en los tres idiomas, y se vuelve a leer igual.
        for tipo in TipoDeEscala.todos {
            XCTAssertNotNil(TipoDeEscala.nombrePeninsularPorTipo[tipo], tipo.nombre)
            let escala = Escala(.re, tipo)
            for notacion in [Nomenclatura.catalan, .gallego, .euskera] {
                let nombre = escala.nombre(en: notacion)
                XCTAssertEqual(Escala(texto: nombre), escala, "\(nombre) (\(tipo.nombre))")
            }
        }

        XCTAssertEqual(Instrumento.clarineteEnSib.nombre(en: .catalan), "clarinet en si♭")
        XCTAssertEqual(Instrumento.violin.nombre(en: .euskera), "biolina")
        XCTAssertEqual(Instrumento.saxofonAlto.nombre(en: .gallego), "saxofón alto")
        for instrumento in Instrumento.todos {
            XCTAssertNotNil(Instrumento.nombresPeninsulares[instrumento.nombre], instrumento.nombre)
        }

        XCTAssertEqual(CicloNeorriemanniano.hexatonico.nombre(en: .catalan), "cicle hexatònic")
        XCTAssertEqual(CicloNeorriemanniano.lr.nombre(en: .euskera), "LR zikloa")
        XCTAssertEqual(CicloNeorriemanniano.octatonico.nombre(en: .ingles), CicloNeorriemanniano.octatonico.nombreEnIngles)
    }

    /// Los textos del motor y los catálogos en portugués, francés e italiano.
    func testTextosEnPortuguesFrancesItaliano() throws {
        XCTAssertEqual(Nomenclatura.frances.idiomaDeLosTextos, .frances)
        XCTAssertEqual(Nomenclatura.italiano.idiomaDeLosTextos, .italiano)

        let sexta = try Intervalo(leyendo: "-6m")
        XCTAssertEqual(sexta.nombre(en: .portugues), "6ª menor descendente")
        XCTAssertEqual(sexta.nombre(en: .frances), "sixte mineure descendante")
        XCTAssertEqual(sexta.nombre(en: .italiano), "sesta minore discendente")
        XCTAssertEqual(Intervalo.terceraMayor.nombre(en: .portugues), "3ª maior")
        XCTAssertEqual(Intervalo.quintaJusta.nombre(en: .frances), "quinte juste")
        XCTAssertEqual(Intervalo.terceraMayor.nombre(en: .italiano), "terza maggiore")
        // El unísono es masculino.
        let unisono = try Intervalo(leyendo: "1A")
        XCTAssertEqual(unisono.nombre(en: .frances), "unisson augmenté")
        XCTAssertEqual(unisono.nombre(en: .italiano), "unisono aumentato")
        XCTAssertEqual(CalidadDeIntervalo.disminuida(2).nombre(en: .frances), "doublement diminuée")
        XCTAssertEqual(Consonancia.perfecta.nombre(en: .italiano), "consonanza perfetta")
        XCTAssertEqual(PapelEnAcorde.fundamental.nombre(en: .frances), "fondamentale")
        XCTAssertEqual(NombreDeGrado.sensible.nombre(en: .portugues), "sensível")
        XCTAssertEqual(Clave.sol.nombre(en: .italiano), "chiave di violino")
        XCTAssertEqual(Duracion(.negra, puntillos: 1).nombre(en: .frances), "noire pointée")
        XCTAssertEqual(Duracion(.corchea, puntillos: 2).nombre(en: .italiano), "croma doppiamente puntata")
        XCTAssertEqual(Figura.blanca.nombre(en: .portugues), "mínima")
        XCTAssertEqual(Cadencia.Tipo.rota.nombre(en: .frances), "cadence rompue")
        XCTAssertEqual(Tonalidad(.do).analizar(["Do", "Fa", "Sol7", "Do"]).nombre(en: .portugues), "I–IV–V7–I em dó maior")
        XCTAssertEqual(Tonalidad(.la, .menor).analizar(["Lam", "Mi7", "Lam"]).nombre(en: .italiano),
                       "i–V7–i in la minore")

        XCTAssertEqual(TipoDeAcorde.dominanteSeptima.nombre(en: .frances), "septième de dominante")
        XCTAssertEqual(TipoDeAcorde.dominanteSeptima.nombre(en: .italiano), "settima di dominante")
        XCTAssertEqual(Acorde("Sol7/Si").nombre(en: .portugues), "sol sétima de dominante, primeira inversão")
        XCTAssertEqual(Acorde("Sol7/Si").nombre(en: .frances), "sol septième de dominante, premier renversement")
        XCTAssertEqual(Acorde("Sol7/Si").nombre(en: .italiano), "sol settima di dominante, primo rivolto")
        XCTAssertEqual(Acorde("Do/Re").nombre(en: .italiano), "do maggiore, con il basso in re")
        for (_, nombre) in TipoDeAcorde.nombresConocidos {
            XCTAssertFalse(nombre.portugues.isEmpty || nombre.frances.isEmpty || nombre.italiano.isEmpty, nombre.espanol)
        }

        XCTAssertEqual(Escala(.re, .dorico).nombre(en: .frances), "ré dorien")
        XCTAssertEqual(Escala(.la, .menorArmonica).nombre(en: .italiano), "la minore armonica")
        XCTAssertEqual(Escala("dó maior"), Escala("Do mayor"))
        XCTAssertEqual(Escala(.re, .hirajoshi).nombre(en: .frances), "ré " + TipoDeEscala.hirajoshi.nombre)
        // Cada escala del catálogo tiene nombre en los tres idiomas; la portuguesa se vuelve a leer igual.
        for tipo in TipoDeEscala.todos {
            XCTAssertNotNil(TipoDeEscala.nombreRomanicoPorTipo[tipo], tipo.nombre)
            let escala = Escala(.re, tipo)
            let nombre = escala.nombre(en: .portugues)
            XCTAssertEqual(Escala(texto: nombre), escala, "\(nombre) (\(tipo.nombre))")
        }

        XCTAssertEqual(Instrumento.clarineteEnSib.nombre(en: .frances), "clarinette en si♭")
        XCTAssertEqual(Instrumento.violin.nombre(en: .portugues), "violino")
        XCTAssertEqual(Instrumento.saxofonAlto.nombre(en: .italiano), "sassofono contralto")
        for instrumento in Instrumento.todos {
            XCTAssertNotNil(Instrumento.nombresRomanicos[instrumento.nombre], instrumento.nombre)
        }
        XCTAssertEqual(CicloNeorriemanniano.hexatonico.nombre(en: .italiano), "ciclo esatonico")
    }

    func testPortugues() {
        let casos: [(String, String)] = [
            ("Fa#", "fá sustenido"), ("Sib", "si bemol"), ("Dox", "dó duplo sustenido"),
            ("Mibb", "mi duplo bemol"), ("Re", "ré"), ("La", "lá"), ("Sol", "sol"),
        ]
        for (espanol, portugues) in casos {
            let nombre = Nota(texto: espanol)!
            XCTAssertEqual(nombre.nombre(en: .portugues), portugues)
            // Se lee sin indicar la notación, con o sin tildes.
            XCTAssertEqual(Nota(texto: portugues), nombre, portugues)
            XCTAssertEqual(try Nota(leyendo: portugues, en: .portugues), nombre, portugues)
        }
        XCTAssertEqual(Nota(texto: "fa sustenido"), Nota("Fa#"))
        XCTAssertEqual(Nota("Reb").nombreCompacto(en: .portugues), "Ré♭")
        XCTAssertEqual(Acorde("Fa#m7").cifrado(en: .portugues), "Fá♯m7")
        XCTAssertEqual(Altura("Fa#3").nombre(en: .portugues), "fá sustenido 3")
        XCTAssertEqual(Altura("fá sustenido 3"), Altura("Fa#3"))
        XCTAssertEqual(Tonalidad("Sib mayor").nombre(en: .portugues), "si bemol maior")
        XCTAssertEqual(Tonalidad("La menor").nombre(en: .portugues), "lá menor")
        XCTAssertEqual(Tonalidad("si bemol maior"), Tonalidad("Sib mayor"))
        XCTAssertEqual(Tonalidad("fá sustenido menor"), Tonalidad("Fa# menor"))
        XCTAssertEqual(Escala("ré dórico"), Escala("Re dórico"))
        XCTAssertEqual(Escala(.re, .dorico).nombre(en: .portugues), "ré dórico")
        XCTAssertEqual(Alteracion(1).nombre(en: .portugues), "sustenido")
        XCTAssertEqual(Alteracion(-2).nombre(en: .portugues), "duplo bemol")
        XCTAssertEqual(Alteracion(0).nombre(en: .portugues), "bequadro")
        XCTAssertEqual(Alteracion(5).nombre(en: .portugues), "5 sustenidos")
        XCTAssertEqual(Alteracion("sustenido"), .sostenido)
        XCTAssertEqual(Alteracion("duplo bemol"), .dobleBemol)
        XCTAssertEqual(Nomenclatura.portugues.vocabulario, .espanol)
        XCTAssertEqual(Nomenclatura(idioma: .portugues, ascii: true), .portugues)
        XCTAssertEqual(EstiloDeCifrado(notacion: .portugues).nomenclatura, .portugues)
    }

    /// Los nombres de nota en occitano, ruso y griego: se escriben y se leen, también sin indicar
    /// la notación; los demás textos salen en inglés.
    func testOccitanoRusoGriego() throws {
        let casos: [(String, String, String, String)] = [
            ("Fa#", "fa dièsi", "фа-диез", "φα δίεση"),
            ("Sib", "si bemòl", "си-бемоль", "σι ύφεση"),
            ("Sol", "sòl", "соль", "σολ"),
            ("La", "la", "ля", "λα"),
            ("Do", "do", "до", "ντο"),
            ("Dox", "do doble dièsi", "до-дубль-диез", "ντο διπλή δίεση"),
            ("Mibb", "mi doble bemòl", "ми-дубль-бемоль", "μι διπλή ύφεση"),
        ]
        for (espanol, occitano, ruso, griego) in casos {
            let nota = Nota(texto: espanol)!
            for (notacion, nombre) in [(Nomenclatura.occitano, occitano), (.ruso, ruso), (.griego, griego)] {
                XCTAssertEqual(nota.nombre(en: notacion), nombre)
                XCTAssertEqual(try Nota(leyendo: nombre, en: notacion), nota, nombre)
                XCTAssertEqual(Nota(texto: nombre), nota, nombre)
                XCTAssertEqual(Nota(texto: nota.nombreCompacto(en: notacion)), nota, nombre)
            }
        }
        // Sin tildes y con o sin guion.
        XCTAssertEqual(Nota(texto: "σι υφεση"), Nota("Sib"))
        XCTAssertEqual(Nota(texto: "фа диез"), Nota("Fa#"))
        XCTAssertEqual(Nota(texto: "sol diesi"), Nota("Sol#"))
        XCTAssertEqual(Nota("Reb").nombreCompacto(en: .ruso), "Ре♭")
        XCTAssertEqual(Nota("Reb").nombreCompacto(en: .griego), "Ρε♭")
        XCTAssertEqual(Nota("Sol#").nombreCompacto(en: .occitano), "Sòl♯")
        XCTAssertEqual(Acorde("Fa#m7").cifrado(en: .ruso), "Фа♯m7")
        XCTAssertEqual(Altura("Fa#3").nombre(en: .griego), "φα δίεση 3")
        XCTAssertEqual(Altura("Fa#3").nombre(en: .ruso), "фа-диез3")
        XCTAssertEqual(Altura("фа-диез3"), Altura("Fa#3"))
        XCTAssertEqual(Altura("σι ύφεση 4"), Altura("Sib4"))
        XCTAssertEqual(Altura("sòl dièsi 2"), Altura("Sol#2"))
        XCTAssertEqual(Alteracion(-1).nombre(en: .griego), "ύφεση")
        XCTAssertEqual(Alteracion(2).nombre(en: .ruso), "дубль-диез")
        XCTAssertEqual(Alteracion(0).nombre(en: .occitano), "becarre")
        // Tonalidades.
        XCTAssertEqual(Tonalidad("Fa# mayor").nombre(en: .ruso), "фа-диез мажор")
        XCTAssertEqual(Tonalidad("La menor").nombre(en: .ruso), "ля минор")
        XCTAssertEqual(Tonalidad("Re mayor").nombre(en: .griego), "ρε μείζονα")
        XCTAssertEqual(Tonalidad("Sib menor").nombre(en: .griego), "σι ύφεση ελάσσονα")
        XCTAssertEqual(Tonalidad("Sol mayor").nombre(en: .occitano), "sòl major")
        XCTAssertEqual(Tonalidad("ре мажор"), Tonalidad("Re mayor"))
        XCTAssertEqual(Tonalidad("σι ύφεση ελάσσονα"), Tonalidad("Sib menor"))
        XCTAssertEqual(Tonalidad("fa dièsi menor"), Tonalidad("Fa# menor"))
        // Los demás textos, en inglés.
        XCTAssertEqual(Nomenclatura.ruso.idiomaDeLosTextos, .ingles)
        XCTAssertEqual(Intervalo.terceraMayor.nombre(en: .griego), "major third")
        XCTAssertEqual(Acorde("Sol7/Si").nombre(en: .ruso), "соль dominant seventh, first inversion")
        XCTAssertEqual(Escala(.re, .dorico).nombre(en: .occitano), "re dorian")
    }

    /// Las notas en una notación y los textos en otro idioma.
    func testNotasYTextosPorSeparado() {
        let rusoEnEspanol = Nomenclatura.ruso.conTextos(en: .espanol)
        XCTAssertEqual(rusoEnEspanol, .combinada(notas: .ruso, textos: .espanol))
        XCTAssertEqual(rusoEnEspanol.idioma, .ruso)
        XCTAssertEqual(rusoEnEspanol.idiomaDeLosTextos, .espanol)
        XCTAssertEqual(rusoEnEspanol.notas, .ruso)
        XCTAssertEqual(Acorde("Sol7/Si").nombre(en: rusoEnEspanol), "соль séptima de dominante, primera inversión")
        XCTAssertEqual(Acorde("Sol7/La").nombre(en: rusoEnEspanol), "соль séptima de dominante, con bajo en ля")
        XCTAssertEqual(Acorde("Fa#m7").cifrado(en: rusoEnEspanol), "Фа♯m7")
        XCTAssertEqual(Tonalidad("Fa# mayor").nombre(en: rusoEnEspanol), "фа-диез мажор")
        XCTAssertEqual(Intervalo.terceraMayor.nombre(en: rusoEnEspanol), "3ª mayor")
        XCTAssertEqual(Intervalo.quintaJusta.abreviatura(en: rusoEnEspanol), "5J")
        XCTAssertEqual(try Nota(leyendo: "фа-диез", en: rusoEnEspanol), Nota("Fa#"))
        XCTAssertEqual(try Altura(leyendo: "фа-диез3", en: rusoEnEspanol), Altura("Fa#3"))
        // Letras inglesas con textos en euskera; sílabas con textos en inglés.
        let inglesEnEuskera = Nomenclatura.ingles.conTextos(en: .euskera)
        XCTAssertEqual(Acorde("Sol7").nombre(en: inglesEnEuskera), "G dominanteko zazpigarrena, oinarrizko egoera")
        XCTAssertEqual(Escala(.re, .dorico).nombre(en: inglesEnEuskera), "D doriarra")
        XCTAssertEqual(Acorde("Sol7").nombre(en: Nomenclatura.espanol.conTextos(en: .ingles)),
                       "Sol dominant seventh, root position")
        XCTAssertEqual(Tonalidad("Fa# mayor").nombre(en: Nomenclatura.aleman.conTextos(en: .frances)), "Fis-Dur")
        XCTAssertEqual(Acorde("Sib7").cifrado(en: Nomenclatura.aleman.conTextos(en: .frances)), "B7")
        // Si el idioma ya es el de los textos, la notación queda simple; no se anidan.
        XCTAssertEqual(Nomenclatura.catalan.conTextos(en: .catalan), .catalan)
        XCTAssertEqual(Nomenclatura.aleman.conTextos(en: .aleman), .aleman)
        XCTAssertEqual(Nomenclatura.griego.conTextos(en: .ingles), .griego)
        XCTAssertEqual(rusoEnEspanol.conTextos(en: .frances), .combinada(notas: .ruso, textos: .frances))
        XCTAssertEqual(rusoEnEspanol.conTextos(en: .ingles), .ruso)
        XCTAssertFalse(Nomenclatura.allCases.contains(rusoEnEspanol))
        // Los mensajes de error.
        do {
            _ = try Acorde(leyendo: "Do7(b3)")
            XCTFail("Do7(b3) no es un cifrado válido")
        } catch let error as ErrorDeLectura {
            XCTAssertEqual(error.descripcion(en: Nomenclatura.ingles.conTextos(en: .espanol)), error.description)
        } catch {
            XCTFail("\(error)")
        }
    }

    /// Las escalas se leen también con la tónica y el tipo en francés, italiano, ruso o griego.
    func testEscalasEnOtrasLenguas() {
        XCTAssertEqual(Escala(texto: "ré dorien"), Escala(.re, .dorico))
        XCTAssertEqual(Escala(texto: "fa dièse lydien"), Escala(Nota("Fa#"), .lidio))
        XCTAssertEqual(Escala(texto: "si bémol mineur harmonique"), Escala(Nota("Sib"), .menorArmonica))
        XCTAssertEqual(Escala(texto: "fa diesis lidio"), Escala(Nota("Fa#"), .lidio))
        XCTAssertEqual(Escala(texto: "si bemolle minore melodica"), Escala(Nota("Sib"), .menorMelodica))
        XCTAssertEqual(Escala(texto: "ре дорийский"), Escala(.re, .dorico))
        XCTAssertEqual(Escala(texto: "ля гармонический минор"), Escala(.la, .menorArmonica))
        XCTAssertEqual(Escala(texto: "фа-диез минорная пентатоника"), Escala(Nota("Fa#"), .pentatonicaMenor))
        XCTAssertEqual(Escala(texto: "λα αρμονική ελάσσονα"), Escala(.la, .menorArmonica))
        XCTAssertEqual(Escala(texto: "ρε δωριος"), Escala(.re, .dorico))
        XCTAssertEqual(Escala(texto: "σι ύφεση μιξολύδιος"), Escala(Nota("Sib"), .mixolidio))
        // Con la tónica en ruso o griego, el tipo puede ir en inglés.
        XCTAssertEqual(Escala(texto: "до lydian dominant"), Escala(.do, .lidioDominante))
        XCTAssertEqual(Escala(texto: "ντο altered"), Escala(.do, .alterada))
        // Todos los nombres franceses e italianos del catálogo se leen.
        for tipo in TipoDeEscala.todos {
            for notacion in [Nomenclatura.frances, .italiano] {
                let escala = Escala(Nota("Fa#"), tipo)
                XCTAssertEqual(Escala(texto: escala.nombre(en: notacion)), escala, escala.nombre(en: notacion))
            }
        }
        for fila in TipoDeEscala.nombresRusosYGriegos {
            for nombre in fila.ruso { XCTAssertEqual(Escala(texto: "ре " + nombre), Escala(.re, fila.tipo), nombre) }
            for nombre in fila.griego { XCTAssertEqual(Escala(texto: "ρε " + nombre), Escala(.re, fila.tipo), nombre) }
        }
        // El español no cambia: no se mezclan idiomas.
        XCTAssertNil(Escala(texto: "Re dorian"))
    }

    func testVocabularioEIdas() {
        XCTAssertEqual(Nomenclatura.aleman.idioma, .aleman)
        XCTAssertEqual(Nomenclatura.frances.vocabulario, .ingles)
        XCTAssertEqual(Nomenclatura.espanolASCII.vocabulario, .espanol)
        XCTAssertEqual(Nomenclatura(idioma: .italiano, ascii: false), .italiano)
        // En alemán, el resto del vocabulario sale en inglés.
        XCTAssertEqual(Escala(.re, .dorico).nombre(en: .aleman), "D dorian")
        XCTAssertEqual(Intervalo.terceraMayor.nombre(en: .aleman), "major third")
        // Todos los nombres de nota (hasta cuatro alteraciones) vuelven a leerse igual.
        for notacion in [Nomenclatura.aleman, .frances, .italiano, .catalan, .gallego, .euskera, .portugues] {
            for quintas in -29...33 {
                let nombre = Nota(pasosDeQuinta: quintas)
                XCTAssertEqual(try Nota(leyendo: nombre.nombre(en: notacion), en: notacion), nombre,
                               "\(nombre) \(notacion)")
                let nota = Altura(nombre, octava: 2)
                XCTAssertEqual(try Altura(leyendo: nota.nombre(en: notacion), en: notacion), nota)
            }
            for tonalidad in Tonalidad.circuloDeQuintas() + Tonalidad.circuloDeQuintas(.menor) {
                XCTAssertEqual(Tonalidad(texto: tonalidad.nombre(en: notacion)), tonalidad, tonalidad.nombre(en: notacion))
            }
        }
    }

    func testSinonimosAlLeer() {
        // Undécima y decimotercera, y también oncena y trecena.
        XCTAssertEqual(PapelEnAcorde("undécima"), .tension(11))
        XCTAssertEqual(PapelEnAcorde("Oncena"), .tension(11))
        XCTAssertEqual(PapelEnAcorde("decimotercera"), .tension(13))
        XCTAssertEqual(PapelEnAcorde("trecena"), .tension(13))
        XCTAssertEqual(PapelEnAcorde("séptima"), .septima)
        XCTAssertEqual(PapelEnAcorde("suspension"), .suspension)
        XCTAssertEqual(PapelEnAcorde("thirteenth"), .tension(13))
        XCTAssertEqual(PapelEnAcorde("root"), .fundamental)
        XCTAssertNil(PapelEnAcorde("duodécima"))
        XCTAssertEqual(Intervalo.decimoterceraMayor, Intervalo("13M"))
        XCTAssertEqual(Intervalo.undecimaAumentada.semitonos, 18)
        // Submediante junto a superdominante.
        XCTAssertEqual(NombreDeGrado("submediante"), .superdominante)
        XCTAssertEqual(NombreDeGrado("Superdominante"), .superdominante)
        XCTAssertEqual(NombreDeGrado("submediant"), .superdominante)
        XCTAssertEqual(NombreDeGrado("tónica"), .tonica)
        XCTAssertEqual(NombreDeGrado("TONICA"), .tonica)
        XCTAssertEqual(NombreDeGrado("leading tone"), .sensible)
        XCTAssertNil(NombreDeGrado("dominantísima"))
        XCTAssertEqual(Escala(.la, .menorNatural).nombreDeGrado(de: .fa), .superdominante)
    }
}
