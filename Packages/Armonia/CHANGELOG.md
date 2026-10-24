# Cambios

## Sin publicar

### Código

- `ErrorDeLectura` explica sus motivos con un solo `switch` que devuelve una `Traduccion`, en lugar de uno
  por idioma (de 765 a 458 líneas). Los textos no cambian, y un motivo nuevo no compila sin sus ocho idiomas.
- Los `switch` sobre `Nomenclatura` de `Nota(leyendo:en:)`, `Altura(leyendo:en:)` y `Nota.nombreCompacto(en:)`
  ya no tienen `default`: el compilador avisa al añadir una notación.

### Notas y textos en idiomas distintos

- `Nomenclatura.conTextos(en:)` combina los nombres de nota de una notación con los textos de otro
  idioma: `Acorde("Sol7/Si").nombre(en: Nomenclatura.ruso.conTextos(en: .espanol))` es «соль séptima de
  dominante, primera inversión». `Nomenclatura` gana el caso `.combinada(notas:textos:)` y la propiedad
  `notas`; `allCases` sigue listando solo las notaciones simples. Los textos siguen `idiomaDeLosTextos`
  en lugar de `idioma`.
- Las apps eligen por separado las notas y los textos en el selector de notación (se guarda como
  «ruso+espanol»), y la línea de comandos tiene `--textos`.

### Escalas en francés, italiano, ruso y griego

- `Escala(leyendo:)` acepta la tónica y el tipo en francés e italiano (`Escala("fa dièse lydien")`), y
  en ruso y griego con los tipos más comunes o con su nombre inglés (`Escala("ре дорийский")`,
  `Escala("до lydian dominant")`).

### Nombres de nota en occitano, ruso y griego

- `Nomenclatura` e `Idioma` tienen `.occitano`, `.ruso` y `.griego`: notas, alteraciones y tonalidades
  se escriben y se leen en esas lenguas (`Nota("Fa#").nombre(en: .ruso)` es «фа-диез»;
  `Tonalidad("Re mayor").nombre(en: .griego)`, «ρε μείζονα»; `Altura("sòl dièsi 2")`, Sol♯2). Las lecturas
  genéricas también las aceptan, sin distinguir tildes griegas ni la ё rusa. Los demás textos salen en
  inglés, como en alemán.

### Textos en portugués, francés e italiano

- Los textos del motor y los nombres de los catálogos salen también en portugués, francés e italiano con esas
  notaciones: antes salían en español (portugués) o en inglés (francés e italiano). `Traduccion` pide ahora ocho
  textos (`pt:`, `fr:`, `it:`), y `idiomaDeLosTextos` solo cambia el alemán, que sigue en inglés. El portugués es el europeo (tónica, meio-tom, traste).
  `Intervalo.terceraMayor.nombre(en: .frances)` es «tierce majeure»; `Escala(.re, .dorico).nombre(en: .italiano)`,
  «re dorico»; `Acorde("Sol7/Si").nombre(en: .portugues)`, «sol sétima de dominante, primeira inversão».
- Las escalas se leen también con su nombre en portugués: `Escala("dó maior")`.
- En la línea de comandos, `--idioma pt|fr|it` y la ayuda en esos idiomas.

### Textos en catalán, gallego y euskera

- Los textos del motor salen en catalán, gallego y euskera con esas notaciones, además de en español e inglés:
  los mensajes de `ErrorDeLectura`, los nombres de intervalos, calidades, consonancias, papeles en el acorde,
  calidades de tríada, grados, funciones tonales, claves, figuras y duraciones, cadencias, faltas de conducción,
  análisis y modulaciones, y los nombres de las pistas MIDI. `Intervalo.terceraMayor.nombre(en: .catalan)` es
  «3a major»; en euskera, «3. handia».
- `Traduccion`: un texto en los cinco idiomas, sin valores por omisión, para que el compilador señale el que falta.
  `Nomenclatura.idiomaDeLosTextos` dice en qué idioma salen: el propio en esos cinco, el inglés en alemán, francés
  e italiano, y el español en portugués.
- Cambia la salida con `.catalan`, `.gallego` y `.euskera`, que antes era en español.
- Los nombres de los catálogos también: tipos de acorde («sèptima de dominant», «dominanteko zazpigarrena»), nombres
  de acorde con su inversión, tipos de escala («dòric», «doriarra»; los nombres tradicionales, como los ragas, no
  cambian), instrumentos de la partitura, ciclos neorriemannianos y los títulos y leyendas de los dibujos SVG. Las
  escalas se leen también en esos idiomas: `Escala("re doriarra")`. `Nomenclatura.vocabulario` queda solo para las
  abreviaturas de los intervalos.
- En la línea de comandos, `--idioma ca|gl|eu|es|en` (o `--language`) escribe las notas, los nombres, las
  etiquetas, los errores y la ayuda en ese idioma. Los nombres de las órdenes y de las opciones siguen en español.

### Cadencias, modulaciones y armonización

- `AnalisisArmonico.cadencias`: las cadencias de la progresión (`Cadencia`, con su `Tipo`: auténtica, plagal, rota
  y semicadencia), dónde están y si la auténtica es perfecta (`esPerfecta`).
