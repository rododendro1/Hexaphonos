#!/usr/bin/env python3
"""Comprueba, sin compilar, que los enlaces de la documentación DocC apuntan a algo que existe.

DocC solo avisa de un enlace roto al construir la documentación (en macOS). Este script atrapa lo más
frecuente sin necesidad de Swift:

  - ``Tipo`` y ``Tipo/miembro``: el tipo tiene que estar declarado en algún módulo y el miembro
    (func, var, let, case, init, subscript) en alguna parte del código.
  - <doc:Articulo>: tiene que existir Articulo.md en el catálogo.

No sustituye a DocC (no resuelve sobrecargas ni comprueba que el símbolo sea público): es un filtro barato.
Uso: python3 Scripts/comprobar_enlaces_docc.py
"""
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent / "Packages" / "Armonia"
FUENTES = RAIZ / "Sources"
CATALOGOS = sorted(FUENTES.glob("*/*.docc"))

DECLARACION_DE_TIPO = re.compile(r"\b(?:struct|enum|class|actor|protocol|typealias)\s+([A-Za-z_]\w*)")


def declarado(codigo: str):
    tipos = set(DECLARACION_DE_TIPO.findall(codigo))
    miembros = set(re.findall(r"\b(?:func|var|let|typealias|associatedtype)\s+([A-Za-z_]\w*)", codigo))
    for caso in re.findall(r"\bcase\s+([^\n:{]+)", codigo):
        for nombre in re.findall(r"[A-Za-z_]\w*", caso.split("(")[0] if "," not in caso else caso):
            miembros.add(nombre)
    if re.search(r"\binit[?!]?\s*[(<]", codigo):
        miembros.add("init")
    if re.search(r"\bsubscript\b", codigo):
        miembros.add("subscript")
    return tipos, miembros


codigo = "\n".join(f.read_text(encoding="utf-8") for f in FUENTES.rglob("*.swift"))
tipos, miembros = declarado(codigo)
modulos = {d.name for d in FUENTES.iterdir() if d.is_dir()}

errores = 0
enlaces = 0
for catalogo in CATALOGOS:
    articulos = {f.stem for f in catalogo.glob("*.md")}
    modulo = catalogo.parent.name
    for md in sorted(catalogo.rglob("*.md")):
        texto = md.read_text(encoding="utf-8")
        # Los bloques de código no llevan enlaces.
        sin_codigo = re.sub(r"```[\s\S]*?```", "", texto)
        for numero, linea in enumerate(sin_codigo.splitlines(), 1):
            for ruta in re.findall(r"``([^`\n]+)``", linea):
                enlaces += 1
                partes = [p for p in ruta.split("/") if p]
                if partes and partes[0] in modulos | {modulo}:
                    partes = partes[1:]            # ``Modulo/Tipo`` o ``Modulo``
                if not partes:
                    continue
                tipo = partes[0]
                if tipo not in tipos:
                    print(f"{md.relative_to(RAIZ)}: ``{ruta}``: no hay ningún tipo «{tipo}»")
                    errores += 1
                    continue
                for miembro in partes[1:]:
                    nombre = re.split(r"[(\-]", miembro)[0]
                    if nombre and nombre not in miembros and nombre not in tipos:
                        print(f"{md.relative_to(RAIZ)}: ``{ruta}``: no hay ningún miembro «{nombre}»")
                        errores += 1
            for destino in re.findall(r"<doc:([^>#\s]+)", linea):
                enlaces += 1
                if destino not in articulos:
                    print(f"{md.relative_to(RAIZ)}: <doc:{destino}>: no hay un artículo con ese nombre")
                    errores += 1

print(f"{enlaces} enlaces revisados en {len(CATALOGOS)} catálogo(s).")
if errores:
    print(f"{errores} enlace(s) roto(s).")
    sys.exit(1)
print("Enlaces de DocC correctos.")
