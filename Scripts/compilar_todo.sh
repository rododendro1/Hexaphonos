#!/bin/sh
# Compila y prueba todo el repositorio por capas, en el orden en que conviene arreglar los errores.
# Es lo que hay que ejecutar la primera vez que se tiene Swift a mano (el repositorio se montó sin
# compilador) y después de cualquier cambio grande.
#
#     ./Scripts/compilar_todo.sh            # todo lo que se pueda en esta máquina
#     ./Scripts/compilar_todo.sh --rapido   # sin las pruebas exhaustivas ni las apps de Xcode
#
# Una capa que falla impide las que dependen de ella (si el núcleo no compila, nada más lo hará), pero las
# independientes se siguen intentando. El log de cada paso queda en `.logs-compilacion/` y, si falla,
# se muestran sus primeros errores. Sale con 0 solo si todo pasó.
set -u
cd "$(dirname "$0")/.."

RAPIDO=0
[ "${1:-}" = "--rapido" ] && RAPIDO=1

LOGS=".logs-compilacion"
rm -rf "$LOGS" && mkdir -p "$LOGS"
FALLOS=""
HECHOS=0
MOTOR_COMPILA=1

# paso <nombre> <carpeta> <comando…>: ejecuta el comando en la carpeta y apunta si falla.
paso() {
    nombre=$1; carpeta=$2; shift 2
    log="$LOGS/$(printf '%s' "$nombre" | tr -c 'A-Za-z0-9' '_').log"
    printf '==> %s\n' "$nombre"
    if (cd "$carpeta" && "$@") >"$log" 2>&1; then
        printf '    ok\n'
        HECHOS=$((HECHOS + 1))
        return 0
    fi
    printf '    FALLA (log: %s)\n' "$log"
    grep -E "error:|Fatal error|XCTAssert.*failed|failed - " "$log" | sed 's/^/      /' | head -15
    FALLOS="$FALLOS\n  - $nombre"
    return 1
}

omitir() { printf '==> %s\n    omitido: %s\n' "$1" "$2"; }

# 0. Comprobaciones de Python: no necesitan Swift.
paso "Comprobaciones (higiene, dependencias, DocC)" . sh -c '
    python3 Scripts/comprobar_higiene.py &&
    python3 Scripts/comprobar_dependencias.py &&
    python3 Scripts/comprobar_modulos.py &&
    python3 Scripts/comprobar_catalogo.py &&
    python3 Scripts/comprobar_enlaces_docc.py &&
    python3 Scripts/generar_pruebas_de_documentacion.py --comprobar'

if ! command -v swift >/dev/null 2>&1; then
    printf '\nNo hay Swift en esta máquina: instala Xcode (macOS) o la cadena de herramientas de swift.org.\n'
    [ -n "$FALLOS" ] && printf 'Fallos:%b\n' "$FALLOS"
    exit 1
fi
swift --version 2>&1 | head -2

# 1. El motor, módulo a módulo y en el orden de sus dependencias: el primer error de verdad suele estar
#    en la capa más baja que falla.
for modulo in ArmoniaNucleo ArmoniaTeoria ArmoniaRepresentaciones ArmoniaPartitura ArmoniaTrastes Armonia; do
    if [ "$MOTOR_COMPILA" = 1 ]; then
        paso "Motor: compilar $modulo" Packages/Armonia swift build --target "$modulo" || MOTOR_COMPILA=0
    else
        omitir "Motor: compilar $modulo" "una capa anterior no compila"
    fi
done

# 2. Las pruebas del motor (compilarlas aparte separa «no compila» de «una prueba falla»).
if [ "$MOTOR_COMPILA" = 1 ]; then
    if paso "Motor: compilar las pruebas" Packages/Armonia swift build --build-tests; then
        paso "Motor: pruebas rápidas" Packages/Armonia swift test --skip-build --parallel --filter '^ArmoniaTests\.'
        paso "Motor: ejemplos de la documentación" Packages/Armonia swift test --skip-build --parallel --filter '^ArmoniaDocumentacionTests\.'
        if [ "$RAPIDO" = 0 ]; then
            paso "Motor: pruebas exhaustivas" Packages/Armonia swift test --skip-build --parallel --filter '^ArmoniaExhaustivasTests\.'
        fi
    fi
else
    omitir "Motor: pruebas" "el motor no compila"
fi

# 3. Lo que depende del motor: la línea de comandos, el ejemplo, la medida del rendimiento y HexaphonosUI.
if [ "$MOTOR_COMPILA" = 1 ]; then
    paso "Línea de comandos: compilar" Apps/ArmoniaCLI swift build &&
        paso "Línea de comandos: pruebas" Apps/ArmoniaCLI swift test --parallel
    paso "Ejemplo: ejecutar" Ejemplos/ArmoniaEjemplo swift run ArmoniaEjemplo
    paso "Rendimiento: compilar" Herramientas/ArmoniaRendimiento swift build
    paso "HexaphonosUI: compilar" Packages/HexaphonosUI swift build &&
        paso "HexaphonosUI: pruebas" Packages/HexaphonosUI swift test --parallel
else
    omitir "Línea de comandos, ejemplo, rendimiento y HexaphonosUI" "el motor no compila"
fi

# 4. Las rejillas hexagonales: no dependen del motor.
paso "Hexagonos: compilar" Packages/Hexagonos swift build &&
    paso "Hexagonos: pruebas" Packages/Hexagonos swift test --parallel

# 5. Las apps de SwiftUI, solo en macOS y con XcodeGen.
if [ "$RAPIDO" = 1 ]; then
    omitir "Apps de Xcode" "--rapido"
elif [ "$(uname)" != "Darwin" ]; then
    omitir "Apps de Xcode" "hace falta macOS"
elif ! command -v xcodegen >/dev/null 2>&1; then
    omitir "Apps de Xcode" "falta XcodeGen (brew install xcodegen)"
elif [ "$MOTOR_COMPILA" = 1 ]; then
    paso "Apps: generar el proyecto" . ./Scripts/generar_proyecto.sh &&
        for esquema in ArmoniaApp TonnetzApp; do
            paso "$esquema (macOS)" . xcodebuild build -project Hexaphonos.xcodeproj -scheme "$esquema" \
                -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
            paso "$esquema (iOS, simulador)" . xcodebuild build -project Hexaphonos.xcodeproj -scheme "$esquema" \
                -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
        done
else
    omitir "Apps de Xcode" "el motor no compila"
fi

printf '\n'
if [ -z "$FALLOS" ]; then
    printf 'Todo en orden (%d pasos).\n' "$HECHOS"
    exit 0
fi
printf 'Fallos (%d pasos bien):%b\n' "$HECHOS" "$FALLOS"
printf 'Los logs completos están en %s/\n' "$LOGS"
exit 1
