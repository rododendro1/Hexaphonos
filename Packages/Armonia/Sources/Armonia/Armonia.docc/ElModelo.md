# El modelo

Las coordenadas de quintas y octavas en que se apoya todo el motor.

## El modelo

| Tipo | Coordenadas | Ejemplo |
|---|---|---|
| `Nota` | `pasosDeQuinta` | Do = 0, Sol = 1, Fa = −1, Fa♯ = 6, Si♭ = −2 |
| `Altura` | `pasosDeQuinta`, `pasosDeOctava` (origen Do4) | La4 = (3, −1), Re4 = (2, −1) |
| `Intervalo` | `pasosDeQuinta`, `pasosDeOctava`, `direccion` | 3ª mayor = (4, −2), 5ª justa = (1, 0) |
| `Acorde` | fundamental + `TipoDeAcorde` + bajo | Sol7/Si, Do/Re |
| `Escala` | tónica + `TipoDeEscala` | Re dórico |

Las coordenadas dicen cuántas quintas y cuántas octavas justas hay que dar para llegar: la 3ª
mayor son cuatro quintas arriba y dos octavas abajo (`Intervalo(pasosDeQuinta: 4, pasosDeOctava: -2)`).
`pasosDeOctava` no es la octava en que suena una altura; esa es `Altura.octava`.
`TipoDeAcorde.pasosDeQuinta` es el conjunto de los pasos de quinta de sus notas desde la
fundamental, y `EstructuraDeAcorde.quintasDelAcorde`, las quintas del acorde (5ª justa, ♭5, ♯5).

Los nombres siguen la terminología de la teoría: la **nota** no tiene octava (Do, Fa♯), la
**altura** sí (Do4, Fa♯3) y la **nota natural** es la que no lleva alteración (do, re, mi…).
`Altura.nota` da la nota de una altura, y `Nota.natural`, su nota natural.

Fórmulas centrales (vector *q* quintas, *o* octavas):

- pasos diatónicos = 4q + 7o → número del intervalo
- semitonos = 7q + 12o → MIDI = 60 + 7q + 12o
- calidad: depende sólo de *q* (las octavas no la cambian)
- nota natural = posición (q + 1) mód 7 en Fa‑Do‑Sol‑Re‑La‑Mi‑Si; alteración = ⌊(q + 1) / 7⌋
- transponer = sumar vectores; inversión = (0, 1) − intervalo simple

`Intervalo` guarda siempre la magnitud en forma canónica ascendente y la dirección aparte, así
que dos intervalos iguales musicalmente son iguales con `==`.

## Uso

```swift
import Armonia

let i = Altura("Re5") - Altura("Do4")       // 9ª mayor, (2, 0)
Nota.si.intervalo(hasta: .fa)        // 5ª disminuida
Intervalo.terceraMayor.inversion           // 6ª menor
Altura("La4").frecuencia()                  // 440.0
Altura(midi: 63, preferirBemoles: true)      // Mi♭4

Acorde("Sol7/Si").posicionCerrada(octava: 3)   // [Si3, Re4, Fa4, Sol4]
Acorde.identificar([.mi, .sol, .do]).first         // Do/Mi

let menor = Escala("La menor armónica")
menor.cifradosRomanos(cuatriadas: true)
// ["i(maj7)", "iiø7", "♭III+maj7", "iv7", "V7", "♭VImaj7", "vii°7"]
Escala("Mib mayor").armadura              // -3
Escala(.do).rotacion(2)                    // Re dórico
```
