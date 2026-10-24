# Acordes

Cifrado americano generativo, identificación tolerante, estilos y estructura de los acordes.

## Acordes: cifrado generativo

Un `TipoDeAcorde` es el conjunto de desplazamientos en quintas de sus notas respecto a la
fundamental. Como la ortografía fija el papel de cada nota (la ♯9 es +9 quintas y la 3ª
menor −3, aunque suenen igual), el cifrado se **genera** a partir del conjunto y se **lee**
con la misma gramática, sin una lista cerrada de tipos:

```swift
Acorde("G7(b9,#11)").cifrado        // "Sol7(♭9,♯11)"
TipoDeAcorde("m11").cifrado           // "m11"
TipoDeAcorde("13sus4").intervalos     // [1ª justa, 4ª justa, 5ª justa, 7ª menor, 9ª mayor, 13ª mayor]
TipoDeAcorde("7alt").cifrado          // "7(♭9,♯9,♯11,♭13)"
Acorde("Do6/9/Mi")                  // la barra del bajo es la última seguida de una nota
Acorde("Do/Re").tieneBajoAjeno      // true
```

Se aceptan, entre otros: `m min -`, `° dim o`, `ø`, `+ aug`, `maj M Δ 7M`, `5 6 7 9 11 13`,
`6/9`, `sus sus2 sus4`, `add9 add♭13`, alteraciones `b9 #11 -5 +9` con o sin paréntesis,
`alt`, `omit3 no5`. Cualquier cifrado generado se vuelve a leer igual (comprobado sobre
miles de combinaciones).

**Igualdad por contenido.** Dos `TipoDeAcorde` son iguales si tienen las mismas notas
(`"add2" == "add9"`, `"Δ" == "maj7"`), y dos `TipoDeEscala` si tienen los mismos intervalos,
sea cual sea su nombre.

**Identificación tolerante.** `Acorde.candidatos(_:)` devuelve todas las lecturas razonables
ordenadas por coste (menor = más probable), como `Candidato<Acorde>`. Admite notas duplicadas, quinta omitida,
tensiones alteradas y bajo ajeno:

```swift
let c = Acorde.candidatos([.do, .mi, "Sib"]).first!
c.valor.cifrado    // "Do7"
c.omitidas         // [Sol]
Acorde.identificar([.do, .mi, "Sib", "Reb"]).first   // Do7(♭9)
```

## Sextas aumentadas

Los acordes de sexta aumentada se escriben desde el bajo natural, ♭6̂, con la sexta aumentada
(`♯6`) dentro de la octava, como una sexta añadida: la italiana es `La♭(♯6,omit5)`, la francesa
`La♭(♯6,♯11,omit5)` y la alemana `La♭(♯6)`. Sin quinta, la italiana y la francesa no se dan por
incompletas al identificarlas:

```swift
Acorde("Lab(#6,omit5)").tipo.nombre                         // "sexta aumentada italiana"
Acorde.identificar(["La♭", "Do", "Fa♯"] as [Nota]).first?.cifrado             // "La♭(♯6,omit5)"
Acorde.identificar(["La♭", "Do", "Mi♭", "Fa♯"] as [Nota]).first?.cifrado      // "La♭(♯6)"
```

La francesa también es `Re7(♭5)/La♭`, que sale antes al identificarla; el análisis en una
tonalidad las reconoce escritas de cualquier forma (véase «Tonalidad»).

## Identificación desde alturas (MIDI)

Un teclado o un archivo MIDI sólo da alturas. `Acorde.candidatos(midi:)` y
`candidatos(clasesDeAltura:)` prueban todas las ortografías posibles de cada nota (cada
distancia en semitonos admite una o dos posiciones en la línea de quintas), puntúan cada
lectura igual que con nombres y escriben la fundamental de la forma más sencilla:

```swift
Acorde.identificar(midi: [60, 64, 68]).first          // Do+   (no La♭+/Do)
Acorde.identificar(midi: [60, 63, 66, 69]).first      // Do°7  (no Si♯°7)
Acorde.identificar(midi: [61, 65, 68]).first          // Re♭   (no Do♯)
Acorde.identificar(midi: [55, 59, 62, 65, 68]).first  // Sol7(♭9)
Acorde.identificar(midi: [66, 70, 73], tonalidad: "Solb mayor").first   // Sol♭
Acorde("Do+").ortografiar(midi: [60, 64, 68])        // [Do4, Mi4, Sol♯4]
```

Con `tonalidad:` se prefieren las notas propias de la tonalidad (en menor, también el 6.º y
el 7.º elevados); con `escala:`, las de una escala cualquiera, como un modo. Una prueba exhaustiva recorre todos los tipos
predefinidos sobre las 12 fundamentales y comprueba que el acorde correcto sale primero.

## Estilos de cifrado

Las adiciones, alteraciones y omisiones van en un único grupo entre paréntesis
(`Mim(add♭13)`, `sus4(add9)`, `7(♭9,♯11)`), y `EstiloDeCifrado` cambia la notación sin
cambiar el significado. Todos los estilos se vuelven a leer igual.

| Estilo | Si♭7(♭9)/Re | Do♯m7(♭5) | Mi♭maj7 | Fa+ |
|---|---|---|---|---|
| `.predeterminado` | Si♭7(♭9)/Re | Do♯m7(♭5) | Mi♭maj7 | Fa+ |
| `.ascii` | Sib7(b9)/Re | Do#m7(b5) | Mibmaj7 | Fa+ |
| `.ingles` | Bb7(b9)/D | C#m7(b5) | Ebmaj7 | F+ |
| `.inglesUnicode` | B♭7(♭9)/D | C♯m7(♭5) | E♭maj7 | F+ |
| `.jazz` | Bb7(b9)/D | C#ø7 | EbΔ7 | F+ |
| `.palabras` | Si♭7(♭9)/Re | Do♯min7(♭5) | Mi♭maj7 | Faaug |

