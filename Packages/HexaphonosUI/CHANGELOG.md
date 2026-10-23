# Cambios

## Sin publicar

Componentes de SwiftUI para las apps de Hexaphonos, sobre `Armonia` y `Hexagonos`:

- `DiagramaDeMastil`: el mástil con una escala o una digitación, y `PresentacionDeMastil`, la parte que no es
  dibujo (qué trastes y cuerdas se enseñan).
- `DiagramaDeTonnetz` y `VistaSVG`: los dibujos SVG del motor en una vista.
- `DiagramaHexagonal` y `PresentacionHexagonal`: rejillas hexagonales interactivas.
- `SelectorDeNotacion` y `AjustesHexaphonos`: la notación (española o inglesa) que comparten las apps.
- `TemaHexaphonos`: colores y medidas comunes.

En Linux solo compila la lógica que no usa SwiftUI. `MastilView`, `TonnetzView` y `SVGView` siguen aceptándose,
marcados como obsoletos.
