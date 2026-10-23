# ``Armonia``

Motor de armonía tonal en Swift, con la API en español.

## Overview

Todo se apoya en un mismo sistema de coordenadas —la **línea de quintas** y el **plano quintas ×
octavas**—, que conserva la ortografía de las notas (Fa♯ ≠ Sol♭, 4ª aumentada ≠ 5ª disminuida)
y reduce casi todas las operaciones a sumas de enteros.

```swift
import Armonia

Acorde("Sol7/Si").posicionCerrada(octava: 3)   // [Si3, Re4, Fa4, Sol4]
Escala("La menor armónica").cifradosRomanos(cuatriadas: true)
Tonalidad.identificar(midi: [69, 71, 72, 74, 76, 77, 80, 81]).first   // La menor
```

## Topics

### Artículos

- <doc:ElModelo>
- <doc:Acordes>
- <doc:Escalas>
- <doc:Tonalidad>
- <doc:NotacionYPartitura>
- <doc:MelodiaYRitmo>
- <doc:AfinacionYRepresentaciones>
- <doc:Trastes>
- <doc:Postonal>
- <doc:Convenciones>

### Fundamentos

- ``Nota``
- ``Alteracion``
- ``Altura``
- ``Intervalo``
- ``Candidato``

### Acordes y escalas

- ``Acorde``
- ``TipoDeAcorde``
- ``Escala``
- ``TipoDeEscala``
- ``ModoGregoriano``
- ``Tonalidad``
- ``AnalisisArmonico``
- ``ConduccionDeVoces``

### Mástil y digitaciones

- ``Encordado``
- ``Mastil``
- ``Posicion``
- ``Digitacion``

### Ritmo

- ``Duracion``
- ``Compas``
- ``Tempo``
- ``Voz``
