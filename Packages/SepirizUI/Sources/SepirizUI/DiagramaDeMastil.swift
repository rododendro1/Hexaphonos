#if canImport(SwiftUI)
import SwiftUI
import Armonia

/// Un mástil dibujado en horizontal, con las cuerdas graves abajo, y unas posiciones marcadas.
///
///     DiagramaDeMastil(mastil: Mastil(.guitarra), escala: Escala(.la, .pentatonicaMenor))
///     DiagramaDeMastil(digitacion: digitacion, acorde: acorde)
///
/// Las notas se escriben con la ortografía de la escala o del acorde (Si♭ en Fa mayor, no La♯).
/// Si el rango no empieza en el 0, las cuerdas al aire se dibujan con un círculo vacío en un canal a la
/// izquierda, y las apagadas con una ×.
public struct DiagramaDeMastil: View {
    public let mastil: Mastil
    public let marcas: [Posicion]
    /// Los trastes que se dibujan (el 0 es la cuerda al aire).
    public let rango: ClosedRange<Int>
    /// Escribe el nombre de la nota dentro de cada marca.
    public let etiquetas: Bool
    /// Las cuerdas (desde 0) que no suenan: se marcan con una ×.
    public let apagadas: Set<Int>
    /// Cómo se escribe cada clase de altura (0…11). Las que no estén se escriben como `Altura(midi:)`.
    public let ortografia: [Int: Nota]
    public let notacion: Nomenclatura

    public init(mastil: Mastil, marcas: [Posicion] = [], rango: ClosedRange<Int> = 0...12, etiquetas: Bool = true,
                apagadas: Set<Int> = [], ortografia: [Int: Nota] = [:], notacion: Nomenclatura = .espanol) {
        self.mastil = mastil
        self.marcas = marcas
        self.rango = rango
        self.etiquetas = etiquetas
        self.apagadas = apagadas
        self.ortografia = ortografia
        self.notacion = notacion
    }

    /// Las notas de una escala en el mástil, escritas como las escribe la escala.
    public init(mastil: Mastil, escala: Escala, rango: ClosedRange<Int> = 0...12, etiquetas: Bool = true,
                notacion: Nomenclatura = .espanol) {
        self.init(mastil: mastil, marcas: mastil.posiciones(de: escala, trastes: rango), rango: rango,
                  etiquetas: etiquetas, ortografia: PresentacionDeMastil.ortografia(de: escala.notas),
                  notacion: notacion)
    }

    /// Muestra una digitación, con un rango de trastes que la deja a la vista. Si se da el acorde, las
    /// notas se escriben con su ortografía.
    public init(digitacion: Digitacion, acorde: Acorde? = nil, etiquetas: Bool = true,
                notacion: Nomenclatura = .espanol) {
        self.init(mastil: digitacion.mastil, marcas: digitacion.posiciones,
                  rango: PresentacionDeMastil.rango(de: digitacion), etiquetas: etiquetas,
                  apagadas: PresentacionDeMastil.apagadas(de: digitacion),
                  ortografia: PresentacionDeMastil.ortografia(de: acorde?.notas ?? []), notacion: notacion)
    }

    /// Los trastes con puntos de referencia en un mástil de guitarra.
    static let trastesConPunto: Set<Int> = [3, 5, 7, 9, 12, 15, 17, 19, 21, 24]

    /// Las cuerdas al aire que se marcan.
    private var alAire: Set<Int> {
        Set(marcas.filter { $0.traste == 0 && mastil.contiene($0) }.map(\.cuerda))
    }

    /// ¿Hay un canal a la izquierda para las cuerdas al aire y las apagadas? Solo cuando el 0 no se dibuja.
    private var hayCanal: Bool {
        !rango.contains(0) && (!alAire.isEmpty || !apagadas.isEmpty)
    }