- `RecorridoTonal`: parte una progresión en tramos (`TramoTonal`), cada uno en su tonalidad, con sus modulaciones
  (`Modulacion`) y el acorde pivote de cada una (`AcordePivote`: «Lam = vi en Do mayor = ii en Sol mayor»). Una
  tonalidad nueva se confirma con una cadencia auténtica; si no, es una tonicalización y no se parte.
- `Tonalidad.acordes(para:)`: los acordes de la tonalidad que tienen una nota, ordenados por coste.
  `Tonalidad.armonizar(melodia:propuestas:)`: las mejores armonizaciones de una melodía (`Armonizacion`), de menor a
  mayor coste, según la armonía funcional y terminando en cadencia.
- `ConduccionDeVoces.realizar(_:soprano:en:)`: escribe unos acordes a cuatro voces sin ninguna falta de las que
  comprueba `problemas`, moviendo las voces lo menos posible, con el soprano fijado si se da.
  `Tonalidad.armonizarACuatroVoces(_:)` armoniza una melodía y la escribe como coral con la melodía en el soprano.
- En la línea de comandos, `analizar` escribe las cadencias y, sin `--en`, las modulaciones con su pivote;
  `armonizar` (`harmonize`) propone acordes para una melodía y, con octavas, escribe el coral; `realizar`
  (`realize`) escribe unos acordes a cuatro voces.

### Paquetes

- El repositorio tiene un `Package.swift` en la raíz, para usar el motor desde otro proyecto:
  `.package(url: "https://github.com/rododendro1/Hexaphonos.git", branch: "main")`, con los productos `Armonia`
  (y uno por capa), `Hexagonos` y `HexaphonosUI`.
- `import Armonia` ya no reexporta `Hexagonos`: quien nombre sus tipos (`CoordenadaAxial`, `FormasDeMapa`,
  `DireccionHexagonal`…) escribe también `import Hexagonos`. Lo que devuelve el motor no cambia.

### La rejilla hexagonal

El motor depende ahora del paquete `Hexagonos` (rejillas hexagonales).

- `PuntoDelTonnetz.coordenada` y `PuntoDelTonnetz(_:)` pasan de un punto del Tonnetz a una `CoordenadaAxial` y
  de vuelta; `distancia(hasta:)` es la de la rejilla (el resultado no cambia).
- `Tonnetz.trazado(paso:)` y `TablaArmonica.trazado(paso:)` dicen dónde dibuja `svg()` cada nota, y
  `punto(en:paso:)`, qué nota hay bajo un punto del dibujo. Los dos dibujos colocan ya las notas con ellas (el SVG
  es el mismo, salvo algún `-0.0` que pasa a `0.0`). `TablaArmonica.coordenada(de:)` y `punto(de:)` traducen entre
  el Tonnetz y la rejilla de la tabla, que es la misma girada 120°.
- `TecladoIsomorfico`: teclados de botones hexagonales en los que cada dirección sube siempre el mismo intervalo
  (`.tablaArmonica`, `.wickiHayden`, `.janko` o cualquier otro), con la altura de cada casilla, las casillas de una
  altura y su dibujo en SVG.

### Hexaphonos

- El ecosistema pasa a llamarse Hexaphonos: el proyecto de Xcode es `Hexaphonos.xcodeproj`, y el paquete de la
  interfaz, `SepirizUI`, pasa a `HexaphonosUI` (con `AjustesHexaphonos` y `TemaHexaphonos`). El motor no cambia.

### Nombres de tipos

Los nombres anteriores se siguen aceptando, marcados como obsoletos.

- `Tonnetz.Arista.Intervalo` pasa a `Tonnetz.Arista.Eje`, y la propiedad `intervalo` a `eje`: son los tres ejes de la
  red (quinta justa, tercera mayor y tercera menor), y el nombre tapaba a `Intervalo` dentro de `Tonnetz`.
- `TablaArmonica.Modo` pasa a `TablaArmonica.Colocacion`, y la propiedad `modo` a `colocacion`: dice cómo se colocaron
  las notas, y «modo» ya es `Tonalidad.Modo`.
- `Razon` pasa a `RazonDeFrecuencias`.

### Terminología

- `Digitacion.cifra` pasa a `tablatura` (el nombre anterior sigue aceptándose, marcado como obsoleto): «cifra» se
  confundía con el cifrado de los acordes.
- La transformación neorriemanniana P se llama «homónima» en `nombre`, no «paralela»: en español, Do mayor y Do menor
  son tonalidades homónimas, y «paralela» era un calco del inglés. El caso `.p` y la letra no cambian.
- `Tonnetz.disposicion(paso:)` y `TablaArmonica.disposicion(paso:)` pasan a `trazado(paso:)` y devuelven un
  `Trazado`, el nuevo nombre de `Disposicion` en `Hexagonos`. Los nombres anteriores siguen aceptándose, marcados como
  obsoletos.
- La documentación de `Digitacion.trastesPisados` decía que eran el más grave y el más agudo; son todos los que se
  pisan.

### Carpetas

- El objetivo de pruebas `ArmoniaPruebasExhaustivas` pasa a `ArmoniaExhaustivasTests`, como los demás
  (`swift test --filter "^ArmoniaExhaustivasTests\."`).
- El ejemplo pasa de `Apps/ArmoniaEjemplo` a `Ejemplos/ArmoniaEjemplo`: no es una app.
- Los scripts del motor (`comprobar_modulos.py`, `comprobar_catalogo.py`, `comprobar_enlaces_docc.py` y
  `generar_pruebas_de_documentacion.py`) pasan de `Packages/Armonia/Scripts/` al `Scripts/` de la raíz, junto a los
  demás, y se ejecutan desde la raíz del repositorio.

