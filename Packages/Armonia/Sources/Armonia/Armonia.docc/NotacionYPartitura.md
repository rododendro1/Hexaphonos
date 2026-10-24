# Notación y partitura

Notación española e inglesa, alteraciones, intervalos, pentagrama, instrumentos y errores de lectura.

## Notación internacional

| | Español | Internacional |
|---|---|---|
| Altura | `Altura("Fa#3").nombreCompleto` → Fa♯3 | `.nombre(en: .ingles)` → F#3 |
| Intervalo | `.abreviatura` → 4A · `.nombre` → 4ª aumentada | `.abreviatura(en: .ingles)` → A4 · `.nombre(en: .ingles)` → augmented fourth |
| Escala | `.nombre` → Re dórico | `.nombre(en: .ingles)` → D dorian |
| Acorde | `.cifrado` → Si♭7(♭9)/Re | `.cifrado(en: .ingles)` → Bb7(b9)/D |
| Nombre de acorde | Sol séptima de dominante, primera inversión | G dominant seventh, first inversion |

`Nomenclatura` reúne el idioma y los caracteres: `.espanol` (Fa♯), `.espanolASCII` (Fa#),
`.ingles` (F#) y `.inglesUnicode` (F♯). Se usa en `nombre(en:)`, `texto(_:)`, `abreviatura(en:)`,
`cifrado(en:)` y `EstiloDeCifrado(notacion:)`.

Todo se lee en ambas notaciones (`Intervalo("P5")`, `Escala("Bb harmonic minor")`,
`Acorde("B♭7(♭9)/D")`), y `Nomenclatura` (`.espanol`, `.espanolASCII`, `.ingles`,
`.inglesUnicode`) elige la forma.

## Otras lenguas

Además del español y el inglés, `Nomenclatura` tiene `.aleman`, `.frances`, `.italiano`, `.catalan`,
`.gallego`, `.euskera`, `.portugues`, `.occitano`, `.ruso` y `.griego`:

| | Do♯ | Mi♭ | Si♭ | Si | Fa♯ mayor | La menor |
|---|---|---|---|---|---|---|
| `.aleman` | Cis | Es | B | H | Fis-Dur | a-Moll |
| `.frances` | do dièse | mi bémol | si bémol | si | fa dièse majeur | la mineur |
| `.italiano` | do diesis | mi bemolle | si bemolle | si | fa diesis maggiore | la minore |
| `.catalan` | do sostingut | mi bemoll | si bemoll | si | fa sostingut major | la menor |
| `.gallego` | do sostido | mi bemol | si bemol | si | fa sostido maior | la menor |
| `.euskera` | do diesa | mi bemol | si bemol | si | fa diesa maiorra | la minorra |
| `.portugues` | dó sustenido | mi bemol | si bemol | si | fá sustenido maior | lá menor |
| `.occitano` | do dièsi | mi bemòl | si bemòl | si | fa dièsi major | la menor |
| `.ruso` | до-диез | ми-бемоль | си-бемоль | си | фа-диез мажор | ля минор |
| `.griego` | ντο δίεση | μι ύφεση | σι ύφεση | σι | φα δίεση μείζονα | λα ελάσσονα |

```swift
Nota("Sib").nombre(en: .aleman)            // "B"
Nota("Mibb").nombre(en: .aleman)           // "Eses"
Altura("Fa#3").nombre(en: .frances)                  // "fa dièse 3"
Acorde("Sim7").cifrado(en: .aleman)                // "Hm7"
Acorde("Rebmaj7").cifrado(en: .frances)            // "Ré♭maj7"
try Nota(leyendo: "B", en: .aleman)         // Si♭
try Altura(leyendo: "re diesis 5", en: .italiano)     // Re♯5
Tonalidad("Fis-Dur"), Tonalidad("ré bémol majeur"), Tonalidad("la minore")
Alteracion(-2).nombre(en: .frances)                 // "double bémol"
Nota("Fa#").nombre(en: .portugues)                  // "fá sustenido"
Alteracion(2).nombre(en: .portugues)                // "duplo sustenido"
Acorde("Rebmaj7").cifrado(en: .portugues)           // "Ré♭maj7"
Altura("fá sustenido 3")                            // Fa♯3
Tonalidad("si bemol maior")                         // Si♭ mayor
Escala("ré dórico")                                 // Re dórico
Nota("Fa#").nombre(en: .ruso)                       // "фа-диез"
Tonalidad("Re mayor").nombre(en: .griego)           // "ρε μείζονα"
Acorde("Sibm7").cifrado(en: .griego)                // "Σι♭m7"
Altura("sòl dièsi 2")                               // Sol♯2
Tonalidad("ля минор")                               // La menor
```

- En francés, italiano, catalán, gallego, euskera, portugués, occitano, ruso y griego los nombres van
  en minúscula y con las alteraciones en palabras (en euskera, con el adjetivo detrás: diesa
  bikoitza; en ruso, unidas con guion: фа-диез); en los cifrados se usa la forma compacta
  (`nombreCompacto(en:)`: Fa♯, Ré♭, Фа♯, Σι♭).
- Las octavas son siempre las científicas (Do4 = do central), también en francés, donde a menudo
  se numera de otra forma.
- Las lecturas genéricas (`init(leyendo:)`) aceptan español, inglés, catalán, gallego, euskera,
  portugués, occitano, ruso y griego, que no se confunden entre sí: `Altura("fa sostido 3")`,
  `Escala("re bemoll dòric")`, `Altura("fá sustenido 3")`, `Nota("си-бемоль")`, `Nota("σι ύφεση")`. El
  alemán, el francés y el italiano se leen con `Nota(leyendo:en:)` y `Altura(leyendo:en:)`,
  porque «B» no significa lo mismo en inglés que en alemán. `Tonalidad` lee todas.
- Un mismo texto no mezcla idiomas: con la tónica en español, el tipo de escala o de tonalidad
  va en español (`Escala("Re dórico")`, `Escala("D dorian")`, pero no «Re dorian»), y el bajo de
  un acorde se escribe como su fundamental (`Acorde("Sol7/Si")`, `Acorde("G7/B")`, pero no
  «Sol7/B», que da el error `.idiomasMezclados`).
- Los textos del motor (mensajes de error, intervalos, calidades, papeles en el acorde, grados,
  claves, figuras, cadencias y faltas de conducción) están en español, inglés, catalán, gallego,
  euskera, portugués, francés e italiano; en alemán, occitano, ruso y griego salen en inglés. Es lo que indica
  `notacion.idiomaDeLosTextos`, y cada texto es una `Traduccion` con los ocho idiomas.
- Los nombres de los catálogos (tipos de acorde y de escala, instrumentos) siguen el mismo
  `idiomaDeLosTextos`. Los nombres tradicionales de escala (raga, maqam, pentatónicas japonesas…)
  se escriben igual en todos los idiomas, y una escala se lee también con su nombre en catalán,
  gallego, euskera o portugués (`Escala("re doriarra")`, `Escala("dó maior")`).

```swift
Intervalo.terceraMayor.nombre(en: .catalan)        // "3a major"
Intervalo.terceraMayor.nombre(en: .gallego)        // "3ª maior"
Intervalo.sextaMenor.nombre(en: .euskera)          // "6. txikia"
Cadencia.Tipo.rota.nombre(en: .catalan)            // "cadència trencada"
Escala(.re, .dorico).nombre(en: .euskera)          // "re doriarra"
Acorde("Sol7/Si").nombre(en: .catalan)           // "sol sèptima de dominant, primera inversió"
Intervalo.terceraMayor.nombre(en: .frances)        // "tierce majeure"
Cadencia.Tipo.rota.nombre(en: .italiano)           // "cadenza d'inganno"
Escala(.re, .dorico).nombre(en: .frances)          // "ré dorien"
Acorde("Sol7/Si").nombre(en: .portugues)         // "sol sétima de dominante, primeira inversão"
```

## Alteraciones

`Alteracion` es el número de semitonos que sube o baja una nota respecto a la natural. Se
puede escribir con un entero (`Nota(.fa, 1)`) o con su nombre (`Nota(.fa, .sostenido)`).

```swift
Nota("Sibb").alteracion          // doble bemol
Alteracion(3).nombre                      // "triple sostenido"
Alteracion(-1).nombre(en: .ingles)        // "flat"
Alteracion(2).simbolo                     // "♯♯"
Alteracion(3).simboloCompacto             // "𝄪♯"
Alteracion(-2).simboloASCII               // "bb"
Alteracion("x"), Alteracion("doble bemol"), Alteracion("♮")
Alteracion.sostenido + .sostenido         // doble sostenido
Alteracion.sostenido.pasosDeQuinta        // 7: un sostenido son siete quintas
```

También la usan `PosicionEnPentagrama.alteracion` y `Clave.altura(lugar:alteracion:)`.

## Intervalos, pentagrama e instrumentos

```swift
Intervalo.sextaMenor.claseIntervalica          // 4
Intervalo.segundaAumentada.consonancia()       // .disonancia (aunque suene como una 3ª menor)
Intervalo(numero: 1, calidad: .disminuida(1))  // nil: no existe el unísono disminuido

Clave.sol.posicion(de: "Do4").descripcion      // "1.ª línea adicional inferior"
Clave.doEnTercera.posicion(de: "Do4").lugar   // 4 (3.ª línea)
Clave.fa.altura(lugar: 8)                   // La3
Clave.masAdecuada(para: ["Do2", "Mi2"])        // .fa

Instrumento.clarineteEnSib.sonido(de: Altura("Do5"))     // Si♭4
Instrumento.saxofonAlto.escritura(de: Escala("Si mayor"))   // La♭ mayor (simplificada)
Instrumento.saxofonAlto.escritura(de: Acorde("Do7"))   // La7
```

Hay 30 instrumentos predefinidos con su transposición y su clave habitual, y nueve claves
(sol, sol octava baja y alta, fa en 4.ª y 3.ª, do en 1.ª a 4.ª).

## Errores

Cada tipo tiene un inicializador `init(leyendo:)` que lanza `ErrorDeLectura` con el
texto, el carácter donde se detuvo y el motivo. Los inicializadores opcionales
(`Acorde(texto: …)`) siguen existiendo y devuelven `nil`.

El mensaje está en español (`description`, `explicacion`) y también en inglés, catalán, gallego,
euskera, portugués, francés e italiano: `descripcion(en:)` y `explicacion(en:)` usan el idioma de
los textos de la notación (`notacion.idiomaDeLosTextos`), como los nombres de intervalos; con
`.aleman`, `.occitano`, `.ruso` y `.griego` sale en inglés.

```swift
do {
    let acorde = try Acorde(leyendo: "Do7(b3)")
    print(acorde)                     // no se llega aquí: la línea anterior lanza el error
} catch let error as ErrorDeLectura {
    print(error)
    // No se puede leer «Do7(b3)» (carácter 5): «b3» no es una tensión válida
    // (se admiten ♭/♯ con 5, 9, 11 y 13, y add con 2, 4, 6, 9, 11 y 13)
    error.motivo     // .tensionNoValida("b3")
    error.posicion   // 4
    print(error.descripcion(en: .ingles))
    // Cannot read "Do7(b3)" (character 5): "b3" is not a valid tension (♭/♯ go with 5, 9, 11 and 13, …
}
do { _ = try TipoDeAcorde(comprobandoPasosDeQuinta: [0, -3, 4]) } catch { print(error) }
// … tiene tercera mayor y menor a la vez (la ♯9 se escribe como 9ª aumentada, no como 3ª menor)
```
