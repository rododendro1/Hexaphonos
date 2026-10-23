# Afinación y otras representaciones

Temperamentos, afinación justa, numeraciones de Hewlett, colores de las notas, el Tonnetz y la tabla armónica.

## Afinaciones

```swift
TemperamentoRegular.igual                    // quinta de 700 cents
TemperamentoRegular.pitagorico               // quintas puras
TemperamentoRegular.mesotonicoCuartoDeComa   // terceras mayores puras
TemperamentoRegular.igual(divisiones: 31)    // la octava dividida en 31 partes iguales
EntonacionJusta(tonica: .do)                  // razones 1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8
Altura("Sol#4").frecuencia(en: TemperamentoRegular.mesotonicoCuartoDeComa)   // más grave que La♭4
Intervalo.terceraMayor.razonJusta            // 5/4
TemperamentoRegular.igual.cents(de: .terceraMayor)       // 400
EntonacionJusta(tonica: .do).desviacion(de: "Mi4")        // −13,69 cents
```

En un temperamento regular cada nota se afina con su coordenada de quintas:
`cents = quintas · quinta + octavas · 1200`. Por eso Sol♯ y La♭, distintos en el motor,
también suenan distintos en el mesotónico.

## Base 40, base 54 y base 600

La numeración de Walter Hewlett da a cada altura un número que conserva la ortografía
(Fa♯ y Sol♭ son distintos) y hace que los intervalos sean restas. Cada letra ocupa un bloque
de valores, de la máxima alteración en bemoles a la máxima en sostenidos, y entre letras a
distancia de tono queda un hueco. Con `m` alteraciones como máximo, la base es 7·(2m + 1) + 5:
40 para dobles alteraciones, 54 para triples y 600 para 42. Do4 vale 4·base + m (162 en base
40, como en Humdrum).

```swift
Altura("Do4").numero(en: .base40)              // 162
Altura("Fa#4").numero(en: .base40)             // 180
Altura("Solb4").numero(en: .base40)            // 184
Altura(numero: 185, en: .base40)                // Sol4
Intervalo.quintaJusta.numero(en: .base40)     // 23
Intervalo(numero: 12, en: .base40)            // 3ª mayor
Intervalo(numero: 20, en: .base40)            // nil (hueco)
Nota("Si#").numero(en: .base40)      // 38
Altura(Nota(.fa, 3), octava: 4).numero(en: .base40)   // nil: solo llega a 𝄪
Altura(Nota(.fa, 3), octava: 4).numero(en: .base54)   // 245
Altura("Do4").numero(en: .base600)             // 2442
BaseDeHewlett(base: 96)                       // hasta 6 alteraciones
```

En el modelo de quintas la conversión es lineal: una quinta justa vale 8m + 7 y una octava, la base.

## Colores de las notas

`CorrespondenciaDeColores` reúne varias correspondencias históricas entre notas y colores. No
son sinestesia, que es un fenómeno de la percepción, sino sistemas propuestos para asociar sonido
y color:

| Correspondencia | Criterio | Do | Re | Mi | Sol |
|---|---|---|---|---|---|
| `.newton` (1704) | los siete colores del espectro sobre las notas naturales | rojo | naranja | amarillo | azul |
| `.castel` (1734) | doce colores por clase de altura | azul | verde | amarillo | rojo |
| `.scriabin` (1911) | *clavier à lumières* de Prometeo, por el círculo de quintas | rojo intenso | amarillo | azul cielo | naranja |
| `.circuloDeQuintas` | círculo cromático sobre el círculo de quintas (30° por quinta) | rojo | amarillo | verde | naranja |

```swift
Nota.re.color(segun: .scriabin)             // #FFFF00
CorrespondenciaDeColores.scriabin.nombreDelColor(de: .mi)         // "azul cielo (luz de luna o escarcha)"
Altura("La4").color(segun: .newton).hexadecimal      // "#4B0082" (añil)
Acorde("Do").colores(segun: .circuloDeQuintas)     // [#FF0000, #00FF00, #FF8000]
Escala(.re, .dorico).colores(segun: .castel)
ColorRGB(hexadecimal: "#FF8000"), ColorRGB(tono: 120, saturacion: 1, brillo: 1)
```

