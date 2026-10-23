import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

/// Pruebas exhaustivas: todo lo que el motor escribe debe volver a leerse igual.
/// Recorren el espacio completo de valores en lugar de ejemplos sueltos, así que
/// cualquier cambio en el lector o el generador de texto que rompa un caso se detecta.
final class IdaYVueltaTests: XCTestCase {

    /// Todas las posiciones (en quintas desde la fundamental) que puede ocupar una nota
    /// de un acorde: terceras, quintas, séptimas y tensiones con sus alteraciones.
    static let posicionesDeAcorde = [-3, 4, 1, -6, 8, -2, 5, -9, -5, 2, 9, -1, 6, -4, 3]

    /// Recorre los 2¹⁵ subconjuntos posibles. Los que forman un acorde interpretable
    /// (9.344) deben generar un cifrado que se vuelva a leer como el mismo conjunto.
    func testTodoCifradoGeneradoSeVuelveALeerIgual() {
        let posiciones = Self.posicionesDeAcorde
        var interpretables = 0
        for mascara in 0..<(1 << posiciones.count) {
            var conjunto: Set<Int> = [0]
            for (i, q) in posiciones.enumerated() where mascara & (1 << i) != 0 {
                conjunto.insert(q)
            }
            guard let tipo = TipoDeAcorde(pasosDeQuinta: conjunto) else { continue }
            interpretables += 1

            let simbolo = tipo.cifrado
            guard let leido = TipoDeAcorde(texto: simbolo) else {
                XCTFail("No se puede leer «\(simbolo)», generado desde \(conjunto.sorted())")
                continue
            }
            XCTAssertEqual(leido.pasosDeQuinta, conjunto, "«\(simbolo)»")

            // La disposición contiene exactamente las notas del conjunto, sin repetir.
            let intervalos = tipo.intervalos
            XCTAssertEqual(intervalos.count, conjunto.count, "«\(simbolo)»")
            XCTAssertEqual(Set(intervalos.map(\.pasosDeQuinta)), conjunto, "«\(simbolo)»")
            XCTAssertEqual(intervalos.first, .unisono, "«\(simbolo)»")
            XCTAssertTrue(zip(intervalos, intervalos.dropFirst()).allSatisfy {
                ($0.pasos, $0.semitonos) <= ($1.pasos, $1.semitonos)
            }, "«\(simbolo)»: intervalos desordenados")
        }
        XCTAssertEqual(interpretables, 9344)
    }

    static let estilos: [EstiloDeCifrado] = [
        .predeterminado, .ascii, .ingles, .inglesUnicode, .jazz, .palabras,
        EstiloDeCifrado(nomenclatura: .ingles, menor: .min, disminuido: .dim, aumentado: .aug,
                      septimaMayor: .mayuscula, semidisminuido: .barrado),
    ]

    /// Lo mismo que la prueba anterior, en cada estilo de cifrado.
    func testTodosLosEstilosSeVuelvenALeerIgual() {
        let posiciones = Self.posicionesDeAcorde
        for estilo in Self.estilos {
            var fallos = 0
            for mascara in 0..<(1 << posiciones.count) {
                var conjunto: Set<Int> = [0]
                for (i, q) in posiciones.enumerated() where mascara & (1 << i) != 0 {
                    conjunto.insert(q)
                }
                guard let tipo = TipoDeAcorde(pasosDeQuinta: conjunto) else { continue }
                let simbolo = tipo.cifrado(estilo: estilo)
                if TipoDeAcorde(texto: simbolo)?.pasosDeQuinta != conjunto {
                    fallos += 1
                    if fallos <= 5 { XCTFail("«\(simbolo)» (\(estilo)) no se vuelve a leer como \(conjunto.sorted())") }
                }
            }
            XCTAssertEqual(fallos, 0, "\(estilo)")
        }
    }