### La línea de comandos, en inglés de verdad

- Con `--ingles`, `armonia` ya no mezcla idiomas: la ayuda, los mensajes de uso («falta el cifrado…») y las
  etiquetas de la salida («pasos», el nombre del instrumento) salen en inglés. Los textos de la herramienta están en
  `Apps/ArmoniaCLI/Sources/ArmoniaCLI/Textos.swift`, cada uno en los dos idiomas, y `LineaDeComandos.ayuda(en:)`
  devuelve la ayuda en el idioma de la notación.
- `Encordado(nombre:)` acepta también «seven-string guitar», «drop D guitar» y «five-string bass».
- Nombres más claros en `armonia` (los de antes se siguen aceptando):
  - `voces` pasa a `revisar` (*check*): busca faltas de conducción, y se confundía con `conduccion`.
  - `camino` pasa a `conduccion-parsimoniosa` (*smooth-path*): «camino» y *path* también nombraban la opción
    `--camino` y el alias inglés de `--recorrido` de `tonnetz` y `tabla`.
  - En `tonnetz` y `tabla`, `--recorrido` es *--sequence* en inglés (antes *--path*).
  - En `midi`, `--instrumento` pasa a `--programa` (*--program*): el instrumento es el de cuerda de `digitaciones`.
  - La inversión de un acorde se escribe con ordinal: «primera inversión» (*first inversion*), no «inversión 1».
- «opción desconocida» lleva siempre comillas: antes, según la orden, salía `--foo`, `«--foo»` o `foo`.

### Digitaciones: dedos, orden y ukelele

- **Dedos.** Nuevos `Digitacion.dedos` (los que hacen falta, como mínimo) y `Digitacion.cejilla` (el traste de la
  cejilla, si la forma la lleva): cada nota pisada pide un dedo, salvo en el traste más bajo, donde el índice pisa
  varias cuerdas a la vez si son seguidas o abarcan cuatro o más. `Mastil.digitaciones` tiene un parámetro nuevo,
  `maximoDeDedos` (4 por defecto). **Cambia el resultado por defecto**: antes se devolvían formas que no se pueden
  tocar (con un modelo de dedos, el 19 % de las de una batería de 32 acordes necesitaba más de cuatro).
- **Orden.** Ya no es «menos abertura, más cuerdas, más cerca de la cejilla», que ponía `8-10-10-0-8-0` por delante de
  `x32010`. Ahora es un coste de comodidad (un punto por traste de posición, dedo y traste de abertura; dos por cuerda
  apagada; uno si falta la quinta de un acorde de cuatro notas o más), y a igual coste, antes la de más cuerdas. En una
  batería de 32 acordes de guitarra, la forma de manual pasa de ser la primera en 16 a serlo en 21 (22 con la quinta
  opcional), y de estar entre las tres primeras en 20 a 30 (31); en una de 10 acordes de ukelele, de 4 a 9 primeras.
  Las cifras salen de una réplica en Python del algoritmo (`TrastesTests` comprueba las mismas formas en Swift).
- **Ukelele y reentrantes.** Nuevo `Encordado.esReentrante`. En esos instrumentos, un acorde en estado fundamental ya
  no exige la raíz en la nota más grave (la cuerda de Do suena más grave que la de Sol): antes no aparecían ni el Sol
  `0232`, ni el Fa `2010`, ni el La menor `2000`. Un acorde con bajo propio (`Do/Mi`) sigue exigiéndolo.
- La quinta sigue siendo obligatoria por defecto (`exigirQuinta: true`); la línea de comandos y la aplicación la piden
  opcional, como se toca (el Do7 de manual, `x32310`, no la tiene).
- Corregido un `guard let` que redeclaraba una variable del mismo ámbito en `digitaciones` (no compilaba).

### Plataformas y entradas inválidas

- `Armonia` declara `platforms: [.macOS(.v13), .iOS(.v16)]`, como las apps y `SepirizUI`. `ArmoniaCLI` y `ArmoniaEjemplo`
  declaran macOS 13: SwiftPM rechaza que un paquete con un mínimo más bajo dependa de uno con un mínimo más alto.
- Nuevos inicializadores que devuelven `nil` en vez de detener el programa: `Duracion(comprobando:_:)` y
  `Duracion(comprobando:puntillos:)` (denominador 0; puntillos fuera de 0…30), `Compas(comprobando:_:agrupacion:)` y
  `Tempo(comprobando:unidad:)`. Los inicializadores de siempre siguen deteniendo el programa ante un error de
  quien llama, y ahora lo dicen en su documentación. `BaseDeHewlett(alteracionMaxima:)` toma un número negativo como 0.
- MusicXML y MIDI solo se exportan (no se leen), y los analizadores de texto validan: hoy ningún dato de entrada puede
  llegar a esas precondiciones.

### Renombrado

- El paquete `ArmoniaMusical` pasa a llamarse `Armonia` (carpeta `Packages/Armonia`), como su producto principal y su
  módulo paraguas. `import Armonia` no cambia; en un `Package.swift` ahora es
  `.package(path: "…/Packages/Armonia")` y `.product(name: "Armonia", package: "Armonia")`. En Xcode, el esquema de todo
  el paquete pasa de `ArmoniaMusical-Package` a `Armonia-Package`.
