# Escalas

Tipos de escala, modos, modos gregorianos, escalas que suben y bajan distinto, y escalas de la
India, Grecia (moderna y antigua), China, Japón, Corea, Etiopía, el mundo árabe, Persia, Indonesia,
los Andes y el klezmer.

## Más escalas y tonalidades

- Modos de la menor armónica (locrio ♮6, jónico ♯5, dórico ♯4, frigio dominante,
  lidio ♯2, ultralocrio) y de la melódica (dórico ♭2, lidio aumentado, lidio dominante,
  mixolidio ♭6, locrio ♮2, alterada), la mayor armónica y sus modos (dórico ♭5, frigio ♭4,
  lidio ♭3, mixolidio ♭2, lidio aumentado ♯2, locrio ♭♭7) y cinco escalas bebop (dominante,
  mayor, dórica, menor melódica y menor armónica).
- Escalas de colores «exóticos»: doble armónica (bizantina), menor y mayor húngaras,
  napolitanas menor y mayor, enigmática (Verdi), persa, mayor locria (árabe), lidio menor y
  Prometeo (Skriabin).
- Simétricas y otras: disminuida semitono-tono (además de la tono-semitono), aumentada, blues
  mayor, egipcia (pentatónica suspendida), Petrushka (dos acordes mayores a un tritono) y
  cromática. Los modos de Messiaen 1 y 2 se leen como tonos enteros y disminuida
  semitono-tono, y del 3 al 7 tienen tipo propio (el 3 es también la escala de nueve notas de
  Tcherepnin).
- La escala flamenca o andaluza: el frigio con la tercera mayor y la menor, de ocho notas.
- Los modos de la doble armónica (lidio ♯2 ♯6, ultrafrigio, menor húngara, oriental,
  jónico ♯2 ♯5, locrio ♭♭3 ♭♭7), de la napolitana mayor (lidio aumentado ♯6 o tonos enteros
  con sensible, lidio dominante aumentado, lidio menor, mayor locria, locrio ♮2 ♭4,
  superlocrio ♭♭3) y de la napolitana menor (lidio ♯6, mixolidio aumentado, eólico ♯4 o
  gitana húngara, locrio dominante, jónico ♯2, ultralocrio ♭♭3).
- Los modos de la mayor húngara: ultralocrio ♭♭6, menor armónica ♭5, superlocrio ♮6 (la
  alterada con 6ª mayor), menor melódica ♯5, dórico ♭2 ♯4 y lidio aumentado ♯3.
- La mayor rumana (Do Re♭ Mi Fa♯ Sol La Si♭), del folclore balcánico.
- Pentatónicas del jazz: dominante, menor 6 (dórica), mayor ♭6 (de Coltrane) y menor ♭5; la
  mixolidia (Do Mi Fa Sol Si♭), la lidia (Do Mi Fa♯ Sol Si) y la escocesa (Do Re Fa Sol La, la
  pentatónica mayor desde su 4.º grado); la blues de nueve notas y la blues menor con 2ª.
- Hexatónicas gaélicas, los modos con un hueco de la música escocesa e irlandesa: jónico sin 4ª,
  mixolidio sin 3ª, dórico sin 6ª y eólico sin 2ª. Y las de dos tríadas, mayores a un tono
  (Do + Re: Do Re Mi Fa♯ Sol La) o menores (Rem + Mim: Re Mi Fa Sol La Si).
- El hexacordo de Guido (ut re mi fa sol la), con `Escala.hexacordoNatural` (Do),
  `hexacordoDuro` (Sol) y `hexacordoBlando` (Fa).
- La argelina, de ocho notas: la menor húngara con la 4ª justa además de la aumentada.
- Otros nombres de escalas que ya estaban: acústica o de Bartók (lidio dominante), menor
  rumana (dórico ♯4), dominante ♭9 ♭13 (frigio dominante), mayor melódica (mixolidio ♭6),
  gitana española (flamenca), nordestina (lidio dominante, la del baião), las que llevan el
  nombre de quien las popularizó (de Liszt = menor húngara, de Rimski-Kórsakov = disminuida
  semitono-tono, de Debussy = tonos enteros, de Weitzmann = aumentada) y las
  auxiliares de la cromática lidia de George Russell (aumentada auxiliar = tonos enteros,
  disminuida auxiliar = disminuida, disminuida auxiliar blues = semitono-tono). La cromática
  lidia en sí tiene las doce notas: es la cromática ordenada por quintas.
