import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class AfinacionTests: XCTestCase {
    func testTemperamentosRegulares() {
        let igual = TemperamentoRegular.igual
        XCTAssertEqual(igual.frecuencia(de: "La4"), 440, accuracy: 1e-9)
        XCTAssertEqual(igual.frecuencia(de: "Do4"), 261.625_565_3, accuracy: 1e-6)
        XCTAssertEqual(igual.cents(de: Intervalo.terceraMayor), 400, accuracy: 1e-9)

        XCTAssertEqual(TemperamentoRegular.pitagorico.frecuencia(de: "Mi5"), 660, accuracy: 1e-6)
        XCTAssertEqual(TemperamentoRegular.mesotonicoCuartoDeComa.cents(de: .terceraMayor),
                       1200 * log2(5.0 / 4.0), accuracy: 1e-9)
        XCTAssertEqual(TemperamentoRegular.mesotonicoTercioDeComa.cents(de: .terceraMenor),
                       1200 * log2(6.0 / 5.0), accuracy: 1e-9)
        XCTAssertEqual(TemperamentoRegular.mesotonicoCuartoDeComa.frecuencia(de: "La4"), 440, accuracy: 1e-9)
        // En el mesotónico, Sol♯ y La♭ no coinciden.
        let meso = TemperamentoRegular.mesotonicoCuartoDeComa
        XCTAssertLessThan(meso.frecuencia(de: "Sol#4"), meso.frecuencia(de: "Lab4"))

        XCTAssertEqual(TemperamentoRegular.igual(divisiones: 12).quinta, 700, accuracy: 1e-9)
        XCTAssertEqual(TemperamentoRegular.igual(divisiones: 31).quinta, 1200 * 18 / 31, accuracy: 1e-9)
        XCTAssertEqual(TemperamentoRegular.igual(divisiones: 53).quinta, 1200 * 31 / 53, accuracy: 1e-9)
        XCTAssertEqual(TemperamentoRegular.igual(divisiones: 19).quinta, 1200 * 11 / 19, accuracy: 1e-9)
        XCTAssertEqual(TemperamentoRegular.igual.afinar(la4: 415).frecuencia(de: "La4"), 415, accuracy: 1e-9)
    }

    func testRazonesJustas() {
        let esperadas: [(Intervalo, String)] = [
            (.segundaMenor, "16/15"), (.segundaMayor, "9/8"), (.terceraMenor, "6/5"), (.terceraMayor, "5/4"),
            (.cuartaJusta, "4/3"), (.cuartaAumentada, "45/32"), (.quintaDisminuida, "36/25"),
            (.quintaJusta, "3/2"), (.sextaMenor, "8/5"), (.sextaMayor, "5/3"), (.septimaMenor, "9/5"),
            (.septimaMayor, "15/8"), (.octava, "2/1"), (.unisonoAumentado, "25/24"), (.novenaMayor, "9/4"),
        ]
        for (intervalo, razon) in esperadas {
            XCTAssertEqual(intervalo.razonJusta.description, razon, intervalo.nombre)
        }
        XCTAssertEqual((-Intervalo.terceraMayor).razonJusta.description, "4/5")
        XCTAssertEqual(Intervalo.terceraMayor.razonJusta.cents, 386.313_7, accuracy: 1e-3)
        XCTAssertEqual(RazonDeFrecuencias.comaSintonica.cents, 21.506, accuracy: 1e-3)
        XCTAssertEqual(RazonDeFrecuencias.comaPitagorica.cents, 23.460, accuracy: 1e-3)
    }

    func testEntonacionJusta() {
        let justa = EntonacionJusta(tonica: .do)
        let do4 = Altura("Do4").frecuencia()
        XCTAssertEqual(justa.frecuencia(de: "Do4"), do4, accuracy: 1e-9)
        XCTAssertEqual(justa.frecuencia(de: "Mi4"), do4 * 5 / 4, accuracy: 1e-9)
        XCTAssertEqual(justa.frecuencia(de: "La4"), do4 * 5 / 3, accuracy: 1e-9)
        XCTAssertEqual(justa.frecuencia(de: "Re5"), do4 * 9 / 4, accuracy: 1e-9)
        XCTAssertEqual(justa.frecuencia(de: "Si3"), do4 * 15 / 16, accuracy: 1e-9)
        XCTAssertEqual(justa.desviacion(de: "Mi4"), 1200 * log2(5.0 / 4.0) - 400, accuracy: 1e-9)
        XCTAssertEqual(justa.cents(desde: "Do4", hasta: "Sol4"), 1200 * log2(1.5), accuracy: 1e-9)
        XCTAssertEqual(Altura("Mi4").frecuencia(en: justa), do4 * 5 / 4, accuracy: 1e-9)
        // La escala mayor de Ptolomeo.
        let razones = Escala(.do).alturas(octava: 4).map { justa.frecuencia(de: $0) / do4 }
        for (r, esperada) in zip(razones, [1, 9.0 / 8, 5.0 / 4, 4.0 / 3, 1.5, 5.0 / 3, 15.0 / 8, 2]) {
            XCTAssertEqual(r, esperada, accuracy: 1e-12)
        }
    }
}

