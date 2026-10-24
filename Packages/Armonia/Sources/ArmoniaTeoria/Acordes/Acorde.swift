import ArmoniaNucleo
// MARK: - Acorde

/// Acorde con ortografía: fundamental + tipo + bajo.
/// El bajo puede ser una nota del acorde (inversión) o una nota ajena (Do/Re).
public struct Acorde: Hashable, Sendable {
    public let fundamental: Nota
    public let tipo: TipoDeAcorde
    public let bajo: Nota

    /// `inversion` indexa las notas del acorde en orden (fundamental, 3ª, 5ª, 7ª, tensiones).
    public init(_ fundamental: Nota, _ tipo: TipoDeAcorde, inversion: Int = 0) {
        self.fundamental = fundamental
        self.tipo = tipo
        let notas = tipo.intervalos.map { fundamental + $0 }
        self.bajo = notas[modulo(inversion, notas.count)]
    }

    /// Acorde con un bajo cualquiera (puede no pertenecer al acorde).
    public init(_ fundamental: Nota, _ tipo: TipoDeAcorde, bajo: Nota) {
        self.fundamental = fundamental
        self.tipo = tipo
        self.bajo = bajo
    }

    /// Lee cifrados como "Do", "Rem7", "Fa#m7b5", "Sib7/Re", "G7(b9,#11)", "Do6/9",
    /// "Rem11", "Sol13sus4", "Do7(omit5)", "Do/Re" (bajo ajeno) o "Faug" (letras).
    /// Si no se puede leer, el error indica dónde y por qué.
    public init(leyendo cifrado: String) throws {
        var inicio = Lector(cifrado)
        try inicio.exigirContenido()
        // Primero se lee la fundamental en español; si el resto no es un cifrado válido,
        // se prueba con letras ("Faug" es F aumentado, no Fa seguido de "ug").
        var primerError: ErrorDeLectura?
        for espanol in [true, false] {
            var lector = inicio
            guard let (fundamental, idioma) = lector.leerNombreNotaConIdioma(espanol: espanol) else { continue }
            do {
                self = try Acorde.leer(fundamental: fundamental, idioma: idioma, lector: lector)
                return
            } catch let error as ErrorDeLectura {
                if primerError == nil { primerError = error }
            }
        }
        throw primerError ?? inicio.error(.notaNoReconocida)
    }

    private static func leer(fundamental: Nota, idioma: Idioma, lector: Lector) throws -> Acorde {
        let resto = lector.resto
        var simbolo = resto
        var bajo = fundamental
        // La barra del bajo es la última seguida de un nombre de nota (así "6/9" no se confunde).
        // El bajo se escribe como la fundamental: "Sol7/Si" o "G7/B", no "Sol7/B".
        if let barra = resto.lastIndex(of: "/") {
            let tras = resto[resto.index(after: barra)...]
            var lectorDelBajo = Lector(texto: lector.texto, fragmento: tras)
            if let (nota, idiomaDelBajo) = lectorDelBajo.leerNombreNotaConIdioma(espanol: idioma == .espanol),
               lectorDelBajo.restoSinEspacios.isEmpty {
                guard idiomaDelBajo == idioma else {
                    throw lector.error(.idiomasMezclados(String(tras).trimmingEspacios()), posicion: tras.posicionEnOrigen)
                }
                bajo = nota
                simbolo = resto[..<barra]
            } else if !tras.allSatisfy({ $0.isNumber || $0 == " " }) {
                throw lector.error(.bajoNoValido(String(tras).trimmingEspacios()), posicion: tras.posicionEnOrigen)
            }
        }
        let tipo = try TipoDeAcorde(lector: Lector(texto: lector.texto, fragmento: simbolo))
        return Acorde(fundamental, tipo, bajo: bajo)
    }

    // MARK: Propiedades

    /// Notas desde la fundamental en orden de disposición (Do, Mi, Sol, Si♭, Re).
    public var notas: [Nota] { tipo.intervalos.map { fundamental + $0 } }

    /// Índice del bajo en `notas`: 0 = estado fundamental; `nil` si el bajo es ajeno.
    public var inversion: Int? { notas.firstIndex(of: bajo) }

    public var tieneBajoAjeno: Bool { inversion == nil }

