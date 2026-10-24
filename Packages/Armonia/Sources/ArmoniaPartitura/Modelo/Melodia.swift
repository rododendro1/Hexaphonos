import ArmoniaNucleo
import ArmoniaTeoria
// Melodías: secuencias de notas con sus transformaciones clásicas, y voces: melodías con
// ritmo en un compás (los eventos y las duraciones están en Ritmo.swift).
//
// Como las notas están en coordenadas (quintas, octavas), transponer es sumar un vector e
// invertir es reflejarlo: la inversión de una 3ª mayor ascendente es exactamente una 3ª
// mayor descendente, con su ortografía (Do–Mi alrededor de Do da Do–La♭).

// MARK: - Melodía

public struct Melodia: Hashable, Sendable, CustomStringConvertible {
    public var alturas: [Altura]

    public init(_ alturas: [Altura]) {
        self.alturas = alturas
    }

    /// Melodía a partir de notas MIDI, escritas según la tonalidad dada o, si no se da,
    /// según la que estima `Tonalidad.candidatos`.
    public init(midi: [Int], tonalidad: Tonalidad? = nil) {
        guard let elegida = tonalidad ?? Tonalidad.identificar(midi: midi).first else {
            self.init(midi.map { Altura(midi: $0) })
            return
        }
        self.init(elegida.ortografiar(midi: midi))
    }

    /// Melodía a partir de notas MIDI, escritas según una escala cualquiera (un modo, por ejemplo).
    public init(midi: [Int], escala: Escala) {
        self.init(escala.ortografiar(midi: midi))
    }

    // MARK: Propiedades

    public var midi: [Int] { alturas.map(\.midi) }

    /// Intervalos entre notas consecutivas (con dirección).
    public var intervalos: [Intervalo] {
        zip(alturas, alturas.dropFirst()).map { $0.intervalo(hasta: $1) }
    }

    /// Contorno: +1 sube, −1 baja, 0 repite.
    public var contorno: [Int] {
        zip(alturas, alturas.dropFirst()).map { a, b in
            b.midi == a.midi ? 0 : (b.midi > a.midi ? 1 : -1)
        }
    }

    public var alturaMasGrave: Altura? { alturas.min() }
    public var alturaMasAguda: Altura? { alturas.max() }

    /// Ámbito: intervalo entre la nota más grave y la más aguda.
    public var ambito: Intervalo? {
        guard let grave = alturaMasGrave, let aguda = alturaMasAguda else { return nil }
        return grave.intervalo(hasta: aguda)
    }

    /// Clases de altura que usa la melodía.
    public var conjuntoDeClases: ConjuntoDeClases { ConjuntoDeClases(alturas: alturas) }

    /// Tonalidades más probables (Krumhansl-Schmuckler, con la ortografía de las notas).
    public var candidatosDeTonalidad: [Candidato<Tonalidad>] { Tonalidad.candidatos(alturas: alturas) }

    public var description: String { alturas.map(\.description).joined(separator: " ") }

    // MARK: Transformaciones

    /// Transposición real (cromática): todas las notas se mueven el mismo intervalo.
    public func transponer(_ intervalo: Intervalo) -> Melodia {
        Melodia(alturas.map { $0 + intervalo })
    }

    /// Transposición tonal: cada nota avanza `grados` grados dentro de la escala (negativo
    /// para bajar), conservando sus alteraciones cromáticas. Do–Mi–Sol en Do mayor, un grado
    /// arriba, da Re–Fa–La. `nil` si la escala no es heptatónica.
    public func transponer(grados: Int, en escala: Escala) -> Melodia? {
        let grados7 = escala.notas
        guard grados7.count == 7, Set(grados7.map(\.natural)).count == 7 else { return nil }
        let resultado = alturas.map { nota -> Altura in
            let indice = grados7.firstIndex { $0.natural == nota.nota.natural } ?? 0
            let alteracionCromatica = nota.nota.pasosDeQuinta - grados7[indice].pasosDeQuinta
            let destino = escala.grado(indice + grados + 1)
            let nombre = Nota(pasosDeQuinta: destino.pasosDeQuinta + alteracionCromatica)
            return Altura(nombre, pasos: nota.pasos + grados)
        }
        return Melodia(resultado)
    }

