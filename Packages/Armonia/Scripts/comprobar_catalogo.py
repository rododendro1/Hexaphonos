#!/usr/bin/env python3
"""Comprueba que el catálogo de escalas no se ha descuadrado.

Una escala tipo `TipoDeEscala` se declara en un sitio, pero hay que apuntarla en otros dos a mano:
la lista donde se busca (`todos` o la de su tradición, que `tradicionales` reúne) y, para las de
`todos`, la tabla `internacionales` con su nombre inglés. Si se olvida una, el compilador no
avisa: la escala existe pero `buscar(nombre:)` no la encuentra, o su nombre inglés cae al español.

Comprueba:
  1. toda `public static let x = TipoDeEscala(…)` está en `todos` o en una lista de tradición;
  2. ninguna lista nombra dos veces la misma escala;
  3. toda escala de `todos` tiene entrada en `internacionales`, y esa tabla no nombra escalas
     que no estén en `todos`.

Uso:  python3 Scripts/comprobar_catalogo.py      (sale con 1 si hay algún problema)
Es una lectura del texto, no del compilador: se limita al estilo con que está escrito el catálogo.
"""
import collections
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent / "Sources" / "ArmoniaTeoria" / "Escalas"
FICHEROS = sorted(RAIZ.rglob("*.swift"))
TEXTO = {f: re.sub(r"//.*", "", f.read_text(encoding="utf-8")) for f in FICHEROS}


def cuerpo_de_lista(nombre):
    """Texto entre corchetes de `public static let nombre: [TipoDeEscala] = [ … ]`."""
    for texto in TEXTO.values():
        m = re.search(r"public static let " + nombre + r"\b[^=\n]*=\s*\[", texto)
        if m:
            i, nivel, j = m.end(), 1, m.end()
            while nivel:
                nivel += (texto[j] == "[") - (texto[j] == "]")
                j += 1
            return texto[i:j - 1]
    return None


definidas = {}
listas = set()
for f, texto in TEXTO.items():
    for m in re.finditer(r"public static let (`?\w+`?)\s*(?::\s*\[TipoDeEscala\])?\s*=\s*(\[|TipoDeEscala\()", texto):
        nombre = m.group(1).strip("`")
        if m.group(2) == "[":
            listas.add(nombre)
        else:
            definidas[nombre] = f.name

errores = []
todos = re.findall(r"\.(\w+)", cuerpo_de_lista("todos") or "")
if not todos:
    sys.exit("No encuentro la lista `todos`: ¿cambió el estilo del catálogo?")

nombradas = set(todos)
for lista in sorted(listas - {"todos", "tradicionales"}):
    elementos = re.findall(r"\.(\w+)", cuerpo_de_lista(lista) or "")
    nombradas |= set(elementos)
    for n, veces in collections.Counter(elementos).items():
        if veces > 1:
            errores.append(f"`{lista}` nombra {n} {veces} veces")
for n, veces in collections.Counter(todos).items():
    if veces > 1:
        errores.append(f"`todos` nombra {n} {veces} veces")

for n, fichero in sorted(definidas.items()):
    if n not in nombradas:
        errores.append(f"{n} ({fichero}) no está en `todos` ni en ninguna lista de tradición: no se podrá buscar")

internacionales = "".join(t for t in TEXTO.values() if "static let internacionales" in t)
con_ingles = set(re.findall(r"^\s*\(\.(\w+),\s*\[", internacionales, re.M))
for n in todos:
    if n not in con_ingles:
        errores.append(f"{n} está en `todos` pero no en `internacionales`: su nombre inglés será el español")
for n in sorted(con_ingles - set(todos)):
    errores.append(f"`internacionales` nombra {n}, que no está en `todos`")

print(f"{len(definidas)} escalas declaradas, {len(todos)} en `todos`, {len(listas) - 2} listas de tradición")
if errores:
    print(f"{len(errores)} problema(s):")
    for e in errores:
        print("  -", e)
    sys.exit(1)
print("Catálogo coherente.")
