# Mapas y caminos

Un valor en cada casilla, y los caminos más baratos cuando cada paso cuesta algo distinto.

## Overview

### Mapas

``MapaHexagonal`` guarda un valor por casilla: un terreno, una altura, una nota. Por dentro es un
diccionario, así que el mapa puede tener cualquier forma, con huecos, y crecer por cualquier lado.
Una casilla que no está en el mapa no tiene valor.

```swift
var mapa = MapaHexagonal(repitiendo: "hierba", en: FormasDeMapa.hexagono(radio: 2))
mapa[CoordenadaAxial(q: 1, r: 0)] = "agua"
mapa.count                                  // 19
mapa[CoordenadaAxial(q: 5, r: 0)]           // nil
mapa.vecinas(de: .origen).count             // 6
```

Se recorre como una colección de pares `(casilla, valor)`, se transforma
(``MapaHexagonal/transformado(_:)``, ``MapaHexagonal/filtrado(_:)``), se mueve, se gira y se refleja
(``MapaHexagonal/desplazado(por:)``, ``MapaHexagonal/rotado(sextos:alrededorDe:)``,
``MapaHexagonal/reflejado(sobre:alrededorDe:)``) y se guarda en JSON si sus valores se pueden guardar.

### Caminos con coste

``CoordenadaAxial/camino(hasta:por:)`` cuenta pasos; cuando unos pasos cuestan más que otros (un
pantano, una subida), ``CoordenadaAxial/caminoMasBarato(hasta:costeMinimo:presupuesto:coste:)`` busca
el más barato con el algoritmo A*. El coste de cada paso lo da una función, que devuelve `nil` donde
no se puede pasar:

```swift
let pantano: Set = [CoordenadaAxial(q: 1, r: 0)]
let camino = CoordenadaAxial.origen.caminoMasBarato(hasta: CoordenadaAxial(q: 2, r: 0)) { _, hacia in
    hacia.longitud > 4 ? nil : (pantano.contains(hacia) ? 5 : 1)
}
camino?.coste                               // 3.0
camino?.pasos                               // 3
```

`costeMinimo` es lo menos que cuesta un paso: con 0 la búsqueda es la de Dijkstra, y cuanto más se
acerca al coste real, menos casillas mira. ``CoordenadaAxial/alcanzables(presupuesto:coste:)`` da todas
las casillas a las que se llega con un presupuesto, y lo que cuesta cada una.

Sobre un mapa, el coste depende del valor de la casilla en la que se entra, y fuera del mapa no se pasa:

```swift
var terreno = MapaHexagonal(repitiendo: 1.0, en: FormasDeMapa.hexagono(radio: 3))
terreno[CoordenadaAxial(q: 1, r: 0)] = 10
terreno.caminoMasBarato(desde: .origen, hasta: CoordenadaAxial(q: 2, r: 0)) { $0 }?.coste   // 3.0
terreno.alcanzables(desde: .origen, presupuesto: 2) { $0 }.count                          // 17
```