- `Apps/LineaDeComandos` pasa a `Apps/ArmoniaCLI`: el paquete, su biblioteca (antes `ArmoniaLineaDeComandos`, ahora
  `ArmoniaCLI`) y sus pruebas (`ArmoniaCLITests`). El ejecutable sigue siendo `armonia`, y el tipo `LineaDeComandos`
  conserva su nombre.
- `Apps/EjemploArmonia` pasa a `Apps/ArmoniaEjemplo` (`swift run ArmoniaEjemplo`).
- Las entradas anteriores de este registro conservan los nombres de su época.

### Eliminado

- Los nombres anteriores de la API, que llevaban una versión marcados como obsoletos (`Armonia/Obsoletos.swift`):
  `quintas`, `octavas`, `quintasConSigno`, `octavasConSigno` y `NotaNatural.quintasBase`, los inicializadores
  `(quintas:octavas:)` y `TipoDeAcorde(quintas:)`/`(comprobandoQuintas:)`, `simpleAscendente(quintas:)`,
  `EstructuraDeAcorde.quintas`, `Altura.octavaCientifica`, `TipoDeAcorde.quinta`, `CalidadDeTriada.quinta`,
  `Intervalo.quinta`, `NombreDeGrado.submediante`, `Intervalo.oncena`/`oncenaAumentada`/`trecenaMenor`/`trecenaMayor`
  y `TipoDeAcorde.dominanteOncena`/`menorSeptimaOncena`/`dominanteTrecena`. Cada uno tiene su equivalente nuevo en la
  tabla de «Nombres nuevos», más abajo. Al leer texto se siguen aceptando «oncena», «trecena» y «submediante».
  `PuntoDelTonnetz.quintas` no cambia: es otra cosa.
- Los dos tests que solo comprobaban que esos alias seguían funcionando, y `Obsoletos.swift` como fichero permitido en
  el módulo paraguas (`Scripts/comprobar_modulos.py`).

### Mástil y digitaciones

- `Mastil(_:trastes:)` toma un número negativo de trastes como 0 en vez de detener el programa.
- Nuevos `Mastil.midiSiExiste(en:)` y `alturaSiExiste(en:preferirBemoles:)`, que devuelven `nil` para una posición
  que no está en el mástil. `midi(en:)` y `altura(en:)` siguen deteniendo el programa en ese caso (error de quien
  llama); ahora lo dicen en su documentación y remiten a las nuevas.
- Nuevos `Digitacion.init?(comprobando:en:)` e `init?(leyendo:en:)` (lee la cifra de `cifra`: «x32010»,
  «x-10-12-12-11-10»), que devuelven `nil` si los trastes no encajan en el mástil. `Digitacion(mastil:trastes:)`
  sigue deteniendo el programa si no hay un traste por cuerda.
- Nuevo `Digitacion.notas(para:)`: las notas que suenan, escritas como las escribe el acorde (Si♭, no La♯).
- Nuevo `Encordado(nombre:)`: busca un instrumento por su nombre, sin tildes ni mayúsculas («ukulele», «drop D»,
  «bajo de 5 cuerdas», «bass»…).
- Nuevo artículo de DocC, `Trastes`, con sus ejemplos entre las pruebas de documentación.
- Corregido un cierre de `Digitacion.digitaciones` que no compilaba (`$0` dentro de un cierre con parámetros
  explícitos).

### Herramientas

- Nuevo `Scripts/comprobar_enlaces_docc.py` (lo ejecuta el CI): los enlaces ``Tipo`` y `<doc:Articulo>` del
  catálogo apuntan a algo que existe. Y, en la raíz, `Scripts/comprobar_higiene.py`: sin caracteres invisibles,
  tabuladores ni espacios al final, scripts ejecutables que compilan.
- Nuevo `Scripts/compilar_todo.sh` (en la raíz del repositorio): compila y prueba por capas, módulo a módulo
  en el orden de sus dependencias, con un log por paso.
- La herramienta de línea de comandos tiene una orden nueva, `armonia digitaciones`
  (`--instrumento`, `--limite`, `--traste`, `--dedos`, `--completo`, `--tab`), que indica los dedos y la cejilla de
  cada forma.
- `Scripts/comprobar_higiene.py` detecta además un `guard let x` que redeclara un `let x` del mismo ámbito.

### Organización interna (la API pública no cambia)

- La carpeta del ejecutable pasa de `Sources/armonia` a `Sources/ArmoniaEjecutable`: en sistemas de
  ficheros que no distinguen mayúsculas (macOS, Windows) chocaba con `Sources/Armonia`. El producto
  sigue llamándose `armonia` (`swift run armonia`). El CI comprueba que ninguna ruta del
  repositorio se repita al ignorar mayúsculas.
- Los catálogos de escalas se reparten en un fichero por tradición (`Escalas/Tradiciones/`) y por
  tema (`Escalas/Occidentales/`). Los tipos y sus nombres son los mismos y `todos` conserva el orden
  (del que depende qué escala gana al identificar).
- Nuevo `Scripts/comprobar_catalogo.py`, que el CI ejecuta: falla si una escala declarada no está en
  `todos` ni en una lista de tradición, si una lista repite una escala, o si una escala de `todos` no
  tiene nombre inglés en `internacionales`.
