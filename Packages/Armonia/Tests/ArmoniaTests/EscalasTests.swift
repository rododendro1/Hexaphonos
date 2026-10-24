import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class EscalaTests: XCTestCase {
    func testNotas() {
        XCTAssertEqual(Escala(.re).notas.map(\.nombre), ["Re", "Mi", "Fa♯", "Sol", "La", "Si", "Do♯"])
        XCTAssertEqual(Escala("Fa mayor").notas.map(\.nombre), ["Fa", "Sol", "La", "Si♭", "Do", "Re", "Mi"])
        XCTAssertEqual(Escala("La menor armónica").grado(7), Nota("Sol#"))
        XCTAssertEqual(Escala("Re dórico").notas, Escala(.do).rotacion(2).notas)
        XCTAssertEqual(Escala(.do).rotacion(5).tipo, .mixolidio)
    }

    func testArmadura() {
        XCTAssertEqual(Escala(.do).armadura, 0)
        XCTAssertEqual(Escala("Re mayor").armadura, 2)
        XCTAssertEqual(Escala("Mib mayor").armadura, -3)
        XCTAssertEqual(Escala("Fa# mayor").armadura, 6)
        XCTAssertEqual(Escala("Do menor").armadura, -3)
        XCTAssertEqual(Escala("Mi dórico").armadura, 2)
        XCTAssertNil(Escala("La menor armónica").armadura)
    }

    func testRelativas() {
        XCTAssertEqual(Tonalidad(.do).relativa, Tonalidad(.la, .menor))
        XCTAssertEqual(Tonalidad("Sol menor").relativa, Tonalidad(Nota("Sib")))
    }

    func testArmonizacionMayor() {
        let e = Escala(.do)
        XCTAssertEqual(e.armonizar().map { $0?.cifrado }, ["Do", "Rem", "Mim", "Fa", "Sol", "Lam", "Si°"])
        XCTAssertEqual(e.cifradosRomanos(), ["I", "ii", "iii", "IV", "V", "vi", "vii°"])
        XCTAssertEqual(e.cifradosRomanos(cuatriadas: true),
                       ["Imaj7", "ii7", "iii7", "IVmaj7", "V7", "vi7", "viiø7"])
    }

    func testArmonizacionMenor() {
        let armonica = Escala(.la, .menorArmonica)
        XCTAssertEqual(armonica.cifradosRomanos(),
                       ["i", "ii°", "♭III+", "iv", "V", "♭VI", "vii°"])
        XCTAssertEqual(armonica.cifradosRomanos(cuatriadas: true),
                       ["i(maj7)", "iiø7", "♭III+maj7", "iv7", "V7", "♭VImaj7", "vii°7"])
        XCTAssertEqual(armonica.acorde(grado: 5, cuatriada: true)?.cifrado, "Mi7")

        let melodica = Escala(.la, .menorMelodica)
        XCTAssertEqual(melodica.cifradosRomanos(cuatriadas: true),
                       ["i(maj7)", "ii7", "♭III+maj7", "IV7", "V7", "viø7", "viiø7"])
    }

    func testNotasConOctava() {
        XCTAssertEqual(Escala("Sol mayor").alturas(octava: 3).map(\.description),
                       ["Sol3", "La3", "Si3", "Do4", "Re4", "Mi4", "Fa♯4", "Sol4"])
    }

    func testIgualdadDeTiposDeEscala() {
        let jonico = TipoDeEscala(nombre: "jónico", intervalos: TipoDeEscala.mayor.intervalos.reversed())
        XCTAssertEqual(jonico, .mayor)
        XCTAssertEqual(Set([jonico, TipoDeEscala.mayor]).count, 1)
        XCTAssertNotEqual(TipoDeEscala.mayor, .lidio)
        XCTAssertEqual(Escala(.do, jonico), Escala(.do))
    }

    func testMenorMelodicaDescendente() {
        XCTAssertEqual(TipoDeEscala.menorMelodica.formaDescendente, .menorNatural)
        XCTAssertEqual(Escala("La menor melódica").alturas(octava: 4, direccion: .descendente).map(\.description),
                       ["La5", "Sol5", "Fa5", "Mi5", "Re5", "Do5", "Si4", "La4"])
        XCTAssertEqual(Escala("La menor melódica").alturas(octava: 4)[5].description, "Fa♯5")
    }

    func testCifradoRomanoConReferencia() {
        let armonica = Escala(.la, .menorArmonica)
        XCTAssertEqual(armonica.cifradosRomanos(referencia: .menorNatural),
                       ["i", "ii°", "III+", "iv", "V", "VI", "♯vii°"])
    }
}

final class EscalasAdicionalesTests: XCTestCase {
    func testModosDeLasMenores() {
        let armonica = Escala(.la, .menorArmonica)
        XCTAssertEqual(armonica.rotacion(2).tipo, .locrioSextaNatural)
        XCTAssertEqual(armonica.rotacion(3).tipo, .jonicoAumentado)
        XCTAssertEqual(armonica.rotacion(4).tipo, .doricoCuartaAumentada)
        XCTAssertEqual(armonica.rotacion(5).tipo, .frigioDominante)
        XCTAssertEqual(armonica.rotacion(6).tipo, .lidioSegundaAumentada)
        XCTAssertEqual(armonica.rotacion(7).tipo, .ultralocrio)
        let melodica = Escala(.la, .menorMelodica)
        XCTAssertEqual(melodica.rotacion(2).tipo, .doricoSegundaMenor)
        XCTAssertEqual(melodica.rotacion(3).tipo, .lidioAumentado)
        XCTAssertEqual(melodica.rotacion(4).tipo, .lidioDominante)
        XCTAssertEqual(melodica.rotacion(5).tipo, .mixolidioSextaMenor)
        XCTAssertEqual(melodica.rotacion(6).tipo, .locrioSegundaNatural)
        XCTAssertEqual(melodica.rotacion(7).tipo, .alterada)
        XCTAssertEqual(melodica.rotacion(7).nombre, "Sol♯ alterada")
    }

    func testLecturaDeNombres() {
        XCTAssertEqual(Escala("Mi frigio dominante"), Escala(.mi, .frigioDominante))
        XCTAssertEqual(Escala("E phrygian dominant"), Escala(.mi, .frigioDominante))
        XCTAssertEqual(Escala("Do jónico ♯5").tipo, .jonicoAumentado)
        XCTAssertEqual(Escala("Do jonico #5").tipo, .jonicoAumentado)
        XCTAssertEqual(Escala("G altered").tipo, .alterada)
        XCTAssertEqual(Escala("Sol superlocrio").tipo, .alterada)
        XCTAssertEqual(Escala("Do mayor armónica").notas.map(\.nombre),
                       ["Do", "Re", "Mi", "Fa", "Sol", "La♭", "Si"])
        XCTAssertEqual(Escala("C bebop").notas.count, 8)
        XCTAssertEqual(Escala("Re bebop dórico").notas.map(\.nombre),
                       ["Re", "Mi", "Fa", "Fa♯", "Sol", "La", "Si", "Do"])
    }

    func testFuncionesDeGrado() {
        XCTAssertEqual(Escala(.do).nombreDeGrado(1), .tonica)
        XCTAssertEqual(Escala(.do).nombreDeGrado(5), .dominante)
        XCTAssertEqual(Escala(.do).nombreDeGrado(7), .sensible)
        XCTAssertEqual(Escala(.la, .menorNatural).nombreDeGrado(7), .subtonica)
        XCTAssertEqual(Escala(.la, .menorArmonica).nombreDeGrado(7), .sensible)
        XCTAssertEqual(Escala(.do).nombreDeGrado(de: .fa), .subdominante)
        XCTAssertNil(Escala(.do).nombreDeGrado(de: "Fa#"))
        XCTAssertNil(Escala(.do, .pentatonicaMayor).nombreDeGrado(1))
        XCTAssertEqual(NombreDeGrado.superdominante.nombre(en: .ingles), "submediant")
    }

