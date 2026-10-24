import ArmoniaNucleo
import ArmoniaTeoria
// Lo común a los dibujos SVG del Tonnetz y de la tabla armónica: los colores, qué puntos se
// marcan, las tríadas que se rellenan, los textos de la leyenda, el título encima, la leyenda
// debajo, el fondo, el escapado del texto y el formato de los números.

import Foundation

/// Lo que se dibuja: de dónde salen las notas, para ponerle título al dibujo.
package enum OrigenDelDibujo: Hashable, Sendable {
    case notas([Nota])
    case acorde(Acorde)
    case escala(Escala)
    case conjunto(ConjuntoDeClases)
    case alturas([Altura])
    case ciclo(CicloNeorriemanniano, Acorde)

    /// "Domaj7", "Re dórico", "Do · Mi · Sol", "Conjunto [0, 4, 7]", "Do3 · Sol3 · Mi4".
    package func titulo(_ notacion: Nomenclatura) -> String {
        switch self {
        case .notas(let notas): return notas.map { $0.nombreCompacto(en: notacion) }.joined(separator: " · ")
        case .acorde(let acorde): return acorde.cifrado(en: notacion)
        case .escala(let escala): return escala.nombre(en: notacion)
        case .conjunto(let conjunto):
            return Traduccion("Conjunto ", "Set ", ca: "Conjunt ", gl: "Conxunto ", eu: "Multzoa ",
                              pt: "Conjunto ", fr: "Ensemble ", it: "Insieme ").en(notacion)
                + conjunto.description
        case .alturas(let alturas):
            return alturas.map { $0.nota.nombreCompacto(en: notacion) + "\($0.octava)" }.joined(separator: " · ")
        case .ciclo(let ciclo, let acorde):
            let nombre = ciclo.nombre(en: notacion), cifrado = acorde.cifrado(en: notacion)
            let titulo = Traduccion("\(nombre) desde \(cifrado)", "\(nombre) from \(cifrado)",
                                    ca: "\(nombre) des de \(cifrado)", gl: "\(nombre) desde \(cifrado)",
                                    eu: "\(nombre) \(cifrado)-tik",
                                    pt: "\(nombre) a partir de \(cifrado)", fr: "\(nombre) depuis \(cifrado)", it: "\(nombre) da \(cifrado)").en(notacion)
            return titulo.prefix(1).uppercased() + titulo.dropFirst()
        }
    }

    /// "tónica", "fundamental" o "primera nota".
    package func primera(_ notacion: Nomenclatura) -> String {
        switch self {
        case .escala: return NombreDeGrado.tonica.nombre(en: notacion)
        case .acorde: return PapelEnAcorde.fundamental.nombre(en: notacion)
        case .conjunto:
            return Traduccion("primera clase", "first pitch class", ca: "primera classe", gl: "primeira clase",
                              eu: "lehen klasea",
                              pt: "primeira classe", fr: "première classe", it: "prima classe").en(notacion)
        default:
            return Traduccion("primera nota", "first note", ca: "primera nota", gl: "primeira nota",
                              eu: "lehen nota", pt: "primeira nota", fr: "première note", it: "prima nota").en(notacion)
        }
    }
}

/// Una entrada de la leyenda: una muestra y su texto.
package struct EntradaDeLeyenda {
    package enum Muestra {
        case triangulo(String)               // relleno
        case hexagono(relleno: String, borde: String)
        case circulo(relleno: String, borde: String)
        case linea(String, grosor: Double)
        case flecha
    }
    package let muestra: Muestra
    package let texto: String
}

