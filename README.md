# Hexaphonos

Ecosistema de apps y paquetes de música en Swift. El motor de armonía (`Armonia`) es la base;
encima hay paquetes para el mástil de los instrumentos de cuerda y para la interfaz, y dos apps de
SwiftUI para iOS y macOS.

```
Apps/
├── ArmoniaApp/       Acordes (con digitaciones), escalas (con el mástil), análisis armónico (con modulaciones y
│                     cadencias) y corales: armonizar, realizar a cuatro voces y revisar; exporta MusicXML y MIDI
├── TonnetzApp/       Un acorde, una escala o un recorrido con P, L y R en el Tonnetz, la tabla armónica o un
│                     teclado isomorfo (Wicki-Hayden, Jankó); exporta el dibujo en SVG
└── ArmoniaCLI/       La herramienta `armonia`, con sus pruebas (SwiftPM)
Ejemplos/
└── ArmoniaEjemplo/   Un recorrido por la API del motor, ejecutable (SwiftPM)
Herramientas/
└── ArmoniaRendimiento/  Cuánto tarda el motor en lo que hacen las apps (SwiftPM; el CI lo mide en cada cambio)
Packages/
├── Armonia/        El motor de armonía, en cinco módulos (Nucleo, Teoria, Representaciones, Partitura, Trastes)
│                   y el paraguas `Armonia`: notas, acordes, escalas, tonalidad, Tonnetz, MusicXML, MIDI,
│                   y los mástiles, afinaciones y digitaciones de acordes (guitarra, bajo, ukelele…)
├── HexaphonosUI/   Componentes SwiftUI (DiagramaDeMastil, DiagramaDeTonnetz, DiagramaHexagonal, VistaSVG, tema) y lo que comparten las apps:
│                   el selector de notación y su ajuste (en el entorno), los textos de la interfaz en ocho
│                   idiomas, lo que enseña cada vista, el cálculo en segundo plano y el menú para exportar.
│                   El análisis y el coral están en el módulo `HexaphonosPresentacion`, sin SwiftUI, que
│                   también usa la línea de comandos
└── Hexagonos/      Rejillas hexagonales: coordenadas axiales, cúbicas, desplazadas y dobladas, vecinos, distancias,
                    líneas, regiones, rotaciones y el paso a píxeles; el motor la usa para el Tonnetz,
                    la tabla armónica y los teclados isomórficos
Scripts/            Comprobaciones del repositorio (también las del motor) y generación del proyecto de Xcode
Config/             Ajustes de compilación de las apps (Local.xcconfig, el de tu equipo, no se guarda en git)
project.yml         Definición del proyecto de Xcode (XcodeGen)
Package.swift       Los tres paquetes juntos, para usarlos desde otro proyecto por URL
```

## Dependencias

```
ArmoniaApp ──┬──► HexaphonosUI ──┬──► Armonia ──► Hexagonos
TonnetzApp ──┘                  └──► Hexagonos
ArmoniaApp, TonnetzApp, ArmoniaCLI, ArmoniaEjemplo, ArmoniaRendimiento ──► Armonia
ArmoniaCLI ──► HexaphonosPresentacion (en el paquete HexaphonosUI, sin SwiftUI) ──► Armonia
```

Un paquete solo depende de los que tiene debajo, y nunca de una app. La línea de comandos (`ArmoniaCLI`),
el ejemplo (`ArmoniaEjemplo`) y la medida del rendimiento (`ArmoniaRendimiento`) se construyen con SwiftPM; las apps de SwiftUI, con Xcode (`project.yml`).
`Scripts/comprobar_dependencias.py` lo comprueba (también en el CI).

El paquete, su producto principal y su módulo paraguas se llaman `Armonia`: en el código es
`import Armonia`, y en un `Package.swift` es `.product(name: "Armonia", package: "Armonia")`.
Cada módulo del motor es también un producto (`ArmoniaNucleo`, `ArmoniaTeoria`, `ArmoniaTrastes`…), por si un paquete necesita solo uno.

## Usar los paquetes en otro proyecto

```swift
dependencies: [
    .package(url: "https://github.com/rododendro1/Hexaphonos.git", branch: "main"),
],
targets: [
    .target(name: "MiApp", dependencies: [
        .product(name: "Armonia", package: "Hexaphonos"),     // o ArmoniaTeoria, Hexagonos, HexaphonosUI…
    ]),
]
```

