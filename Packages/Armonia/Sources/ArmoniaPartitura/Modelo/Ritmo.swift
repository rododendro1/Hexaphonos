import ArmoniaNucleo
import ArmoniaTeoria
// Ritmo: figuras, duraciones exactas, compases, tempo y eventos (notas con duración). Las
// voces, que encadenan eventos en un compás, están en Melodia.swift.
//
// Las duraciones son fracciones exactas de redonda (una negra es 1/4, una corchea con
// puntillo 3/16, una corchea de tresillo 1/12), así que sumar, comparar y repartir en
// compases nunca acumula errores de redondeo.

// MARK: - Figura

/// Figuras musicales, de la cuadrada (dos redondas) a la garrapatea (1/128).
public enum Figura: Int, CaseIterable, Hashable, Sendable, CustomStringConvertible {
    case cuadrada = -1, redonda, blanca, negra, corchea, semicorchea, fusa, semifusa, garrapatea

    /// Duración en redondas: blanca → 1/2, negra → 1/4, cuadrada → 2.
    public var duracion: Duracion {
        rawValue < 0 ? Duracion(2) : Duracion(1, 1 << rawValue)
    }

    public var description: String { nombre }
}

extension Figura: Nombrable {}

// MARK: - Duración

/// Duración exacta, como fracción de redonda (siempre reducida).
///
///     Duracion.negra                       // 1/4
///     Duracion(.negra, puntillos: 1)       // 3/8, «negra con puntillo»
///     Duracion.corchea.grupoIrregular(3, en: 2)   // 1/12, corchea de tresillo
///     Duracion("8.")                       // corchea con puntillo
///     Duracion.blanca + .corchea           // 5/8
///     (Duracion.blanca + .corchea).descomposicion   // [blanca, corchea] (para ligar)
public struct Duracion: Hashable, Sendable, Comparable {
    public let numerador: Int
    public let denominador: Int

    /// `numerador/denominador` redondas, o `nil` si el denominador es 0. Si el denominador viene de fuera, usa esta
    /// variante: `init(_:_:)` detiene el programa en ese caso.
    public init?(comprobando numerador: Int, _ denominador: Int) {
        guard denominador != 0 else { return nil }
        self.init(numerador, denominador)
    }

    /// Figura con puntillos, o `nil` si el número de puntillos no está entre 0 y 30.
    public init?(comprobando figura: Figura, puntillos: Int) {
        guard (0...30).contains(puntillos) else { return nil }
        self.init(figura, puntillos: puntillos)
    }

    /// `numerador/denominador` redondas; se reduce y el signo queda en el numerador. Detiene el programa si el
    /// denominador es 0 (un error de quien llama): `init?(comprobando:_:)` devuelve `nil`.
    public init(_ numerador: Int, _ denominador: Int = 1) {
        precondition(denominador != 0, "una duración no puede tener denominador 0")
        let divisor = max(1, maximoComunDivisor(numerador, denominador))
        let signo = denominador < 0 ? -1 : 1
        self.numerador = signo * numerador / divisor
        self.denominador = abs(denominador) / divisor
    }

    /// Figura con puntillos: cada puntillo añade la mitad de lo anterior
    /// (negra con puntillo = 3/8, con doble puntillo = 7/16).
    public init(_ figura: Figura, puntillos: Int = 0) {
        precondition(puntillos >= 0, "el número de puntillos no puede ser negativo")
        self = figura.duracion * Duracion((1 << (puntillos + 1)) - 1, 1 << puntillos)
    }

    /// Lee una figura al estilo de LilyPond ("1" redonda, "4" negra, "8." corchea con puntillo,
    /// "2.." blanca con doble puntillo) o una fracción de redonda ("3/8", "1/12", "2/1").
    public init(leyendo texto: String) throws {
        let limpio = texto.trimmingEspacios()
        let error = ErrorDeLectura(texto: texto, posicion: nil, motivo: .duracionNoValida(limpio))
        if let barra = limpio.firstIndex(of: "/") {
            guard let a = Int(limpio[..<barra]), let b = Int(limpio[limpio.index(after: barra)...]),
                  a >= 0, b > 0 else { throw error }
            self.init(a, b)
            return
        }
        let cifras = limpio.prefix(while: { $0.isASCII && $0.isNumber })
        let puntos = limpio.dropFirst(cifras.count)
        guard let n = Int(cifras), n > 0, n & (n - 1) == 0, n <= 128,
              puntos.allSatisfy({ $0 == "." }) else { throw error }
        let figura = Figura(rawValue: n.trailingZeroBitCount)!
        self.init(figura, puntillos: puntos.count)
    }

