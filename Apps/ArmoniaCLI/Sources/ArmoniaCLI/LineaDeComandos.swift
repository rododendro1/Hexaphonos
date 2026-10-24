// La herramienta de línea de comandos `armonia`: el motor sin escribir código.
//
//     armonia acorde Sol7/Si
//     armonia identificar Do Mi Sol Sib
//     armonia analizar Do Lam Re7 Sol7 Do
//
// Toda la lógica está aquí, separada del ejecutable, para poder probarla.

import Armonia
import Foundation

/// Lo que produce una orden: el texto de la salida estándar, el de la salida de errores y el
/// código de salida (0 bien, 1 texto que no se puede leer, 2 orden mal escrita). Una orden que
/// produce un fichero binario (MIDI) lo deja en `datos`, que va a la salida estándar en lugar
/// del texto.
public struct ResultadoDeOrden: Equatable, Sendable {
    public var salida: String
    public var error: String
    public var codigo: Int32
    public var datos: Data? = nil
}

public enum LineaDeComandos {
    public static let ayuda = """
    armonia: teoría musical desde la línea de comandos.

    Uso: armonia <orden> <argumentos> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

    Órdenes:
      acorde <cifrado>…            notas, tipo y papel de cada nota      armonia acorde Sol7/Si
      identificar <notas>          acordes que forman unas notas         armonia identificar Do Mi Sol Sib
      intervalo <nota> <nota>      intervalo entre dos notas o alturas   armonia intervalo Do4 Mi5
      escala <escala>              notas y acordes de una escala         armonia escala Re dórico
      tonalidad <tonalidad>        armadura, relativas y grados          armonia tonalidad La menor
      analizar <acordes> [--en <tonalidad>]
                                   cifrado romano, funciones, cadencias
                                   y modulaciones (con su acorde
                                   pivote; sin --en)                     armonia analizar Do Fa Sol7 Do Lam Re7 Sol
      armonizar <melodía> [--en <tonalidad>] [--propuestas 3]
                                   acordes para una melodía, de mejor a
                                   peor; con octavas (Mi4), también el
                                   coral a cuatro voces                  armonia armonizar Mi4 Fa4 Re4 Do4
      realizar <acordes> [--en <tonalidad>]
                                   los acordes a cuatro voces, sin
                                   faltas de conducción                  armonia realizar Do Fa Sol7 Do
      revisar <acordes>            faltas de conducción (quintas
                                   paralelas…); acordes de grave a
                                   agudo, separados por comas            armonia revisar Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4
      musicxml melodia <eventos> [opciones]
                                   partitura MusicXML de una melodía     armonia musicxml melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4 > melodia.musicxml
      musicxml coral <acordes> [opciones]
                                   coral a cuatro voces en MusicXML      armonia musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 > coral.musicxml
      musicxml acordes <cifrados> [opciones]
                                   progresión con cifrados y análisis    armonia musicxml acordes Do Lam Re7 Sol7 Do > progresion.musicxml
                                   opciones: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,
                                   --clave fa, --tempo 90 (o --tempo 60 4.), --titulo Mi coral,
                                   --duracion 2 (lo que dura cada acorde; negra en el coral y
                                   blanca en los acordes si no), --cifrados y --analisis (en el
                                   coral: cifrado americano encima, romano y función debajo)
      midi melodia|coral|acordes <…> [opciones]
                                   lo mismo como fichero MIDI, para oírlo
                                   (sin --clave ni --cifrados; con
                                   --programa 0…127, General MIDI)       armonia midi acordes Do Lam Re7 Sol7 Do > progresion.mid
      tonnetz <notas>              Tonnetz en SVG de unas notas          armonia tonnetz Do Mi Sol Si > tonnetz.svg
      tonnetz --acorde <cifrado> | --escala <escala> | --clases <números>
                                   de un acorde, una escala o un
                                   conjunto de clases de altura          armonia tonnetz --escala Re dórico > dorico.svg
      tonnetz --recorrido <tríadas> | --camino <tríada> <tríada>
                                   un recorrido de tríadas, con flechas,
                                   o el camino más corto por P, L y R    armonia tonnetz --recorrido Do Lam Fa Rem > recorrido.svg
      tonnetz --ciclo <ciclo> <tríada>
                                   un ciclo hexatónico, octatónico o LR  armonia tonnetz --ciclo hexatonico Do > ciclo.svg
                                   (--margen 2: más red alrededor)
      tabla <notas o alturas>      tabla armónica en SVG (hexágonos)     armonia tabla Do3 Sol3 Mi4 > tabla.svg
      tabla --acorde <cifrado> | --escala <escala> | --clases <números>
      tabla --recorrido <tríadas> | --camino <tríada> <tríada>
      tabla --ciclo <ciclo> <tríada>
                                   (--margen 2: más tabla alrededor)     armonia tabla --acorde Domaj7 > domaj7.svg
      vecinos <acorde> [--voces 2] acordes a un semitono (séptimas: dominante, menor, semidisminuida
                                   y disminuida; tríadas: mayor, menor y aumentada; un maj7, entre
                                   las séptimas y los maj7; --ampliada: con los maj7 también)
                                                                         armonia vecinos Sol7
      conduccion-parsimoniosa <acorde> <acorde> [--voces 2] [--ampliada]
                                   de un acorde a otro moviendo una voz
                                   (o dos) un semitono en cada paso      armonia conduccion-parsimoniosa Sol7 Rem7
      conduccion <acorde> <acorde> la conducción con menos semitonos     armonia conduccion Sol7 Do
      plr <tríada> <P, L, R…>      transformaciones neorriemannianas     armonia plr Do PLR
      plr <tríada> <tríada>        el camino más corto por P, L y R      armonia plr Do Mibm
      plr <tríada> <ciclo>         un ciclo: hexatonico (P, L),
                                   octatonico (P, R) o "ciclo LR"        armonia plr Do hexatonico
      digitaciones <cifrado>… [opciones]
                                   formas de tocar un acorde, de la más cómoda a la menos, en un
                                   instrumento de cuerda con trastes (cuerdas de grave a agudo)
                                   opciones: --instrumento guitarra|bajo|ukelele|mandolina|…
                                   (también «guitarra de siete cuerdas», «bajo de 5 cuerdas»,
                                   «drop D»), --limite 5, --traste 12 (el más alto que se usa),
                                   --dedos 4 (los que se pueden usar), --completo (con todas las notas:
                                   por defecto la quinta puede faltar), --diagrama (una línea por cuerda)
                                                                         armonia digitaciones Sol7/Si --instrumento ukelele
      ayuda                        esta ayuda

    Se aceptan nombres en español o en inglés (Do, C, Sib, Bb). Con --ingles, la respuesta
    usa la notación inglesa. Con --idioma ca, gl, eu, pt, fr o it, las notas, los nombres, los
    mensajes y esta ayuda salen en catalán, gallego, euskera, portugués, francés o italiano.
    """

