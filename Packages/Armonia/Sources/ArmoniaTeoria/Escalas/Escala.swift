import ArmoniaNucleo
// MARK: - Escala

/// Escala concreta: tónica + tipo.
public struct Escala: Hashable, Sendable {
    public let tonica: Nota
    public let tipo: TipoDeEscala

    public init(_ tonica: Nota, _ tipo: TipoDeEscala = .mayor) {
        self.tonica = tonica
        self.tipo = tipo
    }

    /// Lee textos como "Re dórico", "Fa# menor armónica", "Sib mayor", "La menor",
    /// o en inglés: "D dorian", "F# harmonic minor", "Bb major".
    /// Si no se puede leer, el error indica dónde y por qué.
    /// También lee la tónica en catalán, gallego, euskera, portugués, occitano, francés o italiano,
    /// con el tipo en español o en esas lenguas: "re bemoll dòric", "fa sostido menor", "re doriarra",
    /// "fá sustenido dórico", "ré bémol dorien", "fa diesis lidio". Con la tónica en ruso o en griego,
    /// el tipo va en esa lengua (los más comunes) o en inglés: "ре дорийский", "λα αρμονική ελάσσονα",
    /// "до lydian dominant".
    public init(leyendo texto: String) throws {
        self = try Escala.leer(texto)
    }

    private static func leer(_ texto: String) throws -> Escala {
        var lector = Lector(texto)
        try lector.exigirContenido()
        do {
            // Con la tónica en español ("Re"), el tipo también va en español ("dórico");
            // con letra ("D"), se acepta en inglés ("dorian") o en español.
            guard let (tonica, idioma) = lector.leerNombreNotaConIdioma() else { throw lector.error(.notaNoReconocida) }
            lector.saltarEspacios()
            let nombre = lector.restoSinEspacios
            guard let tipo = TipoDeEscala.buscar(nombre: nombre, aceptarIngles: idioma == .ingles) else {
                throw lector.error(.tipoDeEscalaNoReconocido(nombre))
            }
            return Escala(tonica, tipo)
        } catch {
            // La tónica puede ocupar varias palabras ("si bemol bikoitza"); se prueba de más a menos.
            let palabras = texto.split(separator: " ").map(String.init)
            for cuantas in stride(from: min(3, palabras.count - 1), through: 1, by: -1) {
                let tonica = palabras[..<cuantas].joined(separator: " ")
                let tipo = palabras[cuantas...].joined(separator: " ")
                guard let (nombre, notacion) = Escala.leerTonica(tonica) else { continue }
                let normalizado = TipoDeEscala.normalizar(tipo)
                let encontrado = notacion == .ruso || notacion == .griego
                    ? TipoDeEscala.indiceRusoGriego[normalizado] ?? TipoDeEscala.buscar(nombre: tipo, aceptarIngles: true)
                    : TipoDeEscala.indicePeninsular[normalizado] ?? TipoDeEscala.buscar(nombre: tipo, aceptarIngles: false)
                if let encontrado { return Escala(nombre, encontrado) }
            }
            throw error
        }
    }

    /// Tónica en una de las lenguas que se leen sin indicar la notación, o en francés o italiano.
    private static func leerTonica(_ texto: String) -> (Nota, Notacion)? {
        let clave = texto.claveDeBusqueda
        for notacion in Notacion.deLecturaGenerica + [.frances, .italiano] {
            if let nombre = Nota.porNombre[notacion]?[clave] { return (nombre, notacion) }
        }
        return nil
    }

    /// Como `init(leyendo:)`, devolviendo `nil` en lugar de un error.
    public init?(texto: String) {
        guard let escala = try? Escala(leyendo: texto) else { return nil }
        self = escala
    }

    // MARK: Notas

    /// Notas de la forma ascendente, desde la tónica. Es la forma que usan los grados, la
    /// armonización, la armadura y el conjunto de clases de altura.
    public var notas: [Nota] { tipo.intervalos.map { tonica + $0 } }

    /// Notas que aparecen al subir o al bajar, de grave a agudo: en La menor melódica,
    /// La Si Do Re Mi Fa Fa♯ Sol Sol♯. En una escala no direccional, igual que `notas`.
    public var notasEnAmbasDirecciones: [Nota] { tipo.intervalosEnAmbasDirecciones.map { tonica + $0 } }

