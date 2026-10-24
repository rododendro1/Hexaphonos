# Cambios

## Sin publicar

Componentes de SwiftUI para las apps de Hexaphonos, sobre `Armonia` y `Hexagonos`:

- `DiagramaDeMastil`: el mástil con una escala o una digitación, y `PresentacionDeMastil`, la parte que no es
  dibujo (qué trastes y cuerdas se enseñan).
- `DiagramaDeTonnetz` y `VistaSVG`: los dibujos SVG del motor en una vista.
- `DiagramaHexagonal` y `PresentacionHexagonal`: rejillas hexagonales interactivas.
- `SelectorDeNotacion` y `AjustesHexaphonos`: la notación (española o inglesa) que comparten las apps, con
  `selectorDeNotacionEnLaBarra(clave:)` para ponerla en la barra de herramientas.
- `comoCampoDeCifrado()`: ajusta un campo de texto para escribir cifrados.
- `TemaHexaphonos`: colores y medidas comunes.
- `PresentacionDeAnalisis`, `PresentacionDeCoral` y `PresentacionDeRedes`: lo que enseñan las vistas de análisis
  (con modulaciones y cadencias), de corales (armonizar, realizar y revisar) y de redes (Tonnetz, tabla armónica y
  teclados isomorfos), en texto y SVG, sin SwiftUI.
- `FicheroParaExportar` y `BotonDeExportar`: un menú que comparte partituras MusicXML, ficheros MIDI y dibujos SVG.

En Linux solo compila la lógica que no usa SwiftUI. `MastilView`, `TonnetzView` y `SVGView` siguen aceptándose,
marcados como obsoletos.

### Sonido

- `Sonido` (en `HexaphonosPresentacion`): qué notas MIDI suenan y cuándo, para un acorde (arpegiado y luego
  junto, desde su bajo), una escala, una progresión o un coral. `AnalisisPresentado` y `CoralPresentado` traen
  el suyo.
- `Reproductor` y `BotonDeEscuchar`: lo tocan con el sintetizador del sistema (`AVAudioUnitSampler`; en macOS
  con el piano General MIDI del sistema). Las apps tienen «Escuchar» en Acordes, Escalas, Análisis, Coral y
  Tonnetz.

### Apps traducidas y ayudantes comunes

- `TextoDeLasApps` (en `HexaphonosPresentacion`): los textos de la interfaz de las dos apps en los ocho idiomas
  de los textos del motor, con los ejemplos de las indicaciones escritos en la notación elegida. Siguen el
  idioma de los textos de la notación, así que el selector cambia la app entera. También se traducen las
  tareas del coral (`Tarea.titulo(en:)`, `indicacion(en:)`), los formatos para exportar
  (`Formato.titulo(en:)`), las redes (`RedDeNotas.nombre(en:)`), el selector y el menú «Exportar».
- La notación va en el entorno: `notacionGuardada()` en la raíz de cada app la lee de los ajustes, las vistas
  usan `@Environment(\.notacion)` y `selectorDeNotacionEnLaBarra()` ya no necesita la clave.
- Si aún no se ha elegido notación, se usa la del idioma del sistema (`Nomenclatura.delSistema()`).
- `calcularEnSegundoPlano(para:esperando:en:_:)`, `Calculado` y `FilaCalculando`: el cálculo con espera
  mientras se escribe, fuera del hilo principal y con «Calculando…», que repetían Acordes y Coral.

### Presentación compartida con la línea de comandos

- `PresentacionDeAnalisis`, `PresentacionDeCoral` y `FicheroParaExportar` pasan al módulo `HexaphonosPresentacion`
  (producto del mismo nombre), que no usa SwiftUI. `HexaphonosUI` lo reexporta, así que las apps no cambian, y
  `armonia analizar`, `armonizar`, `realizar` y `revisar` lo usan en lugar de montar el resultado por su cuenta.
- `PresentacionDeAnalisis.analizar(_:en:notacion:)` acepta una tonalidad dada, y entonces no busca modulaciones.
- `CoralPresentado.avisos` son ahora `CoralPresentado.Aviso` en lugar de textos fijos en español:
  `texto(en:)` los escribe en el idioma de la notación. Los de «sin armonización», «sin realización» y «sin
  faltas» son los mismos que ya escribía la línea de comandos.
- `PresentacionDeCoral.armonizar`, `realizar` y `revisar` son públicas.

### Nombres

Los nombres anteriores se siguen aceptando, marcados como obsoletos.

- `toolbarNotacion(clave:)` pasa a `selectorDeNotacionEnLaBarra(clave:)`, sin mezclar inglés y español.
- `campoDeCifrado()` pasa a `comoCampoDeCifrado()`: no crea un campo, ajusta el que ya hay.