    // MARK: Constantes

    public static let cero = Duracion(0)
    public static let cuadrada = Figura.cuadrada.duracion
    public static let redonda = Figura.redonda.duracion
    public static let blanca = Figura.blanca.duracion
    public static let negra = Figura.negra.duracion
    public static let corchea = Figura.corchea.duracion
    public static let semicorchea = Figura.semicorchea.duracion
    public static let fusa = Figura.fusa.duracion
    public static let semifusa = Figura.semifusa.duracion
    public static let garrapatea = Figura.garrapatea.duracion

    // MARK: Propiedades

    /// Valor en redondas como número decimal: negra → 0,25.
    public var enRedondas: Double { Double(numerador) / Double(denominador) }

    public var esCero: Bool { numerador == 0 }

    /// La figura y los puntillos con que se escribe, si se puede escribir con una sola figura
    /// (hasta cuatro puntillos): 3/8 → (negra, 1). `nil` para 5/8 o 1/12.
    public var figuraYPuntillos: (figura: Figura, puntillos: Int)? {
        for puntillos in 0...4 {
            for figura in Figura.allCases where Duracion(figura, puntillos: puntillos) == self {
                return (figura, puntillos)
            }
        }
        return nil
    }

    /// Figuras sin puntillo que, ligadas, suman esta duración (de mayor a menor), si la duración
    /// es binaria: 5/8 → [blanca, corchea]; 3/8 → [negra con puntillo]. `nil` para duraciones de
    /// grupos irregulares (1/12) o menores que una garrapatea.
    public var descomposicion: [Duracion]? {
        guard numerador > 0 else { return numerador == 0 ? [] : nil }
        if figuraYPuntillos != nil { return [self] }
        guard denominador & (denominador - 1) == 0, denominador <= 128 else { return nil }
        var resto = self
        var partes: [Duracion] = []
        for figura in Figura.allCases {
            while figura.duracion <= resto {
                partes.append(figura.duracion)
                resto = resto - figura.duracion
            }
        }
        return resto.esCero ? partes : nil
    }

    // MARK: Operaciones

    /// Duración de cada nota de un grupo irregular de `n` notas en el tiempo de `m`:
    /// `Duracion.corchea.grupoIrregular(3, en: 2)` (tresillo) → 1/12;
    /// `Duracion.semicorchea.grupoIrregular(5, en: 4)` (quintillo) → 1/20.
    public func grupoIrregular(_ n: Int, en m: Int) -> Duracion { self * Duracion(m, n) }

    /// Pulsos MIDI con la resolución dada: `Duracion.corchea.ticks(porNegra: 480)` → 240.
    /// `nil` si no sale un número entero.
    public func ticks(porNegra resolucion: Int) -> Int? {
        let total = numerador * 4 * resolucion
        return total % denominador == 0 ? total / denominador : nil
    }

    public static func + (a: Duracion, b: Duracion) -> Duracion {
        Duracion(a.numerador * b.denominador + b.numerador * a.denominador, a.denominador * b.denominador)
    }
    public static func - (a: Duracion, b: Duracion) -> Duracion {
        Duracion(a.numerador * b.denominador - b.numerador * a.denominador, a.denominador * b.denominador)
    }
    public static func * (a: Duracion, b: Duracion) -> Duracion {
        Duracion(a.numerador * b.numerador, a.denominador * b.denominador)
    }
    public static func * (a: Duracion, n: Int) -> Duracion { Duracion(a.numerador * n, a.denominador) }
    public static func * (n: Int, a: Duracion) -> Duracion { a * n }
    public static func / (a: Duracion, n: Int) -> Duracion { Duracion(a.numerador, a.denominador * n) }
    /// Cuántas veces cabe `b` en `a` (como fracción): blanca / negra → 2.
    public static func / (a: Duracion, b: Duracion) -> Duracion {
        Duracion(a.numerador * b.denominador, a.denominador * b.numerador)
    }
    public static func < (a: Duracion, b: Duracion) -> Bool {
        a.numerador * b.denominador < b.numerador * a.denominador
    }
}