    /// La ayuda en inglés (`armonia help --ingles`).
    public static let help = """
    armonia: music theory from the command line.

    Usage: armonia <command> <arguments> [--ingles | --language es|en|ca|gl|eu|pt|fr|it]

    Commands:
      chord <symbol>…              notes, type and role of each note     armonia chord G7/B
      identify <notes>             chords formed by some notes           armonia identify C E G Bb
      interval <note> <note>       interval between two notes or pitches armonia interval C4 E5
      scale <scale>                notes and chords of a scale           armonia scale D dorian
      key <key>                    key signature, relatives and degrees  armonia key A minor
      analyze <chords> [--in <key>]
                                   roman numerals, functions, cadences
                                   and modulations (with their pivot
                                   chord; without --in)                  armonia analyze C F G7 C Am D7 G
      harmonize <melody> [--in <key>] [--proposals 3]
                                   chords for a melody, best first; with
                                   octaves (E4), also the four-part
                                   chorale                               armonia harmonize E4 F4 D4 C4
      realize <chords> [--in <key>]
                                   the chords in four parts, without
                                   voice-leading errors                  armonia realize C F G7 C
      check <chords>               voice-leading errors (parallel
                                   fifths…); chords from low to high,
                                   separated by commas                   armonia check C3 E4 G4 C5, G2 D4 G4 B4
      musicxml melody <events> [options]
                                   MusicXML score of a melody            armonia musicxml melody C4:4 D4:8 E4:8 F4:2 --compas 3/4 > melody.musicxml
      musicxml chorale <chords> [options]
                                   four-part chorale in MusicXML         armonia musicxml chorale C3 E4 G4 C5, G2 D4 G4 B4 > chorale.musicxml
      musicxml chords <symbols> [options]
                                   progression with symbols and analysis armonia musicxml chords C Am D7 G7 C > progression.musicxml
                                   options: --compas 6/8 (time signature), --anacrusa 8 (pickup),
                                   --tonalidad G major (key), --clave fa (clef), --tempo 90 (or
                                   --tempo 60 4.), --titulo My chorale (title), --duracion 2 (how
                                   long each chord lasts; a quarter note in the chorale and a half
                                   note in the chords by default), --cifrados and --analisis (in
                                   the chorale: chord symbols above, roman numerals and function below)
      midi melody|chorale|chords <…> [options]
                                   the same as a MIDI file, to listen to
                                   (without --clave or --cifrados; with
                                   --program 0…127, General MIDI)        armonia midi chords C Am D7 G7 C > progression.mid
      tonnetz <notes>              SVG Tonnetz of some notes             armonia tonnetz C E G B > tonnetz.svg
      tonnetz --chord <symbol> | --scale <scale> | --pcs <numbers>
                                   of a chord, a scale or a
                                   pitch-class set                       armonia tonnetz --scale D dorian > dorian.svg
      tonnetz --sequence <triads> | --shortest <triad> <triad>
                                   a sequence of triads, with arrows, or
                                   the shortest path through P, L and R  armonia tonnetz --sequence C Am F Dm > sequence.svg
      tonnetz --cycle <cycle> <triad>
                                   a hexatonic, octatonic or LR cycle    armonia tonnetz --cycle hexatonic C > cycle.svg
                                   (--margen 2: more grid around it)
      tabla <notes or pitches>     SVG harmonic table (hexagons)         armonia tabla C3 G3 E4 > table.svg
      tabla --chord <symbol> | --scale <scale> | --pcs <numbers>
      tabla --sequence <triads> | --shortest <triad> <triad>
      tabla --cycle <cycle> <triad>
                                   (--margen 2: more table around it)    armonia tabla --chord Cmaj7 > cmaj7.svg
      neighbors <chord> [--voices 2]
                                   chords a semitone away (sevenths: dominant, minor, half-diminished
                                   and diminished; triads: major, minor and augmented; a maj7, among
                                   the sevenths and the maj7s; --extended: with the maj7s too)
                                                                         armonia neighbors G7
      smooth-path <chord> <chord> [--voices 2] [--extended]
                                   from one chord to another moving one
                                   voice (or two) a semitone at a time   armonia smooth-path G7 Dm7
      voice-leading <chord> <chord>
                                   the voice leading with fewest semitones
                                                                         armonia voice-leading G7 C
      plr <triad> <P, L, R…>       neo-Riemannian transformations        armonia plr C PLR
      plr <triad> <triad>          the shortest path through P, L and R  armonia plr C Ebm
      plr <triad> <cycle>          a cycle: hexatonic (P, L),
                                   octatonic (P, R) or "LR cycle"        armonia plr C hexatonic
      fingerings <symbol>… [options]
                                   ways to play a chord, from the most comfortable to the least, on a
                                   fretted string instrument (strings from low to high)
                                   options: --instrument guitar|bass|ukulele|mandolin|…
                                   (also "seven-string guitar", "five-string bass",
                                   "drop D"), --limit 5, --fret 12 (the highest one used),
                                   --fingers 4 (how many can be used), --complete (with every note:
                                   by default the fifth may be left out), --diagram (one line per string)
                                                                         armonia fingerings G7/B --instrument ukulele
      help                         this help

    Note names are accepted in Spanish or English (Do, C, Sib, Bb). With --ingles, the answer
    uses English notation, and so do messages and this help. With --language ca, gl, eu, pt, fr or
    it, notes, names, messages and this help are in Catalan, Galician, Basque, Portuguese, French or
    Italian.
    """

