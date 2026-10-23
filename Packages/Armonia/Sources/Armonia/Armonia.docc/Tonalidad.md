# Tonalidad

Tonalidades, ortografía de alturas MIDI, detección de la tonalidad, análisis de progresiones y conducción de voces.

## Tonalidad

Una `Escala` es un conjunto ordenado de notas (Re dórico, Do blues, Sol alterada); una
`Tonalidad` es el marco tonal: tónica y modo, mayor o menor. En menor, la armadura sale de la
menor natural, pero se escribe y se armoniza con la sensible (V mayor, vii°).

```swift
let laMenor: Tonalidad = "La menor"
laMenor.armadura                      // 0
laMenor.relativa, laMenor.homonima    // Do mayor, La mayor
laMenor.vecinas                       // [Do mayor, Sol mayor, Mi menor, Fa mayor, Re menor]
laMenor.armonizar(cuatriadas: true)   // Lam7 Sim7(♭5) Domaj7 Rem7 Mi7 Famaj7 Sol♯°7
laMenor.cifradosRomanos()             // i ii° III iv V VI vii°
laMenor.nombreDeGrado(de: .sol)             // .subtonica  (y Sol♯ es la sensible)
Tonalidad.circuloDeQuintas(.menor)    // La♭ menor … La♯ menor
Tonalidad(Escala(.re, .dorico))       // nil: un modo no es una tonalidad
```

## Ortografía y detección de tonalidad

```swift
Escala(.do).ortografiar(midi: [60, 61, 62])        // Do4 Do♯4 Re4   (sube con sostenido)
Escala(.do).ortografiar(midi: [62, 61, 60])        // Re4 Re♭4 Do4   (baja con bemol)
Altura(midi: 70, escala: Escala(.fa))           // Si♭4
Altura(midi: 68, tonalidad: "La menor")              // Sol♯4
Escala("Fa# mayor").ortografiar(midi: [65, 60])   // Mi♯4 Si♯3
Tonalidad.candidatos(midi: melodia).first?.valor   // La menor  (la de mayor correlación)
```

Las notas de la escala usan su nombre; las cromáticas se eligen entre las dos escrituras
más cercanas a la escala en la línea de quintas, según la dirección de la melodía. La
detección usa el algoritmo de Krumhansl-Schmuckler (con duraciones opcionales) y escribe
la tónica con la armadura más sencilla, o con la ortografía de las notas si se dan nombres.

## Análisis de progresiones

`AnalisisArmonico` lee una sucesión de acordes en una tonalidad: el grado de cada uno en
cifrado romano (con la inversión en cifra de bajo continuo), su función y por qué está ahí.
Si no se da la tonalidad, elige entre las más probables por sus notas la que explica más
acordes y empieza o termina en su tónica.

```swift
let analisis = try AnalisisArmonico.analizar(leyendo: "Do Lam Re7 Sol7 Do")
analisis.tonalidad                    // Do mayor
analisis.cifrados                     // ["I", "vi", "V7/V", "V7", "I"]
analisis.funciones.map { $0?.abreviatura ?? "–" }   // ["T", "T", "D", "D", "T"]
analisis.acordes[2].categoria         // .dominanteSecundaria(de: 5)
analisis.nombre(en: .ingles)          // "I–vi–V7/V–V7–I in C major"

try AnalisisArmonico.analizar(leyendo: "Do Fa/La Sol7/Si Do")      // I–IV6–V65–I en Do mayor
try AnalisisArmonico.analizar(leyendo: "Sim7(b5) Mi7 Lam")         // «iiø7–V7–i en La menor»
try AnalisisArmonico.analizar(leyendo: "Do Lab Sib Do")            // I–♭VI–♭VII–I en Do mayor
try AnalisisArmonico.analizar(leyendo: "Do Reb/Fa Sol7 Do")        // I–♭II6–V7–I en Do mayor
try AnalisisArmonico.analizar(leyendo: "Do Fa#°7 Sol Do")          // I–vii°7/V–V–I en Do mayor
Tonalidad(.la, .menor).analizar(["Lam", "Rem/Fa", "Mi7", "La"]).cifrados   // ["i", "iv6", "V7", "I"]
Tonalidad(.do).analizar(["Mim6", "Mim/Sol"]).cifrados   // ["iii(add6)", "iii6"]
```

La sexta añadida se cifra «(add6)», porque un 6 solo es la primera inversión. Los acordes
invertidos que no son tríadas ni cuatríadas de séptima llevan todos los intervalos sobre el bajo,
de mayor a menor:

```swift
Tonalidad(.do).analizar(["Fa6/La", "Fa6/Do", "Do(add9)/Mi"]).cifrados   // ["IV(add6)643", "IV(add6)642", "I(add9)763"]
```

Cada acorde cae en una de estas categorías (`AcordeAnalizado.Categoria`):

- **Diatónico**: con las notas de la tonalidad; en menor cuentan también el 6.º y el 7.º
  elevados, así que V y vii° son diatónicos.
- **Dominante o sensible secundaria** (V7/V, vii°7/V): dominante o acorde de sensible de un
  grado que no es la tónica. Si resuelve en ese grado es la lectura preferida; si no, solo se
  elige cuando el acorde no es prestado.
- **Napolitana** (♭II): el acorde mayor sobre el 2.º grado rebajado, con función de subdominante.
  Invertida se cifra como cualquier tríada: ♭II6 (la sexta napolitana) o ♭II64.