    func testArmaduras() {
        XCTAssertEqual(Escala("Re mayor").notasDeLaArmadura, ["Fa#", "Do#"])
        XCTAssertEqual(Escala("Mib mayor").notasDeLaArmadura, ["Sib", "Mib", "Lab"])
        XCTAssertEqual(Escala(.do).notasDeLaArmadura, [])
        XCTAssertEqual(Escala("Do# mayor").notasDeLaArmadura?.last, "Si#")
        XCTAssertNil(Escala(.la, .menorArmonica).notasDeLaArmadura)

        XCTAssertEqual(Escala(armadura: 3), Escala(.la))
        XCTAssertEqual(Escala(armadura: -2, tipo: .menorNatural), Escala(.sol, .menorNatural))
        XCTAssertEqual(Escala(armadura: 0, tipo: .dorico), Escala(.re, .dorico))
        XCTAssertNil(Escala(armadura: 0, tipo: .menorArmonica))
    }

    func testCirculoDeQuintasYRelaciones() {
        let circulo = Escala.circuloDeQuintas()
        XCTAssertEqual(circulo.count, 15)
        XCTAssertEqual(circulo.first?.nombre, "Do♭ mayor")
        XCTAssertEqual(circulo.last?.nombre, "Do♯ mayor")
        XCTAssertEqual(circulo.map { $0.armadura! }, Array(-7...7))
        XCTAssertEqual(Escala.circuloDeQuintas(.menorNatural)[7], Escala(.la, .menorNatural))

        XCTAssertEqual(Escala(.do).distancia(hasta: Escala(.sol)), 1)
        XCTAssertEqual(Escala(.do).distancia(hasta: Escala(.la, .menorNatural)), 0)
        XCTAssertEqual(Escala(.do).distancia(hasta: Escala("Fa# mayor")), 6)
        XCTAssertNil(Escala(.do).distancia(hasta: Escala(.do, .menorArmonica)))

        XCTAssertEqual(Escala("Do# mayor").enarmonicaMasSimple.nombre, "Re♭ mayor")
        XCTAssertEqual(Escala("Fa# mayor").enarmonicaMasSimple.nombre, "Fa♯ mayor")
        XCTAssertEqual(Escala("Solb mayor").enarmonicaMasSimple.nombre, "Sol♭ mayor")
        XCTAssertEqual(Escala("La# menor").enarmonicaMasSimple.nombre, "Si♭ menor natural")

        XCTAssertEqual(Set(Tonalidad(.do).vecinas),
                       [Tonalidad(.sol), Tonalidad(.fa), Tonalidad(.la, .menor), Tonalidad(.mi, .menor), Tonalidad(.re, .menor)])
    }

    func testEscalasContenedoras() {
        let porNombre = Escala.identificar([.do, .mi, .sol, .si, "Fa#"])
        // Primero la que tiene exactamente esas notas; luego, la de menos notas de más.
        XCTAssertEqual(porNombre.first, Escala(.do, .pentatonicaLidia))
        XCTAssertEqual(porNombre.dropFirst().first, Escala(.sol))
        XCTAssertTrue(porNombre.contains(Escala(.mi, .menorNatural)))
        XCTAssertTrue(porNombre.contains(Escala(.re, .mixolidio)))
        XCTAssertFalse(porNombre.contains(Escala(.do)))
        XCTAssertTrue(porNombre.allSatisfy { escala in [Nota.do, .mi, .sol, .si, "Fa#"].allSatisfy { escala.contiene($0) } })

        // Con Sol♭ en lugar de Fa♯, la ortografía descarta Sol mayor.
        XCTAssertFalse(Escala.identificar([.do, .mi, .sol, .si, "Solb"]).contains(Escala(.sol)))

        let porAltura = Escala.identificar(clasesDeAltura: [0, 4, 7, 11, 6])
        XCTAssertEqual(porAltura.first, Escala(.do, .pentatonicaLidia))
        XCTAssertEqual(porAltura.dropFirst().first, Escala(.sol))
        XCTAssertTrue(porAltura.contains(Escala(.mi, .menorNatural)))
        XCTAssertEqual(Escala.identificar(clasesDeAltura: [0, 1, 2, 3], tipos: [.mayor]), [])
    }
}

final class EscalasDireccionalesTests: XCTestCase {
    func testMenorMelodica() {
        let melodica = TipoDeEscala.menorMelodica
        XCTAssertTrue(melodica.esDireccional)
        XCTAssertEqual(melodica.formaDescendente, .menorNatural)
        XCTAssertEqual(melodica.formaAscendente.intervalos, melodica.intervalos)
        XCTAssertFalse(melodica.formaAscendente.esDireccional)
        XCTAssertEqual(melodica.intervalosEnAmbasDirecciones.count, 9)
        XCTAssertEqual(Escala(.la, .menorMelodica).alturas(octava: 4, direccion: .descendente).map(\.description),
                       ["La5", "Sol5", "Fa5", "Mi5", "Re5", "Do5", "Si4", "La4"])
        XCTAssertFalse(TipoDeEscala.mayor.esDireccional)
        XCTAssertEqual(TipoDeEscala.mayor.formaDescendente, .mayor)
        // Un descenso igual a la subida no se guarda.
        XCTAssertNil(TipoDeEscala(nombre: "x", intervalos: TipoDeEscala.mayor.intervalos,
                                  descenso: TipoDeEscala.mayor.intervalos).descenso)
    }

    func testMenorMelodicaDeJazz() {
        let jazz = TipoDeEscala.menorMelodicaJazz
        XCTAssertFalse(jazz.esDireccional)
        XCTAssertEqual(jazz.intervalos, TipoDeEscala.menorMelodica.intervalos)
        XCTAssertNotEqual(jazz, .menorMelodica)
        XCTAssertEqual(jazz, TipoDeEscala.menorMelodica.formaAscendente)
        XCTAssertEqual(jazz.nombre(en: .ingles), "jazz minor")
        XCTAssertEqual(TipoDeEscala.menorMelodica.nombre(en: .ingles), "melodic minor")
        XCTAssertEqual(Escala("La menor melódica ascendente").tipo, jazz)
        XCTAssertEqual(Escala("A jazz minor").tipo, jazz)
        XCTAssertEqual(Escala(.la, jazz).alturas(octava: 4, direccion: .descendente).map(\.description),
                       ["La5", "Sol♯5", "Fa♯5", "Mi5", "Re5", "Do5", "Si4", "La4"])
        // Sus modos vuelven a ella.
        XCTAssertEqual(TipoDeEscala.alterada.rotacion(2), jazz)
        XCTAssertEqual(jazz.rotacion(7), .alterada)
        XCTAssertEqual(Tonalidad(Escala(.la, jazz)), Tonalidad(.la, .menor))
        XCTAssertTrue(jazz.equivalentes.contains { $0.nombre == "Gaurīmanoharī" })
    }