- La herramienta de línea de comandos se reparte en una extensión por grupo de órdenes
  (`LineaDeComandos+Consultas`, `+Partituras`, `+Dibujos`, `+Neorriemann`).
- `ConduccionDeVoces` pasa de `Partitura/` a `Tonalidad/`, y `Neorriemann/` (transformaciones, ciclos
  y conducción parsimoniosa) de `Acordes/` a `Representaciones/`, junto al Tonnetz del que depende.
  Las extensiones de `Candidato` para `Acorde` y `Tonalidad` pasan a las carpetas de esos tipos.
- `Texto/Idiomas.swift` conserva los nombres de los tipos del núcleo; los de `Tonalidad`, `PapelEnAcorde`,
  `CalidadDeTriada`, `NombreDeGrado`, `Clave`, `Figura`, `Duracion` y `CorrespondenciaDeColores` pasan a
  un fichero `X+Idiomas.swift` junto a cada tipo, de modo que el núcleo ya no depende de las capas
  superiores. Para añadir un idioma, el compilador señala los `switch` sobre `idioma` que falten.
- La biblioteca se reparte en módulos por capas, y `Armonia` los reexporta: `ArmoniaNucleo`
  (Fundamentos, Texto, Postonal), `ArmoniaTeoria` (Acordes, Escalas, Tonalidad), `ArmoniaRepresentaciones`
  `ArmoniaPartitura` y `ArmoniaTrastes`. `import Armonia` da la misma API pública que antes, y cada capa es también un producto
  (`import ArmoniaTeoria`). Lo que era interno y se usa entre capas pasa a `package`: no se añade a la API pública.
  El paquete se llama ahora `ArmoniaMusical`; el producto y el módulo `Armonia` no cambian.
- La herramienta de línea de comandos (`armonia`, con sus pruebas) y `EjemploArmonia` salen del paquete a
  `Apps/LineaDeComandos` y `Apps/EjemploArmonia`, cada uno con su `Package.swift`. El paquete queda solo con la
  biblioteca; `swift run armonia` y `swift run EjemploArmonia` se ejecutan ahora desde esas carpetas.
- Nuevo módulo `ArmoniaTrastes` (y producto del mismo nombre), reexportado por `Armonia`: `Encordado` (guitarra, bajo,
  ukelele, mandolina…), `Mastil` con `Posicion` (dónde suena una nota o una escala) y `Digitacion` (formas de tocar un
  acorde, con `Mastil.digitaciones(de:)`). Depende de `ArmoniaNucleo` y `ArmoniaTeoria`, como Representaciones y Partitura.
- `Scripts/comprobar_capas.py` se sustituye por `Scripts/comprobar_modulos.py`, que el CI ejecuta: comprueba las
  dependencias declaradas en `Package.swift`, las importaciones y los tipos que cada módulo usa de los demás.
- Nuevo `Scripts/comprobar_catalogo.py`, que el CI ejecuta: falla si una escala declarada no está en
  `todos` ni en una lista de tradición, si una lista repite una escala, o si una escala de `todos` no
  tiene nombre inglés en `internacionales`.
- `Partitura/` se divide en `Modelo/` y `Formatos/`, y `Representaciones/` en `Afinacion/`, `Color/`, `Reticulos/` y
  `Dibujo/`. `Escalas/TipoDeEscala.swift` se reparte en cuatro ficheros. Solo se mueve texto: ningún tipo ni nombre cambia.

## Versión 5

Probada en Linux con Swift 5.9, 5.10, 6.0 y 6.1 (y concurrencia estricta en Swift 6).

### Para actualizar desde la versión 4

Casi todo lo que cambia de nombre sigue compilando: los nombres antiguos están en
`Sources/Armonia/Obsoletos.swift`, marcados como obsoletos, y el compilador avisa y propone el
nombre nuevo (Xcode lo cambia con un clic). Desaparecerán en la próxima versión.

Hay dos cambios que **no avisan** y conviene revisar a mano:

1. **`print` de una `Duracion` da su nombre.** `"\(Duracion(.negra, puntillos: 1))"` era `"4."`
   y ahora es `"negra con puntillo"` (la duración nula es `"cero"`). Si usabas la descripción para
   escribir ritmos que luego se leen, usa `duracion.texto`, que sigue dando `"4."` y `"5/8"`.
2. **El inicializador opcional desde texto se llama `init?(texto:)`.** En la versión 4 era
   `init?(_:)`, pero por SE-0213 `Acorde("Sol7")` con un literal nunca lo usaba (crea el valor
   directamente, sin opcional), y con una variable no compilaba. Ahora:
   - con un literal: `Acorde("Sol7")` o `let a: Acorde = "Sol7"`, sin cambios;
   - con texto del usuario: `Acorde(texto: entrada)` devuelve `nil` si no se puede leer;
   - para saber por qué no se puede leer: `try Acorde(leyendo: entrada)`.

### Nombres nuevos

