#if canImport(SwiftUI)
import SwiftUI
import Hexagonos

/// Un mapa de casillas hexagonales, que avisa de qué casilla se toca.
///
///     DiagramaHexagonal(FormasDeMapa.hexagono(radio: 3), seleccionada: elegida) { elegida = $0 }
///     DiagramaHexagonal(mapa, orientacion: .plana,
///                       relleno: { terreno[$0]?.color }, rotulo: { "\($0.q),\($0.r)" })
///
/// Los hexágonos se encajan lo más grandes posible en el espacio que se le dé, con la proporción del
/// mapa. Un toque fuera del mapa (en el margen o entre casillas que faltan) no avisa.
public struct DiagramaHexagonal: View {
    public let casillas: [CoordenadaAxial]
    public let orientacion: Orientacion
    /// La casilla que se resalta con el color de énfasis.
    public let seleccionada: CoordenadaAxial?
    private let relleno: (CoordenadaAxial) -> Color?
    private let rotulo: (CoordenadaAxial) -> String?
    private let alTocar: ((CoordenadaAxial) -> Void)?

    /// - Parameters:
    ///   - relleno: el color de cada casilla (`nil`, el gris por defecto).
    ///   - rotulo: el texto que se escribe en el centro de cada casilla (`nil`, ninguno).
    ///   - alTocar: lo que se hace al tocar una casilla del mapa.
    public init(_ casillas: [CoordenadaAxial], orientacion: Orientacion = .puntiaguda,
                seleccionada: CoordenadaAxial? = nil,
                relleno: @escaping (CoordenadaAxial) -> Color? = { _ in nil },
                rotulo: @escaping (CoordenadaAxial) -> String? = { _ in nil },
                alTocar: ((CoordenadaAxial) -> Void)? = nil) {
        self.casillas = casillas
        self.orientacion = orientacion
        self.seleccionada = seleccionada
        self.relleno = relleno
        self.rotulo = rotulo
        self.alTocar = alTocar
    }

    /// El margen alrededor del mapa, para que no se corte el trazo de los bordes.
    static let margen: Double = 3

    public var body: some View {
        GeometryReader { geometria in
            let disposicion = PresentacionHexagonal.disposicion(
                para: casillas, orientacion: orientacion,
                ancho: Double(geometria.size.width), alto: Double(geometria.size.height), margen: Self.margen)
            Canvas { contexto, _ in
                if let disposicion {
                    dibujar(en: &contexto, disposicion: disposicion)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { punto in
                guard let alTocar, let disposicion,
                      let casilla = PresentacionHexagonal.casilla(en: Punto(x: Double(punto.x), y: Double(punto.y)),
                                                                  disposicion: disposicion, mapa: Set(casillas))
                else { return }
                alTocar(casilla)
            }
        }
        .aspectRatio(PresentacionHexagonal.proporcion(de: casillas, orientacion: orientacion).map { CGFloat($0) },
                     contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(Text("Rejilla hexagonal"))
        .accessibilityValue(Text(PresentacionHexagonal.descripcion(casillas: casillas.count, seleccionada: seleccionada)))
    }

    private func dibujar(en contexto: inout GraphicsContext, disposicion: Disposicion) {
        let grosor = max(0.5, disposicion.tamano.x * 0.05)

        func hexagono(_ casilla: CoordenadaAxial) -> Path {
            var camino = Path()
            camino.addLines(disposicion.vertices(de: casilla).map { CGPoint(x: $0.x, y: $0.y) })
            camino.closeSubpath()
            return camino
        }

        for casilla in casillas {
            let forma = hexagono(casilla)
            contexto.fill(forma, with: .color(relleno(casilla) ?? Color.gray.opacity(0.15)))
            contexto.stroke(forma, with: .color(.secondary), lineWidth: grosor)
            if let texto = rotulo(casilla) {
                let centro = disposicion.centro(de: casilla)
                contexto.draw(Text(texto).font(.system(size: max(6, disposicion.tamano.x * 0.45))),
                              at: CGPoint(x: centro.x, y: centro.y))
            }
        }

        // La elegida, encima de las demás para que su borde no quede tapado por el de las vecinas.
        if let seleccionada, casillas.contains(seleccionada) {
            contexto.stroke(hexagono(seleccionada), with: .color(TemaHexaphonos.acento), lineWidth: grosor * 3)
        }
    }
}
#endif
