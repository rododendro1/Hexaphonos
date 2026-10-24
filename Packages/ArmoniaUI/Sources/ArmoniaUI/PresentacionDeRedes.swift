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

    /// El nombre de la red en el idioma de los textos: «Tabla armónica», «Harmonic table»…
    public func nombre(en notacion: Notacion) -> String {
        switch self {
        case .tonnetz, .wickiHayden, .janko: return rawValue
        case .tablaArmonica:
            return Traduccion("Tabla armónica", "Harmonic table", ca: "Taula harmònica", gl: "Táboa harmónica",
                              eu: "Taula harmonikoa", pt: "Tabela harmónica", fr: "Table harmonique",
                              it: "Tavola armonica").en(notacion)
        }
    }

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

    /// El lado de las casillas de los teclados en el dibujo.
    static let tamanoDelTeclado = 24.0

    /// La distancia entre dos notas vecinas en el dibujo del Tonnetz o de la tabla: la que usan sus `svg`
    /// por defecto, con más sitio en un recorrido para las flechas. Se fija aquí para saber qué nota se toca.
    static func paso(_ contenido: ContenidoDeRed, en red: RedDeNotas) -> Double {
        var esRecorrido = false
        if case .recorrido(let acordes) = contenido { esRecorrido = acordes.count >= 2 }
        switch red {
        case .tablaArmonica: return esRecorrido ? 72 : 56
        case .tonnetz, .wickiHayden, .janko: return esRecorrido ? 88 : 64
        }
    }

    /// El dibujo SVG del contenido en la red; `nil` si un recorrido está vacío.
    public static func svg(_ contenido: ContenidoDeRed, en red: RedDeNotas, notacion: Notacion) -> String? {
        let paso = Self.paso(contenido, en: red)
        if let teclado = red.teclado {
            let clases = Set(contenido.notas.map(\.claseDeAltura))
            let marcadas = Set((0...127).filter { clases.contains($0 % 12) })
            // Con bemoles si alguna nota lleva bemol (Si♭ está a menos de una quinta por debajo de Fa).
            let bemoles = contenido.notas.contains { $0.pasosDeQuinta < -1 }
            return teclado.svg(casillasDelTeclado, marcadas: marcadas, tamano: tamanoDelTeclado, notacion: notacion,
                               preferirBemoles: bemoles)
        }
        switch (red, contenido) {
        case (.tablaArmonica, .acorde(let acorde)):
            return TablaArmonica(acorde).svg(notacion: notacion, paso: paso)
        case (.tablaArmonica, .escala(let escala)):
            return TablaArmonica(escala).svg(notacion: notacion, paso: paso)
        case (.tablaArmonica, .recorrido(let acordes)):
            guard let primero = acordes.first else { return nil }
            return (acordes.count >= 2 ? TablaArmonica(recorrido: acordes) : nil)?.svg(notacion: notacion, paso: paso)
                ?? TablaArmonica(primero).svg(notacion: notacion, paso: paso)
        case (_, .acorde(let acorde)):
            return Tonnetz(acorde).svg(notacion: notacion, paso: paso)
        case (_, .escala(let escala)):
            return Tonnetz(escala).svg(notacion: notacion, paso: paso)
        case (_, .recorrido(let acordes)):
            guard let primero = acordes.first else { return nil }
            return (acordes.count >= 2 ? Tonnetz(recorrido: acordes) : nil)?.svg(notacion: notacion, paso: paso)
                ?? Tonnetz(primero).svg(notacion: notacion, paso: paso)
        }
    }

    /// La nota que se toca en el dibujo de `svg(_:en:notacion:)`, como número MIDI, o `nil` si el toque no
    /// cae en una nota. `punto` va en las coordenadas del SVG (las de su `viewBox`).
    ///
    /// En el Tonnetz y en la tabla cada nota es una clase de altura, y suena en la octava 4 (de Do4 a Si4);
    /// en un teclado suena la altura de la casilla.
    public static func midi(en punto: Punto, de contenido: ContenidoDeRed, enLaRed red: RedDeNotas) -> Int? {
        if let teclado = red.teclado {
            let casilla = Trazado(orientacion: teclado.orientacion, tamano: tamanoDelTeclado).casilla(en: punto)
            return casillasDelTeclado.contains(casilla) ? teclado.midi(en: casilla) : nil
        }
        let paso = Self.paso(contenido, en: red)
        switch red {
        case .tablaArmonica:
            return 60 + TablaArmonica.punto(en: punto, paso: paso).claseDeAltura
        case .tonnetz, .wickiHayden, .janko:
            // Solo cerca del círculo de la nota: entre dos notas no suena nada.
            let nota = Tonnetz.punto(en: punto, paso: paso)
            let centro = Tonnetz.trazado(paso: paso).centro(de: nota.coordenada)
            let distancia = ((punto.x - centro.x) * (punto.x - centro.x) + (punto.y - centro.y) * (punto.y - centro.y)).squareRoot()
            return distancia <= paso * 0.4 ? 60 + nota.claseDeAltura : nil
        }
    }

    /// El nombre del fichero al exportar el dibujo: «Tonnetz · Dom7».
    public static func nombre(_ contenido: ContenidoDeRed, en red: RedDeNotas, notacion: Notacion) -> String {
        let que: String
        switch contenido {
        case .acorde(let acorde): que = acorde.cifrado(en: notacion)
        case .escala(let escala): que = escala.nombre(en: notacion)
        case .recorrido(let acordes): que = acordes.map { $0.cifrado(en: notacion) }.joined(separator: " ")
        }
        return red.nombre(en: notacion) + " · " + que
    }
}
