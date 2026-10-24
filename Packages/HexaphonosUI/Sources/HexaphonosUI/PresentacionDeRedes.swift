import Armonia
import Hexagonos

/// Las redes en que la app Tonnetz dibuja unas notas: el Tonnetz, la tabla armónica y dos teclados
/// isomorfos. No usa SwiftUI, así que se prueba en Linux.
public enum RedDeNotas: String, CaseIterable, Identifiable, Hashable, Sendable {
    case tonnetz = "Tonnetz"
    case tablaArmonica = "Tabla armónica"
    case wickiHayden = "Wicki-Hayden"
    case janko = "Jankó"

    public var id: Self { self }

    /// El teclado isomorfo de la red; `nil` en el Tonnetz y la tabla, que tienen su propio dibujo.
    public var teclado: TecladoIsomorfico? {
        switch self {
        case .tonnetz, .tablaArmonica: return nil
        case .wickiHayden: return .wickiHayden
        case .janko: return .janko
        }
    }
}

/// Lo que se dibuja: un acorde, una escala o un recorrido de tríadas.
public enum ContenidoDeRed: Hashable, Sendable {
    case acorde(Acorde)
    case escala(Escala)
    case recorrido([Acorde])

    /// Las notas, sin repetir, en el orden en que aparecen.
    public var notas: [Nota] {
        let todas: [Nota]
        switch self {
        case .acorde(let acorde): todas = acorde.notas
        case .escala(let escala): todas = escala.notas
        case .recorrido(let acordes): todas = acordes.flatMap(\.notas)
        }
        var vistas = Set<Nota>()
        return todas.filter { vistas.insert($0).inserted }
    }
}

public enum PresentacionDeRedes {
    /// Las casillas de los teclados: 12 columnas por 7 filas, con el Do4 hacia el centro.
    public static let casillasDelTeclado: [CoordenadaAxial] = FormasDeMapa
        .rectangulo(columnas: 12, filas: 7, .filasImpares)
        .map { $0 + CoordenadaAxial(q: -4, r: -4) }

    /// El dibujo SVG del contenido en la red; `nil` si un recorrido está vacío.
    public static func svg(_ contenido: ContenidoDeRed, en red: RedDeNotas, notacion: Nomenclatura) -> String? {
        if let teclado = red.teclado {
            let clases = Set(contenido.notas.map(\.claseDeAltura))
            let marcadas = Set((0...127).filter { clases.contains($0 % 12) })
            // Con bemoles si alguna nota lleva bemol (Si♭ está a menos de una quinta por debajo de Fa).
            let bemoles = contenido.notas.contains { $0.pasosDeQuinta < -1 }
            return teclado.svg(casillasDelTeclado, marcadas: marcadas, notacion: notacion, preferirBemoles: bemoles)
        }
        switch (red, contenido) {
        case (.tablaArmonica, .acorde(let acorde)):
            return TablaArmonica(acorde).svg(notacion: notacion)
        case (.tablaArmonica, .escala(let escala)):
            return TablaArmonica(escala).svg(notacion: notacion)
        case (.tablaArmonica, .recorrido(let acordes)):
            guard let primero = acordes.first else { return nil }
            return (acordes.count >= 2 ? TablaArmonica(recorrido: acordes) : nil)?.svg(notacion: notacion)
                ?? TablaArmonica(primero).svg(notacion: notacion)
        case (_, .acorde(let acorde)):
            return Tonnetz(acorde).svg(notacion: notacion)
        case (_, .escala(let escala)):
            return Tonnetz(escala).svg(notacion: notacion)
        case (_, .recorrido(let acordes)):
            guard let primero = acordes.first else { return nil }
            return (acordes.count >= 2 ? Tonnetz(recorrido: acordes) : nil)?.svg(notacion: notacion)
                ?? Tonnetz(primero).svg(notacion: notacion)
        }
    }

    /// El nombre del fichero al exportar el dibujo: «Tonnetz · Dom7».
    public static func nombre(_ contenido: ContenidoDeRed, en red: RedDeNotas, notacion: Nomenclatura) -> String {
        let que: String
        switch contenido {
        case .acorde(let acorde): que = acorde.cifrado(en: notacion)
        case .escala(let escala): que = escala.nombre(en: notacion)
        case .recorrido(let acordes): que = acordes.map { $0.cifrado(en: notacion) }.joined(separator: " ")
        }
        return red.rawValue + " · " + que
    }
}