    func testPertenenciaEnAmbasDirecciones() {
        let melodica = Escala(.la, .menorMelodica)
        XCTAssertTrue(melodica.contiene(.sol))
        XCTAssertTrue(melodica.contiene("Sol#"))
        XCTAssertFalse(melodica.contiene(.sol, direccion: .ascendente))
        XCTAssertTrue(melodica.contiene(.sol, direccion: .descendente))
        XCTAssertFalse(melodica.contiene("Sol#", direccion: .descendente))
        XCTAssertTrue(melodica.contieneEnarmonico("Lab", direccion: .ascendente))
        XCTAssertEqual(melodica.notasEnAmbasDirecciones.map(\.nombre),
                       ["La", "Si", "Do", "Re", "Mi", "Fa", "Fa♯", "Sol", "Sol♯"])
        XCTAssertEqual(melodica.notas(direccion: .descendente).map(\.nombre),
                       ["La", "Si", "Do", "Re", "Mi", "Fa", "Sol"])
        XCTAssertEqual(melodica.notas(direccion: .ascendente), melodica.notas)
        // Lo que depende de los grados sigue usando la forma ascendente.
        XCTAssertEqual(melodica.grado(de: "Sol#"), 7)
        XCTAssertNil(melodica.grado(de: .sol))
        XCTAssertEqual(melodica.conjuntoDeClases.numeroDeForte, "7-34")
        // La búsqueda de escalas tiene en cuenta las dos direcciones…
        XCTAssertTrue(Escala.identificar([.la, .sol, "Sol#"], tipos: [.menorMelodica]).contains(melodica))
        XCTAssertTrue(Escala.identificar(clasesDeAltura: [9, 7, 8], tipos: [.menorMelodica])
            .contains { $0.notasEnAmbasDirecciones.map(\.claseDeAltura).contains(7) })
        XCTAssertFalse(Escala.identificar([.la, .sol, "Sol#"], tipos: [.menorMelodicaJazz]).contains(Escala(.la, .menorMelodicaJazz)))
        // …y la ortografía también: en La menor melódica, el 7 MIDI (Sol) no es cromático.
        XCTAssertEqual(melodica.nombre(claseDeAltura: 7), .sol)
        XCTAssertEqual(melodica.nombre(claseDeAltura: 8), Nota("Sol#"))
    }

    func testDromoiDireccionales() {
        XCTAssertEqual(Escala(.re, .rast).notas.map(\.nombre), ["Re", "Mi", "Fa♯", "Sol", "La", "Si", "Do♯"])
        XCTAssertEqual(Escala(.re, TipoDeEscala.rast.formaDescendente).notas.map(\.nombre),
                       ["Re", "Mi", "Fa♯", "Sol", "La", "Si", "Do"])
        XCTAssertNotEqual(TipoDeEscala.rast, .mayor)
        XCTAssertEqual(TipoDeEscala.rast.formaAscendente, .mayor)
        XCTAssertEqual(TipoDeEscala.kiourdi.formaAscendente, .kartzigar)
        XCTAssertEqual(TipoDeEscala.kiourdi.formaDescendente, .menorNatural)
        XCTAssertEqual(TipoDeEscala.houseini.formaAscendente, .mixolidio)
        XCTAssertEqual(Escala("Re kiourdi").tipo.nombre, "Kiourdí")
        XCTAssertEqual(TipoDeEscala.dromoi.count, 15)
    }

    func testJanyas() {
        XCTAssertEqual(Escala(.do, .mohanam).notas.map(\.nombre), ["Do", "Re", "Mi", "Sol", "La"])
        XCTAssertEqual(Escala(.do, .bilahari).alturas(octava: 4, direccion: .descendente).map(\.description),
                       ["Do5", "Si4", "La4", "Sol4", "Fa4", "Mi4", "Re4", "Do4"])
        XCTAssertEqual(TipoDeEscala.bilahari.melakartasCompatibles, [29])
        XCTAssertEqual(TipoDeEscala.kambhoji.melakartasCompatibles, [28])
        XCTAssertEqual(TipoDeEscala.mohanam.melakartasCompatibles, [28, 29, 64, 65])
        XCTAssertEqual(TipoDeEscala.hindolam.melakartasCompatibles, [8, 20])
        XCTAssertEqual(TipoDeEscala.abhogi.melakartasCompatibles, [22, 23])
        XCTAssertEqual(Escala("Do hamsadhwani"), Escala(.do, .hamsadhvani))
        XCTAssertEqual(TipoDeEscala.janyas.count, 11)
    }

    func testIdentidadYEquivalentes() {
        XCTAssertEqual(TipoDeEscala.kafi, .dorico)
        XCTAssertFalse(TipoDeEscala.kafi.esIdentico(a: .dorico))
        XCTAssertTrue(TipoDeEscala.kafi.esIdentico(a: .kafi))
        XCTAssertTrue(Set(TipoDeEscala.mayor.equivalentes.map(\.nombre)).isSuperset(of: ["Bilāval", "Dhīraśaṅkarābharaṇam", "Qīngyuè", "ʿAjam", "Māhur"]))
        XCTAssertTrue(Set(TipoDeEscala.hitzazkiar.equivalentes.map(\.nombre)).isSuperset(of: ["Bhairav", "Māyāmālavagauḷa", "doble armónica", "Ḥijāzkār"]))
        XCTAssertTrue(TipoDeEscala.menorMelodica.equivalentes.isEmpty)
        // La búsqueda por índice da lo mismo que antes: los nombres habituales primero.
        XCTAssertEqual(TipoDeEscala.buscar(nombre: "Dorian")?.nombre, "dórico")
        XCTAssertEqual(TipoDeEscala.buscar(nombre: "jazz minor")?.nombre, "menor melódica de jazz")
        XCTAssertNil(TipoDeEscala.buscar(nombre: "inexistente"))
    }
}

final class EscalasTradicionalesTests: XCTestCase {
    func testMelakarta() {
        XCTAssertEqual(TipoDeEscala.melakartas.count, 72)
        XCTAssertEqual(Set(TipoDeEscala.melakartas.map { $0.intervalos.map(\.semitonos) }).count, 72)
        XCTAssertEqual(TipoDeEscala.melakarta(15)?.nombre, "Māyāmālavagauḷa")
        XCTAssertEqual(TipoDeEscala.melakarta(29), .mayor)
        XCTAssertEqual(TipoDeEscala.melakarta(65), .lidio)
        XCTAssertEqual(TipoDeEscala.melakarta(22), .dorico)
        XCTAssertEqual(TipoDeEscala.melakarta(20), .menorNatural)
        XCTAssertEqual(TipoDeEscala.melakarta(8), .frigio)
        XCTAssertEqual(TipoDeEscala.melakarta(28), .mixolidio)
        XCTAssertEqual(TipoDeEscala.melakarta(21), .menorArmonica)
        // Gaurīmanoharī sube y baja igual; la menor melódica clásica baja como la natural.
        XCTAssertEqual(TipoDeEscala.melakarta(23)?.intervalos, TipoDeEscala.menorMelodica.intervalos)
        XCTAssertNotEqual(TipoDeEscala.melakarta(23), .menorMelodica)
        XCTAssertEqual(TipoDeEscala.melakarta(23), .menorMelodicaJazz)
        XCTAssertNil(TipoDeEscala.melakarta(0))
        XCTAssertNil(TipoDeEscala.melakarta(73))
        // Mayamalavagowla, el thaat Bhairav y el dromos Hitzazkiar son la misma escala.
        XCTAssertEqual(TipoDeEscala.melakarta(15), .bhairav)
        XCTAssertEqual(TipoDeEscala.melakarta(15), .hitzazkiar)
        // Ri3 y Ga1, Dha3 y Ni1 con su escritura tradicional.
        XCTAssertEqual(Escala(.do, TipoDeEscala.melakarta(1)!).notas.map(\.nombre),
                       ["Do", "Re♭", "Mi♭♭", "Fa", "Sol", "La♭", "Si♭♭"])
        XCTAssertEqual(Escala(.do, TipoDeEscala.melakarta(36)!).notas.map(\.nombre),
                       ["Do", "Re♯", "Mi", "Fa", "Sol", "La♯", "Si"])
        XCTAssertEqual(TipoDeEscala.mayor.numeroDeMelakarta, 29)
        XCTAssertEqual(TipoDeEscala.menorArmonica.numeroDeMelakarta, 21)
        XCTAssertEqual(TipoDeEscala.niavent.numeroDeMelakarta, 57)
        XCTAssertNil(TipoDeEscala.pentatonicaMayor.numeroDeMelakarta)
        XCTAssertEqual(TipoDeEscala.mayorArmonica.numeroDeMelakarta, 27)   // Sarasangi
        for n in 1...72 {
            XCTAssertEqual(TipoDeEscala.melakarta(n)?.numeroDeMelakarta, n)
        }
    }

