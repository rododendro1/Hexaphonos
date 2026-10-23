# Armonia

Motor de armonía tonal en Swift, con la API en español. Todo se apoya en un mismo sistema de
coordenadas —la **línea de quintas** y el **plano quintas × octavas**—, que conserva la
ortografía de las notas (Fa♯ ≠ Sol♭, 4ª aumentada ≠ 5ª disminuida) y reduce casi todas las
operaciones a sumas de enteros.

## Uso

```swift
import Armonia

let i = Altura("Re5") - Altura("Do4")       // 9ª mayor, (2, 0)
Nota.si.intervalo(hasta: .fa)        // 5ª disminuida
Intervalo.terceraMayor.inversion           // 6ª menor
Altura("La4").frecuencia()                  // 440.0
Altura(midi: 63, preferirBemoles: true)      // Mi♭4

Acorde("Sol7/Si").posicionCerrada(octava: 3)   // [Si3, Re4, Fa4, Sol4]
Acorde.identificar([.mi, .sol, .do]).first         // Do/Mi

let menor = Escala("La menor armónica")
menor.cifradosRomanos(cuatriadas: true)
// ["i(maj7)", "iiø7", "♭III+maj7", "iv7", "V7", "♭VImaj7", "vii°7"]
Escala("Mib mayor").armadura              // -3
Escala(.do).rotacion(2)                    // Re dórico
```

## Línea de comandos

`armonia` usa el motor sin escribir código. Vive en `Apps/ArmoniaCLI` del repositorio
(`cd Apps/ArmoniaCLI` y `swift run armonia …`). Acepta nombres en español o en inglés y, con
`--ingles`, responde en notación inglesa (`armonia ayuda` lista todas las órdenes):

```sh
$ swift run armonia acorde Sol7/Si
Sol7/Si: séptima de dominante
  notas: Sol Si Re Fa  (bajo Si, inversión 1)
  Sol fundamental · Si tercera · Re quinta · Fa séptima

$ swift run armonia analizar Do Lam Re7 Sol7 Do
I–vi–V7/V–V7–I en Do mayor
  Do        I         tónica
  Lam       vi        tónica
  Re7       V7/V      dominante
  Sol7      V7        dominante
  Do        I         tónica

$ swift run armonia revisar Do3 Sol3 Mi4 Do5, Re3 La3 Fa4 Re5
Quintas paralelas entre bajo y tenor (acordes 1 → 2)
Octavas paralelas entre bajo y soprano (acordes 1 → 2)

$ swift run armonia musicxml melodia Re4:8 Sol4:4 La4:8 Si4:4. --compas 6/8 --anacrusa 8 > tema.musicxml
$ swift run armonia musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4, Do3 Mi4 Sol4 Do5 --duracion 2 > coral.musicxml
$ swift run armonia musicxml acordes Do Lam Re7 Sol7 Do > progresion.musicxml
$ swift run armonia midi acordes Do Lam Re7 Sol7 Do --tempo 80 > progresion.mid

$ swift run armonia tonnetz --escala "Re dórico" > dorico.svg
$ swift run armonia tonnetz --recorrido Do Lam Fa Rem > recorrido.svg
$ swift run armonia tabla Do3 Sol3 Mi4 Si4 > tabla.svg
$ swift run armonia conduccion Sol7 Do
Sol→Sol, Si→Do (+1), Re→Do (−2), Fa→Mi (−1): 4 semitonos

$ swift run armonia plr Do PLR
Do –P→ Dom –L→ La♭ –R→ Fam
PLR, 3 pasos
```