    /// Inversión: cada intervalo cambia de dirección alrededor de `eje`
    /// (por defecto, la primera nota). Do4–Mi4–Sol4 → Do4–La♭3–Fa3.
    public func invertir(alrededorDe eje: Altura? = nil) -> Melodia {
        guard let centro = eje ?? alturas.first else { return self }
        return Melodia(alturas.map {
            Altura(pasosDeQuinta: 2 * centro.pasosDeQuinta - $0.pasosDeQuinta, pasosDeOctava: 2 * centro.pasosDeOctava - $0.pasosDeOctava)
        })
    }

    /// Retrogradación: la melodía al revés.
    public func retrogradar() -> Melodia { Melodia(Array(alturas.reversed())) }

    /// Retrogradación de la inversión (alrededor de la primera nota de la original).
    public func retrogradarInversion(alrededorDe eje: Altura? = nil) -> Melodia {
        invertir(alrededorDe: eje ?? alturas.first).retrogradar()
    }
}

extension Melodia: RandomAccessCollection {
    public var startIndex: Int { alturas.startIndex }
    public var endIndex: Int { alturas.endIndex }
    public subscript(posicion: Int) -> Altura { alturas[posicion] }
}

extension Melodia: ExpressibleByArrayLiteral {
    /// `let m: Melodia = ["Do4", "Mi4", "Sol4"]`.
    public init(arrayLiteral alturas: Altura...) { self.init(alturas) }
}

extension Melodia: Codable {
    /// Se codifica como una lista de notas: ["Do4", "Mi4", "Sol4"].
    public init(from decoder: Decoder) throws {
        let alturas = try decoder.singleValueContainer().decode([Altura].self)
        self.init(alturas)
    }

    public func encode(to encoder: Encoder) throws {
        var contenedor = encoder.singleValueContainer()
        try contenedor.encode(alturas)
    }
}

extension Melodia: Transponible, ConClasesDeAltura {}

// MARK: - Voz

/// Una línea musical con ritmo: eventos (notas, acordes y silencios) en un compás, con
/// anacrusa opcional.
///
///     let voz = try Voz(leyendo: "Do4:4 Re4:8 Mi4:8 Fa4:2. Sol4:4", compas: "3/4")
///     voz.duracion                 // 3/2 (dos compases de 3/4)
///     voz.compases.count           // 2, con la Fa4 repartida y ligada entre ambos
///     voz.segundos(tempo: Tempo(90))
///     voz.melodia                  // Do4 Re4 Mi4 Fa4 Sol4
///     voz.ritmo                    // [4, 8, 8, 2., 4]
public struct Voz: Hashable, Sendable, Codable {
    public var eventos: [Evento]
    public var compas: Compas
    /// Duración del compás incompleto inicial (0 si no hay anacrusa).
    public var anacrusa: Duracion

    public init(_ eventos: [Evento], compas: Compas = .compasillo, anacrusa: Duracion = .cero) {
        self.eventos = eventos
        self.compas = compas
        self.anacrusa = anacrusa
    }

    /// Une una melodía y un ritmo nota a nota. `nil` si no tienen el mismo número de elementos.
    public init?(melodia: Melodia, ritmo: [Duracion], compas: Compas = .compasillo,
                 anacrusa: Duracion = .cero) {
        guard melodia.alturas.count == ritmo.count else { return nil }
        self.init(zip(melodia.alturas, ritmo).map { Evento($0, $1) }, compas: compas, anacrusa: anacrusa)
    }