    /// La ayuda en catalán (`armonia ayuda --idioma ca`).
    public static let ajuda = """
    armonia: teoria musical des de la línia d'ordres.

    Ús: armonia <ordre> <arguments> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

    Ordres (les ordres i les opcions s'escriuen en castellà o en anglès):
      acorde <xifrat>…             notes, tipus i paper de cada nota     armonia acorde Sol7/Si
      identificar <notes>          acords que formen unes notes          armonia identificar Do Mi Sol Sib
      intervalo <nota> <nota>      interval entre dues notes o altures   armonia intervalo Do4 Mi5
      escala <escala>              notes i acords d'una escala           armonia escala Re dórico
      tonalidad <tonalitat>        armadura, relatives i graus           armonia tonalidad La menor
      analizar <acords> [--en <tonalitat>]
                                   xifrat romà, funcions, cadències i
                                   modulacions (amb l'acord pivot;
                                   sense --en)                           armonia analizar Do Fa Sol7 Do Lam Re7 Sol
      armonizar <melodia> [--en <tonalitat>] [--propuestas 3]
                                   acords per a una melodia, de millor
                                   a pitjor; amb octaves (Mi4), també
                                   el coral a quatre veus                armonia armonizar Mi4 Fa4 Re4 Do4
      realizar <acords> [--en <tonalitat>]
                                   els acords a quatre veus, sense
                                   errors de conducció                   armonia realizar Do Fa Sol7 Do
      revisar <acords>             errors de conducció (quintes
                                   paral·leles…); acords de greu a
                                   agut, separats per comes              armonia revisar Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4
      musicxml melodia <esdeveniments> [opcions]
                                   partitura MusicXML d'una melodia      armonia musicxml melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4 > melodia.musicxml
      musicxml coral <acords> [opcions]
                                   coral a quatre veus en MusicXML       armonia musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 > coral.musicxml
      musicxml acordes <xifrats> [opcions]
                                   progressió amb xifrats i anàlisi      armonia musicxml acordes Do Lam Re7 Sol7 Do > progresion.musicxml
                                   opcions: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,
                                   --clave fa, --tempo 90 (o --tempo 60 4.), --titulo El meu coral,
                                   --duracion 2 (el que dura cada acord; negra al coral i blanca
                                   als acords si no), --cifrados i --analisis (al coral: xifrat
                                   americà a dalt, romà i funció a baix)
      midi melodia|coral|acordes <…> [opcions]
                                   el mateix com a fitxer MIDI, per
                                   escoltar-lo (sense --clave ni
                                   --cifrados; amb --programa 0…127,
                                   General MIDI)                         armonia midi acordes Do Lam Re7 Sol7 Do > progresion.mid
      tonnetz <notes>              Tonnetz en SVG d'unes notes           armonia tonnetz Do Mi Sol Si > tonnetz.svg
      tonnetz --acorde <xifrat> | --escala <escala> | --clases <nombres>
                                   d'un acord, una escala o un conjunt
                                   de classes d'altura                   armonia tonnetz --escala Re dórico > dorico.svg
      tonnetz --recorrido <tríades> | --camino <tríada> <tríada>
                                   un recorregut de tríades, amb
                                   fletxes, o el camí més curt per P, L
                                   i R                                   armonia tonnetz --recorrido Do Lam Fa Rem > recorrido.svg
      tonnetz --ciclo <cicle> <tríada>
                                   un cicle hexatònic, octatònic o LR
                                   (--margen 2: més xarxa al voltant)    armonia tonnetz --ciclo hexatonico Do > ciclo.svg
      tabla <notes o altures>      taula harmònica en SVG (hexàgons)     armonia tabla Do3 Sol3 Mi4 > tabla.svg
      tabla --acorde | --escala | --clases | --recorrido | --camino | --ciclo
                                   com al Tonnetz (--margen 2: més
                                   taula al voltant)                     armonia tabla --acorde Domaj7 > domaj7.svg
      vecinos <acord> [--voces 2]  acords a un semitò (sèptimes:
                                   dominant, menor, semidisminuïda i
                                   disminuïda; tríades: major, menor i
                                   augmentada; --ampliada: amb els maj7
                                   també)                                armonia vecinos Sol7
      conduccion-parsimoniosa <acord> <acord> [--voces 2] [--ampliada]
                                   d'un acord a un altre movent una veu
                                   (o dues) un semitò a cada pas         armonia conduccion-parsimoniosa Sol7 Rem7
      conduccion <acord> <acord>   la conducció amb menys semitons       armonia conduccion Sol7 Do
      plr <tríada> <P, L, R…>      transformacions neoriemannianes       armonia plr Do PLR
      plr <tríada> <tríada>        el camí més curt per P, L i R         armonia plr Do Mibm
      plr <tríada> <cicle>         un cicle: hexatonico (P, L),
                                   octatonico (P, R) o "ciclo LR"        armonia plr Do hexatonico
      digitaciones <xifrat>… [opcions]
                                   maneres de tocar un acord, de la més
                                   còmoda a la menys, en un instrument
                                   de corda amb trasts
                                   opcions: --instrumento guitarra|bajo|ukelele|mandolina|… (també
                                   «guitarra de siete cuerdas», «bajo de 5 cuerdas», «drop D»),
                                   --limite 5, --traste 12 (el més alt que es fa servir), --dedos 4
                                   (els que es poden fer servir), --completo (amb totes les notes:
                                   per defecte la quinta pot faltar), --diagrama (una línia per
                                   corda)
                                                                         armonia digitaciones Sol7/Si --instrumento ukelele
      ayuda                        aquesta ajuda

    S'accepten noms de nota en castellà, català, gallec, basc o anglès (Do, C, Sib, Bb, si
    bemoll). Amb --idioma ca, la resposta fa servir la notació catalana i els missatges en
    català; amb --ingles, en anglès.
    """

