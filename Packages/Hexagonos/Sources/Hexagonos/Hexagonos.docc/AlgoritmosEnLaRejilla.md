# Algoritmos en la rejilla

Vecinos, distancias, líneas, regiones, movimiento con obstáculos, rotaciones y reflexiones.

## Overview

Todos se escriben sobre ``CoordenadaAxial``.

### Vecinos y distancias

``CoordenadaAxial/vecinos`` son las seis casillas que comparten una arista, en el orden de
``CoordenadaAxial/direcciones``; ``CoordenadaAxial/vecinosDiagonales``, las seis que están a dos pasos
cruzando una arista. ``CoordenadaAxial/distancia(a:)`` cuenta los pasos entre dos casillas.

```swift
let a = CoordenadaAxial(q: 0, r: 0)
a.vecino(0)                                 // (q: 1, r: 0)
a.distancia(a: CoordenadaAxial(q: 3, r: -7))   // 7
```

### Líneas y visibilidad

``CoordenadaAxial/linea(hasta:)`` da las casillas de la recta entre dos, cada una vecina de la
anterior. ``CoordenadaAxial/ve(_:tapada:)`` dice si la línea entre dos casillas está libre, y
``CoordenadaAxial/visibles(en:tapada:)``, qué casillas de una región se ven desde una.

### Regiones

- ``CoordenadaAxial/alcance(radio:)``: todas las casillas a `radio` pasos o menos.
- ``CoordenadaAxial/interseccion(de:)``: las que están en varios alcances a la vez.
- ``CoordenadaAxial/anillo(radio:)``: las que están a exactamente `radio` pasos.
- ``CoordenadaAxial/espiral(radio:)``: el alcance, del centro hacia fuera, anillo a anillo.
- ``FormasDeMapa``: hexágonos, paralelogramos, triángulos y rectángulos.

```swift
CoordenadaAxial.origen.alcance(radio: 2).count   // 19
CoordenadaAxial.origen.anillo(radio: 2).count    // 12
```

### Movimiento con obstáculos

``CoordenadaAxial/alcanzables(movimientos:bloqueada:)`` busca en anchura las casillas a las que se
llega en unos pasos sin pisar las bloqueadas, y cuántos pasos cuesta cada una.
``CoordenadaAxial/camino(hasta:por:)`` da el camino más corto por un conjunto de casillas transitables.

```swift
let muro: Set = [CoordenadaAxial(q: 1, r: 0)]
CoordenadaAxial.origen.alcanzables(movimientos: 2) { muro.contains($0) }
```

### Rotaciones y reflexiones

Girar 60° es permutar las coordenadas cúbicas y cambiarles el signo:
``CoordenadaAxial/rotadaEnSentidoHorario(alrededorDe:)``,
``CoordenadaAxial/rotadaEnSentidoAntihorario(alrededorDe:)`` y, para varios sextos de vuelta,
``CoordenadaAxial/rotada(sextos:alrededorDe:)``. ``CoordenadaAxial/reflejada(sobre:alrededorDe:)``
refleja sobre uno de los tres ejes (``Eje``). Todas aceptan un centro distinto del origen.