final class BaseDeHewlettTests: XCTestCase {
    func testBases() {
        XCTAssertEqual(BaseDeHewlett.base40.base, 40)
        XCTAssertEqual(BaseDeHewlett.base54.base, 54)
        XCTAssertEqual(BaseDeHewlett.base600.base, 600)
        XCTAssertEqual(BaseDeHewlett(base: 40), .base40)
        XCTAssertEqual(BaseDeHewlett(base: 54)?.alteracionMaxima, 3)
        XCTAssertEqual(BaseDeHewlett(base: 600)?.alteracionMaxima, 42)
        XCTAssertEqual(BaseDeHewlett(base: 12)?.alteracionMaxima, 0)
        XCTAssertNil(BaseDeHewlett(base: 41))
        XCTAssertNil(BaseDeHewlett(base: 7))
        XCTAssertEqual(BaseDeHewlett.base40.description, "base 40")
    }

    func testBase40() {
        // Valores de Hewlett y Humdrum: Do4 = 162, quinta justa = 23.
        let casos: [(Altura, Int)] = [("Do4", 162), ("Sol4", 185), ("Fa#4", 180), ("Solb4", 184),
                                    ("Do5", 202), ("Dobb4", 160), ("Six4", 199), ("Dob4", 161), ("Si#3", 158)]
        for (nota, numero) in casos {
            XCTAssertEqual(nota.numero(en: .base40), numero, nota.description)
            XCTAssertEqual(Altura(numero: numero, en: .base40), nota, nota.description)
        }
        XCTAssertNil(Altura(Nota(.fa, 3), octava: 4).numero(en: .base40))
        XCTAssertNil(Altura(numero: 162 + 20, en: .base40))   // hueco entre Fa𝄪 y Sol𝄫
        XCTAssertEqual(Nota.do.numero(en: .base40), 2)
        XCTAssertEqual(Nota("Si#").numero(en: .base40), 38)
        XCTAssertEqual(Nota("Dob").numero(en: .base40), 1)
        XCTAssertEqual(Nota(numero: 42, en: .base40), .do)
        XCTAssertNil(Nota(numero: 5, en: .base40))
    }

    func testIntervalosEnBase40() {
        let casos: [(Intervalo, Int)] = [
            (.unisono, 0), (.segundaMenor, 5), (.segundaMayor, 6), (.terceraMenor, 11), (.terceraMayor, 12),
            (.cuartaJusta, 17), (.cuartaAumentada, 18), (.quintaDisminuida, 22), (.quintaJusta, 23),
            (.sextaMenor, 28), (.sextaMayor, 29), (.septimaMenor, 34), (.septimaMayor, 35), (.octava, 40),
            (.novenaMayor, 46), (-Intervalo.quintaJusta, -23), (-Intervalo.terceraMayor, -12),
        ]
        for (intervalo, numero) in casos {
            XCTAssertEqual(intervalo.numero(en: .base40), numero, intervalo.description)
            XCTAssertEqual(Intervalo(numero: numero, en: .base40), intervalo, intervalo.description)
        }
        XCTAssertNil(Intervalo(numero: 20, en: .base40))   // entre la 4ª doble aumentada y la 5ª doble disminuida
        // Los intervalos son diferencias de números.
        let re: Altura = "Re4", sib: Altura = "Sib3"
        XCTAssertEqual(re.numero(en: .base40)! - sib.numero(en: .base40)!, (re - sib).numero(en: .base40))
    }