    /// La ayuda en gallego (`armonia ayuda --idioma gl`).
    public static let axuda = """
    armonia: teoría musical desde a liña de comandos.

    Uso: armonia <orde> <argumentos> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

    Ordes (as ordes e as opcións escríbense en castelán ou en inglés):
      acorde <cifrado>…            notas, tipo e papel de cada nota      armonia acorde Sol7/Si
      identificar <notas>          acordes que forman unhas notas        armonia identificar Do Mi Sol Sib
      intervalo <nota> <nota>      intervalo entre dúas notas ou
                                   alturas                               armonia intervalo Do4 Mi5
      escala <escala>              notas e acordes dunha escala          armonia escala Re dórico
      tonalidad <tonalidade>       armadura, relativas e graos           armonia tonalidad La menor
      analizar <acordes> [--en <tonalidade>]
                                   cifrado romano, funcións, cadencias
                                   e modulacións (co seu acorde pivote;
                                   sen --en)                             armonia analizar Do Fa Sol7 Do Lam Re7 Sol
      armonizar <melodía> [--en <tonalidade>] [--propuestas 3]
                                   acordes para unha melodía, de mellor
                                   a peor; con oitavas (Mi4), tamén o
                                   coral a catro voces                   armonia armonizar Mi4 Fa4 Re4 Do4
      realizar <acordes> [--en <tonalidade>]
                                   os acordes a catro voces, sen erros
                                   de condución                          armonia realizar Do Fa Sol7 Do
      revisar <acordes>            erros de condución (quintas
                                   paralelas…); acordes de grave a
                                   agudo, separados por comas            armonia revisar Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4
      musicxml melodia <eventos> [opcións]
                                   partitura MusicXML dunha melodía      armonia musicxml melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4 > melodia.musicxml
      musicxml coral <acordes> [opcións]
                                   coral a catro voces en MusicXML       armonia musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 > coral.musicxml
      musicxml acordes <cifrados> [opcións]
                                   progresión con cifrados e análise     armonia musicxml acordes Do Lam Re7 Sol7 Do > progresion.musicxml
                                   opcións: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,
                                   --clave fa, --tempo 90 (ou --tempo 60 4.), --titulo O meu coral,
                                   --duracion 2 (o que dura cada acorde; negra no coral e branca
                                   nos acordes se non), --cifrados e --analisis (no coral: cifrado
                                   americano enriba, romano e función debaixo)
      midi melodia|coral|acordes <…> [opcións]
                                   o mesmo como ficheiro MIDI, para
                                   escoitalo (sen --clave nin
                                   --cifrados; con --programa 0…127,
                                   General MIDI)                         armonia midi acordes Do Lam Re7 Sol7 Do > progresion.mid
      tonnetz <notas>              Tonnetz en SVG dunhas notas           armonia tonnetz Do Mi Sol Si > tonnetz.svg
      tonnetz --acorde <cifrado> | --escala <escala> | --clases <números>
                                   dun acorde, unha escala ou un
                                   conxunto de clases de altura          armonia tonnetz --escala Re dórico > dorico.svg
      tonnetz --recorrido <tríades> | --camino <tríade> <tríade>
                                   un percorrido de tríades, con
                                   frechas, ou o camiño máis curto por
                                   P, L e R                              armonia tonnetz --recorrido Do Lam Fa Rem > recorrido.svg
      tonnetz --ciclo <ciclo> <tríade>
                                   un ciclo hexatónico, octatónico ou
                                   LR (--margen 2: máis rede arredor)    armonia tonnetz --ciclo hexatonico Do > ciclo.svg
      tabla <notas ou alturas>     táboa harmónica en SVG (hexágonos)    armonia tabla Do3 Sol3 Mi4 > tabla.svg
      tabla --acorde | --escala | --clases | --recorrido | --camino | --ciclo
                                   como no Tonnetz (--margen 2: máis
                                   táboa arredor)                        armonia tabla --acorde Domaj7 > domaj7.svg
      vecinos <acorde> [--voces 2] acordes a un semiton (sétimas:
                                   dominante, menor, semidiminuída e
                                   diminuída; tríades: maior, menor e
                                   aumentada; --ampliada: tamén cos
                                   maj7)                                 armonia vecinos Sol7
      conduccion-parsimoniosa <acorde> <acorde> [--voces 2] [--ampliada]
                                   dun acorde a outro movendo unha voz
                                   (ou dúas) un semiton en cada paso     armonia conduccion-parsimoniosa Sol7 Rem7
      conduccion <acorde> <acorde> a condución con menos semitons        armonia conduccion Sol7 Do
      plr <tríade> <P, L, R…>      transformacións neorriemannianas      armonia plr Do PLR
      plr <tríade> <tríade>        o camiño máis curto por P, L e R      armonia plr Do Mibm
      plr <tríade> <ciclo>         un ciclo: hexatonico (P, L),
                                   octatonico (P, R) ou "ciclo LR"       armonia plr Do hexatonico
      digitaciones <cifrado>… [opcións]
                                   formas de tocar un acorde, da máis
                                   cómoda á menos, nun instrumento de
                                   corda con trastes
                                   opcións: --instrumento guitarra|bajo|ukelele|mandolina|… (tamén
                                   «guitarra de siete cuerdas», «bajo de 5 cuerdas», «drop D»),
                                   --limite 5, --traste 12 (o máis alto que se usa), --dedos 4 (os
                                   que se poden usar), --completo (con todas as notas: por defecto
                                   a quinta pode faltar), --diagrama (unha liña por corda)
                                                                         armonia digitaciones Sol7/Si --instrumento ukelele
      ayuda                        esta axuda

    Acéptanse nomes de nota en castelán, catalán, galego, éuscaro ou inglés (Do, C, Sib, Bb, si
    bemol). Con --idioma gl, a resposta usa a notación galega e as mensaxes en galego; con
    --ingles, en inglés.
    """