extension Duracion: CustomStringConvertible {
    /// El nombre, como en los demás tipos: "negra con puntillo", "5/8 de redonda".
    /// La forma corta para escribir y leer ("4.", "5/8") es `texto`.
    public var description: String { nombre }
}

extension Duracion: RepresentableComoTexto, Nombrable {
    /// "4", "8.", "2.."; si no es una figura de redonda o menor, la fracción ("5/8", "1/12", "2/1").
    public func texto(_ notacion: Nomenclatura) -> String {
        if let escritura = figuraYPuntillos, escritura.figura != .cuadrada {
            return "\(1 << escritura.figura.rawValue)" + String(repeating: ".", count: escritura.puntillos)
        }
        return "\(numerador)/\(denominador)"
    }
}

extension Sequence where Element == Duracion {
    /// Suma de las duraciones.
    public func sumar() -> Duracion { reduce(.cero, +) }
}

// MARK: - Compás

/// Compás: `numerador` unidades de `1/denominador` redonda, agrupadas en pulsos.
///
///     let c: Compas = "6/8"
///     c.tipo         // .compuesto
///     c.pulsos       // 2
///     c.pulso        // negra con puntillo
///     c.agrupacion   // [3, 3]
///     Compas("7/8").agrupacion        // [2, 2, 3]
///     Compas("3+2+2/8").agrupacion    // [3, 2, 2]
///     Compas.compasillo.duracion       // 1 (una redonda)
public struct Compas: Hashable, Sendable, CustomStringConvertible {
    public let numerador: Int
    public let denominador: Int
    /// Unidades (de `1/denominador`) de cada pulso, en orden: [1, 1, 1, 1] en 4/4, [3, 3] en 6/8,
    /// [2, 2, 3] en 7/8. Suman `numerador`.
    public let agrupacion: [Int]

    public enum Tipo: Hashable, Sendable {
        /// Pulsos de una unidad, divisibles en dos (2/4, 3/4, 4/4, 2/2).
        case simple
        /// Pulsos con puntillo, de tres unidades (6/8, 9/8, 12/8).
        case compuesto
        /// Pulsos desiguales (5/8 = 2+3, 7/8 = 2+2+3).
        case amalgama
    }

    /// Fuerza métrica del comienzo de un pulso.
    public enum Acento: Int, Hashable, Sendable, Comparable {
        case debil, semifuerte, fuerte
        public static func < (a: Acento, b: Acento) -> Bool { a.rawValue < b.rawValue }
    }

    /// Como `init(_:_:agrupacion:)`, pero devuelve `nil` en vez de detener el programa si el compás o su
    /// agrupación no son válidos. Es la que hay que usar con datos de fuera.
    public init?(comprobando numerador: Int, _ denominador: Int, agrupacion: [Int]? = nil) {
        guard Compas.esValido(numerador, denominador) else { return nil }
        let grupos = agrupacion ?? Compas.agrupacionHabitual(numerador)
        guard grupos.allSatisfy({ $0 > 0 }), grupos.reduce(0, +) == numerador else { return nil }
        self.init(numerador, denominador, agrupacion: grupos)
    }

    /// El denominador tiene que ser una potencia de 2 (1…64) y el numerador, positivo. Sin
    /// `agrupacion` se usa la habitual: pulsos de una unidad (hasta 4), de tres (6, 9, 12…) o,
    /// en los de amalgama, grupos de dos con uno de tres al final (5 = 2+3, 7 = 2+2+3).
    /// Detiene el programa si no se cumple: con datos de fuera, `init?(comprobando:_:agrupacion:)`.
    public init(_ numerador: Int, _ denominador: Int, agrupacion: [Int]? = nil) {
        precondition(Compas.esValido(numerador, denominador), "compás no válido: \(numerador)/\(denominador)")
        let grupos = agrupacion ?? Compas.agrupacionHabitual(numerador)
        precondition(grupos.allSatisfy { $0 > 0 } && grupos.reduce(0, +) == numerador,
                     "la agrupación \(grupos) no suma \(numerador)")
        self.numerador = numerador
        self.denominador = denominador
        self.agrupacion = grupos
    }

