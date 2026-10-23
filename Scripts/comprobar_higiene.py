#!/usr/bin/env python3
"""Comprobaciones baratas de higiene sobre los ficheros de texto del repositorio.

  - Sin caracteres invisibles (guion blando, espacios de ancho cero, BOM): en un identificador de Swift
    no se ven y rompen la compilación o el nombre de una prueba.
  - Sin tabuladores ni espacios al final de línea en el código (.swift, .py, .sh, .yml, .yaml).
  - Los ficheros acaban en un único salto de línea.
  - Los scripts con shebang son ejecutables y los .py compilan.
  - En Swift, un `guard let x` no redeclara un `let x` / `var x` del mismo ámbito (el compilador lo rechaza:
    un `guard let` declara en el ámbito que lo contiene). Es un error que se cuela fácil al escribir sin compilar.

No sustituye a un formateador: es lo que se puede comprobar sin instalar nada.
Uso: python3 Scripts/comprobar_higiene.py
"""
import os
import py_compile
import re
import subprocess
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
INVISIBLES = {0x00AD: "guion blando", 0x200B: "espacio de ancho cero", 0x200C: "separador de ancho cero",
              0x200D: "unión de ancho cero", 0x2060: "unión de palabras", 0xFEFF: "BOM / espacio sin ancho"}
CODIGO = {".swift", ".py", ".sh", ".yml", ".yaml", ".xcconfig"}
TEXTO = CODIGO | {".md", ".txt", ".json"}
SALTAR = {".git", ".build", ".swiftpm", "DerivedData", "build", "node_modules"}


def ficheros():
    try:
        salida = subprocess.run(["git", "ls-files"], cwd=RAIZ, capture_output=True, text=True, check=True).stdout
        rutas = [RAIZ / r for r in salida.splitlines()]
    except (OSError, subprocess.CalledProcessError):
        rutas = [r for r in RAIZ.rglob("*") if r.is_file() and not (set(r.relative_to(RAIZ).parts) & SALTAR)]
    return sorted(r for r in rutas if r.is_file() and (r.suffix in TEXTO or r.name == ".gitignore"))


def guard_que_redeclara(lineas):
    """(línea del guard, nombre, línea de la declaración) de cada `guard let x` que repite un `let/var x` hermano."""
    for i, linea in enumerate(lineas):
        m = re.match(r"^(\s*)guard\s+(.*)", linea)
        if not m:
            continue
        sangria = len(m.group(1))
        nombres = set(re.findall(r"\blet\s+([A-Za-z_]\w*)\b", m.group(2)))
        for j in range(i - 1, -1, -1):
            anterior = lineas[j]
            if not anterior.strip():
                continue
            sangria_j = len(anterior) - len(anterior.lstrip())
            if sangria_j < sangria:          # salimos del ámbito
                break
            if sangria_j == sangria:
                d = re.match(r"^\s*(?:let|var)\s+([A-Za-z_]\w*)\b", anterior)
                if d and d.group(1) in nombres:
                    yield i + 1, d.group(1), j + 1


problemas = []
for ruta in ficheros():
    rel = ruta.relative_to(RAIZ)
    try:
        texto = ruta.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        problemas.append(f"{rel}: no es UTF-8")
        continue
    for n, linea in enumerate(texto.split("\n"), 1):
        for c in linea:
            if ord(c) in INVISIBLES:
                problemas.append(f"{rel}:{n}: {INVISIBLES[ord(c)]} (U+{ord(c):04X})")
        if ruta.suffix in CODIGO:
            if "\t" in linea:
                problemas.append(f"{rel}:{n}: tabulador")
            if linea != linea.rstrip(" "):
                problemas.append(f"{rel}:{n}: espacios al final de la línea")
    if ruta.suffix == ".swift":
        for n, nombre, declarada in guard_que_redeclara(texto.split("\n")):
            problemas.append(f"{rel}:{n}: `guard let {nombre}` redeclara la variable de la línea {declarada} (mismo ámbito)")
    if texto and (not texto.endswith("\n") or texto.endswith("\n\n")):
        problemas.append(f"{rel}: tiene que acabar en un único salto de línea")
    if texto.startswith("#!") and not os.access(ruta, os.X_OK):
        problemas.append(f"{rel}: tiene shebang pero no es ejecutable (chmod +x)")
    if ruta.suffix == ".py":
        try:
            py_compile.compile(str(ruta), cfile=os.path.join(tempfile.gettempdir(), "higiene.pyc"), doraise=True)
        except py_compile.PyCompileError as error:
            problemas.append(f"{rel}: no compila: {error.msg.strip()}")

if problemas:
    print("\n".join(problemas[:60]))
    if len(problemas) > 60:
        print(f"… y {len(problemas) - 60} más")
    print(f"{len(problemas)} problema(s) de higiene.")
    sys.exit(1)
print(f"Higiene correcta ({len(ficheros())} ficheros).")