Las fuentes históricas dan nombres de colores, no valores exactos: los RGB son una
interpretación de esos nombres. En Newton las alteraciones no cambian el color; en Castel y
Scriabin las enarmónicas comparten color.

## Tonnetz

El Tonnetz de Euler y Riemann dispone las notas en una red triangular: hacia la derecha, quintas
justas; en diagonal hacia arriba, terceras mayores; en diagonal hacia abajo, terceras menores.
Cada tríada mayor es un triángulo con el vértice hacia arriba y cada menor, uno hacia abajo.

Un punto `(a, b)` son `a` quintas y `b` terceras mayores desde Do. Como el motor distingue Sol♯ de
La♭, la red no se cierra: Mi es `(0, 1)` como tercera de Do y `(4, 0)` como cuarta quinta, y un
acorde de Fa♯ no comparte puntos con uno de Sol♭. Con clases de altura, en cambio, la red es un
toro de doce puntos y cada clase se repite.

```swift
PuntoDelTonnetz(quintas: 0, terceras: 1).nota            // Mi
PuntoDelTonnetz(quintas: 1, terceras: -1).nota           // Mi♭
PuntoDelTonnetz(quintas: 4, terceras: -1).claseDeAltura  // 0
"\(Tonnetz(Acorde("Do")))"                               // "Do (0, 0) · Mi (0, 1) · Sol (1, 0)"
Tonnetz(Acorde("Domaj7")).triadas.map(\.acorde) == [Acorde("Do"), Acorde("Mim")]   // true
Tonnetz(Escala(.do)).esConexo                            // true
Tonnetz(Escala(.do, .tonosEnteros)).esConexo             // false
"\(Tonnetz(ConjuntoDeClases([0, 4, 7])))"                // "0 (0, 0) · 4 (0, 1) · 7 (1, 0)"
```

Las notas se colocan en la disposición más compacta: la que deja menos grupos sueltos y, entre
ellas, la de menor suma de distancias entre cada par de notas. Se prueban todas las disposiciones
(con ramificación y poda, en milésimas de segundo incluso para la escala cromática): de las 52
escalas de `TipoDeEscala.todos` en Do, 21 quedan más juntas que colocando las notas una a una. `triadas` da los
triángulos completos y `aristas`, los lados entre notas del conjunto.

`svg(notacion:margen:paso:)` dibuja la red alrededor del conjunto: los triángulos mayores en
naranja, los menores en azul, los lados entre notas del conjunto en trazo grueso y las notas en
círculos oscuros. Con clases de altura se marcan todas las repeticiones de cada clase en la ventana.
Encima va un título (el acorde, la escala, las notas, el conjunto o, en un recorrido, la progresión
con sus pasos) y debajo, una leyenda con solo lo que aparece en el dibujo; en notación inglesa, la
leyenda está en inglés. `svg(titulo:)` cambia el título (`""` lo quita) y `svg(leyenda: false)`
quita la leyenda. Lo mismo vale para la tabla armónica.

```swift
let dibujo = Tonnetz(Escala(.re, .dorico)).svg()          // con el título «Re dórico» y su leyenda
let sinLeyenda = Tonnetz(Acorde("Do")).svg(titulo: "Tónica", leyenda: false)
let ingles = Tonnetz(Acorde("Fa#m7")).svg(notacion: .ingles, margen: 2)
let toro = Tonnetz(ConjuntoDeClases([0, 4, 7, 11])).svg(margen: 3)
```

### Transformaciones neorriemannianas

P, L y R cambian una tríada mayor o menor por otra con la que comparte dos notas; en el Tonnetz,
el triángulo gira sobre uno de sus lados:

| | Lado | Do mayor → | La menor → |
|---|---|---|---|
| **P** (paralela) | la quinta | Do menor | La mayor |
| **L** (cambio de sensible) | la tercera menor | Mi menor | Fa mayor |
| **R** (relativa) | la tercera mayor | La menor | Do mayor |

Las tres son involuciones: aplicadas dos veces, devuelven la tríada. Las secuencias se aplican de
izquierda a derecha, y N (RLP), S (LPR) y H (LPL) son las compuestas habituales. La ortografía se
conserva: H de Do es Sol♯ menor, no La♭ menor.