    func testThaats() {
        XCTAssertEqual(TipoDeEscala.thaats.count, 10)
        XCTAssertEqual(TipoDeEscala.bilaval, .mayor)
        XCTAssertEqual(TipoDeEscala.kalyan, .lidio)
        XCTAssertEqual(TipoDeEscala.khamaj, .mixolidio)
        XCTAssertEqual(TipoDeEscala.kafi, .dorico)
        XCTAssertEqual(TipoDeEscala.asavari, .menorNatural)
        XCTAssertEqual(TipoDeEscala.bhairavi, .frigio)
        XCTAssertEqual(Escala(.do, .todi).notas.map(\.nombre), ["Do", "Re♭", "Mi♭", "Fa♯", "Sol", "La♭", "Si"])
        XCTAssertEqual(Escala(.do, .marva).notas.map(\.nombre), ["Do", "Re♭", "Mi", "Fa♯", "Sol", "La", "Si"])
        XCTAssertEqual(Escala(.do, .purvi).notas.map(\.nombre), ["Do", "Re♭", "Mi", "Fa♯", "Sol", "La♭", "Si"])
    }

    func testDromoi() {
        XCTAssertEqual(TipoDeEscala.dromoi.count, 15)
        XCTAssertEqual(Escala(.re, .hitzaz).notas.map(\.nombre), ["Re", "Mi♭", "Fa♯", "Sol", "La", "Si♭", "Do"])
        XCTAssertEqual(Escala(.re, .pireotikos).notas.map(\.nombre), ["Re", "Mi♭", "Fa♯", "Sol♯", "La", "Si♭", "Do♯"])
        XCTAssertEqual(Escala(.re, .houzam).notas.map(\.nombre), ["Re", "Mi♯", "Fa♯", "Sol", "La", "Si", "Do♯"])
        XCTAssertEqual(Escala(.re, .sabah).notas.map(\.nombre), ["Re", "Mi", "Fa", "Sol♭", "La", "Si♭", "Do"])
        XCTAssertEqual(Escala(.re, .kartzigar).notas.map(\.nombre), ["Re", "Mi", "Fa", "Sol", "La♭", "Si", "Do"])
        XCTAssertEqual(TipoDeEscala.ousak, .frigio)
        XCTAssertEqual(TipoDeEscala.hitzaz, .frigioDominante)
        XCTAssertEqual(TipoDeEscala.nikriz, .doricoCuartaAumentada)
        XCTAssertEqual(TipoDeEscala.tabahaniotikos, .mayorArmonica)
    }

    func testDiacriticos() {
        // Nombres indios en AITS (IAST) y griegos con su acento.
        XCTAssertEqual(TipoDeEscala.melakarta(29)?.nombre, "Dhīraśaṅkarābharaṇam")
        XCTAssertEqual(TipoDeEscala.melakarta(56)?.nombre, "Ṣaṇmukhapriyā")
        XCTAssertEqual(TipoDeEscala.melakarta(65)?.nombre, "Mecakalyāṇī")
        XCTAssertEqual(TipoDeEscala.kafi.nombre, "Kāfī")
        XCTAssertEqual(TipoDeEscala.todi.nombre, "Toḍī")
        XCTAssertEqual(TipoDeEscala.pireotikos.nombre, "Pireótikos")
        XCTAssertEqual(Escala(.do, .asavari).nombre, "Do Āsāvarī")
        // La búsqueda no distingue diacríticos ni mayúsculas.
        for texto in ["Do Kafi", "Do kāfī", "Do KAFI", "Do Kāfī"] {
            XCTAssertEqual(Escala(texto: texto)?.tipo.nombre, "Kāfī", texto)
        }
        XCTAssertEqual(Escala("Do shanmukhapriya").tipo, TipoDeEscala.melakarta(56))
        XCTAssertEqual(Escala("Do Sanmukhapriya").tipo, TipoDeEscala.melakarta(56))
        XCTAssertEqual(Escala("Do dorico"), Escala("Do dórico"))
        XCTAssertEqual(Escala("Re pireotikos"), Escala(.re, .pireotikos))
        // Todas las escalas se vuelven a leer desde su nombre, con diacríticos o sin ellos.
        for tipo in TipoDeEscala.tradicionales {
            XCTAssertEqual(TipoDeEscala.buscar(nombre: tipo.nombre)?.nombre, tipo.nombre, tipo.nombre)
        }
    }

    func testEscalasOccidentalesNuevas() {
        func notas(_ tipo: TipoDeEscala) -> String { Escala(.do, tipo).notas.map(\.description).joined(separator: " ") }
        XCTAssertEqual(notas(.dobleArmonica), "Do Re♭ Mi Fa Sol La♭ Si")
        XCTAssertEqual(notas(.menorHungara), "Do Re Mi♭ Fa♯ Sol La♭ Si")
        XCTAssertEqual(notas(.mayorHungara), "Do Re♯ Mi Fa♯ Sol La Si♭")
        XCTAssertEqual(notas(.napolitanaMenor), "Do Re♭ Mi♭ Fa Sol La♭ Si")
        XCTAssertEqual(notas(.napolitanaMayor), "Do Re♭ Mi♭ Fa Sol La Si")
        XCTAssertEqual(notas(.enigmatica), "Do Re♭ Mi Fa♯ Sol♯ La♯ Si")
        XCTAssertEqual(notas(.persa), "Do Re♭ Mi Fa Sol♭ La♭ Si")
        XCTAssertEqual(notas(.mayorLocria), "Do Re Mi Fa Sol♭ La♭ Si♭")
        XCTAssertEqual(notas(.lidioMenor), "Do Re Mi Fa♯ Sol La♭ Si♭")
        XCTAssertEqual(notas(.prometeo), "Do Re Mi Fa♯ La Si♭")
        XCTAssertEqual(notas(.disminuidaSemitonoTono), "Do Re♭ Mi♭ Mi Fa♯ Sol La Si♭")
        XCTAssertEqual(notas(.aumentada), "Do Mi♭ Mi Sol Sol♯ Si")
        XCTAssertEqual(notas(.bluesMayor), "Do Re Mi♭ Mi Sol La")
        XCTAssertEqual(notas(.egipcia), "Do Re Fa Sol Si♭")
        XCTAssertEqual(notas(.cromatica), "Do Re♭ Re Mi♭ Mi Fa Fa♯ Sol La♭ La Si♭ Si")
        XCTAssertEqual(Set(Escala(.do, .cromatica).notas.map(\.claseDeAltura)).count, 12)

        // Los modos de la mayor armónica son sus rotaciones.
        let modos: [TipoDeEscala] = [.mayorArmonica, .doricoQuintaDisminuida, .frigioCuartaDisminuida, .lidioTerceraMenor,
                                     .mixolidioSegundaMenor, .lidioAumentadoSegundaAumentada, .locrioSeptimaDisminuida]
        for (i, modo) in modos.enumerated() {
            XCTAssertTrue(TipoDeEscala.mayorArmonica.rotacion(i + 1).esIdentico(a: modo), modo.nombre)
        }
        // Las disminuidas suenan como rotaciones la una de la otra (la ortografía cambia).
        XCTAssertEqual(TipoDeEscala.disminuida.rotacion(2).intervalos.map(\.semitonos),
                       TipoDeEscala.disminuidaSemitonoTono.intervalos.map(\.semitonos))

        // Nombres en inglés y alias.
        XCTAssertEqual(Escala("E hungarian minor").tipo, .menorHungara)
        XCTAssertEqual(Escala("C double harmonic").tipo.nombre, "doble armónica")
        XCTAssertEqual(Escala(.do, .enigmatica).nombre(en: .ingles), "C enigmatic")
        XCTAssertEqual(Escala("G half-whole diminished").tipo, .disminuidaSemitonoTono)
        XCTAssertEqual(Escala("Mi española").tipo, .frigioDominante)
        XCTAssertEqual(Escala("Do modo 1 de Messiaen").tipo, .tonosEnteros)
        XCTAssertEqual(Escala("Do modo 2 de Messiaen").tipo, .disminuidaSemitonoTono)
        XCTAssertEqual(Escala("Do gitana menor").tipo, .menorHungara)
        XCTAssertEqual(Escala("Do Skriabin").tipo, .prometeo)

        // Con el mismo contenido que escalas de otras tradiciones.
        XCTAssertEqual(TipoDeEscala.dobleArmonica, .bhairav)
        XCTAssertEqual(TipoDeEscala.menorHungara, .niavent)
        XCTAssertEqual(TipoDeEscala.egipcia, .shang)
        XCTAssertEqual(TipoDeEscala.todos.count, Set(TipoDeEscala.todos).count)   // sin repetidos en el catálogo
        XCTAssertTrue(Escala.identificar(["Do", "Re♭", "Mi", "Fa", "Sol", "La♭", "Si"]).contains(Escala(.do, .dobleArmonica)))
    }