- **Sexta aumentada** (It+6, Fr+6, Ger+6): ♭6̂ y ♯4̂, a distancia de sexta aumentada, con la
  tónica y nada más (italiana), con 2̂ (francesa) o con ♭3̂ (alemana), sea cual sea el bajo. Tiene
  función de subdominante y va a la dominante o al I64 cadencial. La alemana escrita como
  séptima de dominante (La♭7 en Do, con Sol♭ en vez de Fa♯) cuenta como tal si va a la dominante.
- **Préstamo** del modo homónimo: iv, ♭VI o ♭VII en mayor, o el I mayor (tercera de picardía)
  en menor.
- **Cromático**: ninguno de los anteriores; se cifra con la alteración del grado y sin función.

```swift
Tonalidad(.do).analizar(["Do", "Lab(#6,omit5)", "Sol", "Do"]).cifrados          // ["I", "It+6", "V", "I"]
Tonalidad(.do).analizar(["Fa", "Re7(b5)/Lab", "Sol"]).cifrados                  // ["IV", "Fr+6", "V"]
Tonalidad(.do).analizar(["Lab(#6)", "Do/Sol", "Sol7", "Do"]).cifrados           // ["Ger+6", "I64", "V7", "I"]
Tonalidad(.do).analizar(["Lab7", "Sol"]).cifrados                               // ["Ger+6", "V"]
Tonalidad(.do).analizar(["Reb/Lab", "Sol7", "Do"]).cifrados                     // ["♭II64", "V7", "I"]
```

Las funciones siguen los grados: I, iii y vi son de tónica; ii y IV, de subdominante; V y
vii°, de dominante. La alteración delante del numeral (♭VI) se mide respecto a la escala de
la armadura, y en menor no se escribe para el 6.º y el 7.º elevados (vii°, no ♯vii°).

`musicXML(duracion:compas:tempo:titulo:parte:cifrados:analisis:notacion:)` escribe el análisis
como partitura MusicXML en dos pentagramas: los acordes en posición cerrada en clave de sol,
con su cifrado americano encima (como símbolo de acorde, que el editor reconoce y puede
transportar), y el bajo en clave de fa, con el cifrado romano y la función debajo:

```swift
let analisis = try AnalisisArmonico.analizar(leyendo: "Do Lam Re7 Sol7 Do")
let partituraAnalizada = analisis.musicXML(titulo: "Progresión")
partituraAnalizada.contains("<kind text=\"7\">dominant</kind>")   // true
partituraAnalizada.contains("<text>V7/V</text>")               // true
analisis.musicXML(notacion: .ingles).contains("C major:")      // true
```

## Conducción de voces

`ConduccionDeVoces` comprueba las reglas de la armonía escrita voz por voz. Cada acorde lleva
sus alturas de grave a agudo (a cuatro voces: bajo, tenor, contralto y soprano), separados
por barras o comas:

```swift
let c = try ConduccionDeVoces(leyendo: "Do3 Sol3 Mi4 Do5 | Re3 La3 Fa4 Re5")
c.problemas.map(\.tipo) == [.quintasParalelas, .octavasParalelas]   // true
c.problemas[0].voces                  // [0, 1]
c.problemas[0].description            // "Quintas paralelas entre bajo y tenor (acordes 1 → 2)"
c.problemas[0].descripcion(en: .ingles)   // "Parallel fifths between bass and tenor (chords 1 → 2)"

try ConduccionDeVoces(leyendo: "Do3 Mi4 Sol4 Do5 | Fa3 Fa4 La4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5").esCorrecta   // true
ConduccionDeVoces(voces: [["Do3", "Sol2"], ["Mi4", "Re4"], ["Sol4", "Sol4"], ["Do5", "Si4"]])?.esCorrecta          // true
```

Las faltas que encuentra (`ProblemaDeConduccion.Tipo`):

- **Quintas y octavas paralelas**: dos voces a distancia de quinta justa, u octava justa o
  unísono, que se mueven a otra igual, también por movimiento contrario. Una quinta justa que
  pasa a disminuida no cuenta.
- **Quintas y octavas directas**: bajo y soprano llegan a una quinta u octava justa
  moviéndose en el mismo sentido, con salto en el soprano.
- **Cruce de voces** y **superposición** (una voz pasa más allá de la nota que la vecina
  tenía en el acorde anterior).
- **Más de una octava** entre dos voces superiores vecinas; entre bajo y tenor se permite.
- **Salto no melódico**: más de una octava, o un intervalo aumentado (salvo el semitono cromático).
- **Fuera de tesitura**, a cuatro voces: bajo Mi2–Do4, tenor Do3–Sol4, contralto Sol3–Re5 y
  soprano Do4–Sol5.

`musicXML(duracion:compas:tonalidad:tempo:titulo:parte:)` escribe los acordes como coral en
MusicXML: soprano y contralto en clave de sol, tenor y bajo en clave de fa, cada voz con sus
plicas. Todos los acordes duran lo mismo (negras si no se dice otra cosa) y el último se
alarga hasta la barra:

```swift
let coral = try ConduccionDeVoces(leyendo: "Do3 Mi4 Sol4 Do5 | Fa3 Fa4 La4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5")
let partitura = coral.musicXML(duracion: .blanca, titulo: "Cadencia")
partitura.contains("<staves>2</staves>")        // true
```

Con `cifrados: true` cada acorde lleva su cifrado americano encima del soprano, y con
`analisis: true`, el cifrado romano y la función debajo del bajo. Los acordes se identifican
por sus notas; los que no son de ningún tipo del catálogo (por una nota de paso, por ejemplo)
se quedan sin cifrar:

```swift
let cadencia = try ConduccionDeVoces(leyendo: "Do3 Mi4 Sol4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5")
cadencia.musicXML(cifrados: true, analisis: true).contains("<text>V</text>")   // true
```
