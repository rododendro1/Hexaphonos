# ``Hexagonos``

Rejillas hexagonales en Swift, con la API en español: coordenadas, vecinos, distancias, líneas,
regiones, simetrías y el paso a píxeles.

## Overview

Una rejilla hexagonal se puede numerar de varias maneras, y cada una sirve para algo: las
**axiales** y las **cúbicas** para calcular, las **desplazadas** y las **dobladas** para guardar un
mapa rectangular. El paquete trabaja en axiales (``CoordenadaAxial``) y convierte a las demás.

```swift
import Hexagonos

let a = CoordenadaAxial(q: 1, r: -2)
a.vecinos                                   // las seis vecinas
a.distancia(a: .origen)                     // 2
a.linea(hasta: CoordenadaAxial(q: 4, r: -2))   // las casillas de la recta
a.desplazada(.filasImpares)                 // (columna: 0, fila: -2)

let disposicion = Disposicion(orientacion: .puntiaguda, tamano: 24)
disposicion.centro(de: a)                   // dónde se dibuja
disposicion.casilla(en: Punto(x: 40, y: 10))   // qué casilla se ha tocado
```

Los algoritmos y las convenciones siguen la guía de Red Blob Games sobre rejillas hexagonales
(<https://www.redblobgames.com/grids/hexagons/>), con los nombres en español.

## Topics

### Artículos

- <doc:SistemasDeCoordenadas>
- <doc:AlgoritmosEnLaRejilla>
- <doc:DeCasillasAPixeles>

### Coordenadas

- ``CoordenadaAxial``
- ``CoordenadaCubica``
- ``CoordenadaFraccionaria``
- ``CoordenadaDesplazada``
- ``Desplazamiento``
- ``CoordenadaDoblada``
- ``Doblado``

### Direcciones

- ``DireccionHexagonal``
- ``PuntoCardinal``

### Regiones y simetrías

- ``FormasDeMapa``
- ``Eje``

### Dibujo

- ``Disposicion``
- ``Orientacion``
- ``Punto``