    /// Acordes completos en cada estilo, con fundamentales que ponen a prueba la lectura
    /// (F/Fa, D/Do, dobles alteraciones) y todas las inversiones.
    func testAcordesCompletosEnTodosLosEstilos() {
        let fundamentales: [Nota] = ["Fa", "Re", "Do", "Fa#", "Sib", "Si", "Mibb", "Sol#"]
        for estilo in Self.estilos {
            for tipo in TipoDeAcorde.todos + ["7(b9,#11)", "m(add9)", "+9", "aug11", "7alt"] {
                for raiz in fundamentales {
                    for inversion in 0..<tipo.intervalos.count {
                        let acorde = Acorde(raiz, tipo, inversion: inversion)
                        let texto = acorde.cifrado(estilo: estilo)
                        XCTAssertEqual(Acorde(texto: texto), acorde, "«\(texto)»")
                    }
                }
            }
        }
    }

    /// Acordes completos: fundamental + tipo + cada inversión posible + un bajo ajeno.
    func testCifradosCompletosConFundamentalYBajo() {
        let fundamentales: [Nota] = ["Do", "Fa#", "Sib", "Mi", "Sol#", "Dobb", "Si#"]
        let tipos: [TipoDeAcorde] = TipoDeAcorde.todos
            + ["7(b9,#11)", "13sus4", "m6/9", "7alt", "7(omit5)", "maj7#11", "13(b9)", "+9"]
        for tipo in tipos {
            for raiz in fundamentales {
                for inversion in 0..<tipo.intervalos.count {
                    let acorde = Acorde(raiz, tipo, inversion: inversion)
                    XCTAssertEqual(Acorde(texto: acorde.cifrado), acorde, acorde.cifrado)
                }
                let ajeno = Acorde(raiz, tipo, bajo: raiz + .segundaMenor)
                XCTAssertEqual(Acorde(texto: ajeno.cifrado), ajeno, ajeno.cifrado)
            }
        }
    }

    func testNombresDeNota() {
        for q in -35...35 {
            let nombre = Nota(pasosDeQuinta: q)
            XCTAssertEqual(Nota(texto: nombre.nombre), nombre, nombre.nombre)
            XCTAssertEqual(Nota(texto: nombre.nombreASCII), nombre, nombre.nombreASCII)
            XCTAssertEqual(Nota(texto: nombre.nombre(en: .ingles)), nombre, nombre.nombre(en: .ingles))
            let unicode = nombre.nombre(en: .inglesUnicode)
            XCTAssertEqual(Nota(texto: unicode), nombre, unicode)
        }
    }

    func testNotas() {
        for q in -21...21 {
            for o in -15...15 {
                let nota = Altura(pasosDeQuinta: q, pasosDeOctava: o)
                XCTAssertEqual(Altura(texto: nota.nombreCompleto), nota, nota.nombreCompleto)
                XCTAssertEqual(Altura(texto: nota.nombre(en: .ingles)), nota, nota.nombre(en: .ingles))
                XCTAssertEqual(Altura(texto: nota.nombre(en: .inglesUnicode)), nota)
                XCTAssertEqual(Altura(nota.nota, octava: nota.octava), nota, nota.nombreCompleto)
            }
        }
    }

    func testIntervalos() {
        for q in -21...21 {
            for o in -15...15 {
                for direccion in [Direccion.ascendente, .descendente] {
                    let intervalo = Intervalo(pasosDeQuinta: q, pasosDeOctava: o, direccion: direccion)
                    XCTAssertEqual(Intervalo(texto: intervalo.abreviatura), intervalo, intervalo.abreviatura)
                    XCTAssertEqual(Intervalo(texto: intervalo.abreviatura(en: .ingles)), intervalo,
                                   intervalo.abreviatura(en: .ingles))
                    XCTAssertGreaterThanOrEqual(intervalo.pasos, 0)
                }
            }
        }
    }

    func testCodableDeTodosLosTipos() throws {
        let codificador = JSONEncoder()
        let decodificador = JSONDecoder()
        let acordes = TipoDeAcorde.todos.map { Acorde("Fa#", $0, inversion: 1) }
        XCTAssertEqual(try decodificador.decode([Acorde].self, from: codificador.encode(acordes)), acordes)
        let escalas = TipoDeEscala.todos.map { Escala("Mib", $0) }
        XCTAssertEqual(try decodificador.decode([Escala].self, from: codificador.encode(escalas)), escalas)
    }
}

