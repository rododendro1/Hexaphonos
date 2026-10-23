import ArmoniaNucleo
// MARK: - Estructura

/// Análisis de un tipo de acorde: qué intervalo cumple cada papel.
///
///     let e = TipoDeAcorde("13(b9)").estructura
///     e.tercera          // 3ª mayor
///     e.septima          // 7ª menor
///     e.tensiones        // [9ª menor, 13ª mayor]
///     e.calidadDeTriada  // .mayor
public struct EstructuraDeAcorde: Hashable, Sendable {
    public let tercera: Intervalo?
    public let suspension: Intervalo?
    /// Puede haber más de una (por ejemplo, ♭5 y ♯5 en un acorde alterado) o ninguna.
    public let quintasDelAcorde: [Intervalo]
    public let sexta: Intervalo?
    public let septima: Intervalo?
    /// Tensiones como intervalos compuestos (9ª, 11ª, 13ª), de grave a agudo.
    public let tensiones: [Intervalo]
    /// Todas las notas en orden de disposición, cada una con su papel.
    public let componentes: [TipoDeAcorde.Componente]
    public let calidadDeTriada: CalidadDeTriada

    package init(_ clasificacion: ClasificacionDeAcorde) {
        let simple = { (q: Int) in Intervalo.simpleAscendente(pasosDeQuinta: q) }
        tercera = clasificacion.tercera.map(simple)
        suspension = clasificacion.sus4 ? simple(-1) : (clasificacion.sus2 ? simple(2) : nil)
        quintasDelAcorde = clasificacion.quintasDelAcorde.map(simple).sorted()
        sexta = clasificacion.sexta ? simple(3) : nil
        septima = clasificacion.septima.map(simple)
        tensiones = clasificacion.tensiones.map { simple($0) + .octava }.sorted()
        componentes = clasificacion.intervalos.map {
            TipoDeAcorde.Componente(intervalo: $0, papel: EstructuraDeAcorde.papel(de: $0))
        }
        switch clasificacion.tercera {
        case .some(4): calidadDeTriada = clasificacion.aumentado ? .aumentada : .mayor
        case .some(-3): calidadDeTriada = clasificacion.disminuido ? .disminuida : .menor
        default:
            if clasificacion.sus2 || clasificacion.sus4 {
                calidadDeTriada = .suspendida
            } else if clasificacion.quintasDelAcorde == [1] && clasificacion.septima == nil
                        && clasificacion.tensiones.isEmpty && !clasificacion.sexta {
                calidadDeTriada = .potencia
            } else {
                calidadDeTriada = .sinTercera
            }
        }
    }

    /// Papel de un intervalo de la disposición (simples para las notas del acorde,
    /// compuestos para las tensiones).
    package static func papel(de intervalo: Intervalo) -> PapelEnAcorde {
        if intervalo.pasos >= 7 { return .tension(intervalo.numero) }
        switch intervalo.pasosDeQuinta {
        case 0: return .fundamental
        case -3, 4: return .tercera
        case 1, -6, 8: return .quinta
        case -2, 5, -9: return .septima
        case 3, 10: return .sexta
        default: return .suspension
        }
    }

    public var omiteTercera: Bool { calidadDeTriada == .sinTercera }
    public var omiteQuinta: Bool { quintasDelAcorde.isEmpty }
    public var tieneSeptima: Bool { septima != nil }

    /// Intervalos que cumplen un papel (`.quinta` puede devolver varios).
    public func intervalos(conPapel papel: PapelEnAcorde) -> [Intervalo] {
        componentes.filter { $0.papel == papel }.map(\.intervalo)
    }

    /// Papel de un intervalo desde la fundamental (las octavas no importan).
    public func papel(de intervalo: Intervalo) -> PapelEnAcorde? {
        componentes.first { $0.intervalo.pasosDeQuinta == intervalo.pasosDeQuintaConSigno }?.papel
    }
}

// MARK: - Papel de cada nota

/// Papel que cumple una nota dentro de un acorde.
public enum PapelEnAcorde: Hashable, Sendable, CustomStringConvertible {
    case fundamental
    case tercera
    /// 2ª o 4ª que sustituye a la tercera (sus2, sus4).
    case suspension
    case quinta
    /// Sexta añadida de un acorde de sexta (sin séptima), o sexta aumentada (La♭(♯6)).
    case sexta
    case septima
    /// Tensión por encima de la octava: 9, 11 o 13 (la alteración está en el intervalo).
    case tension(Int)

    public var description: String { nombre }

    /// Lee el nombre de un papel en español o en inglés, sin distinguir mayúsculas ni tildes.
    /// Acepta también los nombres de la armonía moderna para las tensiones:
    /// "undécima" u "oncena", "decimotercera" o "trecena", "eleventh", "9ª"…
    public init?(_ texto: String) {
        let clave = texto.claveDeBusqueda
        let alias: [String: PapelEnAcorde] = [
            "oncena": .tension(11), "trecena": .tension(13),
            "tonica": .fundamental, "9ª": .tension(9), "11ª": .tension(11), "13ª": .tension(13),
            "9": .tension(9), "11": .tension(11), "13": .tension(13),
        ]
        if let papel = alias[clave] {
            self = papel
            return
        }
        let todos: [PapelEnAcorde] = [.fundamental, .tercera, .suspension, .quinta, .sexta, .septima,
                                      .tension(9), .tension(11), .tension(13)]
        guard let papel = todos.first(where: { p in
            p.nombre.claveDeBusqueda == clave || p.nombre(en: .ingles).claveDeBusqueda == clave
        }) else { return nil }
        self = papel
    }
}

extension PapelEnAcorde: Nombrable {}

extension TipoDeAcorde {
    /// Una nota de un tipo de acorde: su intervalo desde la fundamental y su papel.
    public struct Componente: Hashable, Sendable {
        public let intervalo: Intervalo
        public let papel: PapelEnAcorde
    }
}

/// Calidad de la tríada básica de un acorde (sin contar séptima ni tensiones).
public enum CalidadDeTriada: Hashable, Sendable {
    case mayor, menor, disminuida, aumentada
    /// sus2 o sus4
    case suspendida
    /// Acorde de potencia o de quinta (fundamental y quinta, sin tercera).
    case potencia
    /// Sin tercera ni suspensión (por ejemplo, 7(omit3)).
    case sinTercera
}

extension CalidadDeTriada: Nombrable {}