    /// La ayuda en euskera (`armonia ayuda --idioma eu`).
    public static let laguntza = """
    armonia: musika-teoria komando-lerrotik.

    Erabilera: armonia <agindua> <argumentuak> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

    Aginduak (aginduak eta aukerak gaztelaniaz edo ingelesez idazten dira):
      acorde <zifratua>…           notak, mota eta nota bakoitzaren
                                   papera                                armonia acorde Sol7/Si
      identificar <notak>          nota batzuek osatzen dituzten
                                   akordeak                              armonia identificar Do Mi Sol Sib
      intervalo <nota> <nota>      bi nota edo altueren arteko tartea    armonia intervalo Do4 Mi5
      escala <eskala>              eskala baten notak eta akordeak       armonia escala Re dórico
      tonalidad <tonalitatea>      armadura, erlatiboak eta graduak      armonia tonalidad La menor
      analizar <akordeak> [--en <tonalitatea>]
                                   zifratu erromatarra, funtzioak,
                                   kadentziak eta modulazioak (pibota
                                   barne; --en gabe)                     armonia analizar Do Fa Sol7 Do Lam Re7 Sol
      armonizar <melodia> [--en <tonalitatea>] [--propuestas 3]
                                   melodia baterako akordeak, onenetik
                                   txarrenera; zortzidunekin (Mi4), lau
                                   ahotseko korala ere bai               armonia armonizar Mi4 Fa4 Re4 Do4
      realizar <akordeak> [--en <tonalitatea>]
                                   akordeak lau ahotsetara, ahots-
                                   eramate akatsik gabe                  armonia realizar Do Fa Sol7 Do
      revisar <akordeak>           ahots-eramate akatsak (bosgarren
                                   paraleloak…); akordeak baxutik
                                   altura, komaz bereizita               armonia revisar Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4
      musicxml melodia <gertaerak> [aukerak]
                                   melodia baten MusicXML partitura      armonia musicxml melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4 > melodia.musicxml
      musicxml coral <akordeak> [aukerak]
                                   lau ahotseko korala MusicXMLn         armonia musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 > coral.musicxml
      musicxml acordes <zifratuak> [aukerak]
                                   progresioa zifratu eta analisiarekin  armonia musicxml acordes Do Lam Re7 Sol7 Do > progresion.musicxml
                                   aukerak: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,
                                   --clave fa, --tempo 90 (edo --tempo 60 4.), --titulo Nire
                                   korala, --duracion 2 (akorde bakoitzaren iraupena; bestela
                                   beltza koralean eta zuria akordeetan), --cifrados eta --analisis
                                   (koralean: zifratu amerikarra goian, erromatarra eta funtzioa
                                   behean)
      midi melodia|coral|acordes <…> [aukerak]
                                   gauza bera MIDI fitxategi gisa,
                                   entzuteko (--clave eta --cifrados
                                   gabe; --programa 0…127, General
                                   MIDI)                                 armonia midi acordes Do Lam Re7 Sol7 Do > progresion.mid
      tonnetz <notak>              nota batzuen Tonnetza SVGn            armonia tonnetz Do Mi Sol Si > tonnetz.svg
      tonnetz --acorde <zifratua> | --escala <eskala> | --clases <zenbakiak>
                                   akorde, eskala edo altuera-klase
                                   multzo batena                         armonia tonnetz --escala Re dórico > dorico.svg
      tonnetz --recorrido <triadeak> | --camino <triadea> <triadea>
                                   triade-ibilbide bat, geziekin, edo
                                   P, L eta R bidezko biderik laburrena  armonia tonnetz --recorrido Do Lam Fa Rem > recorrido.svg
      tonnetz --ciclo <zikloa> <triadea>
                                   ziklo hexatoniko, oktatoniko edo LR
                                   bat (--margen 2: sare gehiago
                                   inguruan)                             armonia tonnetz --ciclo hexatonico Do > ciclo.svg
      tabla <notak edo altuerak>   taula harmonikoa SVGn (hexagonoak)    armonia tabla Do3 Sol3 Mi4 > tabla.svg
      tabla --acorde | --escala | --clases | --recorrido | --camino | --ciclo
                                   Tonnetzean bezala (--margen 2: taula
                                   gehiago inguruan)                     armonia tabla --acorde Domaj7 > domaj7.svg
      vecinos <akordea> [--voces 2]
                                   tonuerdi batera dauden akordeak
                                   (zazpigarrenak: dominantea, txikia,
                                   erdi-gutxitua eta gutxitua;
                                   triadeak: handia, txikia eta
                                   gehitua; --ampliada: maj7ekin ere)    armonia vecinos Sol7
      conduccion-parsimoniosa <akordea> <akordea> [--voces 2] [--ampliada]
                                   akorde batetik bestera, urrats
                                   bakoitzean ahots bat (edo bi)
                                   tonuerdi bat mugituz                  armonia conduccion-parsimoniosa Sol7 Rem7
      conduccion <akordea> <akordea>
                                   tonuerdi gutxieneko ahots-eramatea    armonia conduccion Sol7 Do
      plr <triadea> <P, L, R…>     eraldaketa neoerriemanndarrak         armonia plr Do PLR
      plr <triadea> <triadea>      P, L eta R bidezko biderik laburrena  armonia plr Do Mibm
      plr <triadea> <zikloa>       ziklo bat: hexatonico (P, L),
                                   octatonico (P, R) edo "ciclo LR"      armonia plr Do hexatonico
      digitaciones <zifratua>… [aukerak]
                                   akorde bat jotzeko moduak,
                                   erosoenetik gutxien erosora,
                                   trasteak dituen hari-instrumentu
                                   batean
                                   aukerak: --instrumento guitarra|bajo|ukelele|mandolina|… (baita
                                   «guitarra de siete cuerdas», «bajo de 5 cuerdas», «drop D» ere),
                                   --limite 5, --traste 12 (erabiltzen den altuena), --dedos 4
                                   (erabil daitezkeenak), --completo (nota guztiekin: berez
                                   bosgarrena falta daiteke), --diagrama (lerro bat hari
                                   bakoitzeko)
                                                                         armonia digitaciones Sol7/Si --instrumento ukelele
      ayuda                        laguntza hau

    Nota-izenak gaztelaniaz, katalanez, galegoz, euskaraz edo ingelesez onartzen dira (Do, C,
    Sib, Bb, si bemol). --idioma eu erabiliz, erantzunak euskal notazioa eta euskarazko mezuak
    ditu; --ingles erabiliz, ingelesez.
    """

    /// La ayuda en portugués (`armonia ayuda --idioma pt`).
    public static let ajudaEmPortugues = """
    armonia: teoria musical a partir da linha de comandos.

    Uso: armonia <comando> <argumentos> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

    Comandos (os comandos e as opções escrevem-se em espanhol ou em inglês):
      acorde <cifra>…              notas, tipo e papel de cada nota      armonia acorde Sol7/Si
      identificar <notas>          acordes que algumas notas formam      armonia identificar Do Mi Sol Sib
      intervalo <nota> <nota>      intervalo entre duas notas ou
                                   alturas                               armonia intervalo Do4 Mi5
      escala <escala>              notas e acordes de uma escala         armonia escala Re dórico
      tonalidad <tonalidade>       armadura, relativas e graus           armonia tonalidad La menor
      analizar <acordes> [--en <tonalidade>]
                                   cifra romana, funções, cadências e
                                   modulações (com o acorde pivô; sem
                                   --en)                                 armonia analizar Do Fa Sol7 Do Lam Re7 Sol
      armonizar <melodia> [--en <tonalidade>] [--propuestas 3]
                                   acordes para uma melodia, do melhor
                                   para o pior; com oitavas (Mi4),
                                   também o coral a quatro vozes         armonia armonizar Mi4 Fa4 Re4 Do4
      realizar <acordes> [--en <tonalidade>]
                                   os acordes a quatro vozes, sem erros
                                   de condução                           armonia realizar Do Fa Sol7 Do
      revisar <acordes>            erros de condução (quintas
                                   paralelas…); acordes do grave ao
                                   agudo, separados por vírgulas         armonia revisar Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4
      musicxml melodia <eventos> [opções]
                                   partitura MusicXML de uma melodia     armonia musicxml melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4 > melodia.musicxml
      musicxml coral <acordes> [opções]
                                   coral a quatro vozes em MusicXML      armonia musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 > coral.musicxml
      musicxml acordes <cifras> [opções]
                                   progressão com cifras e análise       armonia musicxml acordes Do Lam Re7 Sol7 Do > progresion.musicxml
                                   opções: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,
                                   --clave fa, --tempo 90 (ou --tempo 60 4.), --titulo O meu coral,
                                   --duracion 2 (o que dura cada acorde; semínima no coral e mínima
                                   nos acordes, se não), --cifrados e --analisis (no coral: cifra
                                   americana em cima, romana e função em baixo)
      midi melodia|coral|acordes <…> [opções]
                                   o mesmo como ficheiro MIDI, para
                                   ouvir (sem --clave nem --cifrados;
                                   com --programa 0…127, General MIDI)   armonia midi acordes Do Lam Re7 Sol7 Do > progresion.mid
      tonnetz <notas>              Tonnetz em SVG de algumas notas       armonia tonnetz Do Mi Sol Si > tonnetz.svg
      tonnetz --acorde <cifra> | --escala <escala> | --clases <números>
                                   de um acorde, uma escala ou um
                                   conjunto de classes de altura         armonia tonnetz --escala Re dórico > dorico.svg
      tonnetz --recorrido <tríades> | --camino <tríade> <tríade>
                                   um percurso de tríades, com setas,
                                   ou o caminho mais curto por P, L e R  armonia tonnetz --recorrido Do Lam Fa Rem > recorrido.svg
      tonnetz --ciclo <ciclo> <tríade>
                                   um ciclo hexatónico, octatónico ou
                                   LR (--margen 2: mais rede em volta)   armonia tonnetz --ciclo hexatonico Do > ciclo.svg
      tabla <notas ou alturas>     tabela harmónica em SVG (hexágonos)   armonia tabla Do3 Sol3 Mi4 > tabla.svg
      tabla --acorde | --escala | --clases | --recorrido | --camino | --ciclo
                                   como no Tonnetz (--margen 2: mais
                                   tabela em volta)                      armonia tabla --acorde Domaj7 > domaj7.svg
      vecinos <acorde> [--voces 2] acordes a um meio-tom (sétimas:
                                   dominante, menor, meio-diminuta e
                                   diminuta; tríades: maior, menor e
                                   aumentada; --ampliada: também com os
                                   maj7)                                 armonia vecinos Sol7
      conduccion-parsimoniosa <acorde> <acorde> [--voces 2] [--ampliada]
                                   de um acorde a outro movendo uma voz
                                   (ou duas) um meio-tom em cada passo   armonia conduccion-parsimoniosa Sol7 Rem7
      conduccion <acorde> <acorde> a condução com menos meios-tons       armonia conduccion Sol7 Do
      plr <tríade> <P, L, R…>      transformações neorriemannianas       armonia plr Do PLR
      plr <tríade> <tríade>        o caminho mais curto por P, L e R     armonia plr Do Mibm
      plr <tríade> <ciclo>         um ciclo: hexatonico (P, L),
                                   octatonico (P, R) ou "ciclo LR"       armonia plr Do hexatonico
      digitaciones <cifra>… [opções]
                                   formas de tocar um acorde, da mais
                                   cómoda à menos, num instrumento de
                                   cordas com trastes
                                   opções: --instrumento guitarra|bajo|ukelele|mandolina|… (também
                                   «guitarra de siete cuerdas», «bajo de 5 cuerdas», «drop D»),
                                   --limite 5, --traste 12 (o traste mais alto usado), --dedos 4 (os
                                   que se podem usar), --completo (com todas as notas: por omissão a
                                   quinta pode faltar), --diagrama (uma linha por corda)
                                                                         armonia digitaciones Sol7/Si --instrumento ukelele
      ayuda                        esta ajuda

    Aceitam-se nomes de nota em espanhol, catalão, galego, basco, português ou inglês (Do, C,
    Sib, Bb, si bemol, ré). Com --idioma pt, a resposta usa a notação portuguesa e as mensagens
    em português; com --ingles, em inglês.
    """