    /// Notas empezando por el bajo.
    public var notasDesdeElBajo: [Nota] {
        let n = notas
        guard let i = inversion else { return [bajo] + n }
        return Array(n[i...] + n[..<i])
    }

    /// "Do7", "Rem/Fa", "Si°", "Do/Re".
    public var cifrado: String { cifrado(estilo: .predeterminado) }

    /// Cifrado en un estilo concreto: `Acorde("Sib7(b9)/Re").cifrado(estilo: .ingles)`
    /// → "Bb7(b9)/D". Todos los estilos se vuelven a leer igual.
    public func cifrado(estilo: EstiloDeCifrado) -> String {
        estilo.nombre(fundamental) + tipo.cifrado(estilo: estilo)
            + (bajo != fundamental ? "/" + estilo.nombre(bajo) : "")
    }

    /// Cifrado en el estilo básico de una notación: `.ingles` → "Bb7(b9)/D".
    public func cifrado(en notacion: Nomenclatura) -> String { cifrado(estilo: EstiloDeCifrado(notacion: notacion)) }

    /// "Do séptima de dominante, primera inversión", "C dominant seventh, first inversion",
    /// "C major over D", "do sèptima de dominant, primera inversió", "do dominanteko zazpigarrena,
    /// lehen inbertsioa", "dó sétima de dominante, primeira inversão", "sol septième de dominante,
    /// premier renversement", "sol settima di dominante, primo rivolto".
    public func nombre(en notacion: Nomenclatura) -> String {
        let raiz = fundamental.nombre(en: notacion)
        let bajo = self.bajo.nombre(en: notacion)
        let tipo = self.tipo.nombre(en: notacion)
        let inversiones: [String]
        let inversionN: String, conBajo: String
        switch notacion.idiomaDeLosTextos {
        case .espanol:
            inversiones = ["estado fundamental", "primera inversión", "segunda inversión", "tercera inversión",
                           "cuarta inversión", "quinta inversión"]
            inversionN = "inversión"; conBajo = "con bajo en \(bajo)"
        case .ingles, .aleman, .occitano, .ruso, .griego:
            guard let i = inversion else { return "\(raiz) \(tipo) over \(bajo)" }
            let enIngles = ["root position", "first inversion", "second inversion", "third inversion",
                            "fourth inversion", "fifth inversion"]
            return "\(raiz) \(tipo), " + (i < enIngles.count ? enIngles[i] : "inversion \(i)")
        case .catalan:
            inversiones = ["estat fonamental", "primera inversió", "segona inversió", "tercera inversió",
                           "quarta inversió", "cinquena inversió"]
            inversionN = "inversió"; conBajo = "amb el baix en \(bajo)"
        case .gallego:
            inversiones = ["estado fundamental", "primeira inversión", "segunda inversión", "terceira inversión",
                           "cuarta inversión", "quinta inversión"]
            inversionN = "inversión"; conBajo = "co baixo en \(bajo)"
        case .euskera:
            inversiones = ["oinarrizko egoera", "lehen inbertsioa", "bigarren inbertsioa", "hirugarren inbertsioa",
                           "laugarren inbertsioa", "bosgarren inbertsioa"]
            inversionN = "inbertsioa"; conBajo = "baxua \(bajo) dela"
        case .portugues:
            inversiones = ["estado fundamental", "primeira inversão", "segunda inversão", "terceira inversão",
                           "quarta inversão", "quinta inversão"]
            inversionN = "inversão"; conBajo = "com o baixo em \(bajo)"
        case .frances:
            inversiones = ["état fondamental", "premier renversement", "deuxième renversement",
                           "troisième renversement", "quatrième renversement", "cinquième renversement"]
            inversionN = "renversement"; conBajo = "avec la basse en \(bajo)"
        case .italiano:
            inversiones = ["stato fondamentale", "primo rivolto", "secondo rivolto", "terzo rivolto",
                           "quarto rivolto", "quinto rivolto"]
            inversionN = "rivolto"; conBajo = "con il basso in \(bajo)"
        }
        guard let i = inversion else { return "\(raiz) \(tipo), \(conBajo)" }
        let detalle = i < inversiones.count ? inversiones[i]
            : (notacion.idiomaDeLosTextos == .euskera ? "\(i). \(inversionN)" : "\(inversionN) \(i)")
        return "\(raiz) \(tipo), \(detalle)"
    }

