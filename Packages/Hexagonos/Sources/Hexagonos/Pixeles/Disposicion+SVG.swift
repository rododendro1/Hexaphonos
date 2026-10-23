// MARK: - Dibujo en SVG

extension Disposicion {
    /// Un SVG con los hexágonos de `casillas`, ajustado a su tamaño con un `margen` alrededor.
    ///
    /// Cada hexágono es un `<polygon>` con la clase `casilla`; `relleno` elige su color (cualquier
    /// color de CSS, o `nil` para el gris por defecto) y `rotulo`, el texto que se escribe en el centro
    /// (o `nil` para ninguno). Para ver las coordenadas: `rotulo: { "\($0.q),\($0.r)" }`.
    public func svg(_ casillas: [CoordenadaAxial], margen: Double = 4,
                    relleno: (CoordenadaAxial) -> String? = { _ in nil },
                    rotulo: (CoordenadaAxial) -> String? = { _ in nil }) -> String {
        guard let rectangulo = limites(de: casillas) else {
            return #"<svg xmlns="http://www.w3.org/2000/svg" width="0" height="0"></svg>"#
        }
        let (minimo, maximo) = (rectangulo.minimo, rectangulo.maximo)
        let ancho = maximo.x - minimo.x + 2 * margen
        let alto = maximo.y - minimo.y + 2 * margen
        let caja = [minimo.x - margen, minimo.y - margen, ancho, alto].map(numero).joined(separator: " ")
        var lineas = [
            #"<svg xmlns="http://www.w3.org/2000/svg" viewBox="\#(caja)" width="\#(numero(ancho))" height="\#(numero(alto))">"#,
            #"<style>.casilla { stroke: #444; stroke-width: 1; } text { font: \#(numero(min(tamano.x, tamano.y) * 0.5))px sans-serif; text-anchor: middle; dominant-baseline: central; }</style>"#,
        ]
        for casilla in casillas {
            let puntos = vertices(de: casilla).map { "\(numero($0.x)),\(numero($0.y))" }.joined(separator: " ")
            let color = escapar(relleno(casilla) ?? "#eee")
            lineas.append(#"<polygon class="casilla" points="\#(puntos)" fill="\#(color)"/>"#)
            if let texto = rotulo(casilla) {
                let c = centro(de: casilla)
                lineas.append(#"<text x="\#(numero(c.x))" y="\#(numero(c.y))">\#(escapar(texto))</text>"#)
            }
        }
        lineas.append("</svg>")
        return lineas.joined(separator: "\n")
    }
}

/// Un número con dos decimales como mucho y sin ceros de sobra: 12, 12.5, −3.46.
private func numero(_ valor: Double) -> String {
    let redondeado = (valor * 100).rounded() / 100
    if redondeado == 0 { return "0" }   // ni «-0»
    if redondeado == redondeado.rounded() { return String(Int(redondeado)) }
    return String(redondeado)
}

/// El texto con `&`, `<`, `>` y `"` escapados para XML.
private func escapar(_ texto: String) -> String {
    var resultado = ""
    for caracter in texto {
        switch caracter {
        case "&": resultado += "&amp;"
        case "<": resultado += "&lt;"
        case ">": resultado += "&gt;"
        case "\"": resultado += "&quot;"
        default: resultado.append(caracter)
        }
    }
    return resultado
}