    /// Notas de una dirección: las de subida o las de bajada (de grave a agudo).
    public func notas(direccion: Direccion) -> [Nota] {
        direccion == .ascendente ? notas : Escala(tonica, tipo.formaDescendente).notas
    }

    /// Grado 1-based; se repite cíclicamente (grado 8 = grado 1).
    public func grado(_ n: Int) -> Nota {
        tonica + tipo.intervalos[modulo(n - 1, tipo.intervalos.count)]
    }

    /// Alturas de la escala con octava. Al subir, de la tónica en `octava` a la tónica superior;
    /// al bajar, de la tónica superior a la tónica en `octava`, con la forma descendente del tipo
    /// (La menor melódica baja con Sol♮ y Fa♮).
    public func alturas(octava: Int, direccion: Direccion = .ascendente) -> [Altura] {
        guard direccion == .ascendente else {
            return Array(Escala(tonica, tipo.formaDescendente).alturas(octava: octava).reversed())
        }
        let inicio = Altura(tonica, octava: octava)
        let alturas: [Altura] = tipo.intervalos.map { inicio + $0 }
        return alturas + [inicio + Intervalo.octava]
    }

    /// Contiene el nombre exacto (Fa♯ ≠ Sol♭), al subir o al bajar; con `direccion`, solo en
    /// esa dirección. La menor melódica contiene Sol (al bajar) y Sol♯ (al subir).
    public func contiene(_ nota: Nota, direccion: Direccion? = nil) -> Bool {
        (direccion.map { notas(direccion: $0) } ?? notasEnAmbasDirecciones).contains(nota)
    }

    /// Contiene la altura, sin importar la ortografía (al subir o al bajar, o en `direccion`).
    public func contieneEnarmonico(_ nota: Nota, direccion: Direccion? = nil) -> Bool {
        (direccion.map { notas(direccion: $0) } ?? notasEnAmbasDirecciones).contains { $0.esEnarmonica(de: nota) }
    }

    /// Grado (1-based) de una nota en la forma ascendente, si pertenece a ella.
    public func grado(de nota: Nota) -> Int? {
        notas.firstIndex(of: nota).map { $0 + 1 }
    }

    // MARK: Armadura y relaciones

    /// Armadura (+ sostenidos, − bemoles) para escalas diatónicas: las siete notas
    /// ocupan siete posiciones consecutivas de la línea de quintas.
    /// Re mayor → 2, Mi♭ mayor → −3, Re dórico → 0. `nil` para escalas no diatónicas.
    public var armadura: Int? {
        let posiciones = Set(notas.map(\.pasosDeQuinta))
        guard posiciones.count == 7, let minimo = posiciones.min(),
              posiciones == Set(minimo..<(minimo + 7)) else { return nil }
        return minimo + 1
    }

    /// Rotación que empieza en el grado indicado (el modo de ese grado): `Escala(.do).rotacion(2)` → Re dórico.
    public func rotacion(_ grado: Int) -> Escala {
        Escala(self.grado(grado), tipo.rotacion(grado))
    }

    public func transponer(_ intervalo: Intervalo) -> Escala {
        Escala(tonica + intervalo, tipo)
    }

    // MARK: Armonización

    /// Acorde por terceras superpuestas sobre un grado (tríada o cuatríada).
    public func acorde(grado: Int, cuatriada: Bool = false) -> Acorde? {
        let nombres = (0..<(cuatriada ? 4 : 3)).map { self.grado(grado + 2 * $0) }
        let raiz = nombres[0]
        guard let tipo = TipoDeAcorde(pasosDeQuinta: Set(nombres.map { $0.pasosDeQuinta - raiz.pasosDeQuinta })) else {
            return nil
        }
        return Acorde(raiz, tipo)
    }

    /// Acordes de todos los grados (`nil` si un grado no forma un tipo conocido).
    public func armonizar(cuatriadas: Bool = false) -> [Acorde?] {
        (1...tipo.intervalos.count).map { acorde(grado: $0, cuatriada: cuatriadas) }
    }