    func testMessiaenFlamencaBebopYAlias() {
        func notas(_ tipo: TipoDeEscala) -> String { Escala(.do, tipo).notas.map(\.description).joined(separator: " ") }
        XCTAssertEqual(notas(.messiaen3), "Do Re Mi♭ Mi Fa♯ Sol La♭ Si♭ Si")
        XCTAssertEqual(notas(.messiaen4), "Do Re♭ Re Fa Fa♯ Sol La♭ Si")
        XCTAssertEqual(notas(.messiaen5), "Do Re♭ Fa Fa♯ Sol Si")
        XCTAssertEqual(notas(.messiaen6), "Do Re Mi Fa Fa♯ Sol♯ La♯ Si")
        XCTAssertEqual(notas(.messiaen7), "Do Re♭ Re Mi♭ Fa Fa♯ Sol La♭ La Si")
        XCTAssertEqual(notas(.flamenca), "Do Re♭ Mi♭ Mi Fa Sol La♭ Si♭")
        XCTAssertEqual(notas(.petrushka), "Do Re♭ Mi Fa♯ Sol Si♭")
        XCTAssertEqual(notas(.bebopMenorMelodica), "Do Re Mi♭ Fa Sol Sol♯ La Si")
        XCTAssertEqual(notas(.bebopMenorArmonica), "Do Re Mi♭ Fa Sol La♭ Si♭ Si")

        // Transposición limitada: cuántas transposiciones distintas tiene cada modo.
        func transposiciones(_ tipo: TipoDeEscala) -> Int {
            let clases = tipo.intervalos.map { modulo($0.semitonos, 12) }
            return Set((0..<12).map { t in Set(clases.map { modulo($0 + t, 12) }) }).count
        }
        XCTAssertEqual([TipoDeEscala.tonosEnteros, .disminuida, .messiaen3, .messiaen4, .messiaen5, .messiaen6, .messiaen7]
            .map(transposiciones), [2, 3, 4, 6, 6, 6, 6])
        // Petrushka: los acordes mayores de Do y de Fa♯ (con Re♭ por Do♯ y Si♭ por La♯).
        XCTAssertEqual(Set(Escala(.do, .petrushka).notas.map(\.claseDeAltura)),
                       Set((Acorde("Do").notas + Acorde("Fa#").notas).map(\.claseDeAltura)))

        // Nombres y alias.
        XCTAssertEqual(Escala("Do modo 3 de Messiaen").tipo, .messiaen3)
        XCTAssertEqual(Escala("Do Tcherepnin").tipo, .messiaen3)
        XCTAssertEqual(Escala("C Messiaen mode 7").tipo, .messiaen7)
        XCTAssertEqual(Escala("Mi andaluza").tipo, .flamenca)
        XCTAssertEqual(Escala("E flamenco").tipo, .flamenca)
        XCTAssertEqual(Escala("Do bebop menor armónica").tipo, .bebopMenorArmonica)
        XCTAssertEqual(Escala("C bebop melodic minor").tipo, .bebopMenorMelodica)
        XCTAssertEqual(Escala("Re menor rumana").tipo, .doricoCuartaAumentada)
        XCTAssertEqual(Escala("D Romanian minor").tipo, .doricoCuartaAumentada)
        XCTAssertEqual(Escala("Mi Freygish").tipo.nombre, "Freygish")
        XCTAssertEqual(Escala("Mi Ahavah Rabbah").tipo, .frigioDominante)   // mismo contenido
        XCTAssertEqual(Escala("Do de Bartók").tipo, .lidioDominante)
        XCTAssertEqual(Escala("C overtone").tipo, .lidioDominante)
        XCTAssertEqual(Escala("Do disminuida auxiliar blues").tipo, .disminuidaSemitonoTono)
        XCTAssertEqual(Escala("C auxiliary augmented").tipo, .tonosEnteros)
        XCTAssertEqual(Escala(.do, .messiaen3).nombre(en: .ingles), "C Messiaen mode 3")
        XCTAssertEqual(Escala(.mi, .flamenca).nombre(en: .ingles), "E flamenco")
        XCTAssertEqual(TipoDeEscala.todos.count, Set(TipoDeEscala.todos).count)
    }

    func testModosDeLaDobleArmonicaYDeLasNapolitanas() {
        func modos(_ base: TipoDeEscala, _ esperados: [TipoDeEscala], file: StaticString = #filePath, line: UInt = #line) {
            for (i, modo) in esperados.enumerated() {
                XCTAssertTrue(base.rotacion(i + 1).esIdentico(a: modo), "\(base.nombre) \(i + 1): \(base.rotacion(i + 1).nombre)",
                              file: file, line: line)
            }
        }
        modos(.dobleArmonica, [.dobleArmonica, .lidioSegundaSextaAumentadas, .ultrafrigio, .menorHungara, .oriental,
                               .jonicoSegundaQuintaAumentadas, .locrioTerceraSeptimaDisminuidas])
        modos(.napolitanaMayor, [.napolitanaMayor, .lidioAumentadoSextaAumentada, .lidioDominanteAumentado, .lidioMenor,
                                 .mayorLocria, .locrioSegundaNaturalCuartaDisminuida, .superlocrioTerceraDisminuida])
        modos(.napolitanaMenor, [.napolitanaMenor, .lidioSextaAumentada, .mixolidioAumentado, .eolicoCuartaAumentada,
                                 .locrioDominante, .jonicoSegundaAumentada, .ultralocrioTerceraDisminuida])
        func notas(_ escala: Escala) -> String { escala.notas.map(\.description).joined(separator: " ") }
        XCTAssertEqual(notas(Escala(.do, .oriental)), "Do Re♭ Mi Fa Sol♭ La Si♭")
        XCTAssertEqual(notas(Escala(.do, .ultrafrigio)), "Do Re♭ Mi♭ Fa♭ Sol La♭ Si♭♭")
        XCTAssertEqual(Escala("C leading whole tone").tipo, .lidioAumentadoSextaAumentada)
        XCTAssertEqual(Escala("La gitana húngara").tipo, .eolicoCuartaAumentada)
    }