`midi` escribe lo mismo como fichero MIDI para oírlo (con `--programa` de General MIDI).
`musicxml` escribe una partitura que se abre en MuseScore, Finale, Sibelius o Dorico: una
melodía (con `--compas`, `--anacrusa`, `--tonalidad`, `--clave`, `--tempo` y `--titulo`) o un
coral a cuatro voces en dos pentagramas (con `--duracion` de cada acorde, y `--cifrados` y
`--analisis` para escribir los cifrados y el análisis), o unos acordes con su cifrado americano
encima y el cifrado romano y la función debajo. `tonnetz` dibuja en SVG unas notas, un acorde
(`--acorde`), una escala (`--escala`) o un conjunto de clases de altura (`--clases 0,4,7`) sobre
el Tonnetz, o un recorrido de tríadas con flechas (`--recorrido`, `--camino`, `--ciclo`), y `plr` aplica las
transformaciones neorriemannianas o busca el camino más corto entre dos tríadas. `tabla` dibuja la tabla
armónica en hexágonos, con notas, alturas (`Do3 Sol3 Mi4`), `--acorde`, `--escala`, `--clases`,
`--recorrido`, `--camino` o `--ciclo`. `vecinos`
y `camino` buscan acordes a un semitono (séptimas, maj7 y tríadas, con `--voces 2` para mover dos voces) y
`conduccion`, la conducción con menos semitonos entre dos acordes. Las demás órdenes son
`identificar` (los acordes que forman unas notas), `intervalo`, `escala` y `tonalidad`. Para instalarla: `swift build -c release` y copiar `.build/release/armonia` a
una carpeta del `PATH`.

## Documentación

La documentación está en el catálogo DocC `Sources/Armonia/Armonia.docc`, que Xcode muestra
con *Product › Build Documentation*. También se puede leer directamente:

- [El modelo](Sources/Armonia/Armonia.docc/ElModelo.md): las coordenadas de quintas y octavas en que se apoya todo el motor.
- [Acordes](Sources/Armonia/Armonia.docc/Acordes.md): cifrado americano generativo, identificación tolerante, estilos, estructura y conducción parsimoniosa de los acordes.
- [Escalas](Sources/Armonia/Armonia.docc/Escalas.md): tipos de escala, modos, escalas que suben y bajan distinto, y escalas de la India, Grecia, China y Japón.
- [Tonalidad](Sources/Armonia/Armonia.docc/Tonalidad.md): tonalidades, ortografía de alturas MIDI, detección de la tonalidad, análisis de progresiones y conducción de voces.
- [Notación y partitura](Sources/Armonia/Armonia.docc/NotacionYPartitura.md): notación española e inglesa, alteraciones, intervalos, pentagrama, instrumentos y errores de lectura.
- [Melodía y ritmo](Sources/Armonia/Armonia.docc/MelodiaYRitmo.md): melodías, duraciones exactas, compases, tempo y voces.
- [Afinación y otras representaciones](Sources/Armonia/Armonia.docc/AfinacionYRepresentaciones.md): temperamentos, afinación justa, numeraciones de Hewlett, colores de las notas, el Tonnetz y la tabla armónica.
- [Teoría postonal](Sources/Armonia/Armonia.docc/Postonal.md): conjuntos de clases de altura, formas primas y números de Forte.
- [Convenciones de la API](Sources/Armonia/Armonia.docc/Convenciones.md): protocolos comunes, comodidades, convención de nombres y sinónimos.

## Compilar y probar

```
swift build
swift test                                    # todas las pruebas
swift test --filter "^ArmoniaTests\."          # sólo las rápidas (segundos)
swift test --filter "^ArmoniaExhaustivasTests\."  # sólo las exhaustivas
swift test --filter "^ArmoniaDocumentacionTests\."  # los ejemplos del README y de DocC
python3 ../../Scripts/generar_pruebas_de_documentacion.py # regenera esas pruebas tras cambiar un ejemplo
```

La herramienta `armonia` y el ejemplo (`swift run ArmoniaEjemplo`) son paquetes aparte, en
`Apps/ArmoniaCLI` y `Ejemplos/ArmoniaEjemplo`, y se construyen y prueban desde allí.

Requiere Swift 5.9 o posterior (macOS 13 / iOS 16 en las plataformas de Apple); sin dependencias (sólo Foundation
para `pow`).

Los cambios de cada versión, con la guía para actualizar, están en [CHANGELOG.md](CHANGELOG.md).

### Organización de los ficheros