    /// Cifrado romano del acorde de un grado. Las alteraciones del numeral se miden
    /// respecto a la escala `referencia` sobre la misma tónica (mayor por defecto):
    /// La menor armónica → i, ii°, ♭III+, iv, V, ♭VI, vii°;
    /// con `referencia: .menorNatural` → i, ii°, III+, iv, V, VI, ♯vii°.
    /// Sólo para escalas heptatónicas.
    public func cifradoRomano(grado: Int, cuatriada: Bool = false,
                              referencia: TipoDeEscala = .mayor) -> String? {
        guard tipo.intervalos.count == 7, referencia.intervalos.count == 7,
              let acordeGrado = acorde(grado: grado, cuatriada: cuatriada) else { return nil }
        let i = modulo(grado - 1, 7)
        let diferencia = acordeGrado.fundamental.pasosDeQuinta - tonica.pasosDeQuinta
            - referencia.intervalos[i].pasosDeQuinta
        guard diferencia % 7 == 0 else { return nil }
        let romanos = ["I", "II", "III", "IV", "V", "VI", "VII"]
        let numeral = acordeGrado.tipo.esMenor ? romanos[i].lowercased() : romanos[i]
        return Alteracion(diferencia / 7).simbolo + numeral + acordeGrado.tipo.sufijoRomano
    }

    /// Cifrados romanos de todos los grados.
    public func cifradosRomanos(cuatriadas: Bool = false,
                                referencia: TipoDeEscala = .mayor) -> [String?] {
        (1...tipo.intervalos.count).map {
            cifradoRomano(grado: $0, cuatriada: cuatriadas, referencia: referencia)
        }
    }

    /// "Re dórico".
    public var nombre: String { "\(tonica.nombre) \(tipo.nombre)" }

    /// Nombre en la notación indicada: "Re dórico", "D dorian", `.inglesUnicode` → "B♭ harmonic minor".
    public func nombre(en notacion: Notacion) -> String {
        "\(tonica.nombre(en: notacion)) \(tipo.nombre(en: notacion))"
    }
}

extension Escala: CustomStringConvertible {
    public var description: String { nombre }
}

extension Escala: Codable {
    // Se codifica con su estructura (tónica y tipo con sus intervalos) y no como texto,
    // para conservar también los tipos sin nombre conocido, como los modos de escalas propias.
    private enum Claves: String, CodingKey { case tonica, tipo }

    public init(from decoder: Decoder) throws {
        let contenedor = try decoder.container(keyedBy: Claves.self)
        let tonica = try contenedor.decode(Nota.self, forKey: .tonica)
        let tipo = try contenedor.decode(TipoDeEscala.self, forKey: .tipo)
        self.init(tonica, tipo)
    }

    public func encode(to encoder: Encoder) throws {
        var contenedor = encoder.container(keyedBy: Claves.self)
        try contenedor.encode(tonica, forKey: .tonica)
        try contenedor.encode(tipo, forKey: .tipo)
    }
}

extension Escala: RepresentableComoTexto, Nombrable, Transponible, ConClasesDeAltura {
    /// "Re dórico", "D dorian". Los tipos sin nombre conocido no se pueden volver a leer;
    /// por eso `Escala` se codifica con su estructura y no con este texto.
    public func texto(en notacion: Notacion) -> String { nombre(en: notacion) }

    /// Clases de altura de la escala: cualquier escala mayor → 7-35.
    /// Clases de altura de la forma ascendente (la menor melódica es 7-34, como la de jazz).
    public var conjuntoDeClases: ConjuntoDeClases { ConjuntoDeClases(notas: notas) }
}

// MARK: - Armaduras y círculo de quintas

extension Escala {
    /// Alteraciones de la armadura en su orden tradicional:
    /// Re mayor → [Fa♯, Do♯]; Mi♭ mayor → [Si♭, Mi♭, La♭]. `nil` si la escala no es diatónica.
    ///
    /// Más allá de siete, siguen los dobles (el octavo sostenido es Fa𝄪).
    public var notasDeLaArmadura: [Nota]? {
        guard let n = armadura else { return nil }
        if n > 0 { return (0..<n).map { Nota(pasosDeQuinta: 6 + $0) } }
        return (0..<(-n)).map { Nota(pasosDeQuinta: -2 - $0) }
    }

