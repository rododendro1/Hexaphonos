# Cambios

## Sin publicar

Rejillas hexagonales sin dependencias, solo con la biblioteca estándar y Foundation:

- Coordenadas axiales, cúbicas, desplazadas (cuatro variantes), dobladas (dos) y fraccionarias, y las conversiones
  entre ellas.
- Vecindad: `DireccionHexagonal` con su punto cardinal en cada orientación, vecinos, diagonales y distancias.
- Líneas y visibilidad (`linea(hasta:)`, `ve(_:tapada:)`, `visibles(en:tapada:)`), regiones (`alcance`, `anillo`,
  `espiral`, `FormasDeMapa`) y simetrías (rotaciones y reflexiones).
- Movimiento: `alcanzables`, `camino(hasta:por:)` y, con coste, `caminoMasBarato(hasta:)` (A*) y
  `alcanzables(presupuesto:)` (Dijkstra).
- `MapaHexagonal<Valor>`: un valor por casilla, con vecinas, simetrías, caminos y visibilidad, y `Codable`.
- Dibujo: `Disposicion` (puntiaguda o plana), `centro(de:)`, `casilla(en:)`, `vertices(de:)` y `svg(_:)`.

Se usa desde otro proyecto con `.package(url: "https://github.com/rododendro1/Hexaphonos.git", branch: "main")` y el
producto `Hexagonos`.