package enum DibujoSVG {
    /// Los colores de los dos dibujos.
    package enum Color {
        /// Las notas del conjunto.
        package static let nota = "#1f4e9c"
        /// Tríadas mayores y menores.
        package static let mayor = "#f6b26b"
        package static let menor = "#8fb8e8"
        /// Las flechas de un recorrido.
        package static let flecha = "#c0392b"
        /// El borde de la primera nota (tónica o fundamental).
        package static let primera = "#f39c12"
    }

    /// Los textos de la leyenda, en los ocho idiomas de los textos (`Traduccion`).
    package enum Texto {
        case nota, claseDeAltura, altura, intervalos, contorno, triadaMayor, triadaMenor, pasoDelRecorrido
        case fundamentalDelPrimerAcorde

        package func en(_ notacion: Nomenclatura) -> String { traduccion.en(notacion) }

        private var traduccion: Traduccion {
            switch self {
            case .nota: return Traduccion("nota", "note", ca: "nota", gl: "nota", eu: "nota",
                                          pt: "nota", fr: "note", it: "nota")
            case .claseDeAltura:
                return Traduccion("clase de altura (todas sus copias)", "pitch class (every copy)",
                                  ca: "classe d'altura (totes les còpies)", gl: "clase de altura (todas as súas copias)",
                                  eu: "altuera-klasea (kopia guztiak)",
                                  pt: "classe de altura (todas as cópias)", fr: "classe de hauteur (toutes ses copies)", it: "classe di altezza (tutte le sue copie)")
            case .altura:
                return Traduccion("altura (todas sus teclas)", "pitch (every key)", ca: "altura (totes les tecles)",
                                  gl: "altura (todas as súas teclas)", eu: "altuera (tekla guztiak)",
                                  pt: "altura (todas as teclas)", fr: "hauteur (toutes ses touches)", it: "altezza (tutti i suoi tasti)")
            case .intervalos:
                return Traduccion("quinta o tercera entre notas", "fifth or third between notes",
                                  ca: "quinta o tercera entre notes", gl: "quinta ou terceira entre notas",
                                  eu: "noten arteko bosgarrena edo hirugarrena",
                                  pt: "quinta ou terça entre notas", fr: "quinte ou tierce entre notes", it: "quinta o terza tra note")
            case .contorno:
                return Traduccion("contorno de la forma", "outline of the shape", ca: "contorn de la forma",
                                  gl: "contorno da forma", eu: "formaren ingerada",
                                  pt: "contorno da forma", fr: "contour de la forme", it: "contorno della forma")
            case .triadaMayor:
                return Traduccion("tríada mayor", "major triad", ca: "tríada major", gl: "tríade maior", eu: "triade maiorra",
                                  pt: "tríade maior", fr: "triade majeure", it: "triade maggiore")
            case .triadaMenor:
                return Traduccion("tríada menor", "minor triad", ca: "tríada menor", gl: "tríade menor", eu: "triade minorra",
                                  pt: "tríade menor", fr: "triade mineure", it: "triade minore")
            case .pasoDelRecorrido:
                return Traduccion("paso del recorrido (P, L, R)", "step of the progression (P, L, R)",
                                  ca: "pas del recorregut (P, L, R)", gl: "paso do percorrido (P, L, R)",
                                  eu: "ibilbidearen urratsa (P, L, R)",
                                  pt: "passo do percurso (P, L, R)", fr: "étape du parcours (P, L, R)", it: "passo del percorso (P, L, R)")
            case .fundamentalDelPrimerAcorde:
                return Traduccion("fundamental del primer acorde", "root of the first chord",
                                  ca: "fonamental del primer acord", gl: "fundamental do primeiro acorde",
                                  eu: "lehen akordearen oinarria",
                                  pt: "fundamental do primeiro acorde", fr: "fondamentale du premier accord", it: "fondamentale del primo accordo")
            }
        }
    }

    package static func f(_ v: Double) -> String { String(format: "%.1f", v) }

    package static func escapar(_ texto: String) -> String {
        texto.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// Los puntos de la ventana que se marcan y, entre ellos, los de la primera nota. Sin `clave`,
    /// los puntos mismos; con ella (la clase de altura o el número MIDI), todos los de la ventana
    /// que suenan como alguno de ellos.
    package static func marcar(_ puntos: [PuntoDelTonnetz], en red: [PuntoDelTonnetz],
                       clave: ((PuntoDelTonnetz) -> Int)?) -> (marcados: Set<PuntoDelTonnetz>, primeros: Set<PuntoDelTonnetz>) {
        guard let clave = clave else { return (Set(puntos), puntos.first.map { [$0] } ?? []) }
        let claves = Set(puntos.map(clave))
        let primera = puntos.first.map(clave)
        return (Set(red.filter { claves.contains(clave($0)) }), Set(red.filter { clave($0) == primera }))
    }

    /// Las tríadas mayores y menores con los tres vértices marcados y dentro de la ventana, en el
    /// orden de la red (y, en cada punto, primero la mayor).
    package static func triadas(en red: [PuntoDelTonnetz], marcados: Set<PuntoDelTonnetz>) -> [Tonnetz.Triada] {
        let enRed = Set(red)
        return red.flatMap { punto in
            [true, false].compactMap { mayor -> Tonnetz.Triada? in
                let triada = Tonnetz.Triada(fundamental: punto, mayor: mayor)
                return triada.vertices.allSatisfy { enRed.contains($0) && marcados.contains($0) } ? triada : nil
            }
        }
    }

    /// Envuelve el cuerpo de un dibujo, que ocupa la caja (x, y, ancho, alto), con el fondo, el
    /// título encima y la leyenda debajo (en varias filas si no cabe).
    package static func componer(caja: (x: Double, y: Double, ancho: Double, alto: Double), cuerpo: String,
                         titulo: String, leyenda: [EntradaDeLeyenda], paso: Double) -> String {
        let tamanoDelTitulo = paso * 0.3, tamanoDeLeyenda = paso * 0.2
        let margen = paso * 0.15
        let altoDelTitulo = titulo.isEmpty ? 0 : tamanoDelTitulo * 1.8
        // Anchura aproximada de un texto, para repartir la leyenda.
        func anchoDe(_ texto: String, _ tamano: Double) -> Double { Double(texto.count) * tamano * 0.56 }
        let muestra = tamanoDeLeyenda * 1.6
        let entradas = leyenda.map { (entrada: $0, ancho: muestra + tamanoDeLeyenda * 0.5 + anchoDe($0.texto, tamanoDeLeyenda) + tamanoDeLeyenda * 1.4) }
        let ancho = max(caja.ancho, anchoDe(titulo, tamanoDelTitulo) * 1.12 + 2 * margen,
                        (entradas.map(\.ancho).max() ?? 0) + 2 * margen)
        // Las filas de la leyenda.
        var filas: [[(entrada: EntradaDeLeyenda, ancho: Double)]] = []
        for e in entradas {
            if let ultima = filas.last, ultima.reduce(0, { $0 + $1.ancho }) + e.ancho <= ancho - 2 * margen {
                filas[filas.count - 1].append(e)
            } else {
                filas.append([e])
            }
        }
        let altoDeFila = tamanoDeLeyenda * 1.9
        let altoDeLeyenda = filas.isEmpty ? 0 : Double(filas.count) * altoDeFila + margen
        let x0 = caja.x - (ancho - caja.ancho) / 2
        let y0 = caja.y - altoDelTitulo
        let alto = caja.alto + altoDelTitulo + altoDeLeyenda

        var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"\(f(x0)) \(f(y0)) \(f(ancho)) \(f(alto))\" "
        svg += "width=\"\(f(ancho))\" height=\"\(f(alto))\" font-family=\"sans-serif\">\n"
        if !titulo.isEmpty { svg += "  <title>\(escapar(titulo))</title>\n" }
        svg += "  <rect x=\"\(f(x0))\" y=\"\(f(y0))\" width=\"\(f(ancho))\" height=\"\(f(alto))\" fill=\"#ffffff\"/>\n"
        if !titulo.isEmpty {
            svg += "  <text x=\"\(f(x0 + margen))\" y=\"\(f(y0 + altoDelTitulo / 2 + margen / 2))\" dominant-baseline=\"central\" "
            svg += "font-size=\"\(f(tamanoDelTitulo))\" font-weight=\"600\" fill=\"#222222\">\(escapar(titulo))</text>\n"
        }
        svg += cuerpo
        // La leyenda.
        var y = caja.y + caja.alto + margen / 2 + altoDeFila / 2
        let s = tamanoDeLeyenda * 0.75   // medio lado de la muestra
        for fila in filas {
            var x = x0 + margen
            for (entrada, anchoDeEntrada) in fila {
                let cx = x + muestra / 2
                svg += "  <g class=\"leyenda\">"
                switch entrada.muestra {
                case .triangulo(let color):
                    svg += "<polygon points=\"\(f(cx - s)),\(f(y + s * 0.8)) \(f(cx + s)),\(f(y + s * 0.8)) \(f(cx)),\(f(y - s * 0.9))\" "
                    svg += "fill=\"\(color)\" fill-opacity=\"0.8\" stroke=\"#333333\" stroke-width=\"1\"/>"
                case .hexagono(let relleno, let borde):
                    let r = s * 1.05
                    let esquinas = stride(from: 0.0, to: 360, by: 60).map { a in
                        "\(f(cx + r * cos(a * .pi / 180))),\(f(y + r * sin(a * .pi / 180)))"
                    }.joined(separator: " ")
                    svg += "<polygon points=\"\(esquinas)\" fill=\"\(relleno)\" stroke=\"\(borde)\" stroke-width=\"2\"/>"
                case .circulo(let relleno, let borde):
                    svg += "<circle cx=\"\(f(cx))\" cy=\"\(f(y))\" r=\"\(f(s * 0.8))\" fill=\"\(relleno)\" stroke=\"\(borde)\" stroke-width=\"1.5\"/>"
                case .linea(let color, let grosor):
                    svg += "<line x1=\"\(f(cx - s))\" y1=\"\(f(y))\" x2=\"\(f(cx + s))\" y2=\"\(f(y))\" stroke=\"\(color)\" stroke-width=\"\(f(grosor))\"/>"
                case .flecha:
                    svg += "<line x1=\"\(f(cx - s))\" y1=\"\(f(y))\" x2=\"\(f(cx + s))\" y2=\"\(f(y))\" stroke=\"#c0392b\" stroke-width=\"2.5\" marker-end=\"url(#flecha)\"/>"
                }
                svg += "<text x=\"\(f(x + muestra + tamanoDeLeyenda * 0.5))\" y=\"\(f(y))\" dominant-baseline=\"central\" "
                svg += "font-size=\"\(f(tamanoDeLeyenda))\" fill=\"#444444\">\(escapar(entrada.texto))</text></g>\n"
                x += anchoDeEntrada
            }
            y += altoDeFila
        }
        return svg + "</svg>\n"
    }

    /// El título de un recorrido: "Do –R→ Lam –L→ Fa", con la secuencia más corta de P, L y R
    /// entre tríadas que no son vecinas; vacío si no hay recorrido.
    /// Con `acordes`, los nombres de las tríadas son esos (los de un ciclo, que no siempre
    /// coinciden con la posición del triángulo).
    package static func titulo(deRecorrido recorrido: [Tonnetz.Triada], _ notacion: Nomenclatura,
                       acordes: [Acorde] = []) -> String {
        guard !recorrido.isEmpty else { return "" }
        let nombres = acordes.count == recorrido.count ? acordes : recorrido.map(\.acorde)
        var titulo = nombres[0].cifrado(en: notacion)
        for (i, (uno, otro)) in zip(recorrido, recorrido.dropFirst()).enumerated() {
            let pasos = Tonnetz.camino(desde: uno.acorde, hasta: otro.acorde) ?? []
            titulo += (pasos.isEmpty ? " – " : " –\(pasos.map(\.rawValue).joined())→ ") + nombres[i + 1].cifrado(en: notacion)
        }
        return titulo
    }

    /// Las flechas de un recorrido, de tríada en tríada, con un punto en la primera. `centro` da
    /// dónde se dibuja cada tríada en unidades de `paso` (el centro del triángulo en el Tonnetz,
    /// el vértice común de los tres hexágonos en la tabla armónica).
    package static func flechas(_ recorrido: [Tonnetz.Triada], centro: (Tonnetz.Triada) -> (Double, Double), paso: Double) -> String {
        var svg = ""
        if !recorrido.isEmpty {
            svg += "  <defs><marker id=\"flecha\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"5\" "
            svg += "markerHeight=\"5\" orient=\"auto\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"\(DibujoSVG.Color.flecha)\"/></marker></defs>\n"
            let (x0, y0) = centro(recorrido[0])
            svg += "  <circle cx=\"\(f(x0 * paso))\" cy=\"\(f(y0 * paso))\" r=\"\(f(paso * 0.07))\" fill=\"\(DibujoSVG.Color.flecha)\"/>\n"
        }
        // Las flechas entre los mismos dos triángulos (de ida o de vuelta) se separan: se curvan
        // hacia lados distintos de la línea entre sus centros, cada una un poco más que la anterior.
        let pasos = zip(recorrido, recorrido.dropFirst()).filter { $0.0 != $0.1 }
        func par(_ uno: Tonnetz.Triada, _ otro: Tonnetz.Triada) -> [Tonnetz.Triada] {
            func clave(_ t: Tonnetz.Triada) -> (Int, Int, Int) { (t.fundamental.quintas, t.fundamental.terceras, t.mayor ? 0 : 1) }
            return clave(uno) < clave(otro) ? [uno, otro] : [otro, uno]
        }
        var veces: [[Tonnetz.Triada]: Int] = [:]
        for (uno, otro) in pasos { veces[par(uno, otro), default: 0] += 1 }
        var dibujadas: [[Tonnetz.Triada]: Int] = [:]
        for (uno, otro) in pasos {
            let clave = par(uno, otro)
            let k = dibujadas[clave, default: 0]
            dibujadas[clave] = k + 1
            // El desplazamiento, perpendicular al sentido del par (no al de la flecha), para que la
            // ida y la vuelta caigan en lados opuestos.
            let (px1, py1) = centro(clave[0]), (px2, py2) = centro(clave[1])
            let largoDelPar = ((px2 - px1) * (px2 - px1) + (py2 - py1) * (py2 - py1)).squareRoot()
            let separacion = (Double(k) - Double(veces[clave]! - 1) / 2) * 0.12
            let (nx, ny) = (-(py2 - py1) / largoDelPar, (px2 - px1) / largoDelPar)
            // Los extremos, algo apartados de los centros y entre sí; el punto de control, más.
            let (x1, y1) = (centro(uno).0 + nx * separacion * 0.6, centro(uno).1 + ny * separacion * 0.6)
            let (x2, y2) = (centro(otro).0 + nx * separacion * 0.6, centro(otro).1 + ny * separacion * 0.6)
            let largo = ((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)).squareRoot()
            let recorte = min(0.1, largo / 4) / largo
            let (ax, ay) = (x1 + (x2 - x1) * recorte, y1 + (y2 - y1) * recorte)
            let (bx, by) = (x2 - (x2 - x1) * recorte, y2 - (y2 - y1) * recorte)
            if separacion == 0 {
                svg += "  <line x1=\"\(f(ax * paso))\" y1=\"\(f(ay * paso))\" x2=\"\(f(bx * paso))\" y2=\"\(f(by * paso))\" "
            } else {
                let (cx, cy) = ((ax + bx) / 2 + nx * separacion * 1.4, (ay + by) / 2 + ny * separacion * 1.4)
                svg += "  <path d=\"M\(f(ax * paso)),\(f(ay * paso)) Q\(f(cx * paso)),\(f(cy * paso)) \(f(bx * paso)),\(f(by * paso))\" fill=\"none\" "
            }
            svg += "stroke=\"\(DibujoSVG.Color.flecha)\" stroke-width=\"\(veces[clave]! > 1 ? "2.2" : "3")\" marker-end=\"url(#flecha)\"/>\n"
        }
        return svg
    }
}