Todavía no hay versiones con etiqueta, así que se sigue la rama `main`. Los cambios de cada paquete están en su
`CHANGELOG.md`; mientras no haya versiones, un cambio puede quitar lo que uno anterior marcó
como obsoleto.

## Empezar

```sh
# Los paquetes, desde su carpeta
cd Packages/Armonia && swift test
cd Packages/Hexagonos && swift test      # las rejillas hexagonales
swift run --package-path Apps/ArmoniaCLI armonia acorde Sol7/Si  # la herramienta de línea de comandos
swift run --package-path Apps/ArmoniaCLI armonia digitaciones Sol7/Si --instrumento ukelele --diagrama
swift run --package-path Ejemplos/ArmoniaEjemplo ArmoniaEjemplo      # el ejemplo
swift run -c release --package-path Herramientas/ArmoniaRendimiento ArmoniaRendimiento   # los tiempos del motor

# Las apps (macOS, con XcodeGen)
brew install xcodegen
cp Config/Local.xcconfig.ejemplo Config/Local.xcconfig   # tu equipo de firma y el prefijo de identificadores
./Scripts/generar_proyecto.sh        # crea Hexaphonos.xcodeproj
open Hexaphonos.xcodeproj     # elige el esquema ArmoniaApp o TonnetzApp
```

`HexaphonosUI` usa SwiftUI para dibujar, pero su lógica (notación, qué trastes y qué notas enseña el mástil,
qué muestran el análisis, el coral y las redes, y los ficheros que se exportan) no: esa parte
compila y se prueba también en Linux, y la de interfaz queda tras `#if canImport(SwiftUI)`. El dibujo y las apps se
construyen en macOS.

## Rendimiento

`Herramientas/ArmoniaRendimiento` mide, compilado con optimización, lo que hacen las apps y la línea de comandos:
leer y escribir cifrados, identificar acordes y escalas, analizar, armonizar y realizar a cuatro voces (con
sucesiones de varias longitudes, para ver cómo crece el tiempo), digitaciones, dibujos y partituras. Escribe una
tabla en Markdown con la primera vez (que paga lo que el motor prepara una sola vez), la mediana y el mínimo.

```sh
cd Herramientas/ArmoniaRendimiento
swift run -c release ArmoniaRendimiento --json antes.json        # guarda los tiempos
# … un cambio en el motor …
swift run -c release ArmoniaRendimiento --comparar antes.json    # y los compara
swift run -c release ArmoniaRendimiento --filtro armonizar       # solo unos casos
```

El CI la ejecuta en cada cambio y deja la tabla en el resumen de la ejecución y los tiempos en el artefacto
`rendimiento`; no falla por lentitud, porque sus máquinas varían demasiado para fijar límites.

## Añadir un paquete o una app

1. Crea la carpeta en `Packages/` (con el mismo nombre que el paquete) o en `Apps/`.
2. Un paquete se añade a `PERMITIDO` en `Scripts/comprobar_dependencias.py`, con los paquetes de los que puede depender,
   y sus módulos y bibliotecas al `Package.swift` de la raíz (el script avisa si no coinciden).
3. Una app de SwiftUI, además, en `project.yml` (un `target` y su `scheme`); un paquete, en `packages:`. Una app de
   SwiftPM solo necesita su `Package.swift`, con dependencias por ruta a `Packages/`.
4. Añade su job a `.github/workflows/ci.yml`.

## Estado

Todo compila y pasa las pruebas en el CI: el motor en Linux (Swift 5.9 y 6.2) y en macOS, `HexaphonosUI`, `Hexagonos`, la línea de
comandos, el ejemplo, las dos apps en macOS y en el simulador de iOS, y la documentación de DocC, sin enlaces sin
resolver. `./Scripts/compilar_todo.sh` hace lo mismo en una máquina con Swift, por capas y con un log por paso.

El código se publica con licencia MIT (`LICENSE`). Las dos apps llevan un icono provisional en
`Apps/<App>/Assets.xcassets/AppIcon.appiconset`, que conviene sustituir por uno definitivo antes de publicarlas.
El equipo de firma y el prefijo de los identificadores no se guardan en el repositorio: cada cual los pone en
su `Config/Local.xcconfig`.