    /// La ayuda en francés (`armonia ayuda --idioma fr`).
    public static let aide = """
    armonia : théorie musicale en ligne de commande.

    Utilisation : armonia <commande> <arguments> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

    Commandes (les commandes et les options s'écrivent en espagnol ou en anglais) :
      acorde <chiffrage>…          notes, type et rôle de chaque note    armonia acorde Sol7/Si
      identificar <notes>          accords que forment des notes         armonia identificar Do Mi Sol Sib
      intervalo <note> <note>      intervalle entre deux notes ou
                                   hauteurs                              armonia intervalo Do4 Mi5
      escala <gamme>               notes et accords d'une gamme          armonia escala Re dórico
      tonalidad <tonalité>         armure, relatives et degrés           armonia tonalidad La menor
      analizar <accords> [--en <tonalité>]
                                   chiffrage romain, fonctions,
                                   cadences et modulations (avec
                                   l'accord pivot ; sans --en)           armonia analizar Do Fa Sol7 Do Lam Re7 Sol
      armonizar <mélodie> [--en <tonalité>] [--propuestas 3]
                                   accords pour une mélodie, du
                                   meilleur au moins bon ; avec octaves
                                   (Mi4), aussi le choral à quatre voix  armonia armonizar Mi4 Fa4 Re4 Do4
      realizar <accords> [--en <tonalité>]
                                   les accords à quatre voix, sans
                                   faute de conduite des voix            armonia realizar Do Fa Sol7 Do
      revisar <accords>            fautes de conduite des voix (quintes
                                   parallèles…) ; accords du grave à
                                   l'aigu, séparés par des virgules      armonia revisar Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4
      musicxml melodia <événements> [options]
                                   partition MusicXML d'une mélodie      armonia musicxml melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4 > melodia.musicxml
      musicxml coral <accords> [options]
                                   choral à quatre voix en MusicXML      armonia musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 > coral.musicxml
      musicxml acordes <chiffrages> [options]
                                   progression avec chiffrages et
                                   analyse                               armonia musicxml acordes Do Lam Re7 Sol7 Do > progresion.musicxml
                                   options : --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,
                                   --clave fa, --tempo 90 (ou --tempo 60 4.), --titulo Mon choral,
                                   --duracion 2 (la durée de chaque accord ; noire dans le choral
                                   et blanche dans les accords sinon), --cifrados et --analisis
                                   (dans le choral : chiffrage américain au-dessus, romain et
                                   fonction au-dessous)
      midi melodia|coral|acordes <…> [options]
                                   la même chose en fichier MIDI, pour
                                   l'écouter (sans --clave ni
                                   --cifrados ; avec --programa 0…127,
                                   General MIDI)                         armonia midi acordes Do Lam Re7 Sol7 Do > progresion.mid
      tonnetz <notes>              Tonnetz en SVG de quelques notes      armonia tonnetz Do Mi Sol Si > tonnetz.svg
      tonnetz --acorde <chiffrage> | --escala <gamme> | --clases <nombres>
                                   d'un accord, d'une gamme ou d'un
                                   ensemble de classes de hauteur        armonia tonnetz --escala Re dórico > dorico.svg
      tonnetz --recorrido <triades> | --camino <triade> <triade>
                                   un parcours de triades, avec des
                                   flèches, ou le chemin le plus court
                                   par P, L et R                         armonia tonnetz --recorrido Do Lam Fa Rem > recorrido.svg
      tonnetz --ciclo <cycle> <triade>
                                   un cycle hexatonique, octatonique ou
                                   LR (--margen 2 : plus de réseau
                                   autour)                               armonia tonnetz --ciclo hexatonico Do > ciclo.svg
      tabla <notes ou hauteurs>    table harmonique en SVG (hexagones)   armonia tabla Do3 Sol3 Mi4 > tabla.svg
      tabla --acorde | --escala | --clases | --recorrido | --camino | --ciclo
                                   comme pour le Tonnetz (--margen 2 :
                                   plus de table autour)                 armonia tabla --acorde Domaj7 > domaj7.svg
      vecinos <accord> [--voces 2] accords à un demi-ton (septièmes :
                                   de dominante, mineure, semi-diminuée
                                   et diminuée ; triades : majeure,
                                   mineure et augmentée ; --ampliada :
                                   aussi avec les maj7)                  armonia vecinos Sol7
      conduccion-parsimoniosa <accord> <accord> [--voces 2] [--ampliada]
                                   d'un accord à l'autre en bougeant
                                   une voix (ou deux) d'un demi-ton à
                                   chaque étape                          armonia conduccion-parsimoniosa Sol7 Rem7
      conduccion <accord> <accord> la conduite avec le moins de demi-
                                   tons                                  armonia conduccion Sol7 Do
      plr <triade> <P, L, R…>      transformations néo-riemanniennes     armonia plr Do PLR
      plr <triade> <triade>        le chemin le plus court par P, L et
                                   R                                     armonia plr Do Mibm
      plr <triade> <cycle>         un cycle : hexatonico (P, L),
                                   octatonico (P, R) ou « ciclo LR »     armonia plr Do hexatonico
      digitaciones <chiffrage>… [options]
                                   façons de jouer un accord, de la
                                   plus commode à la moins commode, sur
                                   un instrument à cordes et à frettes
                                   options : --instrumento guitarra|bajo|ukelele|mandolina|… (aussi
                                   « guitarra de siete cuerdas », « bajo de 5 cuerdas », « drop D
                                   »), --limite 5, --traste 12 (la case la plus haute utilisée),
                                   --dedos 4 (ceux qu'on peut utiliser), --completo (avec toutes
                                   les notes : par défaut la quinte peut manquer), --diagrama (une
                                   ligne par corde)
                                                                         armonia digitaciones Sol7/Si --instrumento ukelele
      ayuda                        cette aide

    Les noms de note s'écrivent en espagnol, catalan, galicien, basque, portugais ou anglais
    (Do, C, Sib, Bb, si bemol, ré). Avec --idioma fr, la réponse utilise la notation française
    et les messages en français ; avec --ingles, en anglais.
    """

