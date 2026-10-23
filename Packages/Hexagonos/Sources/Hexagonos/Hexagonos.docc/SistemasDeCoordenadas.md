# Sistemas de coordenadas

Las cuatro maneras de numerar las casillas, y cómo se pasa de una a otra.

## Overview

### Cúbicas

Una rejilla hexagonal es el corte de una pila de cubos por el plano `x + y + z = 0`. Cada casilla
tiene tres coordenadas, `q`, `r` y `s`, que siempre suman cero (``CoordenadaCubica``). Los tres ejes
son iguales, así que las rotaciones y las reflexiones son permutaciones con cambio de signo, y la
distancia es la mayor de las tres diferencias.

### Axiales

Como `s = −q − r`, basta con guardar dos: ``CoordenadaAxial`` es `(q, r)`, y `s` se calcula. Es la
coordenada de trabajo del paquete. Se suman, se restan y se multiplican por un entero como vectores:
la vecina en la dirección `i` es `casilla + CoordenadaAxial.direcciones[i]`.

```swift
let a = CoordenadaAxial(q: 2, r: -1)
a.cubica                 // (q: 2, r: -1, s: -1)
CoordenadaAxial(CoordenadaCubica(q: 2, r: -1, s: -1)) == a   // true
```

### Desplazadas

Las coordenadas desplazadas (``CoordenadaDesplazada``) son `(columna, fila)` de una tabla en la que
filas o columnas alternas se empujan media casilla. Hay cuatro variantes (``Desplazamiento``):

| Desplazamiento                       | Orientación | Qué se empuja                         |
|--------------------------------------|-------------|---------------------------------------|
| ``Desplazamiento/filasImpares``      | puntiaguda  | las filas impares, hacia la derecha   |
| ``Desplazamiento/filasPares``        | puntiaguda  | las filas pares, hacia la derecha     |
| ``Desplazamiento/columnasImpares``   | plana       | las columnas impares, hacia abajo     |
| ``Desplazamiento/columnasPares``     | plana       | las columnas pares, hacia abajo       |

Sirven para guardar un mapa rectangular en una matriz, pero no se pueden sumar: la vecina de arriba a
la derecha está en otra columna según la fila sea par o impar. Para calcular, se pasan a axiales:

```swift
let d = CoordenadaDesplazada(columna: 3, fila: 1)
let a = d.axial(.filasImpares)           // (q: 3, r: 1)
a.desplazada(.filasImpares) == d         // true
d.vecinos(.filasImpares)                 // las seis vecinas, en desplazadas
```

### Dobladas

Las coordenadas dobladas (``CoordenadaDoblada``) también dibujan una tabla, pero cuentan uno de los
ejes de dos en dos: con ``Doblado/anchoDoble`` (puntiagudos) la columna avanza dos por casilla, y con
``Doblado/altoDoble`` (planos), la fila. Solo valen las parejas con `columna + fila` par
(``CoordenadaDoblada/esValida``). A cambio de esas casillas vacías, los pasos a las vecinas son
siempre los mismos y la distancia tiene una fórmula directa
(``CoordenadaDoblada/distancia(a:_:)``).

```swift
CoordenadaAxial(q: 1, r: 2).doblada(.anchoDoble)   // (columna: 4, fila: 2)
CoordenadaAxial(q: 1, r: 2).doblada(.altoDoble)    // (columna: 1, fila: 5)
```

### Fraccionarias

Al convertir un píxel o interpolar entre dos casillas salen coordenadas con decimales
(``CoordenadaFraccionaria``). ``CoordenadaFraccionaria/redondeada()`` devuelve la casilla que contiene
el punto: redondea las tres componentes cúbicas y corrige la que más se ha movido, para que sigan
sumando cero.

### Direcciones

Las seis direcciones (``DireccionHexagonal``) se numeran del 0 al 5 en sentido antihorario (con el
eje y hacia abajo, como en la pantalla). Cada una suma 1 a una coordenada cúbica y resta 1 a otra, y
se llama por eso: ``DireccionHexagonal/qMasSMenos`` es `(q + 1, r, s − 1)`. Los puntos cardinales
dependen de la orientación (``DireccionHexagonal/puntoCardinal(_:)``):

| Número | Dirección      | Paso      | Puntiaguda | Plana     |
|-------:|----------------|-----------|------------|-----------|
|      0 | `qMasSMenos`   | (+1,  0)  | este       | sureste   |
|      1 | `qMasRMenos`   | (+1, −1)  | noreste    | noreste   |
|      2 | `sMasRMenos`   | ( 0, −1)  | noroeste   | norte     |
|      3 | `sMasQMenos`   | (−1,  0)  | oeste      | noroeste  |
|      4 | `rMasQMenos`   | (−1, +1)  | suroeste   | suroeste  |
|      5 | `rMasSMenos`   | ( 0, +1)  | sureste    | sur       |

```swift
let este = DireccionHexagonal(.este, .puntiaguda)!   // .qMasSMenos
CoordenadaAxial.origen.vecino(este)                  // (q: 1, r: 0)
CoordenadaAxial.origen.avanzando(3, hacia: este)     // (q: 3, r: 0)
este.opuesta                                         // .sMasQMenos
```