    func testPentatonicasBluesYHexacordos() {
        func notas(_ escala: Escala) -> String { escala.notas.map(\.description).joined(separator: " ") }
        XCTAssertEqual(notas(Escala(.do, .pentatonicaDominante)), "Do Re Mi Sol Si♭")
        XCTAssertEqual(notas(Escala(.do, .pentatonicaMenorSexta)), "Do Mi♭ Fa Sol La")
        XCTAssertEqual(notas(Escala(.do, .pentatonicaMayorSextaMenor)), "Do Re Mi Sol La♭")
        XCTAssertEqual(notas(Escala(.do, .pentatonicaMenorQuintaDisminuida)), "Do Mi♭ Fa Sol♭ Si♭")
        XCTAssertEqual(notas(Escala(.do, .bluesDeNueveNotas)), "Do Re Mi♭ Mi Fa Sol♭ Sol La Si♭")
        XCTAssertEqual(notas(Escala(.do, .bluesMenorConSegunda)), "Do Re Mi♭ Fa Sol♭ Sol Si♭")
        XCTAssertEqual(notas(.hexacordoNatural), "Do Re Mi Fa Sol La")
        XCTAssertEqual(notas(.hexacordoDuro), "Sol La Si Do Re Mi")
        XCTAssertEqual(notas(.hexacordoBlando), "Fa Sol La Si♭ Do Re")
        XCTAssertEqual(Escala("Do pentatónica de Coltrane").tipo, .pentatonicaMayorSextaMenor)
        XCTAssertEqual(Escala("C dominant pentatonic").tipo, .pentatonicaDominante)
        XCTAssertEqual(Escala("Sol hexacordo").tipo, .hexacordo)
        XCTAssertEqual(Escala(.do, .bluesDeNueveNotas).nombre(en: .ingles), "C nine tone blues")
        // Alias de escalas que ya estaban.
        XCTAssertEqual(Escala("Do mayor melódica").tipo, .mixolidioSextaMenor)
        XCTAssertEqual(Escala("Sol dominante b9 b13").tipo, .frigioDominante)
        XCTAssertEqual(TipoDeEscala.todos.count, Set(TipoDeEscala.todos).count)
    }

    func testEtiopesMaqamatIndonesiaYKlezmer() {
        func notas(_ tipo: TipoDeEscala) -> String { Escala(.do, tipo).notas.map(\.description).joined(separator: " ") }
        XCTAssertEqual(notas(.tezetaMayor), "Do Re Mi Sol La")
        XCTAssertEqual(notas(.tezetaMenor), "Do Re Mi♭ Sol La♭")
        XCTAssertEqual(notas(.batiMayor), "Do Mi Fa Sol Si")
        XCTAssertEqual(notas(.batiMenor), "Do Mi♭ Fa Sol Si♭")
        XCTAssertEqual(notas(.ambassel), "Do Re♭ Fa Sol La♭")
        XCTAssertEqual(notas(.anchihoye), "Do Re♭ Fa Sol♭ La")
        XCTAssertEqual(notas(.pelog), "Do Re♭ Mi♭ Sol La♭")
        XCTAssertEqual(notas(.slendro), "Do Re Fa Sol La")
        XCTAssertEqual(notas(.akebono), "Do Re Mi♭ Sol La")
        XCTAssertEqual(notas(.kokinjoshi), "Do Re♭ Fa Sol Si♭")
        XCTAssertEqual(notas(.adonaiMalakh), "Do Re Mi♭ Mi Fa Sol La Si♭")
        XCTAssertEqual(notas(.argelina), "Do Re Mi♭ Fa Fa♯ Sol La♭ Si")
        // Los maqamat temperados y los modos klezmer son escalas que ya había, con otro nombre.
        XCTAssertEqual(TipoDeEscala.hiyaz, .frigioDominante)
        XCTAssertEqual(TipoDeEscala.nahawand, .menorArmonica)
        XCTAssertEqual(TipoDeEscala.kurd, .frigio)
        XCTAssertEqual(TipoDeEscala.ajam, .mayor)
        XCTAssertEqual(TipoDeEscala.hiyazkar, .dobleArmonica)
        XCTAssertEqual(TipoDeEscala.nawaAthar, .menorHungara)
        XCTAssertEqual(TipoDeEscala.freygish, .frigioDominante)
        XCTAssertEqual(TipoDeEscala.misheberakh, .doricoCuartaAumentada)
        XCTAssertEqual(TipoDeEscala.magenAvot, .menorNatural)
        XCTAssertTrue(TipoDeEscala.frigioDominante.equivalentes.map(\.nombre).contains("Ḥijāz"))
        // Con diacríticos y sin ellos, y en su escritura.
        XCTAssertEqual(Escala("Do Təzəta menor").tipo.nombre, "Təzəta menor")
        XCTAssertEqual(Escala("Do Tezeta menor").tipo.nombre, "Təzəta menor")
        XCTAssertEqual(Escala("Do Tizita").tipo.nombre, "Təzəta mayor")
        XCTAssertEqual(Escala("Do anchihoye").tipo.nombre, "Ančihoye")
        XCTAssertEqual(Escala("Re Nahawand").tipo.nombre, "Nahāwand")
        XCTAssertEqual(Escala("Re Ajam").tipo.nombre, "ʿAjam")
        XCTAssertEqual(Escala("Re حجاز").tipo.nombre, "Ḥijāz")
        XCTAssertEqual(Escala("Do pelog").tipo.nombre, "Pélog selisir")
        XCTAssertEqual(Escala("Do slendro").tipo.nombre, "Sléndro")
        XCTAssertEqual(Escala("Do Kokin-joshi").tipo.nombre, "Kokin-jōshi")
        XCTAssertEqual(Escala("Mi gitana española").tipo, .flamenca)
        XCTAssertEqual(Escala("C Algerian").tipo, .argelina)
        XCTAssertEqual(Escala(.re, .nahawand).nombre(en: .ingles), "D Nahāwand")
        // Las tradicionales no entran en las búsquedas de escalas habituales.
        XCTAssertFalse(TipoDeEscala.todos.contains { $0.nombre == "Ḥijāz" })
    }