    /// La ayuda en italiano (`armonia ayuda --idioma it`).
    public static let aiuto = """
    armonia: teoria musicale dalla riga di comando.

    Uso: armonia <comando> <argomenti> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

    Comandi (i comandi e le opzioni si scrivono in spagnolo o in inglese):
      acorde <sigla>…              note, tipo e ruolo di ogni nota       armonia acorde Sol7/Si
      identificar <note>           accordi che formano alcune note       armonia identificar Do Mi Sol Sib
      intervalo <nota> <nota>      intervallo tra due note o altezze     armonia intervalo Do4 Mi5
      escala <scala>               note e accordi di una scala           armonia escala Re dórico
      tonalidad <tonalità>         armatura, relative e gradi            armonia tonalidad La menor
      analizar <accordi> [--en <tonalità>]
                                   numeri romani, funzioni, cadenze e
                                   modulazioni (con l'accordo perno;
                                   senza --en)                           armonia analizar Do Fa Sol7 Do Lam Re7 Sol
      armonizar <melodia> [--en <tonalità>] [--propuestas 3]
                                   accordi per una melodia, dal
                                   migliore al peggiore; con le ottave
                                   (Mi4), anche il corale a quattro
                                   voci                                  armonia armonizar Mi4 Fa4 Re4 Do4
      realizar <accordi> [--en <tonalità>]
                                   gli accordi a quattro voci, senza
                                   errori di condotta delle parti        armonia realizar Do Fa Sol7 Do
      revisar <accordi>            errori di condotta delle parti
                                   (quinte parallele…); accordi dal
                                   grave all'acuto, separati da virgole  armonia revisar Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4
      musicxml melodia <eventi> [opzioni]
                                   partitura MusicXML di una melodia     armonia musicxml melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4 > melodia.musicxml
      musicxml coral <accordi> [opzioni]
                                   corale a quattro voci in MusicXML     armonia musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 > coral.musicxml
      musicxml acordes <sigle> [opzioni]
                                   progressione con sigle e analisi      armonia musicxml acordes Do Lam Re7 Sol7 Do > progresion.musicxml
                                   opzioni: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,
                                   --clave fa, --tempo 90 (o --tempo 60 4.), --titulo Il mio
                                   corale, --duracion 2 (quanto dura ogni accordo; semiminima nel
                                   corale e minima negli accordi, altrimenti), --cifrados e
                                   --analisis (nel corale: sigla americana sopra, numero romano e
                                   funzione sotto)
      midi melodia|coral|acordes <…> [opzioni]
                                   lo stesso come file MIDI, per
                                   ascoltarlo (senza --clave né
                                   --cifrados; con --programa 0…127,
                                   General MIDI)                         armonia midi acordes Do Lam Re7 Sol7 Do > progresion.mid
      tonnetz <note>               Tonnetz in SVG di alcune note         armonia tonnetz Do Mi Sol Si > tonnetz.svg
      tonnetz --acorde <sigla> | --escala <scala> | --clases <numeri>
                                   di un accordo, una scala o un
                                   insieme di classi di altezza          armonia tonnetz --escala Re dórico > dorico.svg
      tonnetz --recorrido <triadi> | --camino <triade> <triade>
                                   un percorso di triadi, con frecce, o
                                   il cammino più breve per P, L e R     armonia tonnetz --recorrido Do Lam Fa Rem > recorrido.svg
      tonnetz --ciclo <ciclo> <triade>
                                   un ciclo esatonico, ottatonico o LR
                                   (--margen 2: più rete intorno)        armonia tonnetz --ciclo hexatonico Do > ciclo.svg
      tabla <note o altezze>       tabella armonica in SVG (esagoni)     armonia tabla Do3 Sol3 Mi4 > tabla.svg
      tabla --acorde | --escala | --clases | --recorrido | --camino | --ciclo
                                   come nel Tonnetz (--margen 2: più
                                   tabella intorno)                      armonia tabla --acorde Domaj7 > domaj7.svg
      vecinos <accordo> [--voces 2]
                                   accordi a un semitono (settime: di
                                   dominante, minore, semidiminuita e
                                   diminuita; triadi: maggiore, minore
                                   e aumentata; --ampliada: anche con
                                   le maj7)                              armonia vecinos Sol7
      conduccion-parsimoniosa <accordo> <accordo> [--voces 2] [--ampliada]
                                   da un accordo all'altro muovendo una
                                   voce (o due) di un semitono a ogni
                                   passo                                 armonia conduccion-parsimoniosa Sol7 Rem7
      conduccion <accordo> <accordo>
                                   la condotta con meno semitoni         armonia conduccion Sol7 Do
      plr <triade> <P, L, R…>      trasformazioni neoriemanniane         armonia plr Do PLR
      plr <triade> <triade>        il cammino più breve per P, L e R     armonia plr Do Mibm
      plr <triade> <ciclo>         un ciclo: hexatonico (P, L),
                                   octatonico (P, R) o «ciclo LR»        armonia plr Do hexatonico
      digitaciones <sigla>… [opzioni]
                                   modi di suonare un accordo, dal più
                                   comodo al meno comodo, su uno
                                   strumento a corde con tasti
                                   opzioni: --instrumento guitarra|bajo|ukelele|mandolina|… (anche
                                   «guitarra de siete cuerdas», «bajo de 5 cuerdas», «drop D»),
                                   --limite 5, --traste 12 (il tasto più alto usato), --dedos 4
                                   (quelle che si possono usare), --completo (con tutte le note: di
                                   solito la quinta può mancare), --diagrama (una riga per corda)
                                                                         armonia digitaciones Sol7/Si --instrumento ukelele
      ayuda                        questo aiuto

    I nomi delle note si scrivono in spagnolo, catalano, galiziano, basco, portoghese o inglese
    (Do, C, Sib, Bb, si bemol, ré). Con --idioma it, la risposta usa la notazione italiana e i
    messaggi in italiano; con --ingles, in inglese.
    """

