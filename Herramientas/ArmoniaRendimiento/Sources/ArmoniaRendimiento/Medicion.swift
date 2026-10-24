import Foundation

/// Una operación que se mide. Devuelve un número que depende de lo calculado, para que el optimizador no se
/// la salte.
struct Caso {
    let grupo: String
    let nombre: String
    let trabajo: () -> Int

    var titulo: String { "\(grupo) · \(nombre)" }
}

/// Lo que se ha medido de un caso. Los tiempos van en segundos.
struct Resultado: Codable {
    let caso: String
    /// La primera vez, que además paga lo que el motor prepara una sola vez (inventarios, tablas).
    let primera: Double
    let mediana: Double
    let minimo: Double
    let repeticiones: Int
}

enum Medicion {
    /// Repite el caso hasta gastar `presupuesto` segundos (al menos tres veces) y se queda con la mediana,
    /// que no se mueve por una vuelta que el sistema haya interrumpido.
    static func medir(_ caso: Caso, presupuesto: Double, comprobacion: inout Int) -> Resultado {
        let reloj = ContinuousClock()
        var valor = 0
        let primera = segundos(reloj.measure { valor = caso.trabajo() })
        comprobacion &+= valor

        var tiempos: [Double] = []
        let inicio = reloj.now
        repeat {
            tiempos.append(segundos(reloj.measure { valor = caso.trabajo() }))
            comprobacion &+= valor
        } while tiempos.count < 3
            || (segundos(inicio.duration(to: reloj.now)) < presupuesto && tiempos.count < 100_000)
        tiempos.sort()
        return Resultado(caso: caso.titulo, primera: primera, mediana: tiempos[tiempos.count / 2],
                         minimo: tiempos[0], repeticiones: tiempos.count)
    }

    static func segundos(_ duracion: Duration) -> Double {
        let (s, atto) = duracion.components
        return Double(s) + Double(atto) / 1e18
    }

    /// 850 ns, 12.5 µs, 3.2 ms, 1.25 s.
    static func texto(_ segundos: Double) -> String {
        switch segundos {
        case ..<1e-6: return String(format: "%.0f ns", segundos * 1e9)
        case ..<1e-3: return String(format: "%.1f µs", segundos * 1e6)
        case ..<1: return String(format: "%.1f ms", segundos * 1e3)
        default: return String(format: "%.2f s", segundos)
        }
    }

    /// El cambio de la mediana frente a una medición anterior: «+35 %», «−20 %».
    static func cambio(_ ahora: Double, antes: Double) -> String {
        guard antes > 0 else { return "–" }
        let porcentaje = (ahora / antes - 1) * 100
        return (porcentaje < 0 ? "−" : "+") + String(format: "%.0f %%", abs(porcentaje))
    }
}
