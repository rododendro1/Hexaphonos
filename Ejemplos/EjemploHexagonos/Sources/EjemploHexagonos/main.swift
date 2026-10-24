import Hexagonos
import Foundation

func titulo(_ texto: String) { print("\n== \(texto) ==") }

/// Dibuja unas casillas con caracteres, en coordenadas dobladas: cada fila va media casilla a la derecha
/// de la de arriba, como en una rejilla de hexágonos puntiagudos.
func dibujar(_ casillas: [CoordenadaAxial], _ caracter: (CoordenadaAxial) -> Character) {
    let dobladas = casillas.map { (casilla: $0, doblada: $0.doblada(.anchoDoble)) }
    guard let izquierda = dobladas.map(\.doblada.columna).min(), let derecha = dobladas.map(\.doblada.columna).max(),
          let arriba = dobladas.map(\.doblada.fila).min(), let abajo = dobladas.map(\.doblada.fila).max() else { return }
    for fila in arriba...abajo {
        var linea = [Character](repeating: " ", count: derecha - izquierda + 1)
        for (casilla, doblada) in dobladas where doblada.fila == fila {
            linea[doblada.columna - izquierda] = caracter(casilla)
        }
        var texto = String(linea)
        while texto.last == " " { texto.removeLast() }
        print("    " + texto)
    }
}

titulo("Coordenadas")
let a = CoordenadaAxial(q: 1, r: -2)
print("Axial \(a), s = \(a.s) · cúbica \(a.cubica)")
for desplazamiento in Desplazamiento.allCases {
    let desplazada = a.desplazada(desplazamiento)
    print("  desplazada (\(desplazamiento)): \(desplazada) → de vuelta \(CoordenadaAxial(desplazada, desplazamiento))")
}
for doblado in Doblado.allCases {
    let doblada = a.doblada(doblado)
    print("  doblada (\(doblado)): \(doblada) → de vuelta \(CoordenadaAxial(doblada, doblado))")
}

titulo("Vecinos y distancias")
print("Vecinos de \(a):", a.vecinos.map(\.description).joined(separator: " "))
print("Diagonales:", a.vecinosDiagonales.map(\.description).joined(separator: " "))
let b = CoordenadaAxial(q: 4, r: -1)
print("De \(a) a \(b): \(a.distancia(hasta: b)) pasos")
for direccion in DireccionHexagonal.allCases {
    print("  dirección \(direccion.numero): paso \(direccion.paso), \(direccion.puntoCardinal(.puntiaguda))",
          "con hexágonos puntiagudos, \(direccion.puntoCardinal(.plana)) con planos")
}

titulo("Líneas")
let desde = CoordenadaAxial(q: -3, r: 2)
let hasta = CoordenadaAxial(q: 3, r: -1)
let recta = desde.linea(hasta: hasta)
print("De \(desde) a \(hasta):", recta.map(\.description).joined(separator: " "))
let conRecta = Set(recta)
dibujar(FormasDeMapa.hexagono(radio: 3)) { conRecta.contains($0) ? "*" : "·" }

titulo("Regiones")
print("Alcance de radio 2: \(CoordenadaAxial.origen.alcance(radio: 2).count) casillas;",
      "anillo de radio 2: \(CoordenadaAxial.origen.anillo(radio: 2).count)")
print("Espiral de radio 1:", CoordenadaAxial.origen.espiral(radio: 1).map(\.description).joined(separator: " "))
let anillo = Set(CoordenadaAxial.origen.anillo(radio: 2))
dibujar(FormasDeMapa.hexagono(radio: 3)) { $0 == .origen ? "o" : (anillo.contains($0) ? "#" : "·") }
for (nombre, forma) in [("Paralelogramo 3 × 2", FormasDeMapa.paralelogramo(columnas: 0...2, filas: 0...1)),
                        ("Triángulo de lado 3", FormasDeMapa.triangulo(lado: 3)),
                        ("Rectángulo 5 × 3", FormasDeMapa.rectangulo(columnas: 5, filas: 3, .filasImpares))] {
    print("  \(nombre): \(forma.count) casillas")
    dibujar(forma) { _ in "#" }
}

