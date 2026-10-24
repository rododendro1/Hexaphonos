# Cambios

## Sin publicar

- Desaparecen los nombres marcados como obsoletos: `Disposicion` (es `Trazado`), `distancia(a:)` (es
  `distancia(hasta:)`), `ve(_:tapada:)` (es `esVisible(_:tapada:)`), `DireccionHexagonal.girada(sextos:)` (es
  `rotada(sextos:)`) y `MapaHexagonal.girado(sextos:alrededorDe:)` (es `rotado(sextos:alrededorDe:)`).

Rejillas hexagonales sin dependencias, solo con la biblioteca estándar y Foundation:

- Coordenadas axiales, cúbicas, desplazadas (cuatro variantes), dobladas (dos) y fraccionarias, y las conversiones
  entre ellas.
- Vecindad: `DireccionHexagonal` con su punto cardinal en cada orientación, vecinos, diagonales y distancias.
- Líneas y visibilidad (`linea(hasta:)`, `esVisible(_:tapada:)`, `visibles(en:tapada:)`), regiones (`alcance`, `anillo`,
  `espiral`, `FormasDeMapa`) y simetrías (rotaciones y reflexiones).
- Movimiento: `alcanzables`, `camino(hasta:por:)` y, con coste, `caminoMasBarato(hasta:)` (A*) y
  `alcanzables(presupuesto:)` (Dijkstra).
- `MapaHexagonal<Valor>`: un valor por casilla, con vecinas, simetrías, caminos y visibilidad, y `Codable`.
- Dibujo: `Trazado` (puntiaguda o plana), `centro(de:)`, `casilla(en:)`, `vertices(de:)` y `svg(_:)`.
- Un ejemplo ejecutable, `Ejemplos/EjemploHexagonos` (`swift run EjemploHexagonos`), que recorre la API y dibuja
  los mapas en el terminal.

### Terminología

Los nombres anteriores se siguen aceptando, marcados como obsoletos.

- `Disposicion` pasa a `Trazado`: «disposición» es, en armonía, el orden de las voces de un acorde.
- `distancia(a:)` pasa a `distancia(hasta:)` en las cuatro coordenadas, como `linea(hasta:)` y `camino(hasta:por:)`.
- `DireccionHexagonal.girada(sextos:)` pasa a `rotada(sextos:)`, y `MapaHexagonal.girado(sextos:alrededorDe:)` a
  `rotado(sextos:alrededorDe:)`, como `CoordenadaAxial.rotada(sextos:alrededorDe:)`.
- `CoordenadaAxial.ve(_:tapada:)` pasa a `esVisible(_:tapada:)`.

Se usa desde otro proyecto con `.package(url: "https://github.com/rododendro1/Hexaphonos.git", branch: "main")` y el
producto `Hexagonos`.