    /// Lee eventos separados por espacios: "Do4:4 Re4:8 Mi4:8 -:4 Do4+Mi4:2~ Do4+Mi4:4".
    public init(leyendo texto: String, compas: Compas = .compasillo, anacrusa: Duracion = .cero) throws {
        var eventos: [Evento] = []
        var inicio = 0
        for trozo in texto.split(separator: " ", omittingEmptySubsequences: false) {
            defer { inicio += trozo.count + 1 }
            guard !trozo.isEmpty else { continue }
            do { eventos.append(try Evento(leyendo: String(trozo))) } catch let e as ErrorDeLectura {
                throw ErrorDeLectura(texto: texto, posicion: inicio + (e.posicion ?? 0), motivo: e.motivo)
            }
        }
        self.init(eventos, compas: compas, anacrusa: anacrusa)
    }

    // MARK: Propiedades

    /// Duración total.
    public var duracion: Duracion { eventos.map(\.duracion).sumar() }

    /// Duraciones de los eventos, en orden (silencios incluidos).
    public var ritmo: [Duracion] { eventos.map(\.duracion) }

    /// Las notas, sin ritmo ni silencios; las ligadas cuentan una sola vez y los acordes
    /// aportan todas sus notas.
    public var melodia: Melodia {
        var alturas: [Altura] = []
        var anteriorLigada = false
        for evento in eventos {
            if !anteriorLigada { alturas += evento.alturas }
            anteriorLigada = evento.ligada
        }
        return Melodia(alturas)
    }

    /// Lo que dura a un tempo dado, en segundos.
    public func segundos(tempo: Tempo) -> Double { tempo.segundos(de: duracion) }

    /// Los eventos repartidos en compases (el primero, de la duración de la anacrusa si la hay).
    /// Una nota que cruza la barra se divide en dos ligadas; un silencio, en dos silencios.
    public var compases: [[Evento]] {
        var resultado: [[Evento]] = []
        var actual: [Evento] = []
        var restante = anacrusa > .cero ? anacrusa : compas.duracion
        for evento in eventos {
            var pendiente = evento
            while pendiente.duracion > restante {
                actual.append(Evento(alturas: pendiente.alturas, duracion: restante, ligada: true))
                resultado.append(actual)
                actual = []
                pendiente = Evento(alturas: pendiente.alturas, duracion: pendiente.duracion - restante,
                                   ligada: pendiente.ligada)
                restante = compas.duracion
            }
            actual.append(pendiente)
            restante = restante - pendiente.duracion
            if restante.esCero {
                resultado.append(actual)
                actual = []
                restante = compas.duracion
            }
        }
        if !actual.isEmpty { resultado.append(actual) }
        return resultado
    }