final class ConjuntoDeClasesExhaustivoTests: XCTestCase {
    /// Los 4096 subconjuntos de las doce clases caen en 224 clases (223 con nombre más el
    /// vacío), y transponer o invertir nunca cambia la clase ni el vector interválico.
    func testTodosLosSubconjuntos() {
        var nombres = Set<String>()
        for mascara in 0..<(1 << 12) {
            let conjunto = ConjuntoDeClases((0..<12).filter { mascara & (1 << $0) != 0 })
            guard !conjunto.clases.isEmpty else { continue }
            guard let nombre = conjunto.numeroDeForte else {
                XCTFail("Sin nombre de Forte: \(conjunto) → \(conjunto.formaPrima)")
                continue
            }
            nombres.insert(nombre)
            XCTAssertTrue(nombre.hasPrefix("\(conjunto.cardinalidad)-"), nombre)
            let otro = conjunto.transponer(mascara % 12).invertir(mascara % 7)
            XCTAssertEqual(otro.formaPrima, conjunto.formaPrima)
            XCTAssertEqual(otro.vectorIntervalico, conjunto.vectorIntervalico)
            XCTAssertEqual(ConjuntoDeClases(conjunto.formaPrima).formaPrima, conjunto.formaPrima)
        }
        XCTAssertEqual(nombres.count, 223)
        XCTAssertEqual(nombres.filter { $0.contains("Z") }.count, 46)
    }
}

final class IdentificacionPorAlturaExhaustivaTests: XCTestCase {
    /// Cada tipo predefinido, sobre las 12 fundamentales y en estado fundamental,
    /// debe identificarse primero desde MIDI (con cualquier ortografía enarmónica de la fundamental).
    func testTodosLosTiposPredefinidosEnEstadoFundamental() {
        for tipo in TipoDeAcorde.todos {
            for raiz in 0..<12 {
                let midi = tipo.intervalos.map { 48 + raiz + $0.semitonos }
                guard let acorde = Acorde.identificar(midi: midi).first else {
                    XCTFail("Nada para \(tipo.nombre) sobre \(raiz)")
                    continue
                }
                XCTAssertEqual(acorde.tipo, tipo, "\(tipo.nombre) sobre \(raiz): \(acorde.cifrado)")
                XCTAssertEqual(acorde.fundamental.claseDeAltura, raiz, acorde.cifrado)
                XCTAssertEqual(acorde.inversion, 0, acorde.cifrado)
                XCTAssertLessThanOrEqual(acorde.fundamental.alteracion.cantidad, 1, acorde.cifrado)
            }
        }
    }
}

/// Ida y vuelta en las numeraciones de Hewlett: toda nota y todo intervalo admitidos se
/// convierten en un número y vuelven igual, y los números de los huecos no dan nada.
final class BaseDeHewlettExhaustivaTests: XCTestCase {
    func testIdaYVuelta() {
        for base in [BaseDeHewlett.base40, .base54, BaseDeHewlett(alteracionMaxima: 6)] {
            let m = base.alteracionMaxima
            var notas = 0
            for letra in NotaNatural.allCases {
                for alteracion in -m...m {
                    for octava in -1...9 {
                        let nota = Altura(Nota(letra, Alteracion(alteracion)), octava: octava)
                        guard let numero = nota.numero(en: base) else {
                            XCTFail("\(nota) en \(base)")
                            continue
                        }
                        XCTAssertEqual(Altura(numero: numero, en: base), nota, "\(nota) en \(base)")
                        notas += 1
                    }
                }
            }
            // Cada octava tiene 7·(2m + 1) notas y 5 huecos.
            let validos = (0..<base.base).filter { Altura(numero: 4 * base.base + $0, en: base) != nil }.count
            XCTAssertEqual(validos, 7 * (2 * m + 1))
            XCTAssertEqual(notas, 7 * (2 * m + 1) * 11)
            for numero in -3 * base.base...3 * base.base {
                if let intervalo = Intervalo(numero: numero, en: base) {
                    XCTAssertEqual(intervalo.numero(en: base), numero, "\(intervalo) en \(base)")
                }
            }
        }
    }
}
