# De casillas a píxeles

Dónde se dibuja cada casilla y qué casilla hay bajo un punto.

## Overview

``Disposicion`` reúne lo que hace falta para dibujar: la ``Orientacion`` de los hexágonos
(``Orientacion/puntiaguda``, con un vértice arriba, o ``Orientacion/plana``, con una arista arriba),
su tamaño (el radio, del centro a un vértice) y dónde cae el centro de la casilla `(0, 0)`. El eje y
va hacia abajo, como en SwiftUI y en SVG.

```swift
let disposicion = Disposicion(orientacion: .plana, tamano: 20, origen: Punto(x: 200, y: 150))
disposicion.centro(de: CoordenadaAxial(q: 1, r: 0))   // (x: 230, y: 167.32…)
disposicion.vertices(de: .origen)                     // los seis vértices, para trazar el hexágono
disposicion.casilla(en: Punto(x: 231, y: 160))        // (q: 1, r: 0)
```

``Disposicion/casilla(en:)`` es la que se usa para saber qué casilla se ha tocado: convierte el punto
en coordenadas con decimales (``Disposicion/coordenada(en:)``) y las redondea.

### Dibujar en SVG

``Disposicion/svg(_:margen:relleno:rotulo:)`` dibuja un conjunto de casillas, ajustado a su tamaño,
con el color y el texto que se quiera en cada una:

```swift
let mapa = FormasDeMapa.hexagono(radio: 2)
let svg = Disposicion(orientacion: .puntiaguda, tamano: 20).svg(mapa, rotulo: { "\($0.q),\($0.r)" })
```

### Medidas

Un hexágono puntiagudo mide `√3·tamaño` de ancho y `2·tamaño` de alto; uno plano, al revés
(``Disposicion/anchura``, ``Disposicion/altura``). Con un tamaño distinto en cada eje
(`Disposicion(orientacion:tamano:origen:)` con un ``Punto``) los hexágonos se estiran, por ejemplo
para una vista isométrica.
