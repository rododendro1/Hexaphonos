# Hexaphonos

Ecosistema de apps y paquetes de música en Swift. El motor de armonía (`Armonia`) es la base;
encima hay paquetes para el mástil de los instrumentos de cuerda y para la interfaz, y dos apps de
SwiftUI para iOS y macOS.

```
Apps/
├── ArmoniaApp/       Acordes (con digitaciones), escalas (con el mástil) y análisis armónico
├── TonnetzApp/       El Tonnetz de un acorde o una escala, y recorridos con P, L y R
└── ArmoniaCLI/       La herramienta `armonia`, con sus pruebas (SwiftPM)
Ejemplos/
└── ArmoniaEjemplo/   Un recorrido por la API del motor, ejecutable (SwiftPM)
Packages/
├── Armonia/        El motor de armonía, en cinco módulos (Nucleo, Teoria, Representaciones, Partitura, Trastes)
│                   y el paraguas `Armonia`: notas, acordes, escalas, tonalidad, Tonnetz, MusicXML, MIDI,
│                   y los mástiles, afinaciones y digitaciones de acordes (guitarra, bajo, ukelele…)
├── HexaphonosUI/   Componentes SwiftUI (DiagramaDeMastil, DiagramaDeTonnetz, DiagramaHexagonal, VistaSVG, tema) y lo que comparten las apps:
│                   el selector de notación y su ajuste
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
ArmoniaApp, TonnetzApp, ArmoniaCLI, ArmoniaEjemplo ──► Armonia
```

Un paquete solo depende de los que tiene debajo, y nunca de una app. La línea de comandos (`ArmoniaCLI`) y
el ejemplo (`ArmoniaEjemplo`) se construyen con SwiftPM; las apps de SwiftUI, con Xcode (`project.yml`).
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
swift run --package-path Apps/ArmoniaCLI armonia digitaciones Sol7/Si --instrumento ukelele --tab
swift run --package-path Ejemplos/ArmoniaEjemplo ArmoniaEjemplo      # el ejemplo

# Las apps (macOS, con XcodeGen)
brew install xcodegen
cp Config/Local.xcconfig.ejemplo Config/Local.xcconfig   # tu equipo de firma y el prefijo de identificadores
./Scripts/generar_proyecto.sh        # crea Hexaphonos.xcodeproj
open Hexaphonos.xcodeproj     # elige el esquema ArmoniaApp o TonnetzApp
```

`HexaphonosUI` usa SwiftUI para dibujar, pero su lógica (notación, qué trastes y qué notas enseña el mástil) no: esa parte
compila y se prueba también en Linux, y la de interfaz queda tras `#if canImport(SwiftUI)`. El dibujo y las apps se
construyen en macOS.

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
