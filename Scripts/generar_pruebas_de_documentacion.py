#!/usr/bin/env python3
"""Convierte los ejemplos de código del README y del catálogo DocC en pruebas.

Cada bloque ```swift se convierte en una función de prueba que se compila y se ejecuta:
así un ejemplo que deja de compilar, o que se detiene, rompe las pruebas. Además, cuando una
línea es una sola expresión con un comentario detrás (`Nota.re + "3M"   // Fa♯`), se comprueba
que el valor escrito coincide con el principio del comentario. El comentario puede seguir con
una explicación tras dos espacios, un paréntesis, dos puntos o un punto y coma:
`// Do+   (no La♭+/Do)`, `// 29 (Dhīraśaṅkarābharaṇam)`, `// nil: no existe…`.

Un nombre que empieza por minúscula se compara si va entre comillas latinas:
`// «negra con puntillo»`.

Para que un comentario sea solo una explicación y no se compare, empieza por una minúscula
que no sea un valor (`// baja con Sol♮ y Fa♮`) o con `…`.

Uso:
    python3 Scripts/generar_pruebas_de_documentacion.py              # regenera las pruebas
    python3 Scripts/generar_pruebas_de_documentacion.py --comprobar  # falla si están desfasadas
"""
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent / "Packages" / "Armonia"
FUENTES = [RAIZ / "README.md"] + sorted((RAIZ / "Sources/Armonia/Armonia.docc").glob("*.md"))
DESTINO = RAIZ / "Tests/ArmoniaDocumentacionTests/EjemplosDeDocumentacionTests.swift"

# Variables que los ejemplos usan sin declarar (vienen del texto que los rodea).
PRELUDIOS = {
    "entrada": 'let entrada = "Sol7"',
    "melodia": "let melodia = [69, 71, 72, 74, 76, 77, 80, 81]",
}

INICIOS_DE_SENTENCIA = ("let ", "var ", "func ", "import ", "do ", "do{", "}", "{", "print(", "return ",
                        "if ", "for ", "guard ")


def bloques(ruta):
    """(línea de inicio, [líneas]) de cada bloque swift del fichero."""
    dentro, inicio, actual = False, 0, []
    for n, linea in enumerate(ruta.read_text(encoding="utf-8").split("\n"), start=1):
        if linea.strip().startswith("```"):
            if dentro:
                yield inicio, actual
                dentro = False
            elif linea.strip() == "```swift":
                dentro, inicio, actual = True, n + 1, []
            continue
        if dentro:
            actual.append(linea)


def separar_comentario(linea):
    """Separa `código // comentario`, sin confundir `//` dentro de una cadena."""
    en_cadena = False
    i = 0
    while i < len(linea):
        c = linea[i]
        if c == "\\" and en_cadena:
            i += 2
            continue
        if c == '"':
            en_cadena = not en_cadena
        elif not en_cadena and linea.startswith("//", i):
            return linea[:i].rstrip(), linea[i + 2:].strip()
        i += 1
    return linea.rstrip(), None


def coma_de_nivel_superior(codigo):
    """¿Hay una coma fuera de paréntesis, corchetes y cadenas? (`a.tercera, a.quinta`)"""
    nivel, en_cadena = 0, False
    for c in codigo:
        if c == '"':
            en_cadena = not en_cadena
        elif not en_cadena:
            if c in "([{":
                nivel += 1
            elif c in ")]}":
                nivel -= 1
            elif c == "," and nivel == 0:
                return True
    return False


def valor_esperado(comentario):
    """La parte del comentario que es un valor, o None si es solo una explicación."""
    if not comentario or comentario.startswith("…"):
        return None
    if comentario.startswith("«"):  # un nombre en prosa: se compara lo que hay dentro de «…»
        cierre = comentario.find("»")
        return comentario[1:cierre] if cierre > 0 else None
    if comentario.startswith("."):  # un valor de Swift, con sus argumentos: `.dominanteSecundaria(de: 5)`
        return re.match(r"\.[\w.]+(\([^)]*\))?", comentario).group(0)
    if comentario.startswith('"'):  # una cadena, entera aunque lleve paréntesis o espacios
        cierre = comentario.find('"', 1)
        return comentario[: cierre + 1] if cierre > 0 else None
    valor = re.split(r"\s{2,}|\s\(|:\s|;\s| — ", comentario, maxsplit=1)[0].strip()
    # Una explicación en prosa: empieza por minúscula y no es un valor reconocible.
    if re.match(r"^[a-záéíóúñ]", valor) and not re.match(r"^(nil|true|false|[a-z]+\()", valor):
        return None
    return valor or None


def usos(nombre, codigo):
    """Veces que aparece `nombre` como variable: ni `x.nombre` ni la etiqueta `f(nombre: …)`."""
    todas = len(re.findall(rf"(?<![.\w]){nombre}\b", codigo))
    etiquetas = len(re.findall(rf"(?<![.\w]){nombre}:", codigo)) - len(re.findall(rf"\b(?:let|var) {nombre}:", codigo))
    return todas - etiquetas


