import ArmoniaNucleo
import Foundation

// El catálogo de búsqueda: `todos` (el orden decide qué escala gana al identificar), `buscar(nombre:)`
// y los índices por nombre. Las escalas de otras tradiciones están en `tradicionales`.

extension TipoDeEscala {
    public static let todos: [TipoDeEscala] = [
        .mayor, .dorico, .frigio, .lidio, .mixolidio, .menorNatural, .locrio,
        .menorArmonica, .menorMelodica, .menorMelodicaJazz, .mayorArmonica,
        .locrioSextaNatural, .jonicoAumentado, .doricoCuartaAumentada, .frigioDominante,
        .lidioSegundaAumentada, .ultralocrio,
        .doricoSegundaMenor, .lidioAumentado, .lidioDominante, .mixolidioSextaMenor,
        .locrioSegundaNatural, .alterada,
        .pentatonicaMayor, .pentatonicaMenor, .blues, .tonosEnteros, .disminuida,
        .bebopDominante, .bebopMayor, .bebopDorico,
        .doricoQuintaDisminuida, .frigioCuartaDisminuida, .lidioTerceraMenor, .mixolidioSegundaMenor,
        .lidioAumentadoSegundaAumentada, .locrioSeptimaDisminuida,
        .dobleArmonica, .menorHungara, .mayorHungara, .napolitanaMenor, .napolitanaMayor,
        .enigmatica, .persa, .mayorLocria, .lidioMenor, .prometeo,
        .disminuidaSemitonoTono, .aumentada, .bluesMayor, .egipcia, .cromatica,
        .bebopMenorMelodica, .bebopMenorArmonica, .flamenca, .petrushka,
        .messiaen3, .messiaen4, .messiaen5, .messiaen6, .messiaen7,
        .lidioSegundaSextaAumentadas, .ultrafrigio, .oriental, .jonicoSegundaQuintaAumentadas, .locrioTerceraSeptimaDisminuidas,
        .lidioAumentadoSextaAumentada, .lidioDominanteAumentado, .locrioSegundaNaturalCuartaDisminuida, .superlocrioTerceraDisminuida,
        .lidioSextaAumentada, .mixolidioAumentado, .eolicoCuartaAumentada, .locrioDominante, .jonicoSegundaAumentada,
        .ultralocrioTerceraDisminuida,
        .pentatonicaDominante, .pentatonicaMenorSexta, .pentatonicaMayorSextaMenor, .pentatonicaMenorQuintaDisminuida,
        .bluesDeNueveNotas, .bluesMenorConSegunda, .hexacordo, .argelina,
        .jonicoSinCuarta, .mixolidioSinTercera, .doricoSinSexta, .eolicoSinSegunda, .hexatonicaDeDosTriadas,
        .hexatonicaMenorDeDosTriadas, .mayorRumana,
        .ultralocrioSextaDisminuida, .menorArmonicaQuintaDisminuida, .superlocrioSextaNatural,
        .menorMelodicaQuintaAumentada, .doricoSegundaMenorCuartaAumentada, .lidioAumentadoTerceraAumentada,
        .pentatonicaMixolidia, .pentatonicaLidia, .pentatonicaEscocesa,
    ]

    /// Busca un tipo por su nombre en español o en inglés, sin distinguir mayúsculas
    /// ni guiones: "dórico", "dorico", "Dorian", "harmonic minor", "whole-tone". También
    /// encuentra las escalas de `tradicionales`: "Kafi", "hitzaz", "melakarta 15".
    public static func buscar(nombre: String) -> TipoDeEscala? {
        buscar(nombre: nombre, aceptarIngles: true)
    }

    /// Como `buscar(nombre:)`; con `aceptarIngles: false` solo acepta los nombres en español
    /// (y los tradicionales), para no mezclar idiomas: "Re dorian" no es una escala.
    package static func buscar(nombre: String, aceptarIngles: Bool) -> TipoDeEscala? {
        let n = TipoDeEscala.normalizar(nombre)
        return indicePorNombre[n] ?? (aceptarIngles ? indiceInternacional[n] : nil)
    }

    /// Nombres y alias normalizados → tipo. Un nombre gana a un alias (Hijaz es el maqam Ḥijāz,
    /// no el dromos Hitzáz, que lo tiene de alias); entre nombres o entre alias, gana el primero
    /// (los de `todos` antes que los de `tradicionales`).
    package static let indicePorNombre: [String: TipoDeEscala] = {
        var indice: [String: TipoDeEscala] = [:]
        for tipo in todos + tradicionales where indice[normalizar(tipo.nombre)] == nil {
            indice[normalizar(tipo.nombre)] = tipo
        }
        for tipo in todos + tradicionales {
            for nombre in tipo.alias where indice[normalizar(nombre)] == nil {
                indice[normalizar(nombre)] = tipo
            }
        }
        return indice
    }()

    /// Nombres ingleses normalizados → tipo.
    package static let indiceInternacional: [String: TipoDeEscala] = {
        var indice: [String: TipoDeEscala] = [:]
        for (tipo, nombres) in internacionales {
            for nombre in nombres where indice[normalizar(nombre)] == nil { indice[normalizar(nombre)] = tipo }
        }
        return indice
    }()

    /// Tipo → su nombre inglés principal.
    package static let nombreInglesPorTipo: [TipoDeEscala: String] = {
        var nombres: [TipoDeEscala: String] = [:]
        for (tipo, lista) in internacionales where nombres[tipo] == nil { nombres[tipo] = lista.first }
        return nombres
    }()

    /// Nombres de las escalas de otras tradiciones, que no se traducen.
    package static let nombresTradicionales: Set<String> = Set(tradicionales.map(\.nombre))

    /// Minúsculas, sin diacríticos (dórico → dorico, Kāfī → kafi), ♯/♭ como #/b, sin ♮ y con un
    /// solo espacio entre palabras.
    package static func normalizar(_ texto: String) -> String {
        texto.replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "♭", with: "b")
            .replacingOccurrences(of: "♮", with: "")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .lowercased()
            .split(whereSeparator: { $0 == " " || $0 == "-" }).joined(separator: " ")
    }
}
