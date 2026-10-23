// MARK: - Formas de mapa

/// Las casillas de los mapas de formas habituales, para guardarlos en un `Set` o como claves de un
/// diccionario (`[CoordenadaAxial: Terreno]`).
public enum FormasDeMapa {
    /// Un hexágono de `radio` casillas alrededor de `centro` (el alcance de ese radio).
    public static func hexagono(radio: Int, centro: CoordenadaAxial = .origen) -> [CoordenadaAxial] {
        centro.alcance(radio: radio)
    }

    /// Un paralelogramo: todas las casillas con `q` en `columnas` y `r` en `filas`.
    public static func paralelogramo(columnas: ClosedRange<Int>, filas: ClosedRange<Int>) -> [CoordenadaAxial] {
        columnas.flatMap { q in filas.map { r in CoordenadaAxial(q: q, r: r) } }
    }

    /// Un triángulo de `lado` casillas por lado, con un vértice en el origen: las casillas con
    /// `q ≥ 0`, `r ≥ 0` y `q + r < lado`. Con `invertido`, `q ≤ 0`, `r ≤ 0` y `q + r > −lado`
    /// (el que apunta al otro lado).
    public static func triangulo(lado: Int, invertido: Bool = false) -> [CoordenadaAxial] {
        precondition(lado >= 0, "El lado no puede ser negativo (\(lado))")
        var casillas: [CoordenadaAxial] = []
        for q in 0..<lado {
            for r in 0..<(lado - q) {
                casillas.append(invertido ? CoordenadaAxial(q: -q, r: -r) : CoordenadaAxial(q: q, r: r))
            }
        }
        return casillas
    }

    /// Un rectángulo de `columnas × filas` casillas, de `(0, 0)` a `(columnas − 1, filas − 1)` en
    /// coordenadas desplazadas, por filas.
    public static func rectangulo(columnas: Int, filas: Int,
                                  _ desplazamiento: Desplazamiento) -> [CoordenadaAxial] {
        precondition(columnas >= 0 && filas >= 0, "Las medidas no pueden ser negativas")
        var casillas: [CoordenadaAxial] = []
        casillas.reserveCapacity(columnas * filas)
        for fila in 0..<filas {
            for columna in 0..<columnas {
                casillas.append(CoordenadaAxial(CoordenadaDesplazada(columna: columna, fila: fila), desplazamiento))
            }
        }
        return casillas
    }
}