    /// Ejecuta una orden con sus argumentos (sin el nombre del programa).
    public static func ejecutar(_ argumentos: [String]) -> ResultadoDeOrden {
        var argumentos = argumentos
        let ingles = argumentos.contains("--ingles") || argumentos.contains("--english")
        argumentos.removeAll { $0 == "--ingles" || $0 == "--english" }
        var notacion: Nomenclatura = ingles ? .ingles : .espanol
        if let i = argumentos.firstIndex(where: { $0 == "--idioma" || $0 == "--language" }) {
            guard i + 1 < argumentos.count else { return uso(.faltaValor(String(argumentos[i].dropFirst(2))), notacion) }
            guard let elegida = notacionDelIdioma(argumentos[i + 1]) else {
                return uso(.idiomaDesconocido(argumentos[i + 1]), notacion)
            }
            notacion = elegida
            argumentos.removeSubrange(i...(i + 1))
        }

        guard let orden = argumentos.first?.lowercased() else { return bien(ayuda(en: notacion)) }
        let resto = Array(argumentos.dropFirst())
        do {
            switch orden {
            case "ayuda", "help", "-h", "--help", "--ayuda":
                return bien(ayuda(en: notacion))
            case "acorde", "chord":
                guard !resto.isEmpty else { return uso(.faltaCifrado, notacion) }
                return bien(try resto.map { try describir(acorde: Acorde(leyendo: $0), notacion) }.joined(separator: "\n\n"))
            case "identificar", "identify":
                guard !resto.isEmpty else { return uso(.faltanNotas, notacion) }
                return bien(try identificar(resto, notacion))
            case "intervalo", "interval":
                guard resto.count == 2 else { return uso(.dosNotas, notacion) }
                return bien(try intervalo(resto[0], resto[1], notacion))
            case "escala", "scale":
                guard !resto.isEmpty else { return uso(.faltaEscala, notacion) }
                return bien(describir(escala: try Escala(leyendo: resto.joined(separator: " ")), notacion))
            case "tonalidad", "key":
                guard !resto.isEmpty else { return uso(.faltaTonalidad, notacion) }
                return bien(describir(tonalidad: try Tonalidad(leyendo: resto.joined(separator: " ")), notacion))
            case "analizar", "analyze", "analyse":
                return try analizar(resto, notacion)
            case "armonizar", "harmonize", "harmonise":
                return try armonizar(resto, notacion)
            case "realizar", "realize", "realise":
                return try realizar(resto, notacion)
            case "revisar", "check", "voces", "voices":
                guard !resto.isEmpty else { return uso(.faltanAcordesDeLasVoces, notacion) }
                return bien(describir(conduccion: try ConduccionDeVoces(leyendo: resto.joined(separator: " ")), notacion))
            case "tonnetz":
                return try tonnetz(resto, notacion)
            case "tabla", "tabla-armonica", "harmonic-table":
                return try tablaArmonica(resto, notacion)
            case "vecinos", "neighbors":
                return try vecinos(resto, notacion)
            case "conduccion-parsimoniosa", "conducción-parsimoniosa", "smooth-path", "camino", "path":
                return try caminoParsimonioso(resto, notacion)
            case "conduccion", "conducción", "voice-leading":
                guard resto.count == 2 else { return uso(.dosAcordesDeConduccion, notacion) }
                let conduccion = try Acorde(leyendo: resto[0]).conduccionMinima(hasta: try Acorde(leyendo: resto[1]))
                return bien(conduccion.texto(notacion))
            case "digitaciones", "digitacion", "digitación", "fingerings":
                return try digitaciones(resto, notacion)
            case "plr", "neorriemanniano", "neoriemannian":
                return try plr(resto, notacion)
            case "musicxml":
                return try partitura(resto, notacion, formato: .musicXML)
            case "midi":
                return try partitura(resto, notacion, formato: .midi)
            default:
                return uso(.ordenDesconocida(orden), notacion)
            }
        } catch let error as ErrorDeLectura {
            return ResultadoDeOrden(salida: "", error: error.descripcion(en: notacion) + "\n", codigo: 1)
        } catch {
            return ResultadoDeOrden(salida: "", error: "\(error)\n", codigo: 1)
        }
    }

    // MARK: Auxiliares

    static func binario(_ datos: Data) -> ResultadoDeOrden {
        ResultadoDeOrden(salida: "", error: "", codigo: 0, datos: datos)
    }

    static func bien(_ texto: String) -> ResultadoDeOrden {
        ResultadoDeOrden(salida: texto + "\n", error: "", codigo: 0)
    }

    static func uso(_ error: ErrorDeUso, _ notacion: Nomenclatura) -> ResultadoDeOrden {
        ResultadoDeOrden(salida: "", error: error.texto(en: notacion), codigo: 2)
    }

    /// La ayuda en el idioma de los textos de la notación (`Nomenclatura.idiomaDeLosTextos`).
    public static func ayuda(en notacion: Nomenclatura) -> String {
        switch notacion.idiomaDeLosTextos {
        case .ingles, .aleman, .occitano, .ruso, .griego: return help
        case .catalan: return ajuda
        case .gallego: return axuda
        case .euskera: return laguntza
        case .portugues: return ajudaEmPortugues
        case .frances: return aide
        case .italiano: return aiuto
        case .espanol: return ayuda
        }
    }

    /// La notación de `--idioma`: es, en, ca, gl, eu, pt, fr o it, o el nombre del idioma.
    static func notacionDelIdioma(_ texto: String) -> Nomenclatura? {
        switch texto.lowercased() {
        case "es", "espanol", "español", "castellano": return .espanol
        case "en", "ingles", "inglés", "english": return .ingles
        case "ca", "catalan", "catalán", "català": return .catalan
        case "gl", "gallego", "galego": return .gallego
        case "eu", "euskera", "euskara": return .euskera
        case "pt", "portugues", "portugués", "português": return .portugues
        case "fr", "frances", "francés", "français", "francais": return .frances
        case "it", "italiano": return .italiano
        default: return nil
        }
    }
}
