# Teoría postonal

Conjuntos de clases de altura, formas primas y números de Forte.

## Conjuntos de clases de altura

```swift
let c: ConjuntoDeClases = [0, 4, 7]
c.formaPrima            // [0, 3, 7]
c.numeroDeForte         // "3-11"
c.vectorIntervalico     // [0, 0, 1, 1, 1, 0]
c.nombreComun           // "tríada mayor o menor"
ConjuntoDeClases([0, 1, 4, 6]).estaEnRelacionZ(con: [0, 1, 3, 7])   // true (4-Z15 y 4-Z29)
Escala(.re).conjuntoDeClases.numeroDeForte                          // "7-35"
```

Incluye forma normal, forma prima de Forte y de Rahn (difieren en seis clases), complemento,
Tn/TnI, simetrías y la tabla completa de Forte (223 clases, 46 en relación Z), generada a
partir de las tablas de music21 y comprobada sobre los 4096 subconjuntos posibles.
