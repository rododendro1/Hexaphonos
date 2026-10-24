// Generado por Scripts/generar_pruebas_de_documentacion.py a partir de los bloques ```swift
// del README y del catálogo DocC. No lo edites a mano: cambia el ejemplo y vuelve a generarlo.

import Foundation
import XCTest
@testable import Armonia
import Hexagonos

final class EjemplosDeDocumentacionTests: XCTestCase {
    func testREADME1() throws {
        // README.md, línea 11
        let i = Altura("Re5") - Altura("Do4")
        comprobar(Nota.si.intervalo(hasta: .fa), #"5ª disminuida"#, #"README.md"#, 14)
        comprobar(Intervalo.terceraMayor.inversion, #"6ª menor"#, #"README.md"#, 15)
        comprobar(Altura("La4").frecuencia(), #"440.0"#, #"README.md"#, 16)
        comprobar(Altura(midi: 63, preferirBemoles: true), #"Mi♭4"#, #"README.md"#, 17)
        comprobar(Acorde("Sol7/Si").posicionCerrada(octava: 3), #"[Si3, Re4, Fa4, Sol4]"#, #"README.md"#, 19)
        comprobar(Acorde.identificar([.mi, .sol, .do]).first, #"Do/Mi"#, #"README.md"#, 20)
        let menor = Escala("La menor armónica")
        comprobar(menor.cifradosRomanos(cuatriadas: true), #"["i(maj7)", "iiø7", "♭III+maj7", "iv7", "V7", "♭VImaj7", "vii°7"]"#, #"README.md"#, 23)
        comprobar(Escala("Mib mayor").armadura, #"-3"#, #"README.md"#, 25)
        comprobar(Escala(.do).rotacion(2), #"Re dórico"#, #"README.md"#, 26)
        _ = i
    }

    func testAcordes1() throws {
        // Sources/Armonia/Armonia.docc/Acordes.md, línea 13
        comprobar(Acorde("G7(b9,#11)").cifrado, #""Sol7(♭9,♯11)""#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 13)
        comprobar(TipoDeAcorde("m11").cifrado, #""m11""#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 14)
        comprobar(TipoDeAcorde("13sus4").intervalos, #"[1ª justa, 4ª justa, 5ª justa, 7ª menor, 9ª mayor, 13ª mayor]"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 15)
        comprobar(TipoDeAcorde("7alt").cifrado, #""7(♭9,♯9,♯11,♭13)""#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 16)
        _ = Acorde("Do6/9/Mi")
        comprobar(Acorde("Do/Re").tieneBajoAjeno, #"true"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 18)
    }

    func testAcordes2() throws {
        // Sources/Armonia/Armonia.docc/Acordes.md, línea 35
        let c = Acorde.candidatos([.do, .mi, "Sib"]).first!
        comprobar(c.valor.cifrado, #""Do7""#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 36)
        comprobar(c.omitidas, #"[Sol]"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 37)
        comprobar(Acorde.identificar([.do, .mi, "Sib", "Reb"]).first, #"Do7(♭9)"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 38)
    }

    func testAcordes3() throws {
        // Sources/Armonia/Armonia.docc/Acordes.md, línea 49
        comprobar(Acorde("Lab(#6,omit5)").tipo.nombre, #""sexta aumentada italiana""#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 49)
        comprobar(Acorde.identificar(["La♭", "Do", "Fa♯"] as [Nota]).first?.cifrado, #""La♭(♯6,omit5)""#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 50)
        comprobar(Acorde.identificar(["La♭", "Do", "Mi♭", "Fa♯"] as [Nota]).first?.cifrado, #""La♭(♯6)""#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 51)
    }

    func testAcordes4() throws {
        // Sources/Armonia/Armonia.docc/Acordes.md, línea 65
        comprobar(Acorde.identificar(midi: [60, 64, 68]).first, #"Do+"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 65)
        comprobar(Acorde.identificar(midi: [60, 63, 66, 69]).first, #"Do°7"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 66)
        comprobar(Acorde.identificar(midi: [61, 65, 68]).first, #"Re♭"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 67)
        comprobar(Acorde.identificar(midi: [55, 59, 62, 65, 68]).first, #"Sol7(♭9)"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 68)
        comprobar(Acorde.identificar(midi: [66, 70, 73], tonalidad: "Solb mayor").first, #"Sol♭"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 69)
        comprobar(Acorde("Do+").ortografiar(midi: [60, 64, 68]), #"[Do4, Mi4, Sol♯4]"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 70)
    }

    func testAcordes5() throws {
        // Sources/Armonia/Armonia.docc/Acordes.md, línea 100
        let a: Acorde = "Sol13(b9)"
        comprobar(a.componentes.map { "\($0.nota) \($0.papel)" }, #"["Sol fundamental", "Si tercera", "Re quinta", "Fa séptima", "La♭ novena", "Mi decimotercera"]"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 101)
        _ = (a.tercera, a.quinta, a.septima)
        comprobar(a.tensiones, #"[La♭, Mi]"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 104)
        comprobarIgual(a.papel(de: "Lab"), .tension(9), #"Sources/Armonia/Armonia.docc/Acordes.md"#, 105)
        comprobarIgual(a.estructura.calidadDeTriada, .mayor, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 106)
        comprobar(TipoDeAcorde("7sus4").estructura.suspension, #"4ª justa"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 107)
    }

    func testAcordes6() throws {
        // Sources/Armonia/Armonia.docc/Acordes.md, línea 126
        comprobar(Acorde("Sol7").vecinosParsimoniosos().map(\.description) == ["Sol♯°7 (Sol→Sol♯)", "Solm7 (Si→Si♭)", "Mim7 (Fa→Mi)"], #"true"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 126)
        comprobar(Acorde("Sol7").vecinosParsimoniosos(voces: 2).contains { $0.acorde == Acorde("Reb7") }, #"true"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 127)
        comprobar(Tonnetz.caminoParsimonioso(desde: "Sol7", hasta: "Rem7")?.map(\.acorde.cifrado) == ["Sol♯°7", "Sim7(♭5)", "Rem7"], #"true"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 128)
        comprobar(Tonnetz.caminoParsimonioso(desde: "Sol7", hasta: "Reb7", voces: 2)?.count == 1, #"true"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 129)
        comprobar(Acorde("Domaj7").vecinosParsimoniosos().map(\.description) == ["Do♯m7(♭5) (Do→Do♯)", "Do7 (Si→Si♭)"], #"true"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 130)
        comprobar(Tonnetz.caminoParsimonioso(desde: "Domaj7", hasta: "Sol7")?.count == 3, #"true"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 131)
    }

    func testAcordes7() throws {
        // Sources/Armonia/Armonia.docc/Acordes.md, línea 145
        comprobar("\(Acorde("Sol7").conduccionMinima(hasta: "Do"))", #""Sol→Sol, Si→Do (+1), Re→Do (−2), Fa→Mi (−1): 4 semitonos""#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 145)
        comprobar(Acorde("Rem7").conduccionMinima(hasta: "Sol7").total == 3, #"true"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 146)
        comprobar(Acorde("Do").conduccionMinima(hasta: "Lam").total == 2, #"true"#, #"Sources/Armonia/Armonia.docc/Acordes.md"#, 147)
    }

    func testAfinacionYRepresentaciones1() throws {
        // Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md, línea 8
        _ = TemperamentoRegular.igual
        _ = TemperamentoRegular.pitagorico
        _ = TemperamentoRegular.mesotonicoCuartoDeComa
        _ = TemperamentoRegular.igual(divisiones: 31)
        _ = EntonacionJusta(tonica: .do)
        _ = Altura("Sol#4").frecuencia(en: TemperamentoRegular.mesotonicoCuartoDeComa)
        comprobar(Intervalo.terceraMayor.razonJusta, #"5/4"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 14)
        comprobar(TemperamentoRegular.igual.cents(de: .terceraMayor), #"400"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 15)
        comprobar(EntonacionJusta(tonica: .do).desviacion(de: "Mi4"), #"−13,69 cents"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 16)
    }

    func testAfinacionYRepresentaciones2() throws {
        // Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md, línea 33
        comprobar(Altura("Do4").numero(en: .base40), #"162"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 33)
        comprobar(Altura("Fa#4").numero(en: .base40), #"180"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 34)
        comprobar(Altura("Solb4").numero(en: .base40), #"184"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 35)
        comprobar(Altura(numero: 185, en: .base40), #"Sol4"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 36)
        comprobar(Intervalo.quintaJusta.numero(en: .base40), #"23"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 37)
        comprobar(Intervalo(numero: 12, en: .base40), #"3ª mayor"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 38)
        comprobar(Intervalo(numero: 20, en: .base40), #"nil"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 39)
        comprobar(Nota("Si#").numero(en: .base40), #"38"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 40)
        comprobar(Altura(Nota(.fa, 3), octava: 4).numero(en: .base40), #"nil"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 41)
        comprobar(Altura(Nota(.fa, 3), octava: 4).numero(en: .base54), #"245"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 42)
        comprobar(Altura("Do4").numero(en: .base600), #"2442"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 43)
        _ = BaseDeHewlett(base: 96)
    }

    func testAfinacionYRepresentaciones3() throws {
        // Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md, línea 63
        comprobar(Nota.re.color(segun: .scriabin), #"#FFFF00"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 63)
        comprobar(CorrespondenciaDeColores.scriabin.nombreDelColor(de: .mi), #""azul cielo (luz de luna o escarcha)""#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 64)
        comprobar(Altura("La4").color(segun: .newton).hexadecimal, ##""#4B0082""##, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 65)
        comprobar(Acorde("Do").colores(segun: .circuloDeQuintas), #"[#FF0000, #00FF00, #FF8000]"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 66)
        _ = Escala(.re, .dorico).colores(segun: .castel)
        _ = (ColorRGB(hexadecimal: "#FF8000"), ColorRGB(tono: 120, saturacion: 1, brillo: 1))
    }

    func testAfinacionYRepresentaciones4() throws {
        // Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md, línea 87
        comprobar(PuntoDelTonnetz(quintas: 0, terceras: 1).nota, #"Mi"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 87)
        comprobar(PuntoDelTonnetz(quintas: 1, terceras: -1).nota, #"Mi♭"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 88)
        comprobar(PuntoDelTonnetz(quintas: 4, terceras: -1).claseDeAltura, #"0"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 89)
        comprobar("\(Tonnetz(Acorde("Do")))", #""Do (0, 0) · Mi (0, 1) · Sol (1, 0)""#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 90)
        comprobar(Tonnetz(Acorde("Domaj7")).triadas.map(\.acorde) == [Acorde("Do"), Acorde("Mim")], #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 91)
        comprobar(Tonnetz(Escala(.do)).esConexo, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 92)
        comprobar(Tonnetz(Escala(.do, .tonosEnteros)).esConexo, #"false"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 93)
        comprobar("\(Tonnetz(ConjuntoDeClases([0, 4, 7])))", #""0 (0, 0) · 4 (0, 1) · 7 (1, 0)""#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 94)
    }

    func testAfinacionYRepresentaciones5() throws {
        // Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md, línea 112
        let dibujo = Tonnetz(Escala(.re, .dorico)).svg()
        let sinLeyenda = Tonnetz(Acorde("Do")).svg(titulo: "Tónica", leyenda: false)
        let ingles = Tonnetz(Acorde("Fa#m7")).svg(notacion: .ingles, margen: 2)
        let toro = Tonnetz(ConjuntoDeClases([0, 4, 7, 11])).svg(margen: 3)
        _ = (dibujo, sinLeyenda, ingles, toro)
    }

    func testAfinacionYRepresentaciones6() throws {
        // Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md, línea 134
        comprobar(Acorde("Do").transformar(.r) == Acorde("Lam"), #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 134)
        comprobar(Acorde("Mib").transformar(.r) == Acorde("Dom"), #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 135)
        comprobar(Acorde("Do").transformar(leyendo: "PLR") == Acorde("Fam"), #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 136)
        comprobar(Acorde("Do").transformar(TransformacionNeorriemanniana.s) == Acorde("Do#m"), #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 137)
        comprobar(Acorde("Sol7").transformar(.p) == nil, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 138)
        comprobar(TransformacionNeorriemanniana.entre("Do", "Mim") == .l, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 139)
        comprobar(Tonnetz.camino(desde: "Do", hasta: "Mibm") == [.p, .r, .p], #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 140)
        comprobar(Tonnetz.camino(desde: "Do", hasta: "Sol#", enarmonico: true) == [.p, .l], #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 141)
    }

    func testAfinacionYRepresentaciones7() throws {
        // Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md, línea 157
        let recorrido = Tonnetz(recorrido: ["Do", "Lam", "Fa", "Rem"])
        comprobar(recorrido?.recorrido.count == 4, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 158)
        let bomba = Tonnetz(recorrido: ["Do", "Lam", "Rem", "Sol", "Do"])!
        comprobar(bomba.recorrido.first == bomba.recorrido.last, #"false"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 160)
        let dibujo = Tonnetz(caminoDesde: "Do", hasta: "Fa#")?.svg()
        _ = dibujo
    }

    func testAfinacionYRepresentaciones8() throws {
        // Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md, línea 178
        comprobar(Acorde("Do").ciclo(.hexatonico)?.map(\.cifrado) == ["Do", "Dom", "La♭", "La♭m", "Mi", "Mim", "Do"], #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 178)
        comprobar(Acorde("Do").ciclo(.octatonico)?.map(\.cifrado) == ["Do", "Dom", "Mi♭", "Mi♭m", "Sol♭", "Fa♯m", "La", "Lam", "Do"], #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 179)
        comprobar(Acorde("Do").ciclo(.lr)?.count == 25, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 180)
        comprobar(Tonnetz(ciclo: .hexatonico, desde: "Do")?.recorrido.count == 7, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 181)
    }

    func testAfinacionYRepresentaciones9() throws {
        // Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md, línea 222
        comprobar(TablaArmonica.midi(de: PuntoDelTonnetz(quintas: 1, terceras: 0)) == 67, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 222)
        comprobar(TablaArmonica(Acorde("Domaj7")).triadas.map(\.acorde) == [Acorde("Do"), Acorde("Mim")], #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 223)
        comprobar(TablaArmonica([Altura("Do4"), Altura("Mi4"), Altura("Sol4")]).triadas.count == 1, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 224)
        comprobar(TablaArmonica([Altura("Do3"), Altura("Mi4"), Altura("Sol4")]).triadas.count == 0, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 225)
        comprobar("\(TablaArmonica([Altura("Do4"), Altura("Sol4")]))", #""Do4 (0, 0) · Sol4 (1, 0)""#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 226)
        let dibujo = TablaArmonica(Escala(.re, .dorico)).svg()
        _ = dibujo
    }

    func testAfinacionYRepresentaciones10() throws {
        // Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md, línea 250
        comprobar(TablaArmonica(recorrido: ["Do", "Lam", "Fa"])?.recorrido.count == 3, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 250)
        comprobar(TablaArmonica(caminoDesde: "Do", hasta: "Sol7") == nil, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 251)
    }

    func testAfinacionYRepresentaciones11() throws {
        // Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md, línea 266
        let mi = PuntoDelTonnetz(quintas: 0, terceras: 1)
        comprobar(mi.coordenada == CoordenadaAxial(q: 0, r: 1), #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 269)
        comprobar(PuntoDelTonnetz(CoordenadaAxial(q: 1, r: 0)).nota == .sol, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 270)
        comprobar(Tonnetz.punto(en: Punto(x: 60, y: 3), paso: 64) == PuntoDelTonnetz(quintas: 1, terceras: 0), #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 271)
        comprobar(TablaArmonica.coordenada(de: mi) == CoordenadaAxial(q: 1, r: -1), #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 272)
    }

    func testAfinacionYRepresentaciones12() throws {
        // Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md, línea 280
        let teclado = TecladoIsomorfico.wickiHayden
        comprobar(teclado.midi(en: CoordenadaAxial(q: 1, r: -1)) == 67, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 283)
        comprobar(teclado.semitonos(hacia: DireccionHexagonal(.noreste, .puntiaguda)!) == 7, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 284)
        comprobar(TecladoIsomorfico.tablaArmonica.semitonos(hacia: .sMasRMenos) == 7, #"true"#, #"Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md"#, 285)
        let mapa = FormasDeMapa.rectangulo(columnas: 12, filas: 4, .filasImpares)
        let dibujo = TecladoIsomorfico.janko.svg(mapa, marcadas: [60, 64, 67])
        _ = dibujo
    }

    func testArmonia1() throws {
        // Sources/Armonia/Armonia.docc/Armonia.md, línea 12
        comprobar(Acorde("Sol7/Si").posicionCerrada(octava: 3), #"[Si3, Re4, Fa4, Sol4]"#, #"Sources/Armonia/Armonia.docc/Armonia.md"#, 14)
        _ = Escala("La menor armónica").cifradosRomanos(cuatriadas: true)
        comprobar(Tonalidad.identificar(midi: [69, 71, 72, 74, 76, 77, 80, 81]).first, #"La menor"#, #"Sources/Armonia/Armonia.docc/Armonia.md"#, 16)
    }

    func testConvenciones1() throws {
        // Sources/Armonia/Armonia.docc/Convenciones.md, línea 17
        func subirQuinta<T: Transponible>(_ x: T) -> T { x + .quintaJusta }
        comprobar(subirQuinta(Acorde("Do7")), #"Sol7"#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 18)
        comprobar(subirQuinta(Escala(.do)), #"Sol mayor"#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 19)
        comprobar(Nota.do.secuencia(.quintaJusta, veces: 3), #"Do, Sol, Re, La"#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 20)
        comprobar(Acorde("Do").esDeLaMismaClase(que: Acorde("Lam")), #"true"#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 21)
        comprobar(Acorde("Sib7(b9)/Re").texto(.ingles), #""Bb7(b9)/D""#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 22)
        comprobar(Escala("Re dórico").nombre(en: .ingles), #""D dorian""#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 23)
    }

    func testConvenciones2() throws {
        // Sources/Armonia/Armonia.docc/Convenciones.md, línea 32
        let n: Nota = "Fa#";  let i: Intervalo = "3M";  let a: Acorde = "Sol7/Si"
        let e: Escala = "Re dórico";  let t: TipoDeAcorde = "m7(b5)"
        comprobar(Nota.re + "3M", #"Fa♯"#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 34)
        comprobar(String(decoding: try JSONEncoder().encode([a]), as: UTF8.self), #"["Sol7\/Si"]"#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 35)
        comprobar([Intervalo.quintaJusta, .terceraMayor].sorted(), #"[3ª mayor, 5ª justa]"#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 36)
        _ = Escala("La menor melódica").alturas(octava: 4, direccion: .descendente)
        comprobar(Escala(.la, .menorArmonica).cifradosRomanos(referencia: .menorNatural), #"["i", "ii°", "III+", "iv", "V", "VI", "♯vii°"]"#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 38)
        _ = (n, e, i, t)
    }

    func testConvenciones3() throws {
        // Sources/Armonia/Armonia.docc/Convenciones.md, línea 51
        let entrada = "Sol7"
        let a = Acorde("Sol7")
        let b = Acorde(texto: entrada)
        let c = try Acorde(leyendo: entrada)
        _ = (a, b, c)
    }

    func testConvenciones4() throws {
        // Sources/Armonia/Armonia.docc/Convenciones.md, línea 91
        comprobarIgual(NombreDeGrado("submediante"), .superdominante, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 91)
        _ = (NombreDeGrado("Tónica"), NombreDeGrado("leading tone"))
        comprobar(PapelEnAcorde("oncena") == PapelEnAcorde("undécima"), #"true"#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 93)
        comprobar(PapelEnAcorde("trecena") == PapelEnAcorde("decimotercera"), #"true"#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 94)
        comprobar(PapelEnAcorde.tension(11).nombre, #""undécima""#, #"Sources/Armonia/Armonia.docc/Convenciones.md"#, 95)
    }

    func testElModelo1() throws {
        // Sources/Armonia/Armonia.docc/ElModelo.md, línea 39
        let i = Altura("Re5") - Altura("Do4")
        comprobar(Nota.si.intervalo(hasta: .fa), #"5ª disminuida"#, #"Sources/Armonia/Armonia.docc/ElModelo.md"#, 42)
        comprobar(Intervalo.terceraMayor.inversion, #"6ª menor"#, #"Sources/Armonia/Armonia.docc/ElModelo.md"#, 43)
        comprobar(Altura("La4").frecuencia(), #"440.0"#, #"Sources/Armonia/Armonia.docc/ElModelo.md"#, 44)
        comprobar(Altura(midi: 63, preferirBemoles: true), #"Mi♭4"#, #"Sources/Armonia/Armonia.docc/ElModelo.md"#, 45)
        comprobar(Acorde("Sol7/Si").posicionCerrada(octava: 3), #"[Si3, Re4, Fa4, Sol4]"#, #"Sources/Armonia/Armonia.docc/ElModelo.md"#, 47)
        comprobar(Acorde.identificar([.mi, .sol, .do]).first, #"Do/Mi"#, #"Sources/Armonia/Armonia.docc/ElModelo.md"#, 48)
        let menor = Escala("La menor armónica")
        comprobar(menor.cifradosRomanos(cuatriadas: true), #"["i(maj7)", "iiø7", "♭III+maj7", "iv7", "V7", "♭VImaj7", "vii°7"]"#, #"Sources/Armonia/Armonia.docc/ElModelo.md"#, 51)
        comprobar(Escala("Mib mayor").armadura, #"-3"#, #"Sources/Armonia/Armonia.docc/ElModelo.md"#, 53)
        comprobar(Escala(.do).rotacion(2), #"Re dórico"#, #"Sources/Armonia/Armonia.docc/ElModelo.md"#, 54)
        _ = i
    }

    func testEscalas1() throws {
        // Sources/Armonia/Armonia.docc/Escalas.md, línea 51
        comprobar(Escala(.do, .dobleArmonica).notas, #"Do Re♭ Mi Fa Sol La♭ Si"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 51)
        comprobar(Escala("Do enigmática").notas, #"Do Re♭ Mi Fa♯ Sol♯ La♯ Si"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 52)
        comprobar(Escala("La menor húngara").nombre(en: .ingles), #""A hungarian minor""#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 53)
        comprobar(TipoDeEscala.mayorArmonica.rotacion(4).nombre, #""lidio ♭3""#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 54)
        comprobar(TipoDeEscala.dobleArmonica == .hitzazkiar, #"true"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 55)
        comprobar(Escala("Mi flamenca").notas, #"Mi Fa Sol Sol♯ La Si Do Re"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 56)
        comprobar(Escala("Do modo 3 de Messiaen").notas, #"Do Re Mi♭ Mi Fa♯ Sol La♭ Si♭ Si"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 57)
        comprobar(Escala("Re menor rumana").tipo.nombre, #""dórico ♯4""#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 58)
        comprobar(TipoDeEscala.dobleArmonica.rotacion(5).nombre, #""oriental""#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 59)
        comprobar(Escala.hexacordoBlando.notas, #"Fa Sol La Si♭ Do Re"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 60)
        comprobar(TipoDeEscala.mayorHungara.rotacion(4).nombre, #""superlocrio ♮6""#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 61)
        comprobar(Escala("Do pentatónica escocesa").notas, #"Do Re Fa Sol La"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 62)
        comprobar(Escala("La de Liszt").tipo.nombre, #""menor húngara""#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 63)
    }

    func testEscalas2() throws {
        // Sources/Armonia/Armonia.docc/Escalas.md, línea 123
        comprobar(TipoDeEscala.melakarta(15), #"Māyāmālavagauḷa"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 123)
        comprobar(TipoDeEscala.mayor.numeroDeMelakarta, #"29"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 124)
        comprobar(Escala(.re, .hitzaz).notas, #"Re Mi♭ Fa♯ Sol La Si♭ Do"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 125)
        _ = (Escala("Do Kāfī"), Escala("Do kafi"), Escala("Re hijaz"), Escala("Do melakarta 22"))
        comprobar(Escala(.do, .todi).notas, #"Do Re♭ Mi♭ Fa♯ Sol La♭ Si"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 127)
        comprobar(TipoDeEscala.melakarta(15) == .bhairav, #"true"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 128)
        comprobar(Escala(.re, .zhi).notas, #"Re Mi Sol La Si"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 129)
        comprobar(Escala("Do hirajoshi").notas, #"Do Re Mi♭ Sol La♭"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 130)
        comprobar(Escala("Do 平調子").tipo.nombre, #""Hirajōshi""#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 131)
        comprobar(TipoDeEscala.gong == .pentatonicaMayor, #"true"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 132)
    }

    func testEscalas3() throws {
        // Sources/Armonia/Armonia.docc/Escalas.md, línea 160
        comprobar(ModoGregoriano(2)!.description, #""modo 2 (protus plagal, hipodórico): final Re, tenor Fa, ámbito La3–La4""#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 160)
        comprobar(ModoGregoriano(nombre: "hipofrigio")!.tenor, #"La"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 162)
        comprobar(ModoGregoriano(3)!.escala, #"Mi frigio"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 163)
        comprobar(ModoGregoriano(6)!.ambito.first, #"Do4"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 164)
    }

    func testEscalas4() throws {
        // Sources/Armonia/Armonia.docc/Escalas.md, línea 177
        comprobar(TipoDeEscala.menorMelodica.esDireccional, #"true"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 177)
        comprobarIgual(TipoDeEscala.menorMelodica.formaDescendente, .menorNatural, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 178)
        comprobar(Escala(.la, .menorMelodica).alturas(octava: 4, direccion: .descendente), #"La5 Sol5 Fa5 … La4"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 179)
        comprobar(TipoDeEscala.rast.formaAscendente == .mayor, #"true"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 180)
        comprobarIgual(TipoDeEscala.kiourdi.formaDescendente, .menorNatural, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 181)
        _ = TipoDeEscala.bilahari.intervalosEnAmbasDirecciones
    }

    func testEscalas5() throws {
        // Sources/Armonia/Armonia.docc/Escalas.md, línea 215
        comprobar(TipoDeEscala.kafi.esIdentico(a: .dorico), #"false"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 215)
        comprobar(TipoDeEscala.kafi.equivalentes.contains(.dorico), #"true"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 216)
        comprobar(TipoDeEscala.rast == .mayor, #"false"#, #"Sources/Armonia/Armonia.docc/Escalas.md"#, 217)
    }

    func testMelodiaYRitmo1() throws {
        // Sources/Armonia/Armonia.docc/MelodiaYRitmo.md, línea 8
        let tema: Melodia = ["Do4", "Mi4", "Sol4"]
        comprobar(tema.transponer(.segundaMayor), #"Re4 Fa♯4 La4"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 9)
        comprobar(tema.transponer(grados: 1, en: Escala(.do)), #"Re4 Fa4 La4"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 10)
        comprobar(tema.invertir(), #"Do4 La♭3 Fa3"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 11)
        comprobar(tema.retrogradar(), #"Sol4 Mi4 Do4"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 12)
        _ = (tema.intervalos, tema.contorno, tema.ambito)
        comprobar(Melodia(midi: [69, 71, 72, 74, 76, 77, 80, 81]), #"La4 … Sol♯5 La5"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 14)
    }

    func testMelodiaYRitmo2() throws {
        // Sources/Armonia/Armonia.docc/MelodiaYRitmo.md, línea 24
        comprobar(Duracion(.negra, puntillos: 1), #"negra con puntillo"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 24)
        comprobar(Duracion(.negra, puntillos: 1).texto, #""4.""#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 25)
        comprobar(Duracion.corchea.grupoIrregular(3, en: 2), #"1/12 de redonda"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 26)
        comprobar(Duracion("8."), #"corchea con puntillo"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 27)
        comprobar((Duracion.blanca + .corchea).descomposicion, #"[blanca, corchea]"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 28)
        comprobar(Duracion.corchea.ticks(porNegra: 480), #"240"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 29)
        let c: Compas = "6/8"
        _ = (c.tipo, c.pulsos, c.pulso)
        comprobar(Tempo(100).indicacion, #""Andante""#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 33)
        comprobar(Tempo(120).segundos(de: .blanca), #"1"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 34)
    }

    func testMelodiaYRitmo3() throws {
        // Sources/Armonia/Armonia.docc/MelodiaYRitmo.md, línea 42
        let voz = try Voz(leyendo: "Do4:4 Re4:8 Mi4:8 Fa4:2. Sol4:4", compas: "3/4")
        comprobar(voz.duracion, #"redonda con puntillo"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 43)
        comprobar(voz.compases, #"[[Do4:4, Re4:8, Mi4:8, Fa4:4~], [Fa4:2, Sol4:4]]"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 44)
        comprobar(voz.segundos(tempo: Tempo(90)), #"4"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 45)
        _ = (voz.melodia, voz.ritmo)
        _ = (voz.aumentar(2), voz.disminuir(2), voz.retrogradar(), voz + .quintaJusta)
        _ = Voz(melodia: ["Do4", "Mi4", "Sol4"], ritmo: [.negra, .negra, .blanca], compas: "3/4")
    }

    func testMelodiaYRitmo4() throws {
        // Sources/Armonia/Armonia.docc/MelodiaYRitmo.md, línea 61
        comprobar(Compas("7/8").agrupacion, #"[2, 2, 3]"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 61)
        comprobar(Compas("7/8").pulsos, #"3"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 62)
        comprobar(Compas("6/8").iniciosDePulso, #"[cero, negra con puntillo]"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 63)
        comprobarIgual(Compas.compasillo.acento(pulso: 2), .semifuerte, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 64)
        comprobar(Compas.compasillo.acento(en: .corchea), #"nil"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 65)
    }

    func testMelodiaYRitmo5() throws {
        // Sources/Armonia/Armonia.docc/MelodiaYRitmo.md, línea 85
        comprobar(try Voz(leyendo: "Do4:4 Re4:2 Mi4:4").grafia, #"[[Do4:4, Re4:4~, Re4:4, Mi4:4]]"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 85)
        comprobar(try Voz(leyendo: "Do4:8 Re4:4 Mi4:8 Fa4:2").grafia, #"[[Do4:8, Re4:8~, Re4:8, Mi4:8, Fa4:2]]"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 86)
        comprobar(try Voz(leyendo: "Do4:4. Re4:8 Mi4:2").grafia, #"[[Do4:4., Re4:8, Mi4:2]]"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 87)
        comprobar(try Voz(leyendo: "Do4:4 Re4:4. Mi4:8 Fa4:4").grafia, #"[[Do4:4, Re4:4~, Re4:8, Mi4:8, Fa4:4]]"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 88)
        comprobar(try Voz(leyendo: "Do4:4 Re4:4 Mi4:4", compas: "6/8").grafia, #"[[Do4:4, Re4:8~, Re4:8, Mi4:4]]"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 89)
        comprobar(try Voz(leyendo: "Do4:2..", compas: "7/8").grafia, #"[[Do4:2~, Do4:4.]]"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 90)
        comprobar(try Voz(leyendo: "Do4:2..", compas: "3+2+2/8").grafia, #"[[Do4:4.~, Do4:2]]"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 91)
    }

    func testMelodiaYRitmo6() throws {
        // Sources/Armonia/Armonia.docc/MelodiaYRitmo.md, línea 106
        let escala = try Voz(leyendo: "Do4:4 Re4:8 Mi4:8 Fa4:2 Sol4:1/12 La4:1/12 Si4:1/12 Do5:2.", compas: "3/4")
        let xml = escala.musicXML(tonalidad: Tonalidad(.do), tempo: Tempo(90), titulo: "Escala")
        comprobar(xml.contains("<fifths>0</fifths>"), #"true"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 108)
        comprobar(xml.contains("<actual-notes>3</actual-notes>"), #"true"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 109)
    }

    func testMelodiaYRitmo7() throws {
        // Sources/Armonia/Armonia.docc/MelodiaYRitmo.md, línea 129
        let melodia = try Voz(leyendo: "Do4:4 Re4:8 Mi4:8~ Mi4:4 Sol4+Si4:2", compas: "3/4")
        let datos = melodia.midi(tempo: Tempo(90), titulo: "Escala", instrumento: 40)
        comprobar(datos.prefix(4) == Data("MThd".utf8), #"true"#, #"Sources/Armonia/Armonia.docc/MelodiaYRitmo.md"#, 131)
    }

    func testNotacionYPartitura1() throws {
        // Sources/Armonia/Armonia.docc/NotacionYPartitura.md, línea 39
        comprobar(Nota("Sib").nombre(en: .aleman), #""B""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 39)
        comprobar(Nota("Mibb").nombre(en: .aleman), #""Eses""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 40)
        comprobar(Altura("Fa#3").nombre(en: .frances), #""fa dièse 3""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 41)
        comprobar(Acorde("Sim7").cifrado(en: .aleman), #""Hm7""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 42)
        comprobar(Acorde("Rebmaj7").cifrado(en: .frances), #""Ré♭maj7""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 43)
        comprobar(try Nota(leyendo: "B", en: .aleman), #"Si♭"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 44)
        comprobar(try Altura(leyendo: "re diesis 5", en: .italiano), #"Re♯5"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 45)
        _ = (Tonalidad("Fis-Dur"), Tonalidad("ré bémol majeur"), Tonalidad("la minore"))
        comprobar(Alteracion(-2).nombre(en: .frances), #""double bémol""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 47)
        comprobar(Nota("Fa#").nombre(en: .portugues), #""fá sustenido""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 48)
        comprobar(Alteracion(2).nombre(en: .portugues), #""duplo sustenido""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 49)
        comprobar(Acorde("Rebmaj7").cifrado(en: .portugues), #""Ré♭maj7""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 50)
        comprobar(Altura("fá sustenido 3"), #"Fa♯3"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 51)
        comprobar(Tonalidad("si bemol maior"), #"Si♭ mayor"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 52)
        comprobar(Escala("ré dórico"), #"Re dórico"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 53)
    }

    func testNotacionYPartitura2() throws {
        // Sources/Armonia/Armonia.docc/NotacionYPartitura.md, línea 80
        comprobar(Intervalo.terceraMayor.nombre(en: .catalan), #""3a major""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 80)
        comprobar(Intervalo.terceraMayor.nombre(en: .gallego), #""3ª maior""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 81)
        comprobar(Intervalo.sextaMenor.nombre(en: .euskera), #""6. txikia""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 82)
        comprobar(Cadencia.Tipo.rota.nombre(en: .catalan), #""cadència trencada""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 83)
        comprobar(Escala(.re, .dorico).nombre(en: .euskera), #""re doriarra""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 84)
        comprobar(Acorde("Sol7/Si").nombre(en: .catalan), #""sol sèptima de dominant, primera inversió""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 85)
        comprobar(Intervalo.terceraMayor.nombre(en: .frances), #""tierce majeure""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 86)
        comprobar(Cadencia.Tipo.rota.nombre(en: .italiano), #""cadenza d'inganno""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 87)
        comprobar(Escala(.re, .dorico).nombre(en: .frances), #""ré dorien""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 88)
        comprobar(Acorde("Sol7/Si").nombre(en: .portugues), #""sol sétima de dominante, primeira inversão""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 89)
    }

    func testNotacionYPartitura3() throws {
        // Sources/Armonia/Armonia.docc/NotacionYPartitura.md, línea 98
        _ = Nota("Sibb").alteracion
        comprobar(Alteracion(3).nombre, #""triple sostenido""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 99)
        comprobar(Alteracion(-1).nombre(en: .ingles), #""flat""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 100)
        comprobar(Alteracion(2).simbolo, #""♯♯""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 101)
        comprobar(Alteracion(3).simboloCompacto, #""𝄪♯""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 102)
        comprobar(Alteracion(-2).simboloASCII, #""bb""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 103)
        _ = (Alteracion("x"), Alteracion("doble bemol"), Alteracion("♮"))
        _ = Alteracion.sostenido + .sostenido
        comprobar(Alteracion.sostenido.pasosDeQuinta, #"7"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 106)
    }

    func testNotacionYPartitura4() throws {
        // Sources/Armonia/Armonia.docc/NotacionYPartitura.md, línea 114
        comprobar(Intervalo.sextaMenor.claseIntervalica, #"4"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 114)
        comprobarIgual(Intervalo.segundaAumentada.consonancia(), .disonancia, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 115)
        comprobar(Intervalo(numero: 1, calidad: .disminuida(1)), #"nil"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 116)
        comprobar(Clave.sol.posicion(de: "Do4").descripcion, #""1.ª línea adicional inferior""#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 118)
        comprobar(Clave.doEnTercera.posicion(de: "Do4").lugar, #"4"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 119)
        comprobar(Clave.fa.altura(lugar: 8), #"La3"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 120)
        comprobarIgual(Clave.masAdecuada(para: ["Do2", "Mi2"]), .fa, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 121)
        comprobar(Instrumento.clarineteEnSib.sonido(de: Altura("Do5")), #"Si♭4"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 123)
        comprobar(Instrumento.saxofonAlto.escritura(de: Escala("Si mayor")), #"La♭ mayor"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 124)
        comprobar(Instrumento.saxofonAlto.escritura(de: Acorde("Do7")), #"La7"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 125)
    }

    func testNotacionYPartitura5() throws {
        // Sources/Armonia/Armonia.docc/NotacionYPartitura.md, línea 143
        do {
            let acorde = try Acorde(leyendo: "Do7(b3)")
            print(acorde)
        } catch let error as ErrorDeLectura {
            print(error)
            comprobarIgual(error.motivo, .tensionNoValida("b3"), #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 150)
            comprobar(error.posicion, #"4"#, #"Sources/Armonia/Armonia.docc/NotacionYPartitura.md"#, 151)
            print(error.descripcion(en: .ingles))
        }
        do { _ = try TipoDeAcorde(comprobandoPasosDeQuinta: [0, -3, 4]) } catch { print(error) }
    }

    func testPostonal1() throws {
        // Sources/Armonia/Armonia.docc/Postonal.md, línea 8
        let c: ConjuntoDeClases = [0, 4, 7]
        comprobar(c.formaPrima, #"[0, 3, 7]"#, #"Sources/Armonia/Armonia.docc/Postonal.md"#, 9)
        comprobar(c.numeroDeForte, #""3-11""#, #"Sources/Armonia/Armonia.docc/Postonal.md"#, 10)
        comprobar(c.vectorIntervalico, #"[0, 0, 1, 1, 1, 0]"#, #"Sources/Armonia/Armonia.docc/Postonal.md"#, 11)
        comprobar(c.nombreComun, #""tríada mayor o menor""#, #"Sources/Armonia/Armonia.docc/Postonal.md"#, 12)
        comprobar(ConjuntoDeClases([0, 1, 4, 6]).estaEnRelacionZ(con: [0, 1, 3, 7]), #"true"#, #"Sources/Armonia/Armonia.docc/Postonal.md"#, 13)
        comprobar(Escala(.re).conjuntoDeClases.numeroDeForte, #""7-35""#, #"Sources/Armonia/Armonia.docc/Postonal.md"#, 14)
    }

    func testTonalidad1() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 13
        let laMenor: Tonalidad = "La menor"
        comprobar(laMenor.armadura, #"0"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 14)
        _ = (laMenor.relativa, laMenor.homonima)
        comprobar(laMenor.vecinas, #"[Do mayor, Sol mayor, Mi menor, Fa mayor, Re menor]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 16)
        comprobar(laMenor.armonizar(cuatriadas: true), #"Lam7 Sim7(♭5) Domaj7 Rem7 Mi7 Famaj7 Sol♯°7"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 17)
        _ = laMenor.cifradosRomanos()
        comprobarIgual(laMenor.nombreDeGrado(de: .sol), .subtonica, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 19)
        comprobar(Tonalidad.circuloDeQuintas(.menor), #"La♭ menor … La♯ menor"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 20)
        comprobar(Tonalidad(Escala(.re, .dorico)), #"nil"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 21)
    }

    func testTonalidad2() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 27
        let melodia = [69, 71, 72, 74, 76, 77, 80, 81]
        comprobar(Escala(.do).ortografiar(midi: [60, 61, 62]), #"Do4 Do♯4 Re4"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 27)
        comprobar(Escala(.do).ortografiar(midi: [62, 61, 60]), #"Re4 Re♭4 Do4"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 28)
        comprobar(Altura(midi: 70, escala: Escala(.fa)), #"Si♭4"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 29)
        comprobar(Altura(midi: 68, tonalidad: "La menor"), #"Sol♯4"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 30)
        comprobar(Escala("Fa# mayor").ortografiar(midi: [65, 60]), #"Mi♯4 Si♯3"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 31)
        comprobar(Tonalidad.candidatos(midi: melodia).first?.valor, #"La menor"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 32)
    }

    func testTonalidad3() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 48
        let analisis = try AnalisisArmonico.analizar(leyendo: "Do Lam Re7 Sol7 Do")
        comprobar(analisis.tonalidad, #"Do mayor"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 49)
        comprobar(analisis.cifrados, #"["I", "vi", "V7/V", "V7", "I"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 50)
        comprobar(analisis.funciones.map { $0?.abreviatura ?? "–" }, #"["T", "T", "D", "D", "T"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 51)
        comprobarIgual(analisis.acordes[2].categoria, .dominanteSecundaria(de: 5), #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 52)
        comprobar(analisis.nombre(en: .ingles), #""I–vi–V7/V–V7–I in C major""#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 53)
        comprobar(try AnalisisArmonico.analizar(leyendo: "Do Fa/La Sol7/Si Do"), #"I–IV6–V65–I en Do mayor"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 55)
        comprobar(try AnalisisArmonico.analizar(leyendo: "Sim7(b5) Mi7 Lam"), #"iiø7–V7–i en La menor"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 56)
        comprobar(try AnalisisArmonico.analizar(leyendo: "Do Lab Sib Do"), #"I–♭VI–♭VII–I en Do mayor"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 57)
        comprobar(try AnalisisArmonico.analizar(leyendo: "Do Reb/Fa Sol7 Do"), #"I–♭II6–V7–I en Do mayor"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 58)
        comprobar(try AnalisisArmonico.analizar(leyendo: "Do Fa#°7 Sol Do"), #"I–vii°7/V–V–I en Do mayor"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 59)
        comprobar(Tonalidad(.la, .menor).analizar(["Lam", "Rem/Fa", "Mi7", "La"]).cifrados, #"["i", "iv6", "V7", "I"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 60)
        comprobar(Tonalidad(.do).analizar(["Mim6", "Mim/Sol"]).cifrados, #"["iii(add6)", "iii6"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 61)
    }

    func testTonalidad4() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 69
        comprobar(Tonalidad(.do).analizar(["Fa6/La", "Fa6/Do", "Do(add9)/Mi"]).cifrados, #"["IV(add6)643", "IV(add6)642", "I(add9)763"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 69)
    }

    func testTonalidad5() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 90
        comprobar(Tonalidad(.do).analizar(["Do", "Lab(#6,omit5)", "Sol", "Do"]).cifrados, #"["I", "It+6", "V", "I"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 90)
        comprobar(Tonalidad(.do).analizar(["Fa", "Re7(b5)/Lab", "Sol"]).cifrados, #"["IV", "Fr+6", "V"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 91)
        comprobar(Tonalidad(.do).analizar(["Lab(#6)", "Do/Sol", "Sol7", "Do"]).cifrados, #"["Ger+6", "I64", "V7", "I"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 92)
        comprobar(Tonalidad(.do).analizar(["Lab7", "Sol"]).cifrados, #"["Ger+6", "V"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 93)
        comprobar(Tonalidad(.do).analizar(["Reb/Lab", "Sol7", "Do"]).cifrados, #"["♭II64", "V7", "I"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 94)
    }

    func testTonalidad6() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 107
        let analisis = try AnalisisArmonico.analizar(leyendo: "Do Lam Re7 Sol7 Do")
        let partituraAnalizada = analisis.musicXML(titulo: "Progresión")
        comprobar(partituraAnalizada.contains("<kind text=\"7\">dominant</kind>"), #"true"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 109)
        comprobar(partituraAnalizada.contains("<text>V7/V</text>"), #"true"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 110)
        comprobar(analisis.musicXML(notacion: .ingles).contains("C major:"), #"true"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 111)
    }

    func testTonalidad7() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 125
        let cadencia = try AnalisisArmonico.analizar(leyendo: "Do Fa Sol7 Do").cadencias[0]
        comprobarIgual(cadencia.tipo, .autentica, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 126)
        comprobar(cadencia.esPerfecta, #"true"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 127)
        comprobar(cadencia.description, #""Cadencia auténtica V7–I (acordes 3 → 4)""#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 128)
        comprobar(cadencia.descripcion(en: .ingles), #""Authentic cadence V7–I (chords 3 → 4)""#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 129)
        comprobarIgual(Tonalidad(.do).analizar(["Do", "Fa", "Do"]).cadencias.first?.tipo, .plagal, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 131)
        comprobarIgual(Tonalidad(.do).analizar(["Do", "Sol7", "Lam"]).cadencias.first?.tipo, .rota, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 132)
        comprobarIgual(Tonalidad(.do).analizar(["Do", "Lam", "Fa", "Sol"]).cadencias.first?.tipo, .semicadencia, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 133)
    }

    func testTonalidad8() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 147
        let recorrido = try RecorridoTonal(leyendo: "Do Fa Sol7 Do Lam Re7 Sol")
        comprobar(recorrido.tramos.map(\.tonalidad), #"[Do mayor, Sol mayor]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 148)
        comprobar(recorrido.cifrados, #"["I", "IV", "V7", "I", "ii", "V7", "I"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 149)
        comprobar(recorrido.description, #""I–IV–V7–I en Do mayor → ii–V7–I en Sol mayor""#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 150)
        comprobar(recorrido.modulaciones[0].acorde, #"4"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 151)
        comprobar(recorrido.modulaciones[0].pivote?.description, #""Lam = vi en Do mayor = ii en Sol mayor""#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 152)
        comprobar(recorrido.cadencias.map(\.tonalidad), #"[Do mayor, Sol mayor]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 153)
        comprobar(try RecorridoTonal(leyendo: "Do Sol Do Fa Rem Mi7 Lam").modulaciones[0].description, #""De Do mayor a La menor en el acorde 5 (pivote: Rem = ii en Do mayor = iv en La menor)""#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 155)
    }

    func testTonalidad9() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 164
        comprobar(try RecorridoTonal(leyendo: "Do Lam Re7 Sol7 Do").modulaciones.isEmpty, #"true"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 164)
    }

    func testTonalidad10() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 179
        let c = try ConduccionDeVoces(leyendo: "Do3 Sol3 Mi4 Do5 | Re3 La3 Fa4 Re5")
        comprobar(c.problemas.map(\.tipo) == [.quintasParalelas, .octavasParalelas], #"true"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 180)
        comprobar(c.problemas[0].voces, #"[0, 1]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 181)
        comprobar(c.problemas[0].description, #""Quintas paralelas entre bajo y tenor (acordes 1 → 2)""#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 182)
        comprobar(c.problemas[0].descripcion(en: .ingles), #""Parallel fifths between bass and tenor (chords 1 → 2)""#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 183)
        comprobar(try ConduccionDeVoces(leyendo: "Do3 Mi4 Sol4 Do5 | Fa3 Fa4 La4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5").esCorrecta, #"true"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 185)
        comprobar(ConduccionDeVoces(voces: [["Do3", "Sol2"], ["Mi4", "Re4"], ["Sol4", "Sol4"], ["Do5", "Si4"]])?.esCorrecta, #"true"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 186)
    }

    func testTonalidad11() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 209
        let coral = try ConduccionDeVoces(leyendo: "Do3 Mi4 Sol4 Do5 | Fa3 Fa4 La4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5")
        let partitura = coral.musicXML(duracion: .blanca, titulo: "Cadencia")
        comprobar(partitura.contains("<staves>2</staves>"), #"true"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 211)
    }

    func testTonalidad12() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 220
        let cadencia = try ConduccionDeVoces(leyendo: "Do3 Mi4 Sol4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5")
        comprobar(cadencia.musicXML(cifrados: true, analisis: true).contains("<text>V</text>"), #"true"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 221)
    }

    func testTonalidad13() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 234
        let coral = ConduccionDeVoces.realizar(["Do", "Fa", "Sol7", "Do"])!
        comprobar(coral.esCorrecta, #"true"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 235)
        comprobar(coral.voz(0).map(\.nota), #"[Do, Fa, Sol, Do]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 236)
        let conSoprano = ConduccionDeVoces.realizar(["Do", "Fa", "Sol", "Do"], soprano: ["Mi4", "Fa4", "Re4", "Do4"])!
        comprobar(conSoprano.voz(3), #"[Mi4, Fa4, Re4, Do4]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 239)
        comprobar(ConduccionDeVoces.realizar(["Do", "Rem"], soprano: ["Sol4", "La4"]), #"nil"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 240)
    }

    func testTonalidad14() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 253
        comprobar(Tonalidad(.do).acordes(para: .sol).prefix(3).map(\.valor), #"[Sol, Do, Sol7]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 253)
        let propuestas = Tonalidad(.do).armonizar(melodia: ["Mi", "Fa", "Re", "Do"], propuestas: 3)
        comprobar(propuestas.map(\.valor.cifrados), #"[["I", "IV", "V", "I"], ["I", "IV", "V7", "I"], ["I", "ii", "V", "I"]]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 256)
        comprobar(propuestas[0].valor.description, #""Do Fa Sol Do (I–IV–V–I)""#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 257)
        comprobar(Tonalidad(.do).armonizar(melodia: ["Mi", "Fa#", "Sol", "Do"])[0].valor.cifrados, #"["I", "V/V", "V", "I"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 258)
    }

    func testTonalidad15() throws {
        // Sources/Armonia/Armonia.docc/Tonalidad.md, línea 265
        let armonizada = Tonalidad(.do).armonizarACuatroVoces(["Mi4", "Fa4", "Re4", "Do4"])!
        comprobar(armonizada.armonizacion.cifrados, #"["I", "IV", "V", "I"]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 266)
        comprobar(armonizada.voces.voz(3), #"[Mi4, Fa4, Re4, Do4]"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 267)
        comprobar(armonizada.voces.esCorrecta, #"true"#, #"Sources/Armonia/Armonia.docc/Tonalidad.md"#, 268)
    }

    func testTrastes1() throws {
        // Sources/Armonia/Armonia.docc/Trastes.md, línea 13
        let mastil = Mastil(.guitarra)
        let ukelele = Encordado(nombre: "ukulele")
        let acorde = Acorde("Sol7/Si")
        let formas = mastil.digitaciones(de: acorde, limite: 3)
        let primera = formas.first
        let tablatura = primera?.tablatura
        let notas = primera?.notas(para: acorde)
        let dedos = primera?.dedos
        let cejilla = primera?.cejilla
        let pentatonica = mastil.posiciones(de: Escala(.la, .pentatonicaMenor), trastes: 0...12)
        _ = (ukelele, tablatura, notas, dedos, cejilla, pentatonica)
    }

    func testTrastes2() throws {
        // Sources/Armonia/Armonia.docc/Trastes.md, línea 54
        let mastil = Mastil(.guitarra)
        let leida = Digitacion(leyendo: "x32010", en: mastil)
        let comprobada = Digitacion(comprobando: [nil, 3, 2, 0, 1, 0], en: mastil)
        let sonido = mastil.midiSiExiste(en: Posicion(cuerda: 9, traste: 0))
        _ = (leida, comprobada, sonido)
    }
}
