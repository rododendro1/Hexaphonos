#!/usr/bin/env python3
"""Comprueba que los módulos de `Sources/` respetan las capas del diseño.

La biblioteca se reparte en cinco módulos, más `Armonia`, que los reexporta:

    ArmoniaNucleo            Fundamentos, Texto, Postonal
    ArmoniaTeoria            Acordes, Escalas, Tonalidad   (se necesitan entre sí: van juntas)
    ArmoniaRepresentaciones  Afinacion, Color, Dibujo, Redes (con Neorriemanniana)
    ArmoniaPartitura         Modelo, Formatos
    ArmoniaTrastes           Encordado, Mastil, Digitacion (instrumentos de cuerda con trastes)
    Armonia                  solo reexporta los cinco (no Hexagonos: quien lo use, lo importa)

Fuera del paquete, Representaciones usa `Hexagonos` (la geometría de las rejillas hexagonales), que no depende
de nada, y `Armonia` lo reexporta junto a los cinco.

Un módulo solo puede usar los de su izquierda: Teoria usa Nucleo; Representaciones, Partitura y Trastes
usan Teoria y Nucleo, y no se usan entre sí. SwiftPM no impide por sí solo importar un módulo que no está
declarado como dependencia si otra ruta lo compila antes, así que se comprueba aquí:

  1. las dependencias declaradas en Package.swift son exactamente las permitidas;
  2. ningún fichero importa un módulo `Armonia*` que no sea una dependencia permitida;
  3. ningún fichero nombra un tipo declarado en un módulo que no puede usar (aproximación por nombre);
  4. `Armonia` reexporta los cinco módulos, y `Sources/Armonia` no tiene más código que eso.

Uso:  python3 Scripts/comprobar_modulos.py     (sale con 1 si hay un problema)
"""
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent / "Packages" / "Armonia"
FUENTES = RAIZ / "Sources"

PERMITIDO = {
    "ArmoniaNucleo": set(),
    "ArmoniaTeoria": {"ArmoniaNucleo"},
    "ArmoniaRepresentaciones": {"ArmoniaNucleo", "ArmoniaTeoria", "Hexagonos"},
    "ArmoniaPartitura": {"ArmoniaNucleo", "ArmoniaTeoria"},
    "ArmoniaTrastes": {"ArmoniaNucleo", "ArmoniaTeoria"},
}
PARAGUAS = "Armonia"
# Ficheros permitidos en el módulo paraguas.
EN_PARAGUAS = {"Exportaciones.swift"}

# Nombres que coinciden con un tipo de otro módulo sin serlo (parámetros genéricos, etc.).
IGNORAR = {
    ("ArmoniaNucleo/Fundamentos/Aritmetica.swift", "Clave"),   # parámetro genérico `Clave: Hashable`
}


def limpiar(texto: str) -> str:
    texto = re.sub(r'"""[\s\S]*?"""', '""', texto)
    texto = re.sub(r"//.*", "", texto)
    return re.sub(r'"(?:\\.|[^"\\])*"', '""', texto)


def objetivos_de_package() -> dict:
    """Dependencias declaradas de cada `.target(name:…)` de Package.swift."""
    texto = re.sub(r"//.*", "", (RAIZ / "Package.swift").read_text(encoding="utf-8"))
    resultado = {}
    for m in re.finditer(r'\.(?:target|executableTarget|testTarget)\(\s*name:\s*"(\w+)"(?:,\s*dependencies:\s*\[([^\]]*)\])?', texto):
        resultado[m.group(1)] = set(re.findall(r'"(\w+)"', m.group(2) or ""))
    return resultado


def main() -> int:
    errores = []
    objetivos = objetivos_de_package()

    # 1. Dependencias declaradas.
    for modulo, permitidas in PERMITIDO.items():
        if modulo not in objetivos:
            errores.append(f"Package.swift no declara el módulo {modulo}")
        elif objetivos[modulo] != permitidas:
            errores.append(f"{modulo}: dependencias declaradas {sorted(objetivos[modulo])}, deben ser {sorted(permitidas)}")
    if objetivos.get(PARAGUAS) != set(PERMITIDO):
        errores.append(f"{PARAGUAS}: debe depender de {sorted(PERMITIDO)}, y declara {sorted(objetivos.get(PARAGUAS, []))}")

    # Ficheros por módulo y tipos declarados.
    ficheros = {}
    tipos = {}
    for modulo in list(PERMITIDO) + [PARAGUAS]:
        carpeta = FUENTES / modulo
        if not carpeta.is_dir():
            errores.append(f"Falta Sources/{modulo}")
            continue
        for p in sorted(carpeta.rglob("*.swift")):
            ficheros[p] = modulo
            texto = limpiar(p.read_text(encoding="utf-8"))
            for m in re.finditer(r"^\s*(?:@\w+\s+)*(?:(?:public|package|internal|final|indirect)\s+)*"
                                 r"(?:struct|enum|class|protocol|typealias)\s+([A-Z]\w*)", texto, re.M):
                tipos.setdefault(m.group(1), modulo)

    uso = {}
    for p, modulo in ficheros.items():
        relativo = p.relative_to(FUENTES).as_posix()
        texto = limpiar(p.read_text(encoding="utf-8"))
        if modulo == PARAGUAS:
            continue
        # 2. Importaciones.
        for m in re.finditer(r"^\s*(?:@\w+\s+)*import\s+(Armonia\w*)", texto, re.M):
            if m.group(1) not in PERMITIDO[modulo]:
                errores.append(f"{relativo}: importa {m.group(1)}, que {modulo} no puede usar")
        # 3. Tipos de otros módulos.
        for nombre, suyo in tipos.items():
            if suyo == modulo or (relativo, nombre) in IGNORAR:
                continue
            if re.search(r"\b" + re.escape(nombre) + r"\b", texto):
                uso.setdefault((modulo, suyo), set()).add(nombre)
                if suyo not in PERMITIDO[modulo]:
                    errores.append(f"{relativo}: usa {nombre} (de {suyo}), que {modulo} no puede usar")

    # 4. El paraguas.
    paraguas = FUENTES / PARAGUAS
    reexportados = set()
    for p in paraguas.glob("*.swift"):
        if p.name not in EN_PARAGUAS:
            errores.append(f"Sources/{PARAGUAS}/{p.name}: el módulo paraguas solo tiene {sorted(EN_PARAGUAS)}")
        reexportados |= set(re.findall(r"@_exported\s+import\s+(\w+)", p.read_text(encoding="utf-8")))
    if reexportados != set(PERMITIDO):
        errores.append(f"{PARAGUAS} reexporta {sorted(reexportados)}, debe reexportar {sorted(PERMITIDO)}")
    extra = [p.relative_to(paraguas).as_posix() for p in paraguas.rglob("*.swift") if p.parent != paraguas]
    if extra:
        errores.append(f"Código en subcarpetas de Sources/{PARAGUAS}: {extra}")

    print("Dependencias entre módulos (tipos usados):")
    for (a, b), nombres in sorted(uso.items()):
        marca = "  " if b in PERMITIDO[a] else "✗ "
        print(f"  {marca}{a:24s} → {b:24s} {len(nombres):3d} tipos")
    if errores:
        print(f"\n{len(errores)} problema(s):")
        for e in errores:
            print("  -", e)
        return 1
    print("\nMódulos correctos.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
