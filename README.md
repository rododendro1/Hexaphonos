# SepirizHexaphonos

Ecosistema de apps y paquetes de música en Swift. El motor de armonía (`Armonia`) es la base;
encima hay paquetes para el mástil de los instrumentos de cuerda y para la interfaz, y dos apps de
SwiftUI para iOS y macOS.

```
Apps/
├── ArmoniaApp/       Acordes (con digitaciones), escalas (con el mástil) y análisis armónico
├── TonnetzApp/       El Tonnetz de un acorde o una escala, y recorridos con P, L y R
├── ArmoniaCLI/       La herramienta `armonia`, con sus pruebas (SwiftPM)
└── ArmoniaEjemplo/   Un recorrido por la API del motor, ejecutable (SwiftPM)
Packages/
├── Armonia/        El motor de armonía, en cinco módulos (Nucleo, Teoria, Representaciones, Partitura, Trastes)
│                   y el paraguas `Armonia`: notas, acordes, escalas, tonalidad, Tonnetz, MusicXML, MIDI,
│                   y los mástiles, afinaciones y digitaciones de acordes (guitarra, bajo, ukelele…)
└── SepirizUI/      Componentes SwiftUI (MastilView, TonnetzView, SVGView, tema) y lo que comparten las apps:
                    el selector de notación y su ajuste
Scripts/            Comprobaciones del repositorio y generación del proyecto de Xcode
Config/             Ajustes de compilación de las apps (Local.xcconfig, el de tu equipo, no se guarda en git)
project.yml         Definición del proyecto de Xcode (XcodeGen)
```

## Dependencias

```
ArmoniaApp ──┬──► SepirizUI ──► Armonia
TonnetzApp ──┘
ArmoniaApp, TonnetzApp, ArmoniaCLI, ArmoniaEjemplo ──► Armonia
```

Un paquete solo depende de los que tiene debajo, y nunca de una app. Las apps con `Package.swift`
(`ArmoniaCLI`, `ArmoniaEjemplo`) se construyen con SwiftPM; las de SwiftUI, con Xcode (`project.yml`).
`Scripts/comprobar_dependencias.py` lo comprueba (también en el CI).

El paquete, su producto principal y su módulo paraguas se llaman `Armonia`: en el código es
`import Armonia`, y en un `Package.swift` es `.product(name: "Armonia", package: "Armonia")`.
Cada módulo del motor es también un producto (`ArmoniaNucleo`, `ArmoniaTeoria`, `ArmoniaTrastes`…), por si un paquete necesita solo uno.

## Empezar

```sh
# Los paquetes, desde su carpeta
cd Packages/Armonia && swift test
swift run --package-path Apps/ArmoniaCLI armonia acorde Sol7/Si  # la herramienta de línea de comandos
swift run --package-path Apps/ArmoniaCLI armonia digitaciones Sol7/Si --instrumento ukelele --tab
swift run --package-path Apps/ArmoniaEjemplo ArmoniaEjemplo      # el ejemplo

# Las apps (macOS, con XcodeGen)
brew install xcodegen
cp Config/Local.xcconfig.ejemplo Config/Local.xcconfig   # tu equipo de firma y el prefijo de identificadores
./Scripts/generar_proyecto.sh        # crea SepirizHexaphonos.xcodeproj
open SepirizHexaphonos.xcodeproj     # elige el esquema ArmoniaApp o TonnetzApp
```

`SepirizUI` usa SwiftUI para dibujar, pero su lógica (notación, qué trastes y qué notas enseña el mástil) no: esa parte
compila y se prueba también en Linux, y la de interfaz queda tras `#if canImport(SwiftUI)`. El dibujo y las apps se
construyen en macOS.

## Añadir un paquete o una app

1. Crea la carpeta en `Packages/` (con el mismo nombre que el paquete) o en `Apps/`.
2. Un paquete se añade a `PERMITIDO` en `Scripts/comprobar_dependencias.py`, con los paquetes de los que puede depender.
3. Una app de SwiftUI, además, en `project.yml` (un `target` y su `scheme`); un paquete, en `packages:`. Una app de
   SwiftPM solo necesita su `Package.swift`, con dependencias por ruta a `Packages/`.
4. Añade su job a `.github/workflows/ci.yml`.

## Estado

Todo lo que se puede comprobar sin compilador está comprobado: `Scripts/` (dependencias, módulos, catálogo de
escalas, enlaces de DocC, ejemplos de la documentación, higiene del código) y un port a Python de la búsqueda de
digitaciones. Pero el código de Swift **no se ha compilado todavía**, ni se han ejecutado las pruebas. El primer paso
es `./Scripts/compilar_todo.sh` en una máquina con Swift (o subirlo y mirar el CI): compila y prueba por capas, en el
orden en que conviene arreglar los errores, guarda un log por paso y resume los `error:`. Es probable que salgan
algunos errores de compilación, sobre todo en SwiftUI.

El job `documentacion` del CI no bloquea todavía: el catálogo de DocC cuelga del módulo paraguas `Armonia`, que solo
reexporta los demás, y puede que DocC no resuelva sus símbolos. Cuando el job salga limpio, se le quita
`continue-on-error`.

El código se publica con licencia MIT (`LICENSE`). Las dos apps llevan un icono provisional en
`Apps/<App>/Assets.xcassets/AppIcon.appiconset`, que conviene sustituir por uno definitivo antes de publicarlas.
El equipo de firma y el prefijo de los identificadores no se guardan en el repositorio: cada cual los pone en
su `Config/Local.xcconfig`.
