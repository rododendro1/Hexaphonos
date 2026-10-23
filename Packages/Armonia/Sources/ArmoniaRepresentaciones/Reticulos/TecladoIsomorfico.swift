import ArmoniaNucleo
import Hexagonos
// Los teclados isomórficos: botones hexagonales en los que cada dirección sube siempre el mismo
// intervalo, así que un acorde o una escala tiene la misma forma en todas las tonalidades. La tabla
// armónica es uno de ellos; Wicki-Hayden (concertinas, apps como Musix) y Jankó, otros dos.

import Foundation

/// Un teclado isomórfico sobre una rejilla hexagonal: la casilla `(q, r)` suena
/// `midiDelOrigen + semitonosEnQ · q + semitonosEnR · r`.
///
///     let teclado = TecladoIsomorfico.wickiHayden
///     teclado.midi(en: .origen)                                    // 60
///     teclado.semitonos(hacia: .qMasRMenos)                        // 7
///     teclado.casillas(de: 67, en: FormasDeMapa.hexagono(radio: 3))  // [(q: 1, r: -1)]
///
/// `svg(_:)` lo dibuja con el nombre de cada nota y las teclas negras del piano en gris.
public struct TecladoIsomorfico: Hashable, Sendable {
    public let nombre: String
    /// Cómo se colocan los hexágonos: los intervalos de cada dirección dependen de ella al dibujar.
    public let orientacion: Orientacion
    /// Los semitonos que sube un paso de `q` (la dirección `qMasSMenos`).
    public let semitonosEnQ: Int
    /// Los semitonos que sube un paso de `r` (la dirección `rMasSMenos`).
    public let semitonosEnR: Int
    /// El número MIDI de la casilla `(0, 0)`.
    public let midiDelOrigen: Int

    public init(nombre: String, orientacion: Orientacion, semitonosEnQ: Int, semitonosEnR: Int,
                midiDelOrigen: Int = 60) {
        self.nombre = nombre
        self.orientacion = orientacion
        self.semitonosEnQ = semitonosEnQ
        self.semitonosEnR = semitonosEnR
        self.midiDelOrigen = midiDelOrigen
    }

    /// La tabla armónica (C-Thru AXiS), en las casillas de `TablaArmonica.coordenada(de:)`: hexágonos
    /// planos con la quinta justa hacia arriba, la tercera mayor arriba a la derecha y la tercera menor
    /// arriba a la izquierda.
    public static let tablaArmonica = TecladoIsomorfico(nombre: "Tabla armónica", orientacion: .plana,
                                                        semitonosEnQ: -3, semitonosEnR: -7)

    /// Wicki-Hayden: hexágonos puntiagudos con un tono hacia la derecha, una quinta justa arriba a la
    /// derecha y una cuarta justa arriba a la izquierda.
    public static let wickiHayden = TecladoIsomorfico(nombre: "Wicki-Hayden", orientacion: .puntiaguda,
                                                      semitonosEnQ: 2, semitonosEnR: -5)

    /// Jankó: hexágonos puntiagudos con un tono hacia la derecha y un semitono en las dos diagonales de
    /// la derecha; cada fila es una escala de tonos enteros.
    public static let janko = TecladoIsomorfico(nombre: "Jankó", orientacion: .puntiaguda,
                                                semitonosEnQ: 2, semitonosEnR: 1)

    /// El número MIDI de una casilla.
    public func midi(en casilla: CoordenadaAxial) -> Int {
        midiDelOrigen + semitonosEnQ * casilla.q + semitonosEnR * casilla.r
    }

    /// La altura de una casilla (en afinación igual, sin ortografía: con sostenidos o con bemoles).
    public func altura(en casilla: CoordenadaAxial, preferirBemoles: Bool = false) -> Altura {
        Altura(midi: midi(en: casilla), preferirBemoles: preferirBemoles)
    }

    /// Los semitonos que sube un paso en esa dirección (negativos si baja).
    public func semitonos(hacia direccion: DireccionHexagonal) -> Int {
        semitonosEnQ * direccion.paso.q + semitonosEnR * direccion.paso.r
    }

    /// Las casillas de `region` que suenan a ese número MIDI.
    public func casillas(de midi: Int, en region: some Sequence<CoordenadaAxial>) -> [CoordenadaAxial] {
        region.filter { self.midi(en: $0) == midi }
    }

    /// Las casillas de `region` que suenan a esa altura (las enarmónicas cuentan igual).
    public func casillas(de altura: Altura, en region: some Sequence<CoordenadaAxial>) -> [CoordenadaAxial] {
        casillas(de: altura.midi, en: region)
    }

    /// El teclado dibujado en SVG: un hexágono por casilla con el nombre de su nota y su octava, las teclas
    /// negras del piano en gris y, si se dan, las `marcadas` en el violeta de las notas del Tonnetz.
    public func svg(_ casillas: [CoordenadaAxial], marcadas: Set<Int> = [], tamano: Double = 24,
                    notacion: Nomenclatura = .espanol, preferirBemoles: Bool = false) -> String {
        let negras: Set<Int> = [1, 3, 6, 8, 10]
        return Disposicion(orientacion: orientacion, tamano: tamano).svg(casillas, relleno: { casilla in
            let midi = self.midi(en: casilla)
            if marcadas.contains(midi) { return DibujoSVG.Color.nota }
            return negras.contains(modulo(midi, 12)) ? "#bbbbbb" : "#f4f4f4"
        }, rotulo: { casilla in
            let altura = self.altura(en: casilla, preferirBemoles: preferirBemoles)
            return altura.nota.nombreCompacto(en: notacion) + "\(altura.octava)"
        })
    }
}

extension TecladoIsomorfico: CustomStringConvertible {
    public var description: String {
        "\(nombre): q \(semitonosEnQ >= 0 ? "+" : "")\(semitonosEnQ), r \(semitonosEnR >= 0 ? "+" : "")\(semitonosEnR)"
    }
}