    func testBase54YBase600() {
        let faTripleSostenido = Altura(Nota(.fa, 3), octava: 4)
        XCTAssertEqual(faTripleSostenido.numero(en: .base54), 245)
        XCTAssertEqual(Altura(numero: 245, en: .base54), faTripleSostenido)
        XCTAssertEqual(Altura("Do4").numero(en: .base54), 219)
        XCTAssertEqual(Intervalo.quintaJusta.numero(en: .base54), 31)
        XCTAssertEqual(Altura("Do4").numero(en: .base600), 2442)
        XCTAssertEqual(Intervalo.quintaJusta.numero(en: .base600), 343)
        XCTAssertEqual(Intervalo.octava.numero(en: .base600), 600)
        let muyAlterada = Altura(Nota(.la, -42), octava: 2)
        XCTAssertEqual(Altura(numero: muyAlterada.numero(en: .base600)!, en: .base600), muyAlterada)
        XCTAssertNil(Altura(Nota(.la, 43), octava: 2).numero(en: .base600))
    }
}

final class CorrespondenciaDeColoresTests: XCTestCase {
    func testColorRGB() {
        let naranja = ColorRGB(hexadecimal: "#FF8000")!
        XCTAssertEqual(naranja.rojo, 255)
        XCTAssertEqual(naranja.verde, 128)
        XCTAssertEqual(naranja.azul, 0)
        XCTAssertEqual(naranja.hexadecimal, "#FF8000")
        XCTAssertEqual(ColorRGB(hexadecimal: "0d98ba")?.hexadecimal, "#0D98BA")
        XCTAssertNil(ColorRGB(hexadecimal: "#FF80"))
        XCTAssertNil(ColorRGB(hexadecimal: "#-00001"))
        XCTAssertNil(ColorRGB(hexadecimal: "#GG0000"))
        XCTAssertEqual(ColorRGB(rojo: 300, verde: -4, azul: 16).hexadecimal, "#FF0010")
        XCTAssertEqual(ColorRGB(tono: 0, saturacion: 1, brillo: 1).hexadecimal, "#FF0000")
        XCTAssertEqual(ColorRGB(tono: 120, saturacion: 1, brillo: 1).hexadecimal, "#00FF00")
        XCTAssertEqual(ColorRGB(tono: 240, saturacion: 1, brillo: 1).hexadecimal, "#0000FF")
        XCTAssertEqual(ColorRGB(tono: 30, saturacion: 1, brillo: 1).hexadecimal, "#FF8000")
        XCTAssertEqual(ColorRGB(tono: -60, saturacion: 1, brillo: 1).hexadecimal, "#FF00FF")
        XCTAssertEqual(ColorRGB(tono: 0, saturacion: 0, brillo: 0.5).hexadecimal, "#808080")
    }

    func testCorrespondencias() {
        // Newton: por letra; las alteraciones no cambian el color.
        XCTAssertEqual(Nota.do.color(segun: .newton).hexadecimal, "#FF0000")
        XCTAssertEqual(Nota.la.color(segun: .newton), Nota("La#").color(segun: .newton))
        XCTAssertEqual(CorrespondenciaDeColores.newton.nombreDelColor(de: .la), "añil")
        // Castel: Do azul, Re verde, Mi amarillo, Sol rojo.
        XCTAssertEqual(CorrespondenciaDeColores.castel.nombreDelColor(de: .do), "azul")
        XCTAssertEqual(CorrespondenciaDeColores.castel.nombreDelColor(de: .sol), "rojo")
        // Scriabin: por clase de altura, así que Do♯ y Re♭ comparten color.
        XCTAssertEqual(CorrespondenciaDeColores.scriabin.nombreDelColor(de: .re), "amarillo")
        XCTAssertEqual(CorrespondenciaDeColores.scriabin.nombreDelColor(de: .fa), "rojo oscuro")
        XCTAssertEqual(Nota("Do#").color(segun: .scriabin), Nota("Reb").color(segun: .scriabin))
        // Círculo de quintas: 30° por quinta.
        XCTAssertEqual(Acorde("Do").colores(segun: .circuloDeQuintas).map(\.hexadecimal),
                       ["#FF0000", "#00FF00", "#FF8000"])
        XCTAssertNil(CorrespondenciaDeColores.circuloDeQuintas.nombreDelColor(de: .do))
        XCTAssertEqual(Escala(.do).colores(segun: .scriabin).count, 7)
        XCTAssertEqual(Altura("Re5").color(segun: .scriabin), Nota.re.color(segun: .scriabin))
        // Cada correspondencia da doce colores distintos (Newton, siete).
        for sinestesia in CorrespondenciaDeColores.allCases {
            let colores = Set((0..<12).map { Nota(pasosDeQuinta: $0 * 7 % 12 - 5).color(segun: sinestesia) })
            XCTAssertEqual(colores.count, sinestesia == .newton ? 7 : 12, sinestesia.nombre)
        }
    }
}