    /// "Do séptima de dominante, primera inversión".
    public var nombre: String {
        let inversiones = ["estado fundamental", "primera inversión", "segunda inversión",
                           "tercera inversión", "cuarta inversión", "quinta inversión"]
        let detalle: String
        if let i = inversion {
            detalle = i < inversiones.count ? inversiones[i] : "inversión \(i)"
        } else {
            detalle = "con bajo en \(bajo.nombre)"
        }
        return "\(fundamental.nombre) \(tipo.nombre), \(detalle)"
    }

    // MARK: Operaciones

    public func contiene(_ nota: Nota) -> Bool { notas.contains(nota) }

    public func transponer(_ intervalo: Intervalo) -> Acorde {
        Acorde(fundamental + intervalo, tipo, bajo: bajo + intervalo)
    }

    /// El mismo acorde en otra inversión: `Acorde("Do7").invertir(1)` → Do7/Mi.
    public func invertir(_ inversion: Int) -> Acorde {
        Acorde(fundamental, tipo, inversion: inversion)
    }

    /// El mismo acorde con otro bajo (de dentro o de fuera del acorde): Do → Do/Re.
    public func cambiarBajo(_ bajo: Nota) -> Acorde {
        Acorde(fundamental, tipo, bajo: bajo)
    }

    /// Posición cerrada desde el bajo en la octava indicada: cada voz es la primera
    /// aparición de su nota por encima de la anterior.
    /// `Acorde("Do/Mi").posicionCerrada(octava: 4)` → [Mi4, Sol4, Do5].
    public func posicionCerrada(octava: Int = 4) -> [Altura] {
        var voces: [Altura] = []
        for nombre in notasDesdeElBajo {
            if let anterior = voces.last {
                voces.append(anterior + anterior.nota.intervalo(hasta: nombre))
            } else {
                voces.append(Altura(nombre, octava: octava))
            }
        }
        return voces
    }
}

extension Acorde: CustomStringConvertible {
    public var description: String { cifrado }
}

extension Acorde: RepresentableComoTexto, Nombrable, Transponible, ConClasesDeAltura {
    public func texto(_ notacion: Nomenclatura) -> String { cifrado(en: notacion) }

    /// Clases de altura del acorde (incluye un bajo ajeno): Do7 → [0, 4, 7, 10], clase 4-27.
    public var conjuntoDeClases: ConjuntoDeClases { ConjuntoDeClases(notas: notas + [bajo]) }
}

extension Acorde {
    /// Una nota del acorde con su intervalo desde la fundamental y su papel.
    public struct Componente: Hashable, Sendable {
        public let nota: Nota
        public let intervalo: Intervalo
        public let papel: PapelEnAcorde
    }

    public var estructura: EstructuraDeAcorde { tipo.estructura }

    /// Notas en orden de disposición, cada una con su papel.
    /// `Acorde("Sol7(b9)").componentes` → Sol fundamental, Si tercera, Re quinta,
    /// Fa séptima, La♭ novena.
    public var componentes: [Componente] {
        estructura.componentes.map {
            Componente(nota: fundamental + $0.intervalo, intervalo: $0.intervalo, papel: $0.papel)
        }
    }

    /// Notas que cumplen un papel: `acorde.notas(conPapel: .septima)`.
    public func notas(conPapel papel: PapelEnAcorde) -> [Nota] {
        componentes.filter { $0.papel == papel }.map(\.nota)
    }

    /// Papel de una nota en el acorde, o `nil` si no pertenece a él.
    public func papel(de nota: Nota) -> PapelEnAcorde? {
        componentes.first { $0.nota == nota }?.papel
    }

    public var tercera: Nota? { notas(conPapel: .tercera).first }
    /// La quinta (la justa si hay varias).
    public var quinta: Nota? {
        let quintas = notas(conPapel: .quinta)
        return quintas.first { $0 == fundamental + .quintaJusta } ?? quintas.first
    }
    public var septima: Nota? { notas(conPapel: .septima).first }
    /// Tensiones de grave a agudo.
    public var tensiones: [Nota] {
        componentes.filter {
            if case .tension = $0.papel { return true }
            return false
        }.map(\.nota)
    }
}