    public var body: some View {
        Canvas { contexto, tamano in
            dibujar(en: &contexto, tamano: tamano)
        }
        .aspectRatio(Double(rango.count + (hayCanal ? 1 : 0)) / Double(max(mastil.encordado.numeroDeCuerdas + 1, 3)) * 0.8,
                     contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(Text("Mástil de \(mastil.encordado.nombre), trastes \(rango.lowerBound) a \(rango.upperBound)"))
        .accessibilityValue(Text(PresentacionDeMastil.descripcion(marcas: marcas, apagadas: apagadas)))
    }

    private func dibujar(en contexto: inout GraphicsContext, tamano: CGSize) {
        let cuerdas = mastil.encordado.numeroDeCuerdas
        guard cuerdas > 0 else { return }
        let alAire = self.alAire
        let canal = hayCanal
        let margenX: CGFloat = 8
        let margenSuperior: CGFloat = 8
        let margenInferior: CGFloat = 22   // para los números de traste
        let columnas = rango.count + (canal ? 1 : 0)
        let anchoCasilla = (tamano.width - 2 * margenX) / CGFloat(columnas)
        let inicioX = margenX + (canal ? anchoCasilla : 0)
        let separacion = cuerdas > 1
            ? (tamano.height - margenSuperior - margenInferior) / CGFloat(cuerdas - 1)
            : 0
        let yMinimo = margenSuperior
        let yMaximo = tamano.height - margenInferior

        func x(centroDe traste: Int) -> CGFloat {
            inicioX + (CGFloat(traste - rango.lowerBound) + 0.5) * anchoCasilla
        }
        func y(de cuerda: Int) -> CGFloat {
            // La cuerda 0 (la grave) abajo.
            yMaximo - CGFloat(cuerda) * separacion
        }
        let xDelCanal = margenX + anchoCasilla / 2
        let radio = min(anchoCasilla, max(separacion, 12)) * 0.38

        // Madera.
        let tabla = CGRect(x: inicioX, y: yMinimo - 4, width: tamano.width - margenX - inicioX,
                           height: yMaximo - yMinimo + 8)
        contexto.fill(Path(roundedRect: tabla, cornerRadius: 4), with: .color(TemaSepiriz.madera.opacity(0.45)))

        // Trastes y cejilla.
        for traste in rango {
            let xBorde = inicioX + CGFloat(traste - rango.lowerBound + 1) * anchoCasilla
            var linea = Path()
            linea.move(to: CGPoint(x: xBorde, y: yMinimo - 4))
            linea.addLine(to: CGPoint(x: xBorde, y: yMaximo + 4))
            let esCejilla = traste == 0
            contexto.stroke(linea, with: .color(esCejilla ? TemaSepiriz.maderaOscura : .gray),
                            lineWidth: esCejilla ? 4 : 1)
            // Números de traste y puntos de referencia.
            if traste > 0 {
                contexto.draw(Text("\(traste)").font(.caption2).foregroundColor(.secondary),
                              at: CGPoint(x: x(centroDe: traste), y: tamano.height - 8))
                if DiagramaDeMastil.trastesConPunto.contains(traste) {
                    let centro = CGPoint(x: x(centroDe: traste), y: (yMinimo + yMaximo) / 2)
                    let punto = CGRect(x: centro.x - 3, y: centro.y - 3, width: 6, height: 6)
                    contexto.fill(Path(ellipseIn: punto), with: .color(.gray.opacity(0.5)))
                }
            }
        }

        // Cuerdas.
        for cuerda in 0..<cuerdas {
            var linea = Path()
            linea.move(to: CGPoint(x: inicioX, y: y(de: cuerda)))
            linea.addLine(to: CGPoint(x: tamano.width - margenX, y: y(de: cuerda)))
            contexto.stroke(linea, with: .color(.gray), lineWidth: 1 + CGFloat(cuerdas - 1 - cuerda) * 0.12)
        }

        // Cuerdas apagadas (×) y, si no se dibuja el traste 0, cuerdas al aire (círculo vacío).
        for cuerda in 0..<cuerdas {
            let xIndicador = canal ? xDelCanal : x(centroDe: rango.lowerBound)
            if apagadas.contains(cuerda) {
                contexto.draw(Text("×").font(.system(size: max(10, radio * 1.4), weight: .bold)).foregroundColor(.secondary),
                              at: CGPoint(x: xIndicador, y: y(de: cuerda)))
            } else if canal && alAire.contains(cuerda) {
                let r = radio * 0.7
                let circulo = CGRect(x: xDelCanal - r, y: y(de: cuerda) - r, width: 2 * r, height: 2 * r)
                contexto.stroke(Path(ellipseIn: circulo), with: .color(TemaSepiriz.acento), lineWidth: 1.5)
            }
        }

        // Marcas.
        for posicion in marcas where mastil.contiene(posicion) && rango.contains(posicion.traste) {
            let centro = CGPoint(x: x(centroDe: posicion.traste), y: y(de: posicion.cuerda))
            let circulo = CGRect(x: centro.x - radio, y: centro.y - radio, width: 2 * radio, height: 2 * radio)
            contexto.fill(Path(ellipseIn: circulo), with: .color(TemaSepiriz.acento))
            if etiquetas {
                let altura = mastil.altura(en: posicion)
                let nota = ortografia[altura.nota.claseDeAltura] ?? altura.nota
                contexto.draw(Text(nota.nombre(en: notacion)).font(.system(size: max(8, radio * 0.9), weight: .bold)).foregroundColor(.white),
                              at: centro)
            }
        }
    }
}

@available(*, deprecated, renamed: "DiagramaDeMastil")
public typealias MastilView = DiagramaDeMastil
#endif