    package static func esValido(_ numerador: Int, _ denominador: Int) -> Bool {
        numerador > 0 && denominador > 0 && denominador & (denominador - 1) == 0 && denominador <= 64
    }

    package static func agrupacionHabitual(_ numerador: Int) -> [Int] {
        if numerador <= 4 { return Array(repeating: 1, count: numerador) }
        if numerador % 3 == 0 { return Array(repeating: 3, count: numerador / 3) }
        return Array(repeating: 2, count: (numerador - 3) / 2) + [3]
    }

    /// Lee "4/4", "6/8", "7/8", "2+2+3/8" (con la agrupación), "C" (compasillo) o "¢"/"C|"
    /// (compás partido).
    public init(leyendo texto: String) throws {
        let limpio = texto.trimmingEspacios()
        switch limpio {
        case "C": self = .compasillo; return
        case "¢", "C|": self = .partido; return
        default: break
        }
        let error = ErrorDeLectura(texto: texto, posicion: nil, motivo: .compasNoValido(limpio))
        let partes = limpio.split(separator: "/", omittingEmptySubsequences: false)
        guard partes.count == 2, let b = Int(partes[1]) else { throw error }
        let sumandos = partes[0].split(separator: "+", omittingEmptySubsequences: false).map { Int($0) }
        guard !sumandos.isEmpty, sumandos.allSatisfy({ ($0 ?? 0) > 0 }) else { throw error }
        let grupos = sumandos.compactMap { $0 }
        let a = grupos.reduce(0, +)
        guard Compas.esValido(a, b) else { throw error }
        self.init(a, b, agrupacion: grupos.count > 1 ? grupos : nil)
    }

    /// 4/4.
    public static let compasillo = Compas(4, 4)
    /// 2/2.
    public static let partido = Compas(2, 2)

    /// Duración de un compás completo: 3/4 → blanca con puntillo.
    public var duracion: Duracion { Duracion(numerador, denominador) }

    public var tipo: Tipo {
        if agrupacion.allSatisfy({ $0 == 1 }) { return .simple }
        if agrupacion.allSatisfy({ $0 == 3 }) { return .compuesto }
        return .amalgama
    }

    /// Pulsos por compás: 4 en 4/4, 2 en 6/8, 3 en 7/8 (2+2+3).
    public var pulsos: Int { agrupacion.count }

    /// Duración de cada pulso: en 7/8, [negra, negra, negra con puntillo].
    public var duracionesDePulso: [Duracion] { agrupacion.map { Duracion($0, denominador) } }

    /// Duración del pulso: negra en 4/4, negra con puntillo en 6/8. En los compases de amalgama,
    /// cuyos pulsos son desiguales, la unidad (corchea en 7/8).
    public var pulso: Duracion {
        let distintas = Set(agrupacion)
        return distintas.count == 1 ? Duracion(agrupacion[0], denominador) : Duracion(1, denominador)
    }

    /// Dónde empieza cada pulso, desde el principio del compás: en 6/8, [0, 3/8].
    public var iniciosDePulso: [Duracion] {
        var inicio = Duracion.cero
        return duracionesDePulso.map { d in defer { inicio = inicio + d }; return inicio }
    }

    /// Acento del pulso `i` (desde 0): el primero es fuerte; en compases de 4 pulsos o más con
    /// un número par de pulsos, el de la mitad es semifuerte (el 3.º en 4/4, el 3.º en 6/4…);
    /// en los de amalgama, el comienzo de cada grupo de tres es semifuerte; el resto, débiles.
    public func acento(pulso i: Int) -> Acento {
        let n = modulo(i, pulsos)
        if n == 0 { return .fuerte }
        if pulsos >= 4 && pulsos % 2 == 0 && n == pulsos / 2 { return .semifuerte }
        if tipo == .amalgama && agrupacion[n] == 3 { return .semifuerte }
        return .debil
    }