    func testRagasDastgahCoreanasAndinasYGriegas() {
        func notas(_ tipo: TipoDeEscala) -> String { Escala(.do, tipo).notas.map(\.description).joined(separator: " ") }
        XCTAssertEqual(notas(.malkauns), "Do Mi♭ Fa La♭ Si♭")
        XCTAssertEqual(notas(.durga), "Do Re Fa Sol La")
        XCTAssertEqual(notas(.yaman), "Do Re Mi Fa♯ Sol La Si")
        XCTAssertEqual(notas(.bagesri), "Do Mi♭ Fa La Si♭")
        XCTAssertEqual(Escala(.do, .bagesri.formaDescendente).notas.map(\.description).joined(separator: " "), "Do Re Mi♭ Fa La Si♭")
        XCTAssertEqual(notas(.des), "Do Re Fa Sol Si")
        XCTAssertTrue(TipoDeEscala.des.esDireccional)
        XCTAssertEqual(TipoDeEscala.malkauns, .hindolam)
        XCTAssertEqual(TipoDeEscala.bhupali, .pentatonicaMayor)
        XCTAssertEqual(TipoDeEscala.yaman, .kalyan)
        XCTAssertEqual(TipoDeEscala.mahur, .mayor)
        XCTAssertEqual(TipoDeEscala.homayun, .frigioDominante)
        XCTAssertEqual(TipoDeEscala.cahargah, .dobleArmonica)
        XCTAssertEqual(notas(.pyongjo), "Do Re Fa Sol La")
        XCTAssertEqual(notas(.kyemyonjo), "Do Mi♭ Fa Sol Si♭")
        XCTAssertEqual(notas(.tritonicaAndina), "Do Mi♭ Sol")
        XCTAssertEqual(TipoDeEscala.andina, .pentatonicaMenor)
        XCTAssertEqual(Escala(.mi, .tetracordoCromatico).notas.map(\.description).joined(separator: " "), "Mi Fa Sol♭ La")
        XCTAssertEqual(Escala(.mi, .harmoniaDoriaCromatica).notas.map(\.description).joined(separator: " "), "Mi Fa Sol♭ La Si Do Re♭")
        XCTAssertEqual(TipoDeEscala.harmoniaDoria, .frigio)
        XCTAssertEqual(TipoDeEscala.harmoniaFrigia, .dorico)
        XCTAssertEqual(TipoDeEscala.harmoniaLidia, .mayor)
        // Gaélicas y de dos tríadas, en el catálogo habitual.
        XCTAssertEqual(notas(.jonicoSinCuarta), "Do Re Mi Sol La Si")
        XCTAssertEqual(notas(.mixolidioSinTercera), "Do Re Fa Sol La Si♭")
        XCTAssertEqual(notas(.doricoSinSexta), "Do Re Mi♭ Fa Sol Si♭")
        XCTAssertEqual(notas(.eolicoSinSegunda), "Do Mi♭ Fa Sol La♭ Si♭")
        XCTAssertEqual(Set(Escala(.do, .hexatonicaDeDosTriadas).notas), Set(Acorde("Do").notas + Acorde("Re").notas))
        XCTAssertEqual(TipoDeEscala.todos.count, Set(TipoDeEscala.todos).count)
        // Nombres.
        for (texto, nombre) in [("Do Bhupali", "Bhūpālī"), ("Do malkauns", "Mālkauns"), ("Do Bageshri", "Bāgeśrī"),
                                ("Do Desh", "Deś"), ("Do Chahargah", "Čahārgāh"), ("Do Homayoun", "Homāyun"),
                                ("Do Pyeongjo", "P'yŏngjo"), ("Do 계면조", "Kyemyŏnjo"), ("La andina", "pentatónica andina"),
                                ("Mi harmonia doria cromatica", "harmonía doria cromática"), ("Do jónico sin 4ª", "jónico sin 4ª"),
                                ("C triad pair", "hexatónica de dos tríadas")] {
            XCTAssertEqual(Escala(texto: texto)?.tipo.nombre, nombre, texto)
        }
    }

    func testModosDeLaMayorHungaraPentatonicasYAliasDeCompositor() {
        func notas(_ escala: Escala) -> String { escala.notas.map(\.description).joined(separator: " ") }
        // Las rotaciones de la mayor húngara (Do Re♯ Mi Fa♯ Sol La Si♭) dan sus seis modos.
        let hungara = Escala(.do, .mayorHungara)
        let modos: [(TipoDeEscala, String)] = [
            (.ultralocrioSextaDisminuida, "Re♯ Mi Fa♯ Sol La Si♭ Do"),
            (.menorArmonicaQuintaDisminuida, "Mi Fa♯ Sol La Si♭ Do Re♯"),
            (.superlocrioSextaNatural, "Fa♯ Sol La Si♭ Do Re♯ Mi"),
            (.menorMelodicaQuintaAumentada, "Sol La Si♭ Do Re♯ Mi Fa♯"),
            (.doricoSegundaMenorCuartaAumentada, "La Si♭ Do Re♯ Mi Fa♯ Sol"),
            (.lidioAumentadoTerceraAumentada, "Si♭ Do Re♯ Mi Fa♯ Sol La"),
        ]
        for (i, (tipo, esperado)) in modos.enumerated() {
            XCTAssertEqual(hungara.rotacion(i + 2).tipo.nombre, tipo.nombre)
            XCTAssertEqual(notas(Escala(hungara.grado(i + 2), tipo)), esperado)
        }
        // Pentatónicas.
        XCTAssertEqual(notas(Escala(.do, .pentatonicaMixolidia)), "Do Mi Fa Sol Si♭")
        XCTAssertEqual(notas(Escala(.do, .pentatonicaLidia)), "Do Mi Fa♯ Sol Si")
        XCTAssertEqual(notas(Escala(.do, .pentatonicaEscocesa)), "Do Re Fa Sol La")
        XCTAssertEqual(Escala(.do, .pentatonicaMayor).rotacion(4).tipo.nombre, "pentatónica escocesa")
        XCTAssertTrue(TipoDeEscala.pentatonicaEscocesa.equivalentes.contains { $0.nombre == "Sléndro" })
        XCTAssertTrue(TipoDeEscala.pentatonicaLidia.equivalentes.contains { $0.nombre == "Amṛtavarṣiṇī" })
        XCTAssertTrue(TipoDeEscala.egipcia.equivalentes.contains { $0.nombre == "Megh" })
        // Otras.
        XCTAssertEqual(notas(Escala(.do, .mayorRumana)), "Do Re♭ Mi Fa♯ Sol La Si♭")
        XCTAssertEqual(Set(Escala(.re, .hexatonicaMenorDeDosTriadas).notas), Set(Acorde("Rem").notas + Acorde("Mim").notas))
        XCTAssertEqual(notas(Escala(.do, .sivaranjani)), "Do Re Mi♭ Sol La")
        XCTAssertEqual(notas(Escala(.do, .kalavati)), "Do Mi Sol La Si♭")
        XCTAssertEqual(notas(Escala(.do, .revati)), "Do Re♭ Fa Sol Si♭")
        XCTAssertEqual(notas(Escala(.do, .candrakauns)), "Do Mi♭ Fa La♭ Si")
        XCTAssertEqual(TipoDeEscala.todos.count, Set(TipoDeEscala.todos).count)
        // Nombres de compositor y otros alias.
        for (texto, nombre) in [("La de Liszt", "menor húngara"), ("Do Rimski-Kórsakov", "disminuida semitono-tono"),
                                ("Do de Debussy", "tonos enteros"), ("Do Weitzmann", "aumentada"),
                                ("Do nordestina", "lidio dominante"), ("Do hindú", "mixolidio ♭6"),
                                ("Do escocesa", "pentatónica escocesa"), ("Do superlocrio ♮6", "superlocrio ♮6"),
                                ("C Romanian major", "mayor rumana"), ("Do Shivaranjani", "Śivarañjanī"),
                                ("Do Chandrakauns", "Candrakauns"), ("Do Amritavarshini", "Amṛtavarṣiṇī")] {
            XCTAssertEqual(Escala(texto: texto)?.tipo.nombre, nombre, texto)
        }
    }

    func testModosGregorianos() {
        XCTAssertEqual(ModoGregoriano.todos.map(\.nombreGriego),
                       ["dórico", "hipodórico", "frigio", "hipofrigio", "lidio", "hipolidio", "mixolidio", "hipomixolidio"])
        XCTAssertEqual(ModoGregoriano.todos.map(\.finalis), [.re, .re, .mi, .mi, .fa, .fa, .sol, .sol])
        XCTAssertEqual(ModoGregoriano.todos.map(\.tenor), [.la, .fa, .do, .la, .do, .la, .re, .do])
        XCTAssertNil(ModoGregoriano(0))
        XCTAssertNil(ModoGregoriano(9))

        let primero = ModoGregoriano(1)!
        XCTAssertTrue(primero.esAutentico)
        XCTAssertEqual(primero.maneria, .protus)
        XCTAssertEqual(primero.escala, Escala(.re, .dorico))
        XCTAssertEqual(primero.ambito.map(\.description), ["Re4", "Mi4", "Fa4", "Sol4", "La4", "Si4", "Do5", "Re5"])
        XCTAssertEqual(primero.description, "modo 1 (protus auténtico, dórico): final Re, tenor La, ámbito Re4–Re5")

        let segundo = ModoGregoriano(2)!
        XCTAssertFalse(segundo.esAutentico)
        XCTAssertEqual(segundo.escala, primero.escala)
        XCTAssertEqual(segundo.ambito.map(\.description), ["La3", "Si3", "Do4", "Re4", "Mi4", "Fa4", "Sol4", "La4"])
        XCTAssertEqual(ModoGregoriano(8)!.description, "modo 8 (tetrardus plagal, hipomixolidio): final Sol, tenor Do, ámbito Re4–Re5")
        for modo in ModoGregoriano.todos {
            XCTAssertEqual(modo.ambito.count, 8)
            XCTAssertTrue(modo.ambito.contains(Altura(modo.finalis, octava: 4)))
        }

        XCTAssertEqual(ModoGregoriano(nombre: "hipofrigio")?.numero, 4)
        XCTAssertEqual(ModoGregoriano(nombre: "Tritus Plagal")?.numero, 6)
        XCTAssertEqual(ModoGregoriano(nombre: "modo 7")?.numero, 7)
        XCTAssertEqual(ModoGregoriano(nombre: "hipodorico")?.numero, 2)
        XCTAssertNil(ModoGregoriano(nombre: "eólico"))
    }