- Todas se leen también en inglés ("E phrygian dominant", "G altered", "A hungarian minor").

```swift
Escala(.do, .dobleArmonica).notas      // Do Re♭ Mi Fa Sol La♭ Si
Escala("Do enigmática").notas          // Do Re♭ Mi Fa♯ Sol♯ La♯ Si
Escala("La menor húngara").nombre(en: .ingles)   // "A hungarian minor"
TipoDeEscala.mayorArmonica.rotacion(4).nombre    // "lidio ♭3"
TipoDeEscala.dobleArmonica == .hitzazkiar        // true
Escala("Mi flamenca").notas                      // Mi Fa Sol Sol♯ La Si Do Re
Escala("Do modo 3 de Messiaen").notas            // Do Re Mi♭ Mi Fa♯ Sol La♭ Si♭ Si
Escala("Re menor rumana").tipo.nombre            // "dórico ♯4"
TipoDeEscala.dobleArmonica.rotacion(5).nombre    // "oriental"
Escala.hexacordoBlando.notas                     // Fa Sol La Si♭ Do Re
TipoDeEscala.mayorHungara.rotacion(4).nombre     // "superlocrio ♮6"
Escala("Do pentatónica escocesa").notas          // Do Re Fa Sol La
Escala("La de Liszt").tipo.nombre                // "menor húngara"
```
- `Escala.candidatos(_:)` y `candidatos(clasesDeAltura:)`: qué escalas contienen unas notas, de más a menos
  probable (menos notas sobrantes y menos alteraciones); `identificar` da solo las escalas.
- `notasDeLaArmadura` (Mi♭ mayor → Si♭, Mi♭, La♭), `Escala(armadura:tipo:)`,
  `circuloDeQuintas(_:)`, `distancia(hasta:)` y `enarmonicaMasSimple` (Do♯ → Re♭ mayor),
  también para los modos. Para las relaciones entre tonalidades, mira `Tonalidad`.
- `nombreDeGrado(_:)` y `nombreDeGrado(de:)`: tónica, supertónica… sensible o subtónica.

## Escalas de otras tradiciones

Escalas de otras tradiciones, en su versión temperada (en la práctica, sobre todo los dromoi
usan microtonos):

- **Los 72 melakarta** de la música carnática, generados por su regla: Sa y Pa fijos, Ma (4ª
  justa o aumentada) y una de seis parejas Ri–Ga y Dha–Ni. Ri3, Ga1, Dha3 y Ni1 se escriben
  como 2ª aumentada, 3ª disminuida, 6ª aumentada y 7ª disminuida.
- **Los 10 thaat** de la música indostánica: Bilāval, Kalyāṇ, Khamāj, Kāfī, Āsāvarī, Bhairavī,
  Bhairav, Mārvā, Pūrvī y Toḍī.
- **15 dromoi** griegos: Ousák, Hitzáz, Hitzazkiár, Pireótikos, Tabahaniótikos, Niavént,
  Nikríz (Souzinak), Kartzigár, Sabáh, Houzám, Sengáh, Tsingánikos, Rast, Kiourdí y Houseïní.
- **8 escalas chinas**: los cinco modos pentatónicos Gōng, Shāng, Jué, Zhǐ y Yǔ (la pentatónica
  desde cada una de sus notas) y las heptatónicas Qīngyuè, Yǎyuè y Yànyuè (como la mayor, el
  lidio y el mixolidio).
- **13 escalas japonesas**: Ritsu y Ryo, del gagaku; Yō, Min'yō, Miyakobushi, In e Insen, de la
  música popular y urbana; Iwato, Hirajōshi, Kumoijōshi, Akebono y Kokin-jōshi, afinaciones del
  koto; y Ryūkyū, de Okinawa. Las fuentes occidentales describen algunas de varias formas: aquí
  va la más citada.
- **6 qenet etíopes**: Təzəta mayor y menor, Bati mayor y menor, Ambassäl y Ančihoye. Las
  fuentes no coinciden del todo en sus notas: aquí va la versión más citada.
- **6 maqamat árabes**, solo los que no necesitan cuartos de tono: Ḥijāz (frigio dominante),
  Nahāwand (menor armónica), Kurd (frigio), ʿAjam (mayor), Ḥijāzkār (doble armónica) y Nawā
  Athar (menor húngara). Rast, Bayati o Saba necesitarían microtonos.