    /// Los compases como se escriben en una partitura, con las notas divididas y ligadas según
    /// la métrica:
    ///
    /// - una nota que cruza el comienzo de un pulso se divide en él, salvo que empiece en un
    ///   pulso, acabe en otro y se pueda escribir con una sola figura (una blanca en el 1.er tiempo
    ///   de 4/4, una negra con puntillo en 6/8);
    /// - en los compases simples, una figura con puntillo que empieza en un pulso se escribe entera
    ///   aunque acabe entre dos (la negra con puntillo del 1.er tiempo de 4/4, seguida de corchea);
    /// - en 4/4 (y en los compases de un número par de pulsos, desde 4) una nota que no empieza al
    ///   principio del compás no oculta la mitad: la blanca del 2.º tiempo se escribe negra ligada
    ///   a negra;
    /// - en los compases de amalgama, una figura puede abarcar varios grupos iguales (la blanca
    ///   de los dos primeros de 7/8 = 2+2+3), pero no el paso de un grupo a otro de distinto tamaño:
    ///   el compás entero de 7/8 es blanca ligada a negra con puntillo; el de 3+2+2/8, negra con
    ///   puntillo ligada a blanca;
    /// - lo que no se puede escribir con una figura (con puntillos) se descompone en figuras
    ///   ligadas, de mayor a menor si empieza en un pulso y de menor a mayor si no.
    ///
    /// Los silencios se dividen igual, sin ligaduras, salvo el de todo un compás. Las duraciones de grupos irregulares
    /// (tresillos…) se dejan como están.
    ///
    ///     try Voz(leyendo: "Do4:4 Re4:2 Mi4:4").grafia
    ///     // [[Do4:4, Re4:4~, Re4:4, Mi4:4]]
    public var grafia: [[Evento]] {
        var resultado: [[Evento]] = []
        for (indice, compasActual) in compases.enumerated() {
            // La anacrusa se coloca al final de un compás completo.
            var posicion = indice == 0 && anacrusa > .cero ? compas.duracion - anacrusa : .cero
            var escritos: [Evento] = []
            for evento in compasActual {
                // El silencio de todo un compás no se divide: es un silencio de compás.
                let partes = evento.esSilencio && posicion.esCero && evento.duracion == compas.duracion
                    ? [evento.duracion]
                    : Voz.partir(desde: posicion, duracion: evento.duracion, compas: compas)
                for (k, parte) in partes.enumerated() {
                    let ultima = k == partes.count - 1
                    escritos.append(Evento(alturas: evento.alturas, duracion: parte,
                                           ligada: ultima ? evento.ligada : true))
                }
                posicion = posicion + evento.duracion
            }
            resultado.append(escritos)
        }
        return resultado
    }

    /// Divide una duración que empieza en `inicio` (dentro de un compás) en partes escribibles.
    package static func partir(desde inicio: Duracion, duracion: Duracion, compas: Compas) -> [Duracion] {
        let fin = inicio + duracion
        let pulsos = compas.iniciosDePulso + [compas.duracion]
        let enPulso = { (p: Duracion) in pulsos.contains(p) }
        // ¿Se puede escribir entero el tramo [desde, hasta)?
        func cruzaLaMitad(_ desde: Duracion, _ hasta: Duracion) -> Bool {
            compas.mitad.map { desde > .cero && desde < $0 && hasta > $0 } ?? false
        }
        func cruzaUnaFrontera(_ desde: Duracion, _ hasta: Duracion) -> Bool {
            compas.fronterasDeGrupo.contains { desde < $0 && hasta > $0 }
        }
        func entero(_ desde: Duracion, _ hasta: Duracion) -> Bool {
            enPulso(desde) && enPulso(hasta) && (hasta - desde).figuraYPuntillos != nil
                && !cruzaLaMitad(desde, hasta) && !cruzaUnaFrontera(desde, hasta)
        }
        if entero(inicio, fin) { return [duracion] }
        // En un compás simple, una figura con puntillo que empieza en un pulso se escribe entera
        // aunque acabe entre pulsos (la negra con puntillo del 1.er o del 3.er tiempo de 4/4),
        // si no oculta la mitad. En los compuestos, el pulso con puntillo ya es la figura.
        if compas.tipo == .simple, enPulso(inicio), duracion > compas.pulso,
           let escritura = duracion.figuraYPuntillos, escritura.puntillos > 0, !cruzaLaMitad(inicio, fin) {
            return [duracion]
        }
        // Si cruza comienzos de pulso, se corta en el más lejano que deje entera la primera parte
        // (una blanca ligada a una corchea, mejor que negra–negra–corchea) o, si no hay, en el primero.
        let cortes = pulsos.filter { $0 > inicio && $0 < fin }
        if let corte = cortes.last(where: { entero(inicio, $0) }) ?? cortes.first {
            let primera = corte - inicio
            return partir(desde: inicio, duracion: primera, compas: compas)
                + partir(desde: corte, duracion: fin - corte, compas: compas)
        }
        // Dentro de un pulso: una figura si se puede; si no, figuras ligadas.
        if duracion.figuraYPuntillos != nil { return [duracion] }
        guard let figuras = duracion.descomposicion else { return [duracion] }
        return enPulso(inicio) ? figuras : figuras.reversed()
    }