def literal_swift(texto):
    """Cadena sin escapes de Swift, con tantos # como hagan falta para que no se cierre antes."""
    almohadillas = "#"
    while f'"{almohadillas}' in texto:
        almohadillas += "#"
    return f'{almohadillas}"{texto}"{almohadillas}'


def comprobacion(expresion, esperado, fichero, linea):
    """`// .mayor` y `// == .menorNatural` se comparan como valores de Swift; lo demás, como texto."""
    if esperado.startswith("== "):
        esperado = esperado[3:]
    if esperado.startswith("."):
        return f"comprobarIgual({expresion}, {esperado}, {literal_swift(fichero)}, {linea})"
    return f"comprobar({expresion}, {literal_swift(esperado)}, {literal_swift(fichero)}, {linea})"


def generar():
    funciones = []
    for ruta in FUENTES:
        nombre_fichero = ruta.relative_to(RAIZ).as_posix()
        base = re.sub(r"\W", "", ruta.stem)
        for indice, (inicio, lineas) in enumerate(bloques(ruta), start=1):
            texto = "\n".join(lineas)
            # Solo el código, sin comentarios ni cadenas, para buscar qué nombres se usan.
            codigo_solo = "\n".join(re.sub(r'"[^"]*"', '""', separar_comentario(l)[0]) for l in lineas)
            cuerpo = [f"        // {nombre_fichero}, línea {inicio}"]
            for variable, declaracion in PRELUDIOS.items():
                if usos(variable, codigo_solo) and not re.search(rf"\blet {variable}\b", texto):
                    cuerpo.append(f"        {declaracion}")
            pendiente = None  # expresión cuyo valor está en la línea siguiente (`// [...]`)
            for desplazamiento, linea in enumerate(lineas):
                numero = inicio + desplazamiento
                sangria = linea[: len(linea) - len(linea.lstrip())]
                codigo, comentario = separar_comentario(linea.strip())
                if not codigo:
                    if comentario and pendiente and valor_esperado(comentario):
                        expresion, n = pendiente
                        cuerpo[-1] = f"        {sangria}{comprobacion(expresion, valor_esperado(comentario), nombre_fichero, n)}"
                    pendiente = None
                    continue
                pendiente = None
                if codigo.startswith("import "):
                    continue
                if codigo.startswith(INICIOS_DE_SENTENCIA) or codigo.endswith("{") or "catch" in codigo:
                    cuerpo.append(f"        {sangria}{codigo}")
                    continue
                # Una expresión suelta: se evalúa y, si el comentario es un valor, se compara.
                partes = [p.strip() for p in re.split(r";\s+", codigo)]
                if len(partes) > 1 or coma_de_nivel_superior(codigo):
                    cuerpo.append(f"        {sangria}_ = ({codigo})")
                    continue
                esperado = valor_esperado(comentario)
                if esperado is not None:
                    cuerpo.append(f"        {sangria}{comprobacion(codigo, esperado, nombre_fichero, numero)}")
                else:
                    cuerpo.append(f"        {sangria}_ = {codigo}")
                    pendiente = (codigo, numero)
            # Las constantes que el ejemplo declara y no vuelve a usar se marcan como usadas,
            # para que el compilador no avise.
            sin_usar = [v for v in re.findall(r"^(?:let|var) (\w+)", codigo_solo, re.M)
                        + re.findall(r";\s+(?:let|var) (\w+)", codigo_solo)
                        if usos(v, codigo_solo) == 1]
            if sin_usar:
                cuerpo.append(f"        _ = {sin_usar[0]}" if len(sin_usar) == 1 else f"        _ = ({', '.join(sin_usar)})")
            nombre = f"test{base}{indice}"
            funciones.append(f"    func {nombre}() throws {{\n" + "\n".join(cuerpo) + "\n    }")
    return CABECERA + "\n\n".join(funciones) + "\n}\n"


CABECERA = '''// Generado por Scripts/generar_pruebas_de_documentacion.py a partir de los bloques ```swift
// del README y del catálogo DocC. No lo edites a mano: cambia el ejemplo y vuelve a generarlo.

import Foundation
import XCTest
@testable import Armonia
import Hexagonos

final class EjemplosDeDocumentacionTests: XCTestCase {
'''


def main():
    contenido = generar()
    if "--comprobar" in sys.argv:
        actual = DESTINO.read_text(encoding="utf-8") if DESTINO.exists() else ""
        if actual != contenido:
            print(f"{DESTINO.relative_to(RAIZ)} está desfasado: ejecuta Scripts/generar_pruebas_de_documentacion.py")
            sys.exit(1)
        return
    DESTINO.parent.mkdir(parents=True, exist_ok=True)
    DESTINO.write_text(contenido, encoding="utf-8")


if __name__ == "__main__":
    main()
