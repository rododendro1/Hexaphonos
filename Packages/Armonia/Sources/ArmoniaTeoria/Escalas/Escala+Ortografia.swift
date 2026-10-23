import ArmoniaNucleo
import Foundation

// MARK: - Ortografía según la tonalidad

extension Escala {
    /// Posición media de la escala en la línea de quintas (su "centro de gravedad").
    package var centroDeQuintas: Double {
        let posiciones = notas.map { Double($0.pasosDeQuinta) }
        return posiciones.reduce(0, +) / Double(posiciones.count)
    }

    /// Nombre de una clase de altura (0 = Do … 11 = Si) dentro de esta tonalidad.
    ///
    /// - Si la altura pertenece a la escala, al subir o al bajar, se usa su nombre (Si♭ en Fa
    ///   mayor, Sol♯ en La menor armónica, Mi♯ en Fa♯ mayor; Sol y Sol♯ en La menor melódica).
    /// - Si es cromática, se elige entre las dos escrituras más cercanas a la escala en la
    ///   línea de quintas. Si se conoce la nota siguiente, sube con sostenido y baja con bemol
    ///   (Do–Do♯–Re, Re–Re♭–Do); si no, gana la más cercana (en Do mayor: Do♯, Mi♭, Fa♯, La♭, Si♭).
    ///
    /// `siguiente` es la clase de altura o el número MIDI de la nota siguiente; para comparar
    /// direcciones se usa `alturaActual`, que debe estar en la misma unidad.
    public func nombre(claseDeAltura clase: Int, alturaActual: Int? = nil,
                       siguiente: Int? = nil) -> Nota {
        let q0 = modulo(modulo(clase, 12) * 7, 12)
        let escrituras = [q0 - 12, q0, q0 + 12]
        let propias = Set(notasEnAmbasDirecciones.map(\.pasosDeQuinta))
        if let propia = escrituras.first(where: { propias.contains($0) }) {
            return Nota(pasosDeQuinta: propia)
        }
        let centro = centroDeQuintas
        let cercanas = escrituras.sorted { abs(Double($0) - centro) < abs(Double($1) - centro) }.prefix(2)
        let masSostenida = cercanas.max() ?? q0
        let masBemol = cercanas.min() ?? q0
        let actual = alturaActual ?? clase
        func coste(_ q: Int) -> [Double] {
            var distancia = abs(Double(q) - centro)
            if let siguiente, siguiente != actual {
                if siguiente > actual && q == masSostenida { distancia -= 5 }
                if siguiente < actual && q == masBemol { distancia -= 5 }
            }
            // En caso de empate, la escritura más cercana a la dominante de la tónica
            // (La♭ en Do mayor, pero Sol♯ en La menor), y después la más sostenida.
            return [distancia, Double(abs(q - (tonica.pasosDeQuinta + 1))), Double(-q)]
        }
        let elegida = cercanas.min { coste($0).lexicographicallyPrecedes(coste($1)) } ?? q0
        return Nota(pasosDeQuinta: elegida)
    }

    /// Escribe una secuencia de notas MIDI en esta tonalidad. Las notas cromáticas se
    /// escriben según la dirección de la melodía (sostenido al subir, bemol al bajar).
    ///
    ///     Escala(.do).ortografiar(midi: [60, 61, 62, 63, 64])   // Do4 Do♯4 Re4 Re♯4 Mi4
    ///     Escala(.do).ortografiar(midi: [64, 63, 62, 61, 60])   // Mi4 Mi♭4 Re4 Re♭4 Do4
    public func ortografiar(midi: [Int]) -> [Altura] {
        midi.indices.map { i in
            let altura = midi[i]
            let siguiente = midi[(i + 1)...].first { $0 != altura }
            let nombre = self.nombre(claseDeAltura: altura, alturaActual: altura, siguiente: siguiente)
            return Altura(nombre, midi: altura) ?? Altura(midi: altura)
        }
    }
}

extension Altura {
    /// Altura MIDI escrita según una escala: `Altura(midi: 70, escala: Escala(.fa))` → Si♭4.
    public init(midi: Int, escala: Escala) {
        let nombre = escala.nombre(claseDeAltura: midi)
        self = Altura(nombre, midi: midi) ?? Altura(midi: midi)
    }

    /// Altura MIDI escrita según una tonalidad (en menor, con la sensible):
    /// `Altura(midi: 68, tonalidad: "La menor")` → Sol♯4.
    public init(midi: Int, tonalidad: Tonalidad) {
        self.init(midi: midi, escala: tonalidad.escalaDeReferencia)
    }
}
