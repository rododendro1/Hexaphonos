// Utilidades aritméticas internas.
//
// El sistema de coordenadas del motor usa enteros que pueden ser negativos
// (Fa = −1 quinta, Si♭ = −2 quintas…), así que necesitamos división y módulo
// que redondeen hacia −∞ en lugar de truncar hacia cero como hace `/` y `%`.

/// División entera redondeando hacia −∞.  `divisionEntera(-1, 7) == -1`.
package func divisionEntera(_ a: Int, _ b: Int) -> Int {
    let q = a / b
    return (a % b != 0 && ((a < 0) != (b < 0))) ? q - 1 : q
}

/// Módulo siempre no negativo para divisor positivo.  `modulo(-1, 7) == 6`.
package func modulo(_ a: Int, _ b: Int) -> Int {
    let r = a % b
    return r < 0 ? r + b : r
}

/// Máximo común divisor de dos enteros no negativos (`maximoComunDivisor(0, n) == n`).
package func maximoComunDivisor(_ a: Int, _ b: Int) -> Int {
    var (x, y) = (abs(a), abs(b))
    while y != 0 { (x, y) = (y, x % y) }
    return x
}

/// Búsqueda en anchura del camino más corto: desde `inicio`, por los pasos que da `vecinos` (en
/// su orden, que decide entre caminos igual de cortos), hasta el primer estado que `llega`. Los
/// estados con la misma `clave` cuentan como uno. Devuelve los pasos (vacío si `inicio` ya
/// llega) o `nil` si no hay camino. La usan los caminos por P, L y R y por voces que se mueven.
package func caminoMasCorto<Estado, Clave: Hashable, Paso>(desde inicio: Estado, clave: (Estado) -> Clave,
                                                  vecinos: (Estado) -> [(Paso, Estado)],
                                                  llega: (Estado) -> Bool) -> [Paso]? {
    if llega(inicio) { return [] }
    var previo: [Clave: (Clave, Paso)] = [:]
    var vistos: Set<Clave> = [clave(inicio)]
    var frontera = [inicio]
    while !frontera.isEmpty {
        var siguiente: [Estado] = []
        for estado in frontera {
            let desde = clave(estado)
            for (paso, vecino) in vecinos(estado) {
                let k = clave(vecino)
                guard vistos.insert(k).inserted else { continue }
                previo[k] = (desde, paso)
                if llega(vecino) {
                    var camino: [Paso] = []
                    var actual = k
                    while let (anterior, paso) = previo[actual] { camino.insert(paso, at: 0); actual = anterior }
                    return camino
                }
                siguiente.append(vecino)
            }
        }
        frontera = siguiente
    }
    return nil
}