    /// Acento de una posición dentro del compás, si coincide con el comienzo de un pulso;
    /// `nil` si cae entre pulsos (a contratiempo).
    public func acento(en posicion: Duracion) -> Acento? {
        iniciosDePulso.firstIndex(of: posicion).map { acento(pulso: $0) }
    }

    /// Punto que no debe ocultar una nota que empieza después del principio del compás: la mitad
    /// en los compases de un número par de pulsos (desde 4), según la costumbre de escritura.
    package var mitad: Duracion? {
        pulsos >= 4 && pulsos % 2 == 0 ? iniciosDePulso[pulsos / 2] : nil
    }

    /// Comienzos de los grupos que no miden lo mismo que el anterior: en 7/8 (2+2+3), el del grupo
    /// de tres; en 3+2+2/8, el primero de dos. Una figura sola no los oculta: en 7/8 la nota de
    /// todo el compás se escribe blanca ligada a negra con puntillo, no blanca con dos puntillos.
    package var fronterasDeGrupo: [Duracion] {
        let inicios = iniciosDePulso
        return agrupacion.indices.dropFirst().filter { agrupacion[$0] != agrupacion[$0 - 1] }.map { inicios[$0] }
    }

    /// "4/4", "6/8"; con una agrupación que no es la habitual, "3+2+2/8".
    public var description: String {
        agrupacion == Compas.agrupacionHabitual(numerador)
            ? "\(numerador)/\(denominador)"
            : agrupacion.map(String.init).joined(separator: "+") + "/\(denominador)"
    }
}

extension Compas: RepresentableComoTexto {
    public func texto(_ notacion: Nomenclatura) -> String { description }
}

// MARK: - Tempo

/// Velocidad: cuántas unidades (negras, por defecto) caben en un minuto.
///
///     let t = Tempo(120)
///     t.segundos(de: .blanca)              // 1
///     Tempo(60, unidad: Duracion(.negra, puntillos: 1)).negrasPorMinuto   // 90
///     Tempo(100).indicacion                // "Andante"
public struct Tempo: Hashable, Sendable, CustomStringConvertible {
    public let pulsacionesPorMinuto: Double
    public let unidad: Duracion

    /// Como `init(_:unidad:)`, pero devuelve `nil` si la velocidad o la unidad no son positivas.
    public init?(comprobando pulsacionesPorMinuto: Double, unidad: Duracion = .negra) {
        guard pulsacionesPorMinuto > 0, unidad > .cero else { return nil }
        self.init(pulsacionesPorMinuto, unidad: unidad)
    }

    /// Detiene el programa si la velocidad o la unidad no son positivas: con datos de fuera,
    /// `init?(comprobando:unidad:)`.
    public init(_ pulsacionesPorMinuto: Double, unidad: Duracion = .negra) {
        precondition(pulsacionesPorMinuto > 0 && unidad > .cero, "el tempo tiene que ser positivo")
        self.pulsacionesPorMinuto = pulsacionesPorMinuto
        self.unidad = unidad
    }

    /// Lo que dura una duración, en segundos.
    public func segundos(de duracion: Duracion) -> Double {
        (duracion / unidad).enRedondas * 60 / pulsacionesPorMinuto
    }

    /// El mismo tempo expresado en negras por minuto.
    public var negrasPorMinuto: Double { pulsacionesPorMinuto * (unidad / .negra).enRedondas }

    /// Indicación italiana aproximada según las negras por minuto (los márgenes varían según
    /// la época y el metrónomo): Grave < 40 ≤ Largo < 60 ≤ Larghetto < 66 ≤ Adagio < 76 ≤
    /// Andante < 108 ≤ Moderato < 120 ≤ Allegro < 168 ≤ Presto < 200 ≤ Prestissimo.
    public var indicacion: String {
        let tabla: [(Double, String)] = [(40, "Grave"), (60, "Largo"), (66, "Larghetto"), (76, "Adagio"),
                                         (108, "Andante"), (120, "Moderato"), (168, "Allegro"), (200, "Presto")]
        return tabla.first { negrasPorMinuto < $0.0 }?.1 ?? "Prestissimo"
    }