La biblioteca son cinco módulos por capas, y `Armonia` los reexporta: `import Armonia` da toda la API, e
`import ArmoniaTeoria` (con `ArmoniaNucleo`, de que depende) solo los acordes, las escalas y las tonalidades.
Lo interno que se usa entre capas es `package`, no público. Un módulo solo usa los de su izquierda, y
`Scripts/comprobar_modulos.py`, en la raíz del repositorio, lo vigila:

    ArmoniaNucleo ◄── ArmoniaTeoria ◄──┬── ArmoniaRepresentaciones
                                       ├── ArmoniaPartitura
                                       └── ArmoniaTrastes

Un fichero por concepto: el tipo principal junto con sus tipos auxiliares y sus extensiones
(`Intervalo.swift` contiene también `Direccion`, `CalidadDeIntervalo` y `Consonancia`). Solo se separa en
`Tipo+Tema.swift` lo que es largo y tiene entidad propia, como la identificación de acordes o la
ortografía de las escalas. La conformidad a cada protocolo va en el fichero del tipo.

```
Sources/
├── ArmoniaNucleo/
│   ├── Fundamentos/       Nota (con NotaNatural y Alteracion), Altura, Intervalo (con Direccion,
│   │                      CalidadDeIntervalo, Consonancia), Candidato, Protocolos, Aritmetica
│   ├── Texto/             Idiomas (los nombres que dependen del idioma, de los tipos del núcleo), Nomenclatura (con Idioma y
│   │                      EstiloDeCifrado), Lector, ErrorDeLectura
│   └── Postonal/          ConjuntoDeClases, TablaForte
├── ArmoniaTeoria/
│   ├── Acordes/           TipoDeAcorde, Acorde, Acorde+Identificacion, EstructuraDeAcorde (con
│   │                      PapelEnAcorde, TipoDeAcorde.Componente, CalidadDeTriada), ClasificacionDeAcorde
│   ├── Escalas/           TipoDeEscala (el tipo; +Basicas, +Catalogo con la búsqueda por nombre, +Internacionales
│   │   │                  con los nombres ingleses), Escala (con NombreDeGrado), Escala+Busqueda, Escala+Ortografia, ModoGregoriano
│   │   ├── Occidentales/  TipoDeEscala+Modos, +Exoticas, +Hexatonicas, +Messiaen, +ModosExoticos, +Jazz
│   │   └── Tradiciones/   TipoDeEscala+India, +Grecia, +China, +Japon, +Corea, +Etiopia, +MaqamatYDastgah,
│   │                      +Indonesia, +Klezmer, +Andes y +Tradiciones (la lista `tradicionales`)
│   └── Tonalidad/         Tonalidad, Tonalidad+Deteccion, AnalisisArmonico (con FuncionTonal y AcordeAnalizado),
│                          ConduccionDeVoces (quintas y octavas paralelas, cruces…)
├── ArmoniaRepresentaciones/
│   ├── Afinacion/     Afinacion (frecuencias), BaseDeHewlett (números)
│   ├── Color/         CorrespondenciaDeColores (colores)
│   ├── Reticulos/     Tonnetz (la red de quintas y terceras, en SVG),
│   │   │              TablaArmonica (hexágonos de teclado isomórfico, en SVG)
│   │   └── Neorriemann/   TransformacionesNeorriemannianas (P, L, R y caminos), CiclosNeorriemannianos
│   │                  (hexatónico, octatónico, LR), ConduccionParsimoniosa (vecinos a un semitono,
│   │                  conducción mínima): todo lo que se apoya en el Tonnetz
│   └── Dibujo/        DibujoSVG (título, leyenda y colores comunes de los dibujos)
├── ArmoniaPartitura/
│   ├── Modelo/        Ritmo (Figura, Duracion, Compas, Tempo, Evento), Melodia (con Voz),
│   │                  Pentagrama (Clave, PosicionEnPentagrama, Instrumento)
│   └── Formatos/      MusicXML (exportación de voces y corales),
│                      MIDI (ficheros MIDI estándar de voces, corales y progresiones)
├── ArmoniaTrastes/    Encordado (afinaciones del instrumento), Mastil (con Posicion: dónde suena cada nota),
│                      Digitacion (formas de tocar un acorde en el mástil)
└── Armonia/           el módulo paraguas, sin código propio: Exportaciones (reexporta los cinco)
    │                  y la documentación
    └── Armonia.docc/  portada y un artículo por tema
```