titulo("Rotaciones y reflexiones")
let c = CoordenadaAxial(q: 2, r: -1)
print("\(c) girada de 60 en 60 grados:", (0..<6).map { c.rotada(sextos: $0).description }.joined(separator: " "))
for eje in Eje.allCases {
    print("  reflejada sobre el eje \(eje): \(c.reflejada(sobre: eje))")
}
let girada = Set((0..<6).map { c.rotada(sextos: $0) })
dibujar(FormasDeMapa.hexagono(radio: 2)) { $0 == c ? "1" : (girada.contains($0) ? "*" : "·") }

titulo("Un mapa y el camino más barato")
enum Terreno: String, Codable {
    case hierba = "."
    case bosque = "♣"
    case montana = "^"
    case agua = "~"

    /// Lo que cuesta entrar en la casilla; `nil` si no se puede.
    var coste: Double? {
        switch self {
        case .hierba: return 1
        case .bosque: return 2
        case .montana: return 3
        case .agua: return nil
        }
    }
}
var terreno = MapaHexagonal(repitiendo: Terreno.hierba, en: FormasDeMapa.hexagono(radio: 4))
// Un río de norte a sur que solo se cruza por el sur, unas montañas y un bosque.
for r in -4...1 { terreno[CoordenadaAxial(q: 0, r: r)] = .agua }
for casilla in CoordenadaAxial(q: 2, r: -2).alcance(radio: 1) { terreno[casilla] = .montana }
for casilla in [CoordenadaAxial(q: -1, r: 3), CoordenadaAxial(q: 0, r: 2), CoordenadaAxial(q: 1, r: 2)] {
    terreno[casilla] = .bosque
}
let salida = CoordenadaAxial(q: -4, r: 1)
let llegada = CoordenadaAxial(q: 4, r: -2)
if let camino = terreno.caminoMasBarato(desde: salida, hasta: llegada, costeMinimo: 1, coste: \.coste) {
    print("De \(salida) a \(llegada): \(camino.pasos) pasos, coste \(camino.coste)")
    let pisadas = Set(camino.casillas)
    dibujar(Array(terreno.casillas)) { pisadas.contains($0) ? "*" : Character(terreno[$0]!.rawValue) }
}
let alcanzables = terreno.alcanzables(desde: salida, presupuesto: 4, coste: \.coste)
print("Con un presupuesto de 4 se llega a \(alcanzables.count) casillas")
let vistas = terreno.visibles(desde: llegada, tapa: { $0 == .montana })
print("Desde \(llegada) se ven \(vistas.count) de \(terreno.count) casillas: las montañas tapan")
let alrededor = terreno.vecinas(de: .origen).map { "\($0.casilla) \($0.valor.rawValue)" }
print("Alrededor del centro:", alrededor.joined(separator: ", "))

titulo("Guardar el mapa")
let datos = try! JSONEncoder().encode(terreno)
let leido = try! JSONDecoder().decode(MapaHexagonal<Terreno>.self, from: datos)
print("\(terreno) en \(datos.count) bytes de JSON; leído de vuelta: \(leido),",
      "igual:", leido.casillas.allSatisfy { leido[$0] == terreno[$0] })

titulo("De casillas a píxeles")
let trazado = Trazado(orientacion: .puntiaguda, tamano: 20, origen: Punto(x: 100, y: 100))
print("Hexágonos puntiagudos de tamaño 20: \(trazado.anchura) × \(trazado.altura)")
print("Centro de \(a): \(trazado.centro(de: a))")
let toque = Punto(x: 131, y: 92)
print("Un toque en \(toque) cae en la casilla \(trazado.casilla(en: toque))")
print("Vértices del origen:", trazado.vertices(de: .origen).map { "(\(Int($0.x.rounded())), \(Int($0.y.rounded())))" }
        .joined(separator: " "))
let svg = Trazado(orientacion: .puntiaguda, tamano: 20).svg(FormasDeMapa.hexagono(radio: 2),
                                                             relleno: { $0 == .origen ? "#f39c12" : nil },
                                                             rotulo: { "\($0.q),\($0.r)" })
print("SVG del hexágono de radio 2: \(svg.count) caracteres; empieza por", svg.prefix(60) + "…")