- **Indonesia**, aproximadas a doce notas: Pélog selisir (también «balinesa») y Sléndro.
- **10 ragas indostánicos** que no son thaat: Bhūpālī, Mālkauns, Durgā, Śivarañjanī, Kalāvatī
  (el Valaji carnático), Candrakauns y Megh, pentatónicos; Yaman; y Bāgeśrī y Deś, que suben y
  bajan distinto. Se deja fuera Darbārī, que es vakra.
- **3 dastgāh persas**: Māhur (la mayor), y Homāyun y Čahārgāh, aproximados (como el frigio
  dominante y la doble armónica); Šur y los demás necesitan microtonos (*koron*).
- **2 escalas coreanas**: P'yŏngjo y Kyemyŏnjo.
- **Los Andes**: la pentatónica andina (menor) y la tritónica andina (Do Mi♭ Sol).
- **La Grecia antigua**: los tetracordos diatónico y cromático, y las harmoniai doria (el frigio
  moderno, de Mi a Mi), doria cromática, frigia (el dórico moderno) y lidia (la mayor). El
  género enarmónico usa cuartos de tono y queda fuera.
- **4 modos del klezmer**: Freygish (Ahavah Rabbah), Misheberakh, Adonai Malakh (mixolidio con
  la 3ª menor de paso) y Magen Avot (menor natural).

