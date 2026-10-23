# Trastes

Instrumentos de cuerda con trastes: dónde suena cada nota en el mástil y cómo se toca un acorde.

## Overview

``Encordado`` es la afinación de un instrumento (guitarra, bajo, ukelele, mandolina y algunas
variantes), ``Mastil`` es ese encordado con un número de trastes, ``Posicion`` es un lugar del
mástil (una cuerda y un traste, con el 0 como cuerda al aire) y ``Digitacion`` es una forma de tocar
un acorde: un traste, o ninguno, por cada cuerda.

```swift
import Armonia

let mastil = Mastil(.guitarra)                           // veinticuatro trastes
let ukelele = Encordado(nombre: "ukulele")               // también «bajo de 5 cuerdas», «drop D»…

let acorde = Acorde("Sol7/Si")
let formas = mastil.digitaciones(de: acorde, limite: 3)  // las más cómodas primero
let primera = formas.first
let tablatura = primera?.tablatura                       // como «x20001»: de la cuerda grave a la aguda
let notas = primera?.notas(para: acorde)                 // escritas como el acorde: Si♭, no La♯
let dedos = primera?.dedos                               // cuántos dedos hacen falta, como mínimo
let cejilla = primera?.cejilla                           // el traste de la cejilla, si la lleva

let pentatonica = mastil.posiciones(de: Escala(.la, .pentatonicaMenor), trastes: 0...12)
```

Las digitaciones cumplen unas reglas de comodidad: una abertura de la mano de cuatro trastes como
máximo, las cuerdas que suenan seguidas (las apagadas, solo en los extremos), la nota más grave que
suena es el bajo del acorde y suenan todas sus notas (la quinta de un acorde de más de tres notas
puede omitirse si se pide: el Do7 de manual, `x32310`, no tiene el Sol).

Hacen falta cuatro dedos como máximo. ``Digitacion/dedos`` cuenta los mínimos: cada nota pisada pide un
dedo, salvo en el traste más bajo, donde el índice puede pisar varias cuerdas a la vez (si son seguidas, o
con una cejilla de cuatro cuerdas o más; ``Digitacion/cejilla``). Una cuerda al aire entre dos de ellas lo
impide. Sin este límite, uno de cada cinco resultados de un acorde corriente eran formas imposibles.

En un instrumento reentrante (``Encordado/esReentrante``), como el ukelele, cuya cuerda más grave no es la
primera, un acorde en estado fundamental no exige la raíz en la nota más grave: el `2000` es un La menor aunque
el Do suene más grave. Un acorde con bajo propio (`Do/Mi`) sí lo exige.

El orden es el de un coste de comodidad: un punto por traste de posición, por dedo y por traste de
abertura, dos por cada cuerda apagada y uno si falta la quinta. Por eso `x32010` es la primera forma de
Do.

## Datos que vienen de fuera

Un traste o una posición que escribe una persona puede no existir. Los inicializadores y los
métodos que se detienen ante un error del programador (como salirse de un array) tienen un
equivalente que devuelve `nil`.

```swift
import Armonia

let mastil = Mastil(.guitarra)
let leida = Digitacion(leyendo: "x32010", en: mastil)            // nil si no se entiende o no cabe
let comprobada = Digitacion(comprobando: [nil, 3, 2, 0, 1, 0], en: mastil)
let sonido = mastil.midiSiExiste(en: Posicion(cuerda: 9, traste: 0))   // nil: no hay décima cuerda
```

## Topics

### Instrumentos y mástil

- ``Encordado``
- ``Mastil``
- ``Posicion``

### Acordes en el mástil

- ``Digitacion``
