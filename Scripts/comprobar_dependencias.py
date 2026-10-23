#!/usr/bin/env python3
"""Comprueba el grafo de dependencias del ecosistema.

Reglas:
  1. Cada paquete de `Packages/` se llama como su carpeta (SwiftPM identifica los paquetes locales
     por el nombre de la carpeta, y `.product(package:)` debe coincidir).
  2. Un paquete solo depende de los que están en PERMITIDO, y de ninguna app.
  3. Los paquetes y las apps nombran en `project.yml` solo paquetes que existen; las apps de SwiftPM
     (`Apps/*/Package.swift`) y los ejemplos (`Ejemplos/*/Package.swift`) dependen solo de paquetes
     de `Packages/`.
  4. No hay ciclos (se deduce de 2: PERMITIDO es un orden).

Uso:  python3 Scripts/comprobar_dependencias.py     (sale con 1 si hay un problema)
"""
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PAQUETES = RAIZ / "Packages"

# De más básico a más alto: cada paquete solo puede depender de los anteriores que se listan.
PERMITIDO = {
    "Armonia": set(),
    "HexaphonosUI": {"Armonia"},
}

errores = []
carpetas = sorted(p.name for p in PAQUETES.iterdir() if (p / "Package.swift").exists())

for esperado in PERMITIDO:
    if esperado not in carpetas:
        errores.append(f"Falta el paquete {esperado} en Packages/")
for carpeta in carpetas:
    if carpeta not in PERMITIDO:
        errores.append(f"Packages/{carpeta} no está en PERMITIDO: añádelo con sus dependencias")

for carpeta in carpetas:
    texto = (PAQUETES / carpeta / "Package.swift").read_text(encoding="utf-8")
    texto = re.sub(r"//.*", "", texto)
    nombre = re.search(r'Package\(\s*name:\s*"([^"]+)"', texto)
    if not nombre or nombre.group(1) != carpeta:
        errores.append(f"{carpeta}: el nombre del paquete ({nombre.group(1) if nombre else '?'}) no coincide con la carpeta")
    dependencias = set()
    for ruta in re.findall(r'\.package\(\s*path:\s*"([^"]+)"', texto):
        destino = (PAQUETES / carpeta / ruta).resolve()
        if destino.parent != PAQUETES.resolve():
            errores.append(f"{carpeta}: depende de {ruta}, que no está en Packages/")
        else:
            dependencias.add(destino.name)
    sobran = dependencias - PERMITIDO.get(carpeta, set())
    for d in sorted(sobran):
        errores.append(f"{carpeta} no puede depender de {d}")
    productos = set(re.findall(r'\.product\(\s*name:\s*"[^"]+",\s*package:\s*"([^"]+)"', texto))
    for p in sorted(productos - dependencias):
        errores.append(f"{carpeta}: usa un producto de {p} sin declarar la dependencia")

proyecto = (RAIZ / "project.yml").read_text(encoding="utf-8")
declarados = set(re.findall(r"^  (\w+):\n    path: Packages/(\w+)$", proyecto, re.M))
for nombre, carpeta in sorted(declarados):
    if nombre != carpeta or carpeta not in carpetas:
        errores.append(f"project.yml: el paquete {nombre} apunta a Packages/{carpeta}, que no coincide o no existe")
usados = set(re.findall(r"- package: (\w+)", proyecto))
for u in sorted(usados - {n for n, _ in declarados}):
    errores.append(f"project.yml: una app usa el paquete {u}, que no está declarado")

# Las apps son de dos clases: las de Xcode (SwiftUI, en project.yml) y las de SwiftPM (con Package.swift:
# la línea de comandos). Las de SwiftPM, y los ejemplos de `Ejemplos/`, pueden depender de cualquier paquete
# de Packages/.
apps_swiftpm = []
for app in sorted([*(RAIZ / "Apps").iterdir(), *(RAIZ / "Ejemplos").iterdir()]):
    if not app.is_dir():
        continue
    lugar = f"{app.parent.name}/{app.name}"
    manifiesto = app / "Package.swift"
    if manifiesto.exists():
        apps_swiftpm.append(app.name)
        texto = re.sub(r"//.*", "", manifiesto.read_text(encoding="utf-8"))
        nombre = re.search(r'Package\(\s*name:\s*"([^"]+)"', texto)
        if not nombre or nombre.group(1) != app.name:
            errores.append(f"{lugar}: el nombre del paquete ({nombre.group(1) if nombre else '?'}) no coincide con la carpeta")
        dependencias = set()
        for ruta in re.findall(r'\.package\(\s*path:\s*"([^"]+)"', texto):
            destino = (app / ruta).resolve()
            if destino.parent != PAQUETES.resolve() or destino.name not in PERMITIDO:
                errores.append(f"{lugar}: depende de {ruta}, que no es un paquete de Packages/")
            else:
                dependencias.add(destino.name)
        for p in sorted(set(re.findall(r'\.product\(\s*name:\s*"[^"]+",\s*package:\s*"([^"]+)"', texto)) - dependencias):
            errores.append(f"{lugar}: usa un producto de {p} sin declarar la dependencia")
    elif app.parent.name == "Ejemplos" or not re.search(rf"path: Apps/{app.name}\b", proyecto):
        errores.append(f"{lugar} no tiene Package.swift ni está en project.yml")

print("Paquetes:", ", ".join(carpetas))
print("Apps y ejemplos de SwiftPM:", ", ".join(apps_swiftpm))
if errores:
    print(f"{len(errores)} problema(s):")
    for e in errores:
        print("  -", e)
    sys.exit(1)
print("Dependencias correctas.")