Los nombres indios siguen el AITS (Alfabeto Internacional de Transliteración Sánscrita, IAST):
Māyāmālavagauḷa, Ṣaṇmukhapriyā, Mecakalyāṇī. Los griegos llevan el acento de la palabra griega
(Πειραιώτικος → Pireótikos). Los chinos van en pinyin con sus tonos (Zhǐ, Yǎyuè), los japoneses
en Hepburn con macrones en las vocales largas (Hirajōshi, Ryūkyū), los etíopes como en la
Encyclopaedia Aethiopica (Təzəta, Ančihoye), los árabes en ALA-LC (Ḥijāz, ʿAjam) y los de
Indonesia con la grafía javanesa (Pélog, Sléndro), los persas en la transliteración de la
Encyclopædia Iranica (Čahārgāh) y los coreanos en McCune-Reischauer (P'yŏngjo), con la
romanización oficial y el hangul como alias. Un nombre gana a un alias: «Hijaz» es el
maqam Ḥijāz, y el dromos se busca como Hitzáz o Hicaz. Al buscar no importan los
diacríticos ni las mayúsculas, y también se aceptan las transliteraciones habituales sin ellos
(Mayamalavagowla, Shanmukhapriya, Hitzaz, hirajoshi) y los nombres en chino y en japonés (宫, 平調子).

```swift
TipoDeEscala.melakarta(15)                   // Māyāmālavagauḷa
TipoDeEscala.mayor.numeroDeMelakarta         // 29 (Dhīraśaṅkarābharaṇam)
Escala(.re, .hitzaz).notas                   // Re Mi♭ Fa♯ Sol La Si♭ Do
Escala("Do Kāfī"), Escala("Do kafi"), Escala("Re hijaz"), Escala("Do melakarta 22")
Escala(.do, .todi).notas                     // Do Re♭ Mi♭ Fa♯ Sol La♭ Si
TipoDeEscala.melakarta(15) == .bhairav       // true: y también == .hitzazkiar
Escala(.re, .zhi).notas                      // Re Mi Sol La Si
Escala("Do hirajoshi").notas                 // Do Re Mi♭ Sol La♭
Escala("Do 平調子").tipo.nombre               // "Hirajōshi"
TipoDeEscala.gong == .pentatonicaMayor       // true
```

No forman parte de `TipoDeEscala.todos`, para no cambiar las búsquedas de escalas habituales;
están en `TipoDeEscala.tradicionales` (y en `melakartas`, `thaats`, `dromoi`, `chinas`, `japonesas`,
`ragasIndostanicos`, `dastgah`, `coreanas`, `andinas`, `griegasAntiguas`…). Sus nombres
son nombres propios y no se traducen al inglés.

## Modos gregorianos

`ModoGregoriano` describe los ocho modos del canto llano. Además de sus notas, cada uno tiene una
final (*finalis*), un tenor o dominante (la nota de recitación) y un ámbito. Van por parejas
con la misma final: protus (Re), deuterus (Mi), tritus (Fa) y tetrardus (Sol). El impar es el
auténtico, de la final a su octava. El par es el plagal («hipo-»), de una 4ª por debajo de la
final a una 5ª por encima.

| Modo | Nombre | Final | Tenor | Ámbito |
|---|---|---|---|---|
| 1 | protus auténtico (dórico) | Re | La | Re–Re |
| 2 | protus plagal (hipodórico) | Re | Fa | La–La |
| 3 | deuterus auténtico (frigio) | Mi | Do | Mi–Mi |
| 4 | deuterus plagal (hipofrigio) | Mi | La | Si–Si |
| 5 | tritus auténtico (lidio) | Fa | Do | Fa–Fa |
| 6 | tritus plagal (hipolidio) | Fa | La | Do–Do |
| 7 | tetrardus auténtico (mixolidio) | Sol | Re | Sol–Sol |
| 8 | tetrardus plagal (hipomixolidio) | Sol | Do | Re–Re |

```swift
ModoGregoriano(2)!.description
// "modo 2 (protus plagal, hipodórico): final Re, tenor Fa, ámbito La3–La4"
ModoGregoriano(nombre: "hipofrigio")!.tenor      // La
ModoGregoriano(3)!.escala                        // Mi frigio
ModoGregoriano(6)!.ambito.first                  // Do4
```

`ambito` da las notas de la más grave a la más aguda, con la final en la octava 4. Los modos 5 y
6 se cantaban muchas veces con Si♭, que `escala` no incluye.

## Escalas que suben y bajan distinto

Algunas escalas usan notas distintas al subir y al bajar: la menor melódica clásica (que baja
como la natural), los dromoi Rast, Kiourdí y Houseïní, y muchos ragas janya. `intervalos` es la
forma ascendente y `descenso`, la descendente (`nil` si la escala baja igual que sube).

```swift
TipoDeEscala.menorMelodica.esDireccional          // true
TipoDeEscala.menorMelodica.formaDescendente       // == .menorNatural
Escala(.la, .menorMelodica).alturas(octava: 4, direccion: .descendente)   // La5 Sol5 Fa5 … La4
TipoDeEscala.rast.formaAscendente == .mayor       // true; baja con la 7ª menor
TipoDeEscala.kiourdi.formaDescendente             // == .menorNatural
TipoDeEscala.bilahari.intervalosEnAmbasDirecciones
```

Los ragas janya incluidos son Mohanam, Hindolam, Haṃsadhvani, Ābhogi, Madhyamāvatī, Revati,
Amṛtavarṣiṇī (iguales al subir y al bajar), Bilahari, Kāmbhoji, Ārabhi y Kedāragauḷa (distintos). Se dejan fuera los
vakra, que suben o bajan en zigzag. `melakartasCompatibles` dice de qué melakarta puede derivar
cada uno: `TipoDeEscala.mohanam.melakartasCompatibles` → `[28, 29, 64, 65]`.

### Qué forma usa cada operación

- **Las dos direcciones:** `contiene(_:)`, `contieneEnarmonico(_:)`, `Escala.candidatos` y la
  ortografía de alturas MIDI. La menor melódica contiene Sol (al bajar) y Sol♯ (al subir), y
  en ella el Sol no se escribe como nota cromática. Con `direccion:` se mira solo una:
  `contiene(.sol, direccion: .ascendente)` → `false`.
- **Solo la subida:** `notas`, los grados (`grado(_:)`, `grado(de: _:)`, `nombreDeGrado(_:)`), la
  armonización, la armadura y `conjuntoDeClases` (la menor melódica es 7-34).
- `notasEnAmbasDirecciones` y `notas(direccion:)` dan las notas de cada caso.

### Menor melódica clásica y de jazz

`menorMelodica` es la clásica: sube con la 6ª y la 7ª mayores y baja como la natural.
`menorMelodicaJazz` usa la 6ª y la 7ª mayores también al bajar; es la escala madre de los modos
de la menor melódica (`TipoDeEscala.alterada.rotacion(2) == .menorMelodicaJazz`) y tiene el mismo
contenido que el melakarta 23, Gaurīmanoharī. En inglés, "melodic minor" es la clásica y
"jazz minor" o "ascending melodic minor", la de jazz.

## Misma escala y mismo nombre

Dos tipos de escala son iguales (`==`) si tienen el mismo contenido al subir y al bajar, se
llamen como se llamen: `TipoDeEscala.kafi == .dorico`. Para comparar también el nombre está
`esIdentico(a:)`, y `equivalentes` da los otros nombres con que se conoce una escala:

```swift
TipoDeEscala.kafi.esIdentico(a: .dorico)          // false
TipoDeEscala.kafi.equivalentes.contains(.dorico)  // true
TipoDeEscala.rast == .mayor                       // false: baja distinto
```