Cada opción (`notacion`, `alteracionesASCII`, `menor`, `disminuido`, `aumentado`,
`septimaMayor`, `semidisminuido`) se puede combinar libremente. Si no se da `alteracionesASCII`, las
tensiones llevan b y # cuando las notas de la notación los llevan.

## Estructura del acorde

`TipoDeAcorde.estructura` y las propiedades de `Acorde` dicen qué papel cumple cada nota:

```swift
let a: Acorde = "Sol13(b9)"
a.componentes.map { "\($0.nota) \($0.papel)" }
// ["Sol fundamental", "Si tercera", "Re quinta", "Fa séptima", "La♭ novena", "Mi decimotercera"]
a.tercera, a.quinta, a.septima          // Si, Re, Fa
a.tensiones                             // [La♭, Mi]
a.papel(de: "Lab")                      // .tension(9)
a.estructura.calidadDeTriada            // .mayor
TipoDeAcorde("7sus4").estructura.suspension   // 4ª justa
```

## Conducción parsimoniosa

Dos acordes de una familia son vecinos si se pasa de uno a otro moviendo una voz un semitono
(P₁,₀, de Douthett y Steinbach) o dos voces un semitono cada una (P₂,₀). Hay tres familias:

- `TipoDeAcorde.familiaDeSeptimas`: séptimas de dominante, menores, semidisminuidas y
  disminuidas, las «Power Towers». Cada séptima de dominante tiene tres vecinas; la menor, cuatro;
  la semidisminuida, tres, y la disminuida, ocho.
- `TipoDeAcorde.familiaDeTriadas`: tríadas mayores, menores y aumentadas, el «Cube Dance». Aquí
  P y L son movimientos de una voz; R no, porque la quinta sube un tono.
- `TipoDeAcorde.familiaDeSeptimasAmpliada`: las «Power Towers» con las séptimas mayores (maj7).
  Es la de los maj7: Domaj7 pasa a Do7 (Si→Si♭) y a Do♯ø7 (Do→Do♯). Las demás séptimas siguen
  en la primera salvo que se pida con `tipos:`; en esta, la de dominante y la semidisminuida
  tienen cuatro vecinas.

```swift
Acorde("Sol7").vecinosParsimoniosos().map(\.description) == ["Sol♯°7 (Sol→Sol♯)", "Solm7 (Si→Si♭)", "Mim7 (Fa→Mi)"]   // true
Acorde("Sol7").vecinosParsimoniosos(voces: 2).contains { $0.acorde == Acorde("Reb7") }   // true
Tonnetz.caminoParsimonioso(desde: "Sol7", hasta: "Rem7")?.map(\.acorde.cifrado) == ["Sol♯°7", "Sim7(♭5)", "Rem7"]   // true
Tonnetz.caminoParsimonioso(desde: "Sol7", hasta: "Reb7", voces: 2)?.count == 1   // true
Acorde("Domaj7").vecinosParsimoniosos().map(\.description) == ["Do♯m7(♭5) (Do→Do♯)", "Do7 (Si→Si♭)"]   // true
Tonnetz.caminoParsimonioso(desde: "Domaj7", hasta: "Sol7")?.count == 3   // true
```

Con dos voces, Sol7 llega a Re♭7 en un paso, que es la sustitución tritonal. Con
`tipos: [.dominanteSeptima, .semidisminuido]` salen las transformaciones de Childs. La nota
movida se escribe como semitono cromático o diatónico, y el acorde con la ortografía que necesite
menos alteraciones sin renombrar las notas que no se mueven: Re♭7 pasa a Re♭m7, no a Do♯m7.
El camino compara la meta sin ortografía, de modo que Do♯7 llega a Re♭7, y sin `tipos:` va por
la primera familia que tenga a los dos acordes (de Domaj7 a Sol7, por la ampliada).

Entre acordes cualesquiera, incluso de distinto tamaño, `conduccionMinima(hasta:)` da la
conducción con menos semitonos en total, duplicando las notas que haga falta:

```swift
"\(Acorde("Sol7").conduccionMinima(hasta: "Do"))"   // "Sol→Sol, Si→Do (+1), Re→Do (−2), Fa→Mi (−1): 4 semitonos"
Acorde("Rem7").conduccionMinima(hasta: "Sol7").total == 3   // true
Acorde("Do").conduccionMinima(hasta: "Lam").total == 2      // true
```

Desde la línea de órdenes:

```
armonia vecinos Sol7              # Sol♯°7 (Sol→Sol♯), Solm7 (Si→Si♭), Mim7 (Fa→Mi)
armonia vecinos Sol7 --voces 2
armonia vecinos Domaj7            # Do♯m7(♭5) (Do→Do♯), Do7 (Si→Si♭)
armonia vecinos Sol7 --ampliada   # también Solmaj7 (Fa→Fa♯)
armonia conduccion-parsimoniosa Sol7 Rem7   # Sol7 –Sol→Sol♯→ Sol♯°7 –Sol♯→La→ Sim7(♭5) –Si→Do→ Rem7
armonia conduccion Sol7 Do        # Sol→Sol, Si→Do (+1), Re→Do (−2), Fa→Mi (−1): 4 semitonos
```
