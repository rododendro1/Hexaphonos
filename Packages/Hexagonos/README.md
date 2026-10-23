# Hexagonos

Rejillas hexagonales en Swift, con la API en español. Solo usa la biblioteca estándar y Foundation:
compila y se prueba igual en Linux que en macOS, y no depende de ningún otro paquete del repositorio.

```swift
import Hexagonos

let a = CoordenadaAxial(q: 1, r: -2)
a.vecinos                                      // las seis vecinas
a.distancia(a: .origen)                        // 2
a.linea(hasta: CoordenadaAxial(q: 4, r: -2))   // las casillas de la recta
a.alcance(radio: 2)                            // las 19 casillas a dos pasos o menos
a.rotadaEnSentidoHorario()                     // girada 60° alrededor del origen

let disposicion = Disposicion(orientacion: .puntiaguda, tamano: 24)
disposicion.centro(de: a)                      // dónde se dibuja
disposicion.casilla(en: Punto(x: 40, y: 10))   // qué casilla se ha tocado
```

## Qué hay

| Tema         | Tipos y funciones                                                                    |
|--------------|--------------------------------------------------------------------------------------|
| Coordenadas  | `CoordenadaAxial`, `CoordenadaCubica`, `CoordenadaDesplazada` (cuatro variantes), `CoordenadaDoblada` (dos), `CoordenadaFraccionaria` y las conversiones entre ellas |
| Vecindad     | `DireccionHexagonal` (con su punto cardinal en cada orientación), `vecinos`, `vecinosDiagonales`, `direccion(hacia:)`, `distancia(a:)` |
| Líneas       | `linea(hasta:)`, `ve(_:tapada:)`, `visibles(en:tapada:)`                             |
| Regiones     | `alcance(radio:)`, `interseccion(de:)`, `anillo(radio:)`, `espiral(radio:)`, `FormasDeMapa` |
| Movimiento   | `alcanzables(movimientos:bloqueada:)`, `camino(hasta:por:)`                          |
| Simetrías    | `rotadaEnSentidoHorario`, `rotadaEnSentidoAntihorario`, `rotada(sextos:)`, `reflejada(sobre:)` |
| Dibujo       | `Disposicion` (orientación puntiaguda o plana), `centro(de:)`, `casilla(en:)`, `vertices(de:)`, `svg(_:)` |

La documentación de DocC (`Sources/Hexagonos/Hexagonos.docc`) explica cada sistema de coordenadas y
los algoritmos. Siguen la guía de Red Blob Games (https://www.redblobgames.com/grids/hexagons/).

```sh
cd Packages/Hexagonos && swift test
```