```swift
Acorde("Do").transformar(.r) == Acorde("Lam")                     // true
Acorde("Mib").transformar(.r) == Acorde("Dom")                    // true
Acorde("Do").transformar(leyendo: "PLR") == Acorde("Fam")         // true
Acorde("Do").transformar(TransformacionNeorriemanniana.s) == Acorde("Do#m")   // true
Acorde("Sol7").transformar(.p) == nil                             // true
TransformacionNeorriemanniana.entre("Do", "Mim") == .l            // true
Tonnetz.camino(desde: "Do", hasta: "Mibm") == [.p, .r, .p]        // true
Tonnetz.camino(desde: "Do", hasta: "Sol#", enarmonico: true) == [.p, .l]   // true
```

`Tonnetz.camino(desde:hasta:)` da la secuencia más corta de P, L y R entre dos tríadas. Para las séptimas, y
para caminos que pasan por tríadas aumentadas, está la conducción parsimoniosa (véase Acordes). Con
ortografía, Sol♯ y La♭ son destinos distintos; con `enarmonico: true` basta con que suenen igual.

`Tonnetz(recorrido:)` coloca una progresión de tríadas, cada una en el triángulo más cercano a la
anterior, y `Tonnetz(caminoDesde:hasta:)`, el camino más corto. Al dibujarlos, unas flechas rojas
unen los triángulos y debajo se escribe la progresión con sus pasos: «Do –R→ Lam –L→ Fa». Si el
recorrido va y vuelve entre los mismos triángulos, las flechas se curvan hacia lados distintos para
no montarse, y la red se dibuja algo más grande (`paso` 88 en vez de 64). La
progresión Do–Lam–Rem–Sol–Do no vuelve a su punto de partida, sino a otro Do una coma sintónica
más alto: es la «bomba de comas» de la entonación justa.

```swift
let recorrido = Tonnetz(recorrido: ["Do", "Lam", "Fa", "Rem"])
recorrido?.recorrido.count == 4                                   // true
let bomba = Tonnetz(recorrido: ["Do", "Lam", "Rem", "Sol", "Do"])!
bomba.recorrido.first == bomba.recorrido.last                     // false
let dibujo = Tonnetz(caminoDesde: "Do", hasta: "Fa#")?.svg()
```

### Ciclos

Alternando dos transformaciones se vuelve a la tríada de partida (`CicloNeorriemanniano`):

- **hexatónico** (P, L): seis tríadas, con las notas de una escala hexatónica;
- **octatónico** (P, R): ocho, con las de una octatónica;
- **LR** (L, R): las veinticuatro tríadas mayores y menores, avanzando por quintas.

Con ortografía, un ciclo no se cierra: seis pasos del hexatónico llevan de Do a Re♭♭. Por eso
`Acorde.ciclo(_:)` escribe cada tríada con su enarmónica cuando esta evita dobles alteraciones o
lleva al menos dos alteraciones menos (Mi y no Fa♭; Fa♯m y no Sol♭m, que tiene Si♭♭; pero La♭m
sigue siendo La♭m), y termina en la tríada de partida.

```swift
Acorde("Do").ciclo(.hexatonico)?.map(\.cifrado) == ["Do", "Dom", "La♭", "La♭m", "Mi", "Mim", "Do"]   // true
Acorde("Do").ciclo(.octatonico)?.map(\.cifrado) == ["Do", "Dom", "Mi♭", "Mi♭m", "Sol♭", "Fa♯m", "La", "Lam", "Do"]   // true
Acorde("Do").ciclo(.lr)?.count == 25   // true
Tonnetz(ciclo: .hexatonico, desde: "Do")?.recorrido.count == 7   // true
```

`Tonnetz(ciclo:desde:)` lo dibuja como una banda recta de triángulos, de la tríada de partida a la
misma tríada más abajo. Cada punto lleva el nombre que tiene en la primera tríada del ciclo que lo
toca; por eso, donde cambia la ortografía, el triángulo de Mi muestra La♭ y Do♭, que son las notas
que comparte con La♭m. `TablaArmonica(ciclo:desde:)` lo dibuja igual en la tabla armónica, con
los mismos nombres.

Desde la línea de órdenes, `armonia tonnetz` escribe el SVG y `armonia plr`, las transformaciones:

```
armonia tonnetz Do Mi Sol Si > domaj7.svg
armonia tonnetz --acorde Fa#m7 --margen 2 > fasm7.svg
armonia tonnetz --escala "Re dórico" > dorico.svg
armonia tonnetz --clases 0,4,7,11 > clases.svg
armonia tonnetz --recorrido Do Lam Rem Sol Do > bomba-de-comas.svg
armonia tonnetz --camino Do Mibm > camino.svg
armonia tonnetz --ciclo hexatonico Do > hexatonico.svg
armonia tabla --ciclo octatonico Do > octatonico.svg
armonia plr Do PLR          # Do –P→ Dom –L→ La♭ –R→ Fam
armonia plr Do Mibm         # Do –P→ Dom –R→ Mi♭ –P→ Mi♭m
armonia plr Do hexatonico   # Do –P→ Dom –L→ La♭ –P→ La♭m –L→ Mi –P→ Mim –L→ Do
armonia tonnetz --ciclo octatonico Do > octatonico.svg
```

## Tabla armónica

La tabla armónica (*Harmonic Table*) es la disposición en hexágonos de teclados isomórficos como el
C-Thru AXiS: hacia arriba, una quinta justa; en diagonal hacia arriba a la derecha, una tercera
mayor; en diagonal hacia arriba a la izquierda, una tercera menor. Es el dual del Tonnetz, con la
misma red y cada nota en un hexágono, así que `TablaArmonica` usa sus coordenadas y su colocación.
Una tríada son tres hexágonos que se tocan en un vértice, y la forma de un acorde o una escala es
la misma en todas las tonalidades.

Con notas, acordes y escalas se conserva la ortografía, como en el Tonnetz; un conjunto de clases
de altura se repite como un toro. Con alturas, cada hexágono suena a una altura concreta, como en
el instrumento: el hexágono `(a, b)` está 7a + 4b semitonos por encima de Do4, de modo que
Do4–Mi4–Sol4 es una tríada y Do3–Mi4–Sol4 no.

```swift
TablaArmonica.midi(de: PuntoDelTonnetz(quintas: 1, terceras: 0)) == 67    // true
TablaArmonica(Acorde("Domaj7")).triadas.map(\.acorde) == [Acorde("Do"), Acorde("Mim")]   // true
TablaArmonica([Altura("Do4"), Altura("Mi4"), Altura("Sol4")]).triadas.count == 1   // true
TablaArmonica([Altura("Do3"), Altura("Mi4"), Altura("Sol4")]).triadas.count == 0   // true
"\(TablaArmonica([Altura("Do4"), Altura("Sol4")]))"   // "Do4 (0, 0) · Sol4 (1, 0)"
let dibujo = TablaArmonica(Escala(.re, .dorico)).svg()
```

`svg(notacion:margen:paso:)` rellena los hexágonos de las notas, bordea en naranja la primera (la
tónica de la escala o la fundamental del acorde), traza el contorno de la forma y pone un punto
en el vértice común de cada tríada: naranja si es mayor, azul si es menor. Con clases de altura o
alturas se marcan todos los hexágonos que suenan igual.

```
armonia tabla --acorde Domaj7 > domaj7.svg
armonia tabla --escala "Re dórico" > dorico.svg
armonia tabla Do3 Sol3 Mi4 Si4 > abierto.svg      # con octava: alturas
armonia tabla --clases 0,4,7 > clases.svg
armonia tabla --recorrido Do Lam Fa Rem > recorrido.svg
armonia tabla --camino Do Mibm > camino.svg
```

Los recorridos también se dibujan en la tabla: `TablaArmonica(recorrido:)` y
`TablaArmonica(caminoDesde:hasta:)` colocan las tríadas como en el Tonnetz y unen con flechas los
vértices donde se tocan los tres hexágonos de cada una. Como la tabla es el dual del Tonnetz, un
paso de P, L o R es aquí una flecha entre dos vértices vecinos del mismo lado.

```swift
TablaArmonica(recorrido: ["Do", "Lam", "Fa"])?.recorrido.count == 3   // true
TablaArmonica(caminoDesde: "Do", hasta: "Sol7") == nil               // true
```