Los nombres que dependen del idioma están en dos sitios. Los de los tipos del núcleo (letras y
alteraciones en las nueve lenguas, y el vocabulario en español e inglés de calidades de intervalo,
intervalos y consonancias) están en `Texto/Idiomas.swift`. Los de los tipos de las demás capas
(modos y tonalidades, papeles en el acorde, calidades de tríada, grados, claves, figuras,
duraciones y colores) están junto a cada tipo, en un fichero `X+Idiomas.swift`
(`find Sources -name '*+Idiomas.swift'` los lista). Para añadir un idioma: un caso en `Idioma` y
en `Nomenclatura`, y corregir lo que el compilador señale: los `switch` sobre el idioma no tienen
`default`. Tres `switch` sobre `Nomenclatura` sí lo tienen y se revisan a mano (`Altura(leyendo:en:)`,
`Nota(leyendo:en:)` y `Nota.nombreCompacto(en:)`). Los nombres que son datos de un catálogo (tipos
de acorde y de escala, instrumentos) siguen junto a su catálogo.

Las pruebas rápidas están en `Tests/ArmoniaTests/`, un fichero por carpeta de fuentes
(`FundamentosTests.swift`, `TonalidadTests.swift`, `PartituraTests.swift`…) más `GeneralTests.swift`, solo con lo que atraviesa todo el motor
(literales, Codable y convenciones de nombres). Las exhaustivas
están en un objetivo aparte, `Tests/ArmoniaExhaustivasTests/ExhaustivasTests.swift`. Las de la
línea de comandos están con ella, en `Apps/ArmoniaCLI/Tests/`.

### Capas

Aunque la biblioteca es un solo módulo, las carpetas siguen unas capas que podrían separarse en
módulos: **Núcleo** (Fundamentos, Texto, Postonal), **Teoría** (Acordes, Escalas, Tonalidad, que
se necesitan entre sí), y dos hojas independientes que usan las anteriores, **Representaciones**
(con Neorriemann) y **Partitura**. `python3 Scripts/comprobar_capas.py` muestra las dependencias
entre ellas y el CI impide que aparezcan nuevas hacia arriba. Hoy no hay ninguna, así que el
Núcleo, la Teoría, las Representaciones y la Partitura podrían separarse en módulos; falta
decidir qué miembros `internal` pasan a `package` o `public`, algo que conviene hacer con el
compilador delante.

### Integración continua

`.github/workflows/ci.yml` comprueba las rutas y las capas, compila, prueba y ejecuta el ejemplo en Linux (Swift 5.9, la
mínima, y 6.2) y en macOS en cada push o pull request. Con Swift 6 también compila la
biblioteca con concurrencia estricta y los avisos tratados como errores. Primero ejecuta las
pruebas rápidas y después las exhaustivas, así un fallo corriente se ve antes.

### Pruebas exhaustivas

El objetivo `ArmoniaExhaustivasTests` reúne las pruebas que recorren espacios completos:
`ConjuntoDeClasesExhaustivoTests` (los 4.096 subconjuntos de las doce clases y sus 223
nombres de Forte), `IdentificacionPorAlturaExhaustivaTests` (cada tipo predefinido sobre las
12 fundamentales, identificado desde MIDI) e `IdaYVueltaTests`, que recorre espacios completos en lugar de ejemplos sueltos: los 2¹⁵
subconjuntos de notas de acorde (9.344 interpretables) en siete estilos de cifrado, cada acorde predefinido con varias
fundamentales y todas sus inversiones, y miles de nombres de nota, notas e intervalos.
En todos los casos, lo que el motor escribe debe volver a leerse igual.
