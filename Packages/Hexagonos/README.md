# Hexagonos

Rejillas hexagonales en Swift, con la API en español. Solo usa la biblioteca estándar y Foundation:
compila y se prueba igual en Linux que en macOS, y no depende de ningún otro paquete del repositorio.

```swift
import Hexagonos

let a = CoordenadaAxial(q: 1, r: -2)
a.vecinos                                      // las seis vecinas
a.distancia(hasta: .origen)                        // 2
a.linea(hasta: CoordenadaAxial(q: 4, r: -2))   // las casillas de la recta
a.alcance(radio: 2)                            // las 19 casillas a dos pasos o menos
a.rotadaEnSentidoHorario()                     // girada 60° alrededor del origen

let trazado = Trazado(orientacion: .puntiaguda, tamano: 24)
trazado.centro(de: a)                      // dónde se dibuja
trazado.casilla(en: Punto(x: 40, y: 10))   // qué casilla se ha tocado
```

## Qué hay

| Tema         | Tipos y funciones                                                                    |
|--------------|--------------------------------------------------------------------------------------|
| Coordenadas  | `CoordenadaAxial`, `CoordenadaCubica`, `CoordenadaDesplazada` (cuatro variantes), `CoordenadaDoblada` (dos), `CoordenadaFraccionaria` y las conversiones entre ellas |
| Vecindad     | `DireccionHexagonal` (con su punto cardinal en cada orientación), `vecinos`, `vecinosDiagonales`, `direccion(hacia:)`, `distancia(hasta:)` |
| Líneas       | `linea(hasta:)`, `esVisible(_:tapada:)`, `visibles(en:tapada:)`                             |
| Regiones     | `alcance(radio:)`, `interseccion(de:)`, `anillo(radio:)`, `espiral(radio:)`, `FormasDeMapa` |
| Movimiento   | `alcanzables(movimientos:bloqueada:)`, `camino(hasta:por:)`; con coste, `caminoMasBarato(hasta:)` (A*) y `alcanzables(presupuesto:)` (Dijkstra) |
| Mapas        | `MapaHexagonal<Valor>`: un valor por casilla, vecinas, simetrías, caminos y visibilidad sobre el mapa, Codable |
| Simetrías    | `rotadaEnSentidoHorario`, `rotadaEnSentidoAntihorario`, `rotada(sextos:)`, `reflejada(sobre:)` |
| Dibujo       | `Trazado` (orientación puntiaguda o plana), `centro(de:)`, `casilla(en:)`, `vertices(de:)`, `svg(_:)` |

La documentación de DocC (`Sources/Hexagonos/Hexagonos.docc`) explica cada sistema de coordenadas,
los algoritmos, los mapas y los caminos. Siguen la guía de Red Blob Games (https://www.redblobgames.com/grids/hexagons/).

```sh
cd Packages/Hexagonos && swift test
swift run --package-path Ejemplos/EjemploHexagonos EjemploHexagonos   # desde la raíz: un recorrido por la API
```

`Ejemplos/EjemploHexagonos` recorre la API (coordenadas, vecinos, líneas, regiones, simetrías, un mapa con su
camino más barato, JSON y píxeles) y dibuja los mapas con caracteres en el terminal.