    func testEscalasChinas() {
        XCTAssertEqual(TipoDeEscala.chinas.map(\.nombre), ["Gōng", "Shāng", "Jué", "Zhǐ", "Yǔ", "Qīngyuè", "Yǎyuè", "Yànyuè"])
        // Los cinco modos son las rotaciones de la pentatónica: gōng, shāng, jué, zhǐ y yǔ
        // empiezan en Do, Re, Mi, Sol y La.
        let pentatonica = Escala(.do, .gong)
        for (tipo, tonica) in zip([TipoDeEscala.gong, .shang, .jue, .zhi, .yu], [Nota.do, .re, .mi, .sol, .la]) {
            XCTAssertEqual(Set(Escala(tonica, tipo).notas), Set(pentatonica.notas), tipo.nombre)
        }
        XCTAssertEqual(TipoDeEscala.gong, .pentatonicaMayor)
        XCTAssertEqual(TipoDeEscala.yu, .pentatonicaMenor)
        XCTAssertEqual(TipoDeEscala.qingyue, .mayor)
        XCTAssertEqual(TipoDeEscala.yayue, .lidio)
        XCTAssertEqual(TipoDeEscala.yanyue, .mixolidio)
        XCTAssertEqual(Escala(.re, .zhi).notas.map(\.description), ["Re", "Mi", "Sol", "La", "Si"])
        // Se leen con tonos, sin ellos y en caracteres chinos; el nombre no se traduce.
        for texto in ["Do Gōng", "Do gong", "Do GONG", "Do 宫", "Do 宮", "C gong"] {
            XCTAssertEqual(Escala(texto: texto)?.tipo.nombre, "Gōng", texto)
        }
        XCTAssertEqual(Escala("Sol zhi").tipo.nombre, "Zhǐ")
        XCTAssertEqual(Escala("Mi jiao").tipo.nombre, "Jué")
        XCTAssertEqual(Escala("Do yayue").tipo.nombre, "Yǎyuè")
        XCTAssertEqual(Escala(.la, .yu).nombre(en: .ingles), "A Yǔ")
        XCTAssertTrue(TipoDeEscala.pentatonicaMayor.equivalentes.contains { $0.nombre == "Gōng" })
    }

    func testEscalasJaponesas() {
        XCTAssertEqual(TipoDeEscala.japonesas.map(\.nombre),
                       ["Ritsu", "Ryo", "Yō", "Min'yō", "Miyakobushi", "In", "Insen", "Iwato", "Hirajōshi", "Kumoijōshi", "Ryūkyū",
                        "Akebono", "Kokin-jōshi"])
        func notas(_ tonica: Nota, _ tipo: TipoDeEscala) -> String { Escala(tonica, tipo).notas.map(\.description).joined(separator: " ") }
        XCTAssertEqual(notas(.do, .hirajoshi), "Do Re Mi♭ Sol La♭")
        XCTAssertEqual(notas(.do, .kumoijoshi), "Do Re Mi♭ Sol La")
        XCTAssertEqual(notas(.do, .iwato), "Do Re♭ Fa Sol♭ Si♭")
        XCTAssertEqual(notas(.do, .insen), "Do Re♭ Fa Sol Si♭")
        XCTAssertEqual(notas(.mi, .miyakobushi), "Mi Fa La Si Do")
        XCTAssertEqual(notas(.re, .minyo), "Re Fa Sol La Do")
        XCTAssertEqual(notas(.do, .ryukyu), "Do Mi Fa Sol Si")
        XCTAssertEqual(notas(.re, .ritsu), "Re Mi Sol La Si")
        XCTAssertEqual(notas(.re, .ryo), "Re Mi Fa♯ La Si")
        // Varias coinciden en notas con otras: in y miyakobushi, yō y ritsu, min'yō y la
        // pentatónica menor, ryo y la mayor.
        XCTAssertEqual(TipoDeEscala.in, .miyakobushi)
        XCTAssertEqual(TipoDeEscala.yo, .ritsu)
        XCTAssertEqual(TipoDeEscala.minyo, .pentatonicaMenor)
        XCTAssertEqual(TipoDeEscala.ryo, .pentatonicaMayor)
        XCTAssertEqual(Set(TipoDeEscala.in.equivalentes.map(\.nombre)), ["Miyakobushi", "Ambassäl"])
        // Con macrones, sin ellos y en japonés.
        for (texto, nombre) in [("Do Hirajōshi", "Hirajōshi"), ("Do hirajoshi", "Hirajōshi"), ("Do 平調子", "Hirajōshi"),
                                ("Do Ryūkyū", "Ryūkyū"), ("Do ryukyu", "Ryūkyū"), ("Do okinawa", "Ryūkyū"),
                                ("Re min'yō", "Min'yō"), ("Re minyo", "Min'yō"), ("Re yo", "Yō"), ("Mi in", "In"),
                                ("Mi miyako-bushi", "Miyakobushi"), ("Do kumoi", "Kumoijōshi"), ("Do 岩戸", "Iwato")] {
            XCTAssertEqual(Escala(texto: texto)?.tipo.nombre, nombre, texto)
        }
        XCTAssertEqual(Escala(.do, .hirajoshi).nombre(en: .ingles), "C Hirajōshi")
        XCTAssertFalse(TipoDeEscala.todos.contains { $0.nombre == "Hirajōshi" })
    }

    func testBusquedaYNombres() {
        XCTAssertEqual(Escala("Re hitzaz"), Escala(.re, .hitzaz))
        XCTAssertEqual(Escala("Re Hicaz").tipo.nombre, "Hitzáz")
        // «Hijaz» es el nombre del maqam y gana al alias del dromos.
        XCTAssertEqual(Escala("Re Hijaz").tipo.nombre, "Ḥijāz")
        XCTAssertEqual(Escala("Do Kafi"), Escala(.do, .kafi))
        XCTAssertEqual(Escala("Do melakarta 15").tipo.nombre, "Māyāmālavagauḷa")
        XCTAssertEqual(Escala("Do mayamalavagowla").tipo, .bhairav)
        XCTAssertEqual(TipoDeEscala.buscar(nombre: "souzinak")?.nombre, "Nikríz")
        // Los nombres propios no se traducen…
        XCTAssertEqual(Escala(.re, .hitzaz).nombre(en: .ingles), "D Hitzáz")
        XCTAssertEqual(Escala(.re, .hitzaz).texto(en: .ingles), "D Hitzáz")
        // …y las escalas habituales siguen igual: los nombres de siempre van primero.
        XCTAssertEqual(TipoDeEscala.buscar(nombre: "mayor")?.nombre, "mayor")
        XCTAssertEqual(TipoDeEscala.frigioDominante.nombre(en: .ingles), "phrygian dominant")
        XCTAssertFalse(TipoDeEscala.todos.contains { $0.nombre == "Hitzáz" })
    }
}