| Antes | Ahora |
|---|---|
| `Nota.quintas`, `Altura.quintas`, `Intervalo.quintas`, `Alteracion.quintas` | `pasosDeQuinta` |
| `Altura.octavas`, `Intervalo.octavas` | `pasosDeOctava` |
| `Nota(quintas:)`, `Altura(quintas:octavas:)`, `Intervalo(quintas:octavas:direccion:)` | `(pasosDeQuinta:pasosDeOctava:…)` |
| `quintasConSigno`, `octavasConSigno` | `pasosDeQuintaConSigno`, `pasosDeOctavaConSigno` |
| `NotaNatural.quintasBase` | `pasosDeQuintaBase` |
| `Intervalo.simpleAscendente(quintas:)` | `simpleAscendente(pasosDeQuinta:)` |
| `TipoDeAcorde.quintas`, `TipoDeAcorde(quintas:)`, `TipoDeAcorde(comprobandoQuintas:)` | `pasosDeQuinta`, `(pasosDeQuinta:)`, `(comprobandoPasosDeQuinta:)` |
| `EstructuraDeAcorde.quintas` | `quintasDelAcorde` |
| `Altura.octavaCientifica` | `octava` (como en `Altura(.do, octava: 4)`) |
| `TipoDeAcorde.quinta`, `CalidadDeTriada.quinta` (acorde de potencia) | `potencia` |
| `Intervalo.oncena`, `oncenaAumentada`, `trecenaMenor`, `trecenaMayor` | `undecima`, `undecimaAumentada`, `decimoterceraMenor`, `decimoterceraMayor` |
| `TipoDeAcorde.dominanteOncena`, `menorSeptimaOncena`, `dominanteTrecena` | `dominanteUndecima`, `menorSeptimaUndecima`, `dominanteDecimotercera` |
| `Intervalo.quinta` | `quintaJusta` |
| `NombreDeGrado.submediante` | `superdominante` |

Al leer texto se siguen aceptando «oncena», «trecena» y «submediante».

Los nombres que escribe la biblioteca también cambian: el papel en el acorde es «undécima» y
«decimotercera» (antes «oncena» y «trecena»), y los tipos de acorde, «undécima», «menor
undécima», «decimotercera» y «menor decimotercera».

### Correcciones

- El paquete no compilaba: los inicializadores opcionales desde texto chocaban con los literales
  (SE-0213), había dos `switch` sobre opcionales en `EstructuraDeAcorde` que el compilador rechazaba y una
  expresión en `Escala.alturas` que el compilador no podía resolver.
- `TipoDeEscala.melakartasCompatibles` comparaba semitonos y aceptaba escalas con otra ortografía;
  ahora compara las notas.
- La identificación de acordes ya no propone lecturas sin tercera, sin suspensión y sin quinta.
- Los cifrados con paréntesis anidados, sin cerrar o cerrados de más (`Do7((b9))`, `Do7(b9`,
  `Do7)`) se rechazan con un error en lugar de leerse a medias.
- No se mezclan idiomas: la tónica en español va con el tipo en español («Re dórico», «D dorian»,
  pero no «Re dorian»), y el bajo de un acorde se escribe como su fundamental («Sol7/Si», «G7/B»,
  pero no «Sol7/B»).

### Novedades

- **Análisis de progresiones**: `AnalisisArmonico.analizar(leyendo: "Do Lam Re7 Sol7 Do")` da
  «I–vi–V7/V–V7–I en Do mayor», con la función de cada acorde (tónica, subdominante, dominante)
  y su categoría: diatónico, dominante o sensible secundaria, napolitana, préstamo del modo
  homónimo o cromático. Cifra las inversiones (I6, V65) y, si no se le da, elige la tonalidad.
  La sexta añadida se cifra «iii(add6)», para no confundirla con la primera inversión, y los
  acordes invertidos que no son tríadas ni séptimas llevan los intervalos sobre el bajo
  («IV(add6)643»). Reconoce las sextas aumentadas italiana, francesa y alemana («It+6», «Fr+6»,
  «Ger+6»), escritas desde el ♭6̂ (`La♭(♯6)`), desde otra nota (`Re7(♭5)/La♭`) o, la alemana,
  como séptima de dominante que va a la dominante (`La♭7`), y la napolitana invertida («♭II6»,
  «♭II64»). Al leer la progresión, las comas de dentro de un paréntesis son del cifrado.
  También `tonalidad.analizar(acordes)` para una tonalidad conocida.
- **Conducción de voces**: `ConduccionDeVoces(leyendo: "Do3 Sol3 Mi4 Do5 | Re3 La3 Fa4 Re5").problemas`
  señala quintas y octavas paralelas y directas, cruces, superposiciones, separación excesiva,
  saltos no melódicos y notas fuera de tesitura, con las voces y los acordes donde ocurren.
- **Exportación a MusicXML**: `voz.musicXML(tonalidad:clave:tempo:titulo:)` escribe una melodía
  (con ligaduras, barras, puntillos, tresillos y demás grupos irregulares, anacrusa, armadura,
  clave y tempo) y `conduccion.musicXML(duracion:compas:)`, un coral a cuatro voces en dos
  pentagramas, y `analisis.musicXML()`, una progresión con los cifrados americanos encima (como
  símbolos de acorde que el editor reconoce) y el cifrado romano y la función debajo; el coral
  también puede llevarlos (`cifrados: true, analisis: true`). Los documentos se validan con el esquema oficial de MusicXML 4.0 y se abren en
  MuseScore, Finale, Sibelius o Dorico. Desde la terminal, `armonia musicxml melodia …` y
  `armonia musicxml coral …` y `armonia musicxml acordes Do Lam Re7 Sol7 Do`.