    /// "♩ = 120" o, con otra unidad, "negra con puntillo = 60".
    public var description: String {
        let cifra = pulsacionesPorMinuto.rounded() == pulsacionesPorMinuto
            ? String(Int(pulsacionesPorMinuto)) : String(pulsacionesPorMinuto)
        return (unidad == .negra ? "♩" : unidad.nombre) + " = " + cifra
    }
}

// MARK: - Evento

/// Una nota, un acorde o un silencio con su duración. `ligada` indica que se prolonga en el
/// evento siguiente (las mismas notas).
///
///     let e: Evento = "Do4:4."            // Do4, negra con puntillo
///     Evento("Do4+Mi4+Sol4:2")            // acorde de blancas
///     Evento("-:8")                       // silencio de corchea
///     Evento("Re4:2~")                    // ligada a la siguiente
public struct Evento: Hashable, Sendable {
    /// Alturas que suenan; vacío si es un silencio.
    public let alturas: [Altura]
    public let duracion: Duracion
    public let ligada: Bool

    public init(alturas: [Altura], duracion: Duracion, ligada: Bool = false) {
        self.alturas = alturas
        self.duracion = duracion
        self.ligada = ligada && !alturas.isEmpty
    }

    public init(_ nota: Altura, _ duracion: Duracion, ligada: Bool = false) {
        self.init(alturas: [nota], duracion: duracion, ligada: ligada)
    }

    public static func silencio(_ duracion: Duracion) -> Evento { Evento(alturas: [], duracion: duracion) }

    /// Lee "notas:duración", con las notas de un acorde unidas por "+", "-" (o "silencio")
    /// para un silencio y "~" al final si está ligada: "Do4:4", "C4+E4:2.", "-:8", "Re4:2~".
    public init(leyendo texto: String) throws {
        let caracteres = Array(texto)
        guard let dosPuntos = caracteres.lastIndex(of: ":") else {
            throw ErrorDeLectura(texto: texto, posicion: nil, motivo: .duracionNoValida(texto.trimmingEspacios()))
        }
        var parteDuracion = String(caracteres[(dosPuntos + 1)...]).trimmingEspacios()
        let ligada = parteDuracion.hasSuffix("~")
        if ligada { parteDuracion.removeLast() }
        let duracion: Duracion
        do { duracion = try Duracion(leyendo: parteDuracion) } catch let e as ErrorDeLectura {
            throw ErrorDeLectura(texto: texto, posicion: dosPuntos + 1, motivo: e.motivo)
        }
        let parteNotas = String(caracteres[..<dosPuntos])
        let limpia = parteNotas.trimmingEspacios()
        if limpia == "-" || limpia.claveDeBusqueda == "silencio" {
            self.init(alturas: [], duracion: duracion)
            return
        }
        var alturas: [Altura] = []
        var inicio = 0
        for trozo in parteNotas.split(separator: "+", omittingEmptySubsequences: false) {
            do { alturas.append(try Altura(leyendo: String(trozo))) } catch let e as ErrorDeLectura {
                throw ErrorDeLectura(texto: texto, posicion: inicio + (e.posicion ?? 0), motivo: e.motivo)
            }
            inicio += trozo.count + 1
        }
        self.init(alturas: alturas, duracion: duracion, ligada: ligada)
    }

    public var esSilencio: Bool { alturas.isEmpty }

    public func transponer(_ intervalo: Intervalo) -> Evento {
        Evento(alturas: alturas.map { $0.transponer(intervalo) }, duracion: duracion, ligada: ligada)
    }
}

extension Evento: CustomStringConvertible {
    public var description: String { texto }
}

extension Evento: RepresentableComoTexto, Transponible {
    public func texto(_ notacion: Nomenclatura) -> String {
        let notasTexto = esSilencio ? "-" : alturas.map { $0.texto(notacion) }.joined(separator: "+")
        return notasTexto + ":" + duracion.texto(notacion) + (ligada ? "~" : "")
    }
}
