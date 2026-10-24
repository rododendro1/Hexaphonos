#if canImport(SwiftUI)
import SwiftUI
import Armonia
import Hexagonos

/// Un mapa de casillas hexagonales, que avisa de qué casilla se toca.
///
///     DiagramaDeRejilla(FormasDeMapa.hexagono(radio: 3), seleccionada: elegida) { elegida = $0 }
///     DiagramaDeRejilla(mapa, orientacion: .plana,
///                       relleno: { terreno[$0]?.color }, rotulo: { "\($0.q),\($0.r)" })
///     DiagramaDeRejilla(terreno, relleno: { $0.color })   // un MapaHexagonal<Terreno>
///
/// Los hexágonos se encajan lo más grandes posible en el espacio que se le dé, con la proporción del
/// mapa. Un toque fuera del mapa (en el margen o entre casillas que faltan) no avisa.
public struct DiagramaDeRejilla: View {
    public let casillas: [CoordenadaAxial]
    public let orientacion: Orientacion
    /// La casilla que se resalta con el color de énfasis.
    public let seleccionada: CoordenadaAxial?
    private let relleno: (CoordenadaAxial) -> Color?
    private let rotulo: (CoordenadaAxial) -> String?
    private let alTocar: ((CoordenadaAxial) -> Void)?
    /// La de la app, para lo que lee VoiceOver.
    @Environment(\.notacion) private var notacion

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

    /// Las casillas de un mapa, con el relleno y el rótulo que da el valor de cada una.
    public init<Valor>(_ mapa: MapaHexagonal<Valor>, orientacion: Orientacion = .puntiaguda,
                       seleccionada: CoordenadaAxial? = nil,
                       relleno: @escaping (Valor) -> Color? = { _ in nil },
                       rotulo: @escaping (Valor) -> String? = { _ in nil },
                       alTocar: ((CoordenadaAxial) -> Void)? = nil) {
        self.init(Array(mapa.casillas), orientacion: orientacion, seleccionada: seleccionada,
                  relleno: { mapa[$0].flatMap(relleno) }, rotulo: { mapa[$0].flatMap(rotulo) }, alTocar: alTocar)
    }

    /// El margen alrededor del mapa, para que no se corte el trazo de los bordes.
    static let margen: Double = 3

    public var body: some View {
        GeometryReader { geometria in
            let trazado = PresentacionDeRejilla.trazado(
                para: casillas, orientacion: orientacion,
                ancho: Double(geometria.size.width), alto: Double(geometria.size.height), margen: Self.margen)
            Canvas { contexto, _ in
                if let trazado {
                    dibujar(en: &contexto, trazado: trazado)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { punto in
                guard let alTocar, let trazado,
                      let casilla = PresentacionDeRejilla.casilla(en: Punto(x: Double(punto.x), y: Double(punto.y)),
                                                                  trazado: trazado, mapa: Set(casillas))
                else { return }
                alTocar(casilla)
            }
        }
        .aspectRatio(PresentacionDeRejilla.proporcion(de: casillas, orientacion: orientacion).map { CGFloat($0) },
                     contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(Text(notacion.texto(.rejillaHexagonal)))
        .accessibilityValue(Text(PresentacionDeRejilla.descripcion(casillas: casillas.count, seleccionada: seleccionada,
                                                                  en: notacion)))
    }

    private func dibujar(en contexto: inout GraphicsContext, trazado: Trazado) {
        let grosor = max(0.5, trazado.tamano.x * 0.05)

        func hexagono(_ casilla: CoordenadaAxial) -> Path {
            var camino = Path()
            camino.addLines(trazado.vertices(de: casilla).map { CGPoint(x: $0.x, y: $0.y) })
            camino.closeSubpath()
            return camino
        }

        for casilla in casillas {
            let forma = hexagono(casilla)
            contexto.fill(forma, with: .color(relleno(casilla) ?? Color.gray.opacity(0.15)))
            contexto.stroke(forma, with: .color(.secondary), lineWidth: grosor)
            if let texto = rotulo(casilla) {
                let centro = trazado.centro(de: casilla)
                contexto.draw(Text(texto).font(.system(size: max(6, trazado.tamano.x * 0.45))),
                              at: CGPoint(x: centro.x, y: centro.y))
            }
        }

        // La elegida, encima de las demás para que su borde no quede tapado por el de las vecinas.
        if let seleccionada, casillas.contains(seleccionada) {
            contexto.stroke(hexagono(seleccionada), with: .color(TemaDeLasApps.acento), lineWidth: grosor * 3)
        }
    }
}
#endif