- **Exportación a MIDI**: `voz.midi(tempo:titulo:instrumento:)`, `coral.midi(duracion:)` y
  `analisis.midi()` escriben ficheros MIDI estándar (formato 1) para oír melodías, corales y
  progresiones: tempo, compás, armadura, una pista por voz con su nombre e instrumento General
  MIDI, ligaduras como una sola nota, grupos irregulares exactos y un marcador por acorde con su
  cifrado. Desde la terminal, `armonia midi melodia|coral|acordes … > fichero.mid`.
- **Grafía de las figuras con puntillo**: `voz.grafia` (y con ella el MusicXML) escribe entera la
  figura con puntillo que empieza en un pulso de un compás simple, sin ocultar la mitad del 4/4:
  la negra con puntillo del 1.er o del 3.er tiempo ya no sale como negra ligada a corchea. En 6/8
  no se cruza el grupo de tres corcheas. En los compases de amalgama (5/8, 7/8, 3+2+2/8) no se
  oculta el paso entre grupos de distinto tamaño (el 7/8 entero es blanca ligada a negra con
  puntillo), y el silencio de todo un compás queda entero.
- **Herramienta de línea de comandos `armonia`**: `armonia acorde Sol7/Si`, `armonia identificar
  Do Mi Sol Sib`, `armonia intervalo Do4 Mi5`, `armonia escala Re dórico`, `armonia tonalidad
  La menor`, `armonia analizar Do Lam Re7 Sol7 Do` y `armonia voces …`; con `--ingles`, en
  notación inglesa.
- **Más escalas occidentales** en `TipoDeEscala.todos`: los seis modos de la mayor armónica
  (dórico ♭5, frigio ♭4, lidio ♭3, mixolidio ♭2, lidio aumentado ♯2, locrio ♭♭7), doble
  armónica, menor y mayor húngaras, napolitanas menor y mayor, enigmática, persa, mayor locria,
  lidio menor, Prometeo, disminuida semitono-tono, aumentada, blues mayor, egipcia, cromática,
  flamenca, Petrushka, bebop menor melódica y menor armónica, los modos 3 a 7 de Messiaen, los
  modos de la doble armónica y de las napolitanas, cuatro pentatónicas del jazz (dominante,
  menor 6, mayor ♭6 y menor ♭5), la blues de nueve notas, la blues menor con 2ª y el hexacordo,
  la argelina, con sus nombres en inglés. `Escala.identificar` y `rotacion` las tienen en cuenta: el modo 2
  de la pentatónica mayor es ahora la egipcia. Más nombres para las que ya estaban: acústica o
  de Bartók, menor rumana, dominante ♭9 ♭13, mayor melódica, gitana española, Tcherepnin (modo 3 de
  Messiaen) y las auxiliares de la cromática lidia de Russell.
- **Escalas chinas y japonesas**: los cinco modos pentatónicos chinos (Gōng, Shāng, Jué, Zhǐ,
  Yǔ) y las escalas Qīngyuè, Yǎyuè y Yànyuè; las japonesas Ritsu, Ryo, Yō, Min'yō, Miyakobushi,
  In, Insen, Iwato, Hirajōshi, Kumoijōshi y Ryūkyū. Los nombres llevan sus diacríticos (tonos
  del pinyin, macrones del Hepburn) y se leen también sin ellos y en chino o japonés:
  `Escala("Do hirajoshi")`, `Escala("Do 平調子")`. También Akebono y Kokin-jōshi.
- **Escalas etíopes, maqamat, de Indonesia y klezmer** (en `TipoDeEscala.tradicionales`): los
  qenet Təzəta, Bati, Ambassäl y Ančihoye; los maqamat temperados Ḥijāz, Nahāwand, Kurd, ʿAjam,
  Ḥijāzkār y Nawā Athar; Pélog selisir y Sléndro, aproximadas; y los modos klezmer Freygish,
  Misheberakh, Adonai Malakh y Magen Avot. Con su transliteración y diacríticos, y sin ellos
  como alias. Al buscar por nombre, un nombre gana a un alias: «Hijaz» es ahora el maqam Ḥijāz
  (el dromos sigue siendo Hitzáz o Hicaz; las notas son las mismas).
- **Más escalas de otras tradiciones** (en `TipoDeEscala.tradicionales`): ragas indostánicos
  (Bhūpālī, Mālkauns, Durgā, Śivarañjanī, Kalāvatī, Candrakauns, Megh, Yaman, Bāgeśrī y Deś), los
  janya Revati y Amṛtavarṣiṇī, los dastgāh Māhur, Homāyun y Čahārgāh (estos dos, aproximados),
  las coreanas P'yŏngjo y Kyemyŏnjo, la pentatónica y la tritónica andinas, y los tetracordos y
  harmoniai de la Grecia antigua (diatónicos y cromáticos).
- **Más escalas occidentales** en `TipoDeEscala.todos`: los modos de la mayor húngara
  (ultralocrio ♭♭6, menor armónica ♭5, superlocrio ♮6, menor melódica ♯5, dórico ♭2 ♯4, lidio
  aumentado ♯3), las hexatónicas gaélicas (jónico sin 4ª, mixolidio sin 3ª, dórico sin 6ª, eólico
  sin 2ª), las hexatónicas mayor y menor de dos tríadas, las pentatónicas mixolidia, lidia y
  escocesa, y la mayor rumana. Al identificar Do Mi Sol Si Fa♯, la primera es ahora Do
  pentatónica lidia, que tiene exactamente esas notas, y la segunda, Sol mayor. Más nombres:
  nordestina (lidio dominante) y los de compositor (de Liszt, de Rimski-Kórsakov, de Debussy, de
  Weitzmann).
