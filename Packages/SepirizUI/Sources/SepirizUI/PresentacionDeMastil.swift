import Armonia

/// La parte de `MastilView` que no es dibujo: qué trastes se enseñan, qué cuerdas se apagan, cómo se
/// escriben las notas y cómo se describe el mástil a VoiceOver. No usa SwiftUI, así que se prueba
/// también en Linux.
enum PresentacionDeMastil {
    /// Cuántos trastes se enseñan como mínimo cuando la mano está lejos de la cejilla.
    static let trastesMinimosEnVentana = 4

    /// Los trastes que se dibujan para una digitación.
    ///
    /// Con la mano cerca de la cejilla (hasta el traste 4) se ve desde la cejilla hasta el 5. Más arriba,
    /// una ventana con un traste de margen por cada lado. En una ventana que no incluye el 0 las cuerdas
    /// al aire se dibujan en un canal a la izquierda, no se pierden.
    static func rango(de digitacion: Digitacion) -> ClosedRange<Int> {
        let pisados = digitacion.trastesPisados
        guard let menor = pisados.min(), let mayor = pisados.max(), mayor > 4 else { return 0...5 }
        let desde = max(0, menor - 1)
        let hasta = max(mayor + 1, desde + trastesMinimosEnVentana - 1)
        return desde...hasta
    }

    /// Las cuerdas (índices desde 0) que no suenan en la digitación.
    static func apagadas(de digitacion: Digitacion) -> Set<Int> {
        Set(digitacion.trastes.indices.filter { digitacion.trastes[$0] == nil })
    }

    /// La nota con que se escribe cada clase de altura (0…11): la ortografía del acorde o de la escala,
    /// y no la de `Altura(midi:)`, que usa siempre sostenidos (Si♭ saldría como La♯). Si dos notas
    /// comparten clase, gana la primera.
    static func ortografia(de notas: [Nota]) -> [Int: Nota] {
        Dictionary(notas.map { ($0.claseDeAltura, $0) }, uniquingKeysWith: { primera, _ in primera })
    }

    /// Una descripción corta para VoiceOver.
    static func descripcion(marcas: [Posicion], apagadas: Set<Int>) -> String {
        var partes: [String] = []
        if marcas.count > 12 {
            partes.append("\(marcas.count) marcas")
        } else {
            partes += marcas.sorted { ($0.cuerda, $0.traste) < ($1.cuerda, $1.traste) }.map(\.description)
        }
        if !apagadas.isEmpty {
            partes.append("cuerdas apagadas: " + apagadas.sorted().map { String($0 + 1) }.joined(separator: ", "))
        }
        return partes.isEmpty ? "Sin marcas" : partes.joined(separator: "; ")
    }
}
