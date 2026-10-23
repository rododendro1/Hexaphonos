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

Las seis direcciones se numeran del 0 al 5 en sentido antihorario (con el eje y hacia abajo, como en
la pantalla). Los nombres de los puntos cardinales dependen de la orientación:

| Número | Paso      | Puntiaguda | Plana     |
|-------:|-----------|------------|-----------|
|      0 | (+1,  0)  | este       | sureste   |
|      1 | (+1, −1)  | noreste    | noreste   |
|      2 | ( 0, −1)  | noroeste   | norte     |
|      3 | (−1,  0)  | oeste      | noroeste  |
|      4 | (−1, +1)  | suroeste   | suroeste  |
|      5 | ( 0, +1)  | sureste    | sur       |