- **`ModoGregoriano`**: los ocho modos del canto gregoriano con su final, su tenor y su ámbito:
  `ModoGregoriano(2)` es el protus plagal o hipodórico (final Re, tenor Fa, ámbito La3–La4), y
  también se busca por nombre: `ModoGregoriano(nombre: "hipofrigio")`.
- **Tonnetz**: `Tonnetz(acorde)`, `Tonnetz(escala)`, `Tonnetz(notas)` o `Tonnetz(conjunto)`
  colocan las notas en la red de quintas y terceras, en la disposición más compacta (se prueban
  todas), conservando la
  ortografía (Fa♯ y Sol♭ caen en puntos distintos); `triadas` da los triángulos mayores y menores
  completos y `svg()` dibuja la red. Desde la terminal, `armonia tonnetz --acorde Domaj7`.
- **Transformaciones neorriemannianas**: `Acorde("Do").transformar(.r)` da Lam, y
  `transformar(leyendo: "PLR")` aplica una secuencia (también N, S y H), conservando la
  ortografía. `Tonnetz.camino(desde: "Do", hasta: "Mibm")` da el camino más corto ([P, R, P]) y
  `Tonnetz(recorrido: ["Do", "Lam", "Fa"])` dibuja una progresión con flechas de triángulo a
  triángulo (curvas y separadas cuando el recorrido va y vuelve). Los ciclos hexatónico,
  octatónico y LR (`Acorde("Do").ciclo(.hexatonico)`, `Tonnetz(ciclo:desde:)`) se escriben con la
  ortografía más sencilla y se dibujan como una banda de triángulos. Desde la terminal, `armonia plr Do PLR`, `armonia plr Do Mibm`,
  `armonia plr Do hexatonico` y `armonia tonnetz --recorrido Do Lam Rem Sol Do`.
- **Conducción parsimoniosa**: `Acorde("Sol7").vecinosParsimoniosos()` da los acordes a un
  semitono (Sol♯°7, Solm7, Mim7) entre séptimas de dominante, menores, semidisminuidas y
  disminuidas (las «Power Towers» de Douthett y Steinbach) o entre tríadas mayores, menores y
  aumentadas (el «Cube Dance»); con `voces: 2`, moviendo dos voces (Sol7 → Re♭7). Los maj7
  tienen su propia familia, `familiaDeSeptimasAmpliada` (las «Power Towers» con maj7): Domaj7
  pasa a Do7 y a Do♯ø7.
  `Tonnetz.caminoParsimonioso(desde:hasta:)` da el camino más corto y
  `conduccionMinima(hasta:)`, la conducción con menos semitonos entre acordes cualesquiera
  (Sol7 → Do: 4). Desde la terminal, `armonia vecinos`, `armonia camino` y `armonia conduccion`.
- **Título y leyenda en los dibujos**: los SVG del Tonnetz y de la tabla armónica llevan
  encima el acorde, la escala o la progresión, y debajo una leyenda con lo que aparece (notas,
  tríadas mayores y menores, intervalos, contorno, tónica o fundamental, pasos del recorrido), en
  español o en inglés. `svg(titulo:leyenda:)` los cambia o los quita.
- **Tabla armónica**: `TablaArmonica` coloca notas, acordes, escalas, conjuntos de clases de altura
  o alturas en la disposición en hexágonos de los teclados isomórficos (quinta hacia arriba,
  terceras en diagonal) y `svg()` la dibuja con el contorno de la forma y un punto en cada tríada.
  Con alturas, cada hexágono es una altura concreta, como en el instrumento. También dibuja
  recorridos de tríadas con flechas (`TablaArmonica(recorrido:)`, `TablaArmonica(caminoDesde:hasta:)`)
  y ciclos neorriemannianos (`TablaArmonica(ciclo:desde:)`).
  Desde la terminal, `armonia tabla --acorde Domaj7`, `armonia tabla Do3 Sol3 Mi4`,
  `armonia tabla --recorrido Do Lam Fa Rem` o `armonia tabla --ciclo octatonico Do`.
- **Portugués**: nombres de notas (dó, ré, mi, fá…), alteraciones («sustenido», «bemol», «duplo
  sustenido»…) y modos («maior», «menor»).
- **Errores en inglés**: `ErrorDeLectura` explica el error en inglés cuando se lee con una
  notación inglesa (`descripcion(en:)`), y sus motivos son tipos concretos
  (`ErrorDeLectura.RechazoDeAcorde`, `CalidadesIncompatibles`) en lugar de texto.
- **Pruebas de la documentación**: `Scripts/generar_pruebas_de_documentacion.py` convierte los
  ejemplos del README y del catálogo DocC en pruebas que comprueban el resultado escrito en cada
  comentario. El CI comprueba que estén al día (`--comprobar`).
- **Pruebas nuevas**: ida y vuelta al azar en todas las notaciones (con semilla fija), casos que
  se deben rechazar y nombres obsoletos.