    /// Escala diatónica con una armadura dada: `Escala(armadura: 3)` → La mayor,
    /// `Escala(armadura: -2, tipo: .menorNatural)` → Sol menor, `Escala(armadura: 0, tipo: .dorico)` → Re dórico.
    /// `nil` si el tipo no es diatónico.
    public init?(armadura: Int, tipo: TipoDeEscala = .mayor) {
        let posiciones = tipo.intervalos.map(\.pasosDeQuinta)
        guard let minimo = posiciones.min(), Set(posiciones) == Set(minimo..<(minimo + 7)) else { return nil }
        self.init(Nota(pasosDeQuinta: armadura - 1 - minimo), tipo)
    }

    /// Las tonalidades de un tipo diatónico ordenadas por el círculo de quintas, de 7 bemoles
    /// a 7 sostenidos: Do♭, Sol♭, Re♭ … Do, Sol … Do♯ mayor.
    public static func circuloDeQuintas(_ tipo: TipoDeEscala = .mayor) -> [Escala] {
        (-7...7).compactMap { Escala(armadura: $0, tipo: tipo) }
    }

    /// Distancia en el círculo de quintas entre dos escalas diatónicas: cuántas alteraciones
    /// cambian en la armadura. Do mayor–Sol mayor → 1; Do mayor–La menor → 0.
    public func distancia(hasta otra: Escala) -> Int? {
        guard let a = armadura, let b = otra.armadura else { return nil }
        return abs(a - b)
    }

    /// La escritura enarmónica con menos alteraciones: Do♯ mayor (7♯) → Re♭ mayor (5♭).
    /// Con seis alteraciones en cada lado (Fa♯/Sol♭ mayor) no cambia.
    public var enarmonicaMasSimple: Escala {
        let opciones = [-12, 0, 12].map { Escala(Nota(pasosDeQuinta: tonica.pasosDeQuinta + $0), tipo) }
        func coste(_ e: Escala) -> Int {
            e.armadura.map(abs) ?? e.notas.reduce(0) { $0 + $1.alteracion.cantidad }
        }
        return opciones.min { coste($0) < coste($1) || (coste($0) == coste($1) && $0 == self) } ?? self
    }
}

// MARK: - Funciones de grado

/// Nombre funcional de cada grado de una escala heptatónica.
public enum NombreDeGrado: Hashable, Sendable, CustomStringConvertible {
    case tonica, supertonica, mediante, subdominante, dominante, superdominante
    /// 7.º grado a un semitono de la tónica (Si en Do mayor, Sol♯ en La menor armónica).
    case sensible
    /// 7.º grado a un tono de la tónica (Sol en La menor natural).
    case subtonica

    public var description: String { nombre }


    /// Lee el nombre de una función en español o en inglés, sin distinguir mayúsculas ni tildes:
    /// "Dominante", "superdominante", "submediante", "sensible", "leading tone"…
    public init?(_ texto: String) {
        let clave = texto.claveDeBusqueda
        let alias: [String: NombreDeGrado] = ["submediante": .superdominante, "sub mediante": .superdominante,
                                               "superdominant": .superdominante, "leading note": .sensible]
        if let funcion = alias[clave] {
            self = funcion
            return
        }
        let todas: [NombreDeGrado] = [.tonica, .supertonica, .mediante, .subdominante, .dominante,
                                       .superdominante, .sensible, .subtonica]
        guard let funcion = todas.first(where: { f in
            f.nombre.claveDeBusqueda == clave || f.nombre(en: .ingles).claveDeBusqueda == clave
        }) else { return nil }
        self = funcion
    }
}

extension NombreDeGrado: Nombrable {}

extension Escala {
    /// Función del grado `grado` (1-based) en una escala heptatónica; `nil` en otras escalas.
    public func nombreDeGrado(_ grado: Int) -> NombreDeGrado? {
        guard tipo.intervalos.count == 7 else { return nil }
        let i = modulo(grado - 1, 7)
        let funciones: [NombreDeGrado] = [.tonica, .supertonica, .mediante, .subdominante,
                                           .dominante, .superdominante]
        if i < 6 { return funciones[i] }
        return tipo.intervalos[6].semitonos == 11 ? .sensible : .subtonica
    }

    /// Función de una nota en la escala, si pertenece a ella.
    public func nombreDeGrado(de nota: Nota) -> NombreDeGrado? {
        grado(de: nota).flatMap { nombreDeGrado($0) }
    }
}