    /// Notas unidas por barras en `grafia`: por cada compás, los grupos de índices de notas
    /// consecutivas más breves que una negra dentro de un mismo pulso (dos o más). En 6/8, las
    /// tres corcheas de cada pulso; en 4/4, las corcheas de cada tiempo.
    public var barrasDeAgrupacion: [[[Int]]] {
        grafia.enumerated().map { indice, eventos in
            var posicion = indice == 0 && anacrusa > .cero ? compas.duracion - anacrusa : .cero
            let inicios = compas.iniciosDePulso
            var grupos: [[Int]] = []
            var actual: [Int] = []
            var pulsoActual = -1
            for (i, evento) in eventos.enumerated() {
                let pulso = inicios.lastIndex(where: { $0 <= posicion }) ?? 0
                let corta = !evento.esSilencio && evento.duracion < .negra
                if corta && pulso == pulsoActual {
                    actual.append(i)
                } else {
                    if actual.count >= 2 { grupos.append(actual) }
                    actual = corta ? [i] : []
                    pulsoActual = corta ? pulso : -1
                }
                posicion = posicion + evento.duracion
            }
            if actual.count >= 2 { grupos.append(actual) }
            return grupos
        }
    }

    /// Acento métrico de cada evento de `grafia` (`nil` si empieza a contratiempo).
    public var acentos: [[Compas.Acento?]] {
        grafia.enumerated().map { indice, eventos in
            var posicion = indice == 0 && anacrusa > .cero ? compas.duracion - anacrusa : .cero
            return eventos.map { evento in
                defer { posicion = posicion + evento.duracion }
                return compas.acento(en: posicion)
            }
        }
    }

    /// ¿Acaba justo en una barra de compás (contando la anacrusa)?
    public var terminaEnBarra: Bool {
        let resto = duracion - anacrusa
        return resto >= .cero && (resto / compas.duracion).denominador == 1
    }

    // MARK: Transformaciones

    public func transponer(_ intervalo: Intervalo) -> Voz {
        Voz(eventos.map { $0.transponer(intervalo) }, compas: compas, anacrusa: anacrusa)
    }

    /// Aumentación: todas las duraciones multiplicadas por `factor` (2 = el doble de largo).
    public func aumentar(_ factor: Int) -> Voz {
        Voz(eventos.map { Evento(alturas: $0.alturas, duracion: $0.duracion * factor, ligada: $0.ligada) },
            compas: compas, anacrusa: anacrusa * factor)
    }

    /// Disminución: todas las duraciones divididas por `factor` (2 = la mitad de largo).
    public func disminuir(_ factor: Int) -> Voz {
        Voz(eventos.map { Evento(alturas: $0.alturas, duracion: $0.duracion / factor, ligada: $0.ligada) },
            compas: compas, anacrusa: anacrusa / factor)
    }

    /// Los eventos en orden inverso (las ligaduras pasan a la nota que ahora va delante).
    public func retrogradar() -> Voz {
        let invertidos = eventos.reversed().map { $0 }
        let religados = invertidos.enumerated().map { i, evento -> Evento in
            let ligada = i + 1 < invertidos.count && invertidos[i + 1].ligada
            return Evento(alturas: evento.alturas, duracion: evento.duracion, ligada: ligada)
        }
        return Voz(religados, compas: compas)
    }

    /// Los eventos como texto, separados por espacios: "Do4:4 Re4:8 Mi4:8".
    public func texto(en notacion: Notacion = .espanol) -> String {
        eventos.map { $0.texto(en: notacion) }.joined(separator: " ")
    }
}

extension Voz: CustomStringConvertible {
    public var description: String { "\(compas) " + texto() }
}

extension Voz: Transponible {}
