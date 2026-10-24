import Armonia

// MARK: - La ayuda
//
// La ayuda de `armonia` en los ocho idiomas de los textos, montada a partir de una tabla de órdenes:
// cada orden tiene su sintaxis, su descripción, un ejemplo y, si hace falta, unas notas, cada cosa
// en los ocho idiomas (`Traduccion` no compila si falta alguno). Las columnas se calculan: la
// sintaxis va en la columna 2, la descripción en la 31 y el ejemplo en la 69. Una sintaxis que no
// cabe en su columna deja la descripción en la línea siguiente, y un ejemplo que no cabe al final
// de la descripción va en una línea propia.

extension LineaDeComandos {
    /// Una orden de la ayuda. Cada texto puede tener varias líneas (separadas por "\n"), cortadas
    /// a mano en cada idioma.
    struct EntradaDeAyuda: Sendable {
        /// Una línea por cada forma de escribir la orden.
        let sintaxis: Traduccion
        let descripcion: Traduccion
        /// Se escribe al final de la descripción, en la columna de los ejemplos.
        var ejemplo: Traduccion? = nil
        /// Líneas que siguen al ejemplo, en la columna de la descripción. Un texto vacío es que no hay.
        var notas: Traduccion? = nil
    }

    static let columnaDeLaSintaxis = 2
    static let columnaDeLaDescripcion = 31
    static let columnaDelEjemplo = 69

    /// La ayuda completa en un idioma (el alemán, el occitano, el ruso y el griego la toman en inglés).
    static func textoDeAyuda(en idioma: Idioma) -> String {
        let ordenes = ordenesDeLaAyuda.flatMap { lineas(de: $0, en: idioma) }
        return ([cabeceraDeLaAyuda.texto(en: idioma)] + ordenes + ["", pieDeLaAyuda.texto(en: idioma)])
            .joined(separator: "\n")
    }

    static func lineas(de entrada: EntradaDeAyuda, en idioma: Idioma) -> [String] {
        func columna(_ n: Int) -> String { String(repeating: " ", count: n) }
        func rellenar(_ texto: String, hasta ancho: Int) -> String {
            texto + columna(max(0, ancho - texto.count))
        }
        let sintaxis = entrada.sintaxis.texto(en: idioma).components(separatedBy: "\n")
        var descripcion = entrada.descripcion.texto(en: idioma).components(separatedBy: "\n")[...]
        var lineas = sintaxis.map { columna(columnaDeLaSintaxis) + $0 }
        // La primera línea de la descripción va junto a la sintaxis si queda al menos un espacio.
        if let primera = descripcion.first, let ultima = lineas.last, ultima.count < columnaDeLaDescripcion {
            lineas[lineas.count - 1] = rellenar(ultima, hasta: columnaDeLaDescripcion) + primera
            descripcion = descripcion.dropFirst()
        }
        lineas += descripcion.map { columna(columnaDeLaDescripcion) + $0 }
        if let ejemplo = entrada.ejemplo?.texto(en: idioma), !ejemplo.isEmpty {
            if let ultima = lineas.last, ultima.count < columnaDelEjemplo {
                lineas[lineas.count - 1] = rellenar(ultima, hasta: columnaDelEjemplo) + ejemplo
            } else {
                lineas.append(columna(columnaDelEjemplo) + ejemplo)
            }
        }
        if let notas = entrada.notas?.texto(en: idioma), !notas.isEmpty {
            lineas += notas.components(separatedBy: "\n").map { columna(columnaDeLaDescripcion) + $0 }
        }
        return lineas
    }

    /// Un ejemplo, que se escribe igual en todos los idiomas salvo en inglés (con los nombres ingleses
    /// de las órdenes y las notas).
    static func ejemplo(_ espanol: String, _ ingles: String) -> Traduccion {
        Traduccion(espanol, ingles, ca: espanol, gl: espanol, eu: espanol, pt: espanol, fr: espanol, it: espanol)
    }

    /// Lo que va antes de las órdenes: qué es, cómo se usa y el título de la lista.
    static let cabeceraDeLaAyuda = Traduccion(
        """
        armonia: teoría musical desde la línea de comandos.

        Uso: armonia <orden> <argumentos> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

        Órdenes:
        """,
        """
        armonia: music theory from the command line.

        Usage: armonia <command> <arguments> [--ingles | --language es|en|ca|gl|eu|pt|fr|it]

        Commands:
        """,
        ca: """
        armonia: teoria musical des de la línia d'ordres.

        Ús: armonia <ordre> <arguments> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

        Ordres (les ordres i les opcions s'escriuen en castellà o en anglès):
        """,
        gl: """
        armonia: teoría musical desde a liña de comandos.

        Uso: armonia <orde> <argumentos> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

        Ordes (as ordes e as opcións escríbense en castelán ou en inglés):
        """,
        eu: """
        armonia: musika-teoria komando-lerrotik.

        Erabilera: armonia <agindua> <argumentuak> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

        Aginduak (aginduak eta aukerak gaztelaniaz edo ingelesez idazten dira):
        """,
        pt: """
        armonia: teoria musical a partir da linha de comandos.

        Uso: armonia <comando> <argumentos> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

        Comandos (os comandos e as opções escrevem-se em espanhol ou em inglês):
        """,
        fr: """
        armonia : théorie musicale en ligne de commande.

        Utilisation : armonia <commande> <arguments> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

        Commandes (les commandes et les options s'écrivent en espagnol ou en anglais) :
        """,
        it: """
        armonia: teoria musicale dalla riga di comando.

        Uso: armonia <comando> <argomenti> [--ingles | --idioma es|en|ca|gl|eu|pt|fr|it]

        Comandi (i comandi e le opzioni si scrivono in spagnolo o in inglese):
        """)

    /// Lo que sigue a las órdenes, tras una línea en blanco.
    static let pieDeLaAyuda = Traduccion(
        """
        Se aceptan nombres en español o en inglés (Do, C, Sib, Bb). Con --ingles, la respuesta
        usa la notación inglesa. Con --idioma ca, gl, eu, pt, fr o it, las notas, los nombres, los
        mensajes y esta ayuda salen en catalán, gallego, euskera, portugués, francés o italiano.
        Con --textos, los textos van en otro idioma que las notas: --idioma en --textos es.
        """,
        """
        Note names are accepted in Spanish or English (Do, C, Sib, Bb). With --ingles, the answer
        uses English notation, and so do messages and this help. With --language ca, gl, eu, pt, fr or
        it, notes, names, messages and this help are in Catalan, Galician, Basque, Portuguese, French or
        Italian.
        With --texts, the texts use another language than the notes: --language es --texts en.
        """,
        ca: """
        S'accepten noms de nota en castellà, català, gallec, basc o anglès (Do, C, Sib, Bb, si
        bemoll). Amb --idioma ca, la resposta fa servir la notació catalana i els missatges en
        català; amb --ingles, en anglès.
        Amb --textos, els textos van en un altre idioma que les notes: --idioma en --textos ca.
        """,
        gl: """
        Acéptanse nomes de nota en castelán, catalán, galego, éuscaro ou inglés (Do, C, Sib, Bb, si
        bemol). Con --idioma gl, a resposta usa a notación galega e as mensaxes en galego; con
        --ingles, en inglés.
        Con --textos, os textos van noutro idioma ca as notas: --idioma en --textos gl.
        """,
        eu: """
        Nota-izenak gaztelaniaz, katalanez, galegoz, euskaraz edo ingelesez onartzen dira (Do, C,
        Sib, Bb, si bemol). --idioma eu erabiliz, erantzunak euskal notazioa eta euskarazko mezuak
        ditu; --ingles erabiliz, ingelesez.
        --textos erabiliz, testuak notak ez bezalako hizkuntzan daude: --idioma en --textos eu.
        """,
        pt: """
        Aceitam-se nomes de nota em espanhol, catalão, galego, basco, português ou inglês (Do, C,
        Sib, Bb, si bemol, ré). Com --idioma pt, a resposta usa a notação portuguesa e as mensagens
        em português; com --ingles, em inglês.
        Com --textos, os textos saem noutra língua que as notas: --idioma en --textos pt.
        """,
        fr: """
        Les noms de note s'écrivent en espagnol, catalan, galicien, basque, portugais ou anglais
        (Do, C, Sib, Bb, si bemol, ré). Avec --idioma fr, la réponse utilise la notation française
        et les messages en français ; avec --ingles, en anglais.
        Avec --textos, les textes sont dans une autre langue que les notes : --idioma en --textos fr.
        """,
        it: """
        I nomi delle note si scrivono in spagnolo, catalano, galiziano, basco, portoghese o inglese
        (Do, C, Sib, Bb, si bemol, ré). Con --idioma it, la risposta usa la notazione italiana e i
        messaggi in italiano; con --ingles, in inglese.
        Con --textos, i testi sono in un'altra lingua rispetto alle note: --idioma en --textos it.
        """)

    static let ordenesDeLaAyuda: [EntradaDeAyuda] = [
        // acorde <cifrado>…
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "acorde <cifrado>…",
                "chord <symbol>…",
                ca: "acorde <xifrat>…",
                gl: "acorde <cifrado>…",
                eu: "acorde <zifratua>…",
                pt: "acorde <cifra>…",
                fr: "acorde <chiffrage>…",
                it: "acorde <sigla>…"),
            descripcion: Traduccion(
                "notas, tipo y papel de cada nota",
                "notes, type and role of each note",
                ca: "notes, tipus i paper de cada nota",
                gl: "notas, tipo e papel de cada nota",
                eu: "notak, mota eta nota bakoitzaren\npapera",
                pt: "notas, tipo e papel de cada nota",
                fr: "notes, type et rôle de chaque note",
                it: "note, tipo e ruolo di ogni nota"),
            ejemplo: ejemplo("armonia acorde Sol7/Si",
                             "armonia chord G7/B")),
        // identificar <notas>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "identificar <notas>",
                "identify <notes>",
                ca: "identificar <notes>",
                gl: "identificar <notas>",
                eu: "identificar <notak>",
                pt: "identificar <notas>",
                fr: "identificar <notes>",
                it: "identificar <note>"),
            descripcion: Traduccion(
                "acordes que forman unas notas",
                "chords formed by some notes",
                ca: "acords que formen unes notes",
                gl: "acordes que forman unhas notas",
                eu: "nota batzuek osatzen dituzten\nakordeak",
                pt: "acordes que algumas notas formam",
                fr: "accords que forment des notes",
                it: "accordi che formano alcune note"),
            ejemplo: ejemplo("armonia identificar Do Mi Sol Sib",
                             "armonia identify C E G Bb")),
        // intervalo <nota> <nota>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "intervalo <nota> <nota>",
                "interval <note> <note>",
                ca: "intervalo <nota> <nota>",
                gl: "intervalo <nota> <nota>",
                eu: "intervalo <nota> <nota>",
                pt: "intervalo <nota> <nota>",
                fr: "intervalo <note> <note>",
                it: "intervalo <nota> <nota>"),
            descripcion: Traduccion(
                "intervalo entre dos notas o alturas",
                "interval between two notes or pitches",
                ca: "interval entre dues notes o altures",
                gl: "intervalo entre dúas notas ou\nalturas",
                eu: "bi nota edo altueren arteko tartea",
                pt: "intervalo entre duas notas ou\nalturas",
                fr: "intervalle entre deux notes ou\nhauteurs",
                it: "intervallo tra due note o altezze"),
            ejemplo: ejemplo("armonia intervalo Do4 Mi5",
                             "armonia interval C4 E5")),
        // escala <escala>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "escala <escala>",
                "scale <scale>",
                ca: "escala <escala>",
                gl: "escala <escala>",
                eu: "escala <eskala>",
                pt: "escala <escala>",
                fr: "escala <gamme>",
                it: "escala <scala>"),
            descripcion: Traduccion(
                "notas y acordes de una escala",
                "notes and chords of a scale",
                ca: "notes i acords d'una escala",
                gl: "notas e acordes dunha escala",
                eu: "eskala baten notak eta akordeak",
                pt: "notas e acordes de uma escala",
                fr: "notes et accords d'une gamme",
                it: "note e accordi di una scala"),
            ejemplo: ejemplo("armonia escala Re dórico",
                             "armonia scale D dorian")),
        // tonalidad <tonalidad>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "tonalidad <tonalidad>",
                "key <key>",
                ca: "tonalidad <tonalitat>",
                gl: "tonalidad <tonalidade>",
                eu: "tonalidad <tonalitatea>",
                pt: "tonalidad <tonalidade>",
                fr: "tonalidad <tonalité>",
                it: "tonalidad <tonalità>"),
            descripcion: Traduccion(
                "armadura, relativas y grados",
                "key signature, relatives and degrees",
                ca: "armadura, relatives i graus",
                gl: "armadura, relativas e graos",
                eu: "armadura, erlatiboak eta graduak",
                pt: "armadura, relativas e graus",
                fr: "armure, relatives et degrés",
                it: "armatura, relative e gradi"),
            ejemplo: ejemplo("armonia tonalidad La menor",
                             "armonia key A minor")),
        // analizar <acordes> [--en <tonalidad>]
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "analizar <acordes> [--en <tonalidad>]",
                "analyze <chords> [--in <key>]",
                ca: "analizar <acords> [--en <tonalitat>]",
                gl: "analizar <acordes> [--en <tonalidade>]",
                eu: "analizar <akordeak> [--en <tonalitatea>]",
                pt: "analizar <acordes> [--en <tonalidade>]",
                fr: "analizar <accords> [--en <tonalité>]",
                it: "analizar <accordi> [--en <tonalità>]"),
            descripcion: Traduccion(
                "cifrado romano, funciones, cadencias\ny modulaciones (con su acorde\npivote; sin --en)",
                "roman numerals, functions, cadences\nand modulations (with their pivot\nchord; without --in)",
                ca: "xifrat romà, funcions, cadències i\nmodulacions (amb l'acord pivot;\nsense --en)",
                gl: "cifrado romano, funcións, cadencias\ne modulacións (co seu acorde pivote;\nsen --en)",
                eu: "zifratu erromatarra, funtzioak,\nkadentziak eta modulazioak (pibota\nbarne; --en gabe)",
                pt: "cifra romana, funções, cadências e\nmodulações (com o acorde pivô; sem\n--en)",
                fr: "chiffrage romain, fonctions,\ncadences et modulations (avec\nl'accord pivot ; sans --en)",
                it: "numeri romani, funzioni, cadenze e\nmodulazioni (con l'accordo perno;\nsenza --en)"),
            ejemplo: ejemplo("armonia analizar Do Fa Sol7 Do Lam Re7 Sol",
                             "armonia analyze C F G7 C Am D7 G")),
        // armonizar <melodía> [--en <tonalidad>] [--propuestas 3]
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "armonizar <melodía> [--en <tonalidad>] [--propuestas 3]",
                "harmonize <melody> [--in <key>] [--proposals 3]",
                ca: "armonizar <melodia> [--en <tonalitat>] [--propuestas 3]",
                gl: "armonizar <melodía> [--en <tonalidade>] [--propuestas 3]",
                eu: "armonizar <melodia> [--en <tonalitatea>] [--propuestas 3]",
                pt: "armonizar <melodia> [--en <tonalidade>] [--propuestas 3]",
                fr: "armonizar <mélodie> [--en <tonalité>] [--propuestas 3]",
                it: "armonizar <melodia> [--en <tonalità>] [--propuestas 3]"),
            descripcion: Traduccion(
                "acordes para una melodía, de mejor a\npeor; con octavas (Mi4), también el\ncoral a cuatro voces",
                "chords for a melody, best first; with\noctaves (E4), also the four-part\nchorale",
                ca: "acords per a una melodia, de millor\na pitjor; amb octaves (Mi4), també\nel coral a quatre veus",
                gl: "acordes para unha melodía, de mellor\na peor; con oitavas (Mi4), tamén o\ncoral a catro voces",
                eu: "melodia baterako akordeak, onenetik\ntxarrenera; zortzidunekin (Mi4), lau\nahotseko korala ere bai",
                pt: "acordes para uma melodia, do melhor\npara o pior; com oitavas (Mi4),\ntambém o coral a quatro vozes",
                fr: "accords pour une mélodie, du\nmeilleur au moins bon ; avec octaves\n(Mi4), aussi le choral à quatre voix",
                it: "accordi per una melodia, dal\nmigliore al peggiore; con le ottave\n(Mi4), anche il corale a quattro\nvoci"),
            ejemplo: ejemplo("armonia armonizar Mi4 Fa4 Re4 Do4",
                             "armonia harmonize E4 F4 D4 C4")),
        // realizar <acordes> [--en <tonalidad>]
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "realizar <acordes> [--en <tonalidad>]",
                "realize <chords> [--in <key>]",
                ca: "realizar <acords> [--en <tonalitat>]",
                gl: "realizar <acordes> [--en <tonalidade>]",
                eu: "realizar <akordeak> [--en <tonalitatea>]",
                pt: "realizar <acordes> [--en <tonalidade>]",
                fr: "realizar <accords> [--en <tonalité>]",
                it: "realizar <accordi> [--en <tonalità>]"),
            descripcion: Traduccion(
                "los acordes a cuatro voces, sin\nfaltas de conducción",
                "the chords in four parts, without\nvoice-leading errors",
                ca: "els acords a quatre veus, sense\nerrors de conducció",
                gl: "os acordes a catro voces, sen erros\nde condución",
                eu: "akordeak lau ahotsetara, ahots-\neramate akatsik gabe",
                pt: "os acordes a quatro vozes, sem erros\nde condução",
                fr: "les accords à quatre voix, sans\nfaute de conduite des voix",
                it: "gli accordi a quattro voci, senza\nerrori di condotta delle parti"),
            ejemplo: ejemplo("armonia realizar Do Fa Sol7 Do",
                             "armonia realize C F G7 C")),
        // revisar <acordes>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "revisar <acordes>",
                "check <chords>",
                ca: "revisar <acords>",
                gl: "revisar <acordes>",
                eu: "revisar <akordeak>",
                pt: "revisar <acordes>",
                fr: "revisar <accords>",
                it: "revisar <accordi>"),
            descripcion: Traduccion(
                "faltas de conducción (quintas\nparalelas…); acordes de grave a\nagudo, separados por comas",
                "voice-leading errors (parallel\nfifths…); chords from low to high,\nseparated by commas",
                ca: "errors de conducció (quintes\nparal·leles…); acords de greu a\nagut, separats per comes",
                gl: "erros de condución (quintas\nparalelas…); acordes de grave a\nagudo, separados por comas",
                eu: "ahots-eramate akatsak (bosgarren\nparaleloak…); akordeak baxutik\naltura, komaz bereizita",
                pt: "erros de condução (quintas\nparalelas…); acordes do grave ao\nagudo, separados por vírgulas",
                fr: "fautes de conduite des voix (quintes\nparallèles…) ; accords du grave à\nl'aigu, séparés par des virgules",
                it: "errori di condotta delle parti\n(quinte parallele…); accordi dal\ngrave all'acuto, separati da virgole"),
            ejemplo: ejemplo("armonia revisar Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4",
                             "armonia check C3 E4 G4 C5, G2 D4 G4 B4")),
        // musicxml melodia <eventos> [opciones]
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "musicxml melodia <eventos> [opciones]",
                "musicxml melody <events> [options]",
                ca: "musicxml melodia <esdeveniments> [opcions]",
                gl: "musicxml melodia <eventos> [opcións]",
                eu: "musicxml melodia <gertaerak> [aukerak]",
                pt: "musicxml melodia <eventos> [opções]",
                fr: "musicxml melodia <événements> [options]",
                it: "musicxml melodia <eventi> [opzioni]"),
            descripcion: Traduccion(
                "partitura MusicXML de una melodía",
                "MusicXML score of a melody",
                ca: "partitura MusicXML d'una melodia",
                gl: "partitura MusicXML dunha melodía",
                eu: "melodia baten MusicXML partitura",
                pt: "partitura MusicXML de uma melodia",
                fr: "partition MusicXML d'une mélodie",
                it: "partitura MusicXML di una melodia"),
            ejemplo: ejemplo("armonia musicxml melodia Do4:4 Re4:8 Mi4:8 Fa4:2 --compas 3/4 > melodia.musicxml",
                             "armonia musicxml melody C4:4 D4:8 E4:8 F4:2 --compas 3/4 > melody.musicxml")),
        // musicxml coral <acordes> [opciones]
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "musicxml coral <acordes> [opciones]",
                "musicxml chorale <chords> [options]",
                ca: "musicxml coral <acords> [opcions]",
                gl: "musicxml coral <acordes> [opcións]",
                eu: "musicxml coral <akordeak> [aukerak]",
                pt: "musicxml coral <acordes> [opções]",
                fr: "musicxml coral <accords> [options]",
                it: "musicxml coral <accordi> [opzioni]"),
            descripcion: Traduccion(
                "coral a cuatro voces en MusicXML",
                "four-part chorale in MusicXML",
                ca: "coral a quatre veus en MusicXML",
                gl: "coral a catro voces en MusicXML",
                eu: "lau ahotseko korala MusicXMLn",
                pt: "coral a quatro vozes em MusicXML",
                fr: "choral à quatre voix en MusicXML",
                it: "corale a quattro voci in MusicXML"),
            ejemplo: ejemplo("armonia musicxml coral Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4 > coral.musicxml",
                             "armonia musicxml chorale C3 E4 G4 C5, G2 D4 G4 B4 > chorale.musicxml")),
        // musicxml acordes <cifrados> [opciones]
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "musicxml acordes <cifrados> [opciones]",
                "musicxml chords <symbols> [options]",
                ca: "musicxml acordes <xifrats> [opcions]",
                gl: "musicxml acordes <cifrados> [opcións]",
                eu: "musicxml acordes <zifratuak> [aukerak]",
                pt: "musicxml acordes <cifras> [opções]",
                fr: "musicxml acordes <chiffrages> [options]",
                it: "musicxml acordes <sigle> [opzioni]"),
            descripcion: Traduccion(
                "progresión con cifrados y análisis",
                "progression with symbols and analysis",
                ca: "progressió amb xifrats i anàlisi",
                gl: "progresión con cifrados e análise",
                eu: "progresioa zifratu eta analisiarekin",
                pt: "progressão com cifras e análise",
                fr: "progression avec chiffrages et\nanalyse",
                it: "progressione con sigle e analisi"),
            ejemplo: ejemplo("armonia musicxml acordes Do Lam Re7 Sol7 Do > progresion.musicxml",
                             "armonia musicxml chords C Am D7 G7 C > progression.musicxml"),
            notas: Traduccion(
                "opciones: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,\n--clave fa, --tempo 90 (o --tempo 60 4.), --titulo Mi coral,\n--duracion 2 (lo que dura cada acorde; negra en el coral y\nblanca en los acordes si no), --cifrados y --analisis (en el\ncoral: cifrado americano encima, romano y función debajo)",
                "options: --compas 6/8 (time signature), --anacrusa 8 (pickup),\n--tonalidad G major (key), --clave fa (clef), --tempo 90 (or\n--tempo 60 4.), --titulo My chorale (title), --duracion 2 (how\nlong each chord lasts; a quarter note in the chorale and a half\nnote in the chords by default), --cifrados and --analisis (in\nthe chorale: chord symbols above, roman numerals and function below)",
                ca: "opcions: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,\n--clave fa, --tempo 90 (o --tempo 60 4.), --titulo El meu coral,\n--duracion 2 (el que dura cada acord; negra al coral i blanca\nals acords si no), --cifrados i --analisis (al coral: xifrat\namericà a dalt, romà i funció a baix)",
                gl: "opcións: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,\n--clave fa, --tempo 90 (ou --tempo 60 4.), --titulo O meu coral,\n--duracion 2 (o que dura cada acorde; negra no coral e branca\nnos acordes se non), --cifrados e --analisis (no coral: cifrado\namericano enriba, romano e función debaixo)",
                eu: "aukerak: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,\n--clave fa, --tempo 90 (edo --tempo 60 4.), --titulo Nire\nkorala, --duracion 2 (akorde bakoitzaren iraupena; bestela\nbeltza koralean eta zuria akordeetan), --cifrados eta --analisis\n(koralean: zifratu amerikarra goian, erromatarra eta funtzioa\nbehean)",
                pt: "opções: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,\n--clave fa, --tempo 90 (ou --tempo 60 4.), --titulo O meu coral,\n--duracion 2 (o que dura cada acorde; semínima no coral e mínima\nnos acordes, se não), --cifrados e --analisis (no coral: cifra\namericana em cima, romana e função em baixo)",
                fr: "options : --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,\n--clave fa, --tempo 90 (ou --tempo 60 4.), --titulo Mon choral,\n--duracion 2 (la durée de chaque accord ; noire dans le choral\net blanche dans les accords sinon), --cifrados et --analisis\n(dans le choral : chiffrage américain au-dessus, romain et\nfonction au-dessous)",
                it: "opzioni: --compas 6/8, --anacrusa 8, --tonalidad Sol mayor,\n--clave fa, --tempo 90 (o --tempo 60 4.), --titulo Il mio\ncorale, --duracion 2 (quanto dura ogni accordo; semiminima nel\ncorale e minima negli accordi, altrimenti), --cifrados e\n--analisis (nel corale: sigla americana sopra, numero romano e\nfunzione sotto)")),
        // midi melodia|coral|acordes <…> [opciones]
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "midi melodia|coral|acordes <…> [opciones]",
                "midi melody|chorale|chords <…> [options]",
                ca: "midi melodia|coral|acordes <…> [opcions]",
                gl: "midi melodia|coral|acordes <…> [opcións]",
                eu: "midi melodia|coral|acordes <…> [aukerak]",
                pt: "midi melodia|coral|acordes <…> [opções]",
                fr: "midi melodia|coral|acordes <…> [options]",
                it: "midi melodia|coral|acordes <…> [opzioni]"),
            descripcion: Traduccion(
                "lo mismo como fichero MIDI, para oírlo\n(sin --clave ni --cifrados; con\n--programa 0…127, General MIDI)",
                "the same as a MIDI file, to listen to\n(without --clave or --cifrados; with\n--program 0…127, General MIDI)",
                ca: "el mateix com a fitxer MIDI, per\nescoltar-lo (sense --clave ni\n--cifrados; amb --programa 0…127,\nGeneral MIDI)",
                gl: "o mesmo como ficheiro MIDI, para\nescoitalo (sen --clave nin\n--cifrados; con --programa 0…127,\nGeneral MIDI)",
                eu: "gauza bera MIDI fitxategi gisa,\nentzuteko (--clave eta --cifrados\ngabe; --programa 0…127, General\nMIDI)",
                pt: "o mesmo como ficheiro MIDI, para\nouvir (sem --clave nem --cifrados;\ncom --programa 0…127, General MIDI)",
                fr: "la même chose en fichier MIDI, pour\nl'écouter (sans --clave ni\n--cifrados ; avec --programa 0…127,\nGeneral MIDI)",
                it: "lo stesso come file MIDI, per\nascoltarlo (senza --clave né\n--cifrados; con --programa 0…127,\nGeneral MIDI)"),
            ejemplo: ejemplo("armonia midi acordes Do Lam Re7 Sol7 Do > progresion.mid",
                             "armonia midi chords C Am D7 G7 C > progression.mid")),
        // tonnetz <notas>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "tonnetz <notas>",
                "tonnetz <notes>",
                ca: "tonnetz <notes>",
                gl: "tonnetz <notas>",
                eu: "tonnetz <notak>",
                pt: "tonnetz <notas>",
                fr: "tonnetz <notes>",
                it: "tonnetz <note>"),
            descripcion: Traduccion(
                "Tonnetz en SVG de unas notas",
                "SVG Tonnetz of some notes",
                ca: "Tonnetz en SVG d'unes notes",
                gl: "Tonnetz en SVG dunhas notas",
                eu: "nota batzuen Tonnetza SVGn",
                pt: "Tonnetz em SVG de algumas notas",
                fr: "Tonnetz en SVG de quelques notes",
                it: "Tonnetz in SVG di alcune note"),
            ejemplo: ejemplo("armonia tonnetz Do Mi Sol Si > tonnetz.svg",
                             "armonia tonnetz C E G B > tonnetz.svg")),
        // tonnetz --acorde <cifrado> | --escala <escala> | --clases <números>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "tonnetz --acorde <cifrado> | --escala <escala> | --clases <números>",
                "tonnetz --chord <symbol> | --scale <scale> | --pcs <numbers>",
                ca: "tonnetz --acorde <xifrat> | --escala <escala> | --clases <nombres>",
                gl: "tonnetz --acorde <cifrado> | --escala <escala> | --clases <números>",
                eu: "tonnetz --acorde <zifratua> | --escala <eskala> | --clases <zenbakiak>",
                pt: "tonnetz --acorde <cifra> | --escala <escala> | --clases <números>",
                fr: "tonnetz --acorde <chiffrage> | --escala <gamme> | --clases <nombres>",
                it: "tonnetz --acorde <sigla> | --escala <scala> | --clases <numeri>"),
            descripcion: Traduccion(
                "de un acorde, una escala o un\nconjunto de clases de altura",
                "of a chord, a scale or a\npitch-class set",
                ca: "d'un acord, una escala o un conjunt\nde classes d'altura",
                gl: "dun acorde, unha escala ou un\nconxunto de clases de altura",
                eu: "akorde, eskala edo altuera-klase\nmultzo batena",
                pt: "de um acorde, uma escala ou um\nconjunto de classes de altura",
                fr: "d'un accord, d'une gamme ou d'un\nensemble de classes de hauteur",
                it: "di un accordo, una scala o un\ninsieme di classi di altezza"),
            ejemplo: ejemplo("armonia tonnetz --escala Re dórico > dorico.svg",
                             "armonia tonnetz --scale D dorian > dorian.svg")),
        // tonnetz --recorrido <tríadas> | --camino <tríada> <tríada>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "tonnetz --recorrido <tríadas> | --camino <tríada> <tríada>",
                "tonnetz --sequence <triads> | --shortest <triad> <triad>",
                ca: "tonnetz --recorrido <tríades> | --camino <tríada> <tríada>",
                gl: "tonnetz --recorrido <tríades> | --camino <tríade> <tríade>",
                eu: "tonnetz --recorrido <triadeak> | --camino <triadea> <triadea>",
                pt: "tonnetz --recorrido <tríades> | --camino <tríade> <tríade>",
                fr: "tonnetz --recorrido <triades> | --camino <triade> <triade>",
                it: "tonnetz --recorrido <triadi> | --camino <triade> <triade>"),
            descripcion: Traduccion(
                "un recorrido de tríadas, con flechas,\no el camino más corto por P, L y R",
                "a sequence of triads, with arrows, or\nthe shortest path through P, L and R",
                ca: "un recorregut de tríades, amb\nfletxes, o el camí més curt per P, L\ni R",
                gl: "un percorrido de tríades, con\nfrechas, ou o camiño máis curto por\nP, L e R",
                eu: "triade-ibilbide bat, geziekin, edo\nP, L eta R bidezko biderik laburrena",
                pt: "um percurso de tríades, com setas,\nou o caminho mais curto por P, L e R",
                fr: "un parcours de triades, avec des\nflèches, ou le chemin le plus court\npar P, L et R",
                it: "un percorso di triadi, con frecce, o\nil cammino più breve per P, L e R"),
            ejemplo: ejemplo("armonia tonnetz --recorrido Do Lam Fa Rem > recorrido.svg",
                             "armonia tonnetz --sequence C Am F Dm > sequence.svg")),
        // tonnetz --ciclo <ciclo> <tríada>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "tonnetz --ciclo <ciclo> <tríada>",
                "tonnetz --cycle <cycle> <triad>",
                ca: "tonnetz --ciclo <cicle> <tríada>",
                gl: "tonnetz --ciclo <ciclo> <tríade>",
                eu: "tonnetz --ciclo <zikloa> <triadea>",
                pt: "tonnetz --ciclo <ciclo> <tríade>",
                fr: "tonnetz --ciclo <cycle> <triade>",
                it: "tonnetz --ciclo <ciclo> <triade>"),
            descripcion: Traduccion(
                "un ciclo hexatónico, octatónico o LR",
                "a hexatonic, octatonic or LR cycle",
                ca: "un cicle hexatònic, octatònic o LR\n(--margen 2: més xarxa al voltant)",
                gl: "un ciclo hexatónico, octatónico ou\nLR (--margen 2: máis rede arredor)",
                eu: "ziklo hexatoniko, oktatoniko edo LR\nbat (--margen 2: sare gehiago\ninguruan)",
                pt: "um ciclo hexatónico, octatónico ou\nLR (--margen 2: mais rede em volta)",
                fr: "un cycle hexatonique, octatonique ou\nLR (--margen 2 : plus de réseau\nautour)",
                it: "un ciclo esatonico, ottatonico o LR\n(--margen 2: più rete intorno)"),
            ejemplo: ejemplo("armonia tonnetz --ciclo hexatonico Do > ciclo.svg",
                             "armonia tonnetz --cycle hexatonic C > cycle.svg"),
            notas: Traduccion(
                "(--margen 2: más red alrededor)",
                "(--margen 2: more grid around it)",
                ca: "",
                gl: "",
                eu: "",
                pt: "",
                fr: "",
                it: "")),
        // tabla <notas o alturas>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "tabla <notas o alturas>",
                "tabla <notes or pitches>",
                ca: "tabla <notes o altures>",
                gl: "tabla <notas ou alturas>",
                eu: "tabla <notak edo altuerak>",
                pt: "tabla <notas ou alturas>",
                fr: "tabla <notes ou hauteurs>",
                it: "tabla <note o altezze>"),
            descripcion: Traduccion(
                "tabla armónica en SVG (hexágonos)",
                "SVG harmonic table (hexagons)",
                ca: "taula harmònica en SVG (hexàgons)",
                gl: "táboa harmónica en SVG (hexágonos)",
                eu: "taula harmonikoa SVGn (hexagonoak)",
                pt: "tabela harmónica em SVG (hexágonos)",
                fr: "table harmonique en SVG (hexagones)",
                it: "tabella armonica in SVG (esagoni)"),
            ejemplo: ejemplo("armonia tabla Do3 Sol3 Mi4 > tabla.svg",
                             "armonia tabla C3 G3 E4 > table.svg")),
        // tabla --acorde <cifrado> | --escala <escala> | --clases <números>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "tabla --acorde <cifrado> | --escala <escala> | --clases <números>\ntabla --recorrido <tríadas> | --camino <tríada> <tríada>\ntabla --ciclo <ciclo> <tríada>",
                "tabla --chord <symbol> | --scale <scale> | --pcs <numbers>\ntabla --sequence <triads> | --shortest <triad> <triad>\ntabla --cycle <cycle> <triad>",
                ca: "tabla --acorde | --escala | --clases | --recorrido | --camino | --ciclo",
                gl: "tabla --acorde | --escala | --clases | --recorrido | --camino | --ciclo",
                eu: "tabla --acorde | --escala | --clases | --recorrido | --camino | --ciclo",
                pt: "tabla --acorde | --escala | --clases | --recorrido | --camino | --ciclo",
                fr: "tabla --acorde | --escala | --clases | --recorrido | --camino | --ciclo",
                it: "tabla --acorde | --escala | --clases | --recorrido | --camino | --ciclo"),
            descripcion: Traduccion(
                "(--margen 2: más tabla alrededor)",
                "(--margen 2: more table around it)",
                ca: "com al Tonnetz (--margen 2: més\ntaula al voltant)",
                gl: "como no Tonnetz (--margen 2: máis\ntáboa arredor)",
                eu: "Tonnetzean bezala (--margen 2: taula\ngehiago inguruan)",
                pt: "como no Tonnetz (--margen 2: mais\ntabela em volta)",
                fr: "comme pour le Tonnetz (--margen 2 :\nplus de table autour)",
                it: "come nel Tonnetz (--margen 2: più\ntabella intorno)"),
            ejemplo: ejemplo("armonia tabla --acorde Domaj7 > domaj7.svg",
                             "armonia tabla --chord Cmaj7 > cmaj7.svg")),
        // vecinos <acorde> [--voces 2]
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "vecinos <acorde> [--voces 2]",
                "neighbors <chord> [--voices 2]",
                ca: "vecinos <acord> [--voces 2]",
                gl: "vecinos <acorde> [--voces 2]",
                eu: "vecinos <akordea> [--voces 2]",
                pt: "vecinos <acorde> [--voces 2]",
                fr: "vecinos <accord> [--voces 2]",
                it: "vecinos <accordo> [--voces 2]"),
            descripcion: Traduccion(
                "acordes a un semitono (séptimas: dominante, menor, semidisminuida\ny disminuida; tríadas: mayor, menor y aumentada; un maj7, entre\nlas séptimas y los maj7; --ampliada: con los maj7 también)",
                "chords a semitone away (sevenths: dominant, minor, half-diminished\nand diminished; triads: major, minor and augmented; a maj7, among\nthe sevenths and the maj7s; --extended: with the maj7s too)",
                ca: "acords a un semitò (sèptimes:\ndominant, menor, semidisminuïda i\ndisminuïda; tríades: major, menor i\naugmentada; --ampliada: amb els maj7\ntambé)",
                gl: "acordes a un semiton (sétimas:\ndominante, menor, semidiminuída e\ndiminuída; tríades: maior, menor e\naumentada; --ampliada: tamén cos\nmaj7)",
                eu: "tonuerdi batera dauden akordeak\n(zazpigarrenak: dominantea, txikia,\nerdi-gutxitua eta gutxitua;\ntriadeak: handia, txikia eta\ngehitua; --ampliada: maj7ekin ere)",
                pt: "acordes a um meio-tom (sétimas:\ndominante, menor, meio-diminuta e\ndiminuta; tríades: maior, menor e\naumentada; --ampliada: também com os\nmaj7)",
                fr: "accords à un demi-ton (septièmes :\nde dominante, mineure, semi-diminuée\net diminuée ; triades : majeure,\nmineure et augmentée ; --ampliada :\naussi avec les maj7)",
                it: "accordi a un semitono (settime: di\ndominante, minore, semidiminuita e\ndiminuita; triadi: maggiore, minore\ne aumentata; --ampliada: anche con\nle maj7)"),
            ejemplo: ejemplo("armonia vecinos Sol7",
                             "armonia neighbors G7")),
        // conduccion-parsimoniosa <acorde> <acorde> [--voces 2] [--ampliada]
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "conduccion-parsimoniosa <acorde> <acorde> [--voces 2] [--ampliada]",
                "smooth-path <chord> <chord> [--voices 2] [--extended]",
                ca: "conduccion-parsimoniosa <acord> <acord> [--voces 2] [--ampliada]",
                gl: "conduccion-parsimoniosa <acorde> <acorde> [--voces 2] [--ampliada]",
                eu: "conduccion-parsimoniosa <akordea> <akordea> [--voces 2] [--ampliada]",
                pt: "conduccion-parsimoniosa <acorde> <acorde> [--voces 2] [--ampliada]",
                fr: "conduccion-parsimoniosa <accord> <accord> [--voces 2] [--ampliada]",
                it: "conduccion-parsimoniosa <accordo> <accordo> [--voces 2] [--ampliada]"),
            descripcion: Traduccion(
                "de un acorde a otro moviendo una voz\n(o dos) un semitono en cada paso",
                "from one chord to another moving one\nvoice (or two) a semitone at a time",
                ca: "d'un acord a un altre movent una veu\n(o dues) un semitò a cada pas",
                gl: "dun acorde a outro movendo unha voz\n(ou dúas) un semiton en cada paso",
                eu: "akorde batetik bestera, urrats\nbakoitzean ahots bat (edo bi)\ntonuerdi bat mugituz",
                pt: "de um acorde a outro movendo uma voz\n(ou duas) um meio-tom em cada passo",
                fr: "d'un accord à l'autre en bougeant\nune voix (ou deux) d'un demi-ton à\nchaque étape",
                it: "da un accordo all'altro muovendo una\nvoce (o due) di un semitono a ogni\npasso"),
            ejemplo: ejemplo("armonia conduccion-parsimoniosa Sol7 Rem7",
                             "armonia smooth-path G7 Dm7")),
        // conduccion-minima <acorde> <acorde>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "conduccion-minima <acorde> <acorde>",
                "minimal-voice-leading <chord> <chord>",
                ca: "conduccion-minima <acord> <acord>",
                gl: "conduccion-minima <acorde> <acorde>",
                eu: "conduccion-minima <akordea> <akordea>",
                pt: "conduccion-minima <acorde> <acorde>",
                fr: "conduccion-minima <accord> <accord>",
                it: "conduccion-minima <accordo> <accordo>"),
            descripcion: Traduccion(
                "la conducción con menos semitonos",
                "the voice leading with fewest semitones",
                ca: "la conducció amb menys semitons",
                gl: "a condución con menos semitons",
                eu: "tonuerdi gutxieneko ahots-eramatea",
                pt: "a condução com menos meios-tons",
                fr: "la conduite avec le moins de demi-\ntons",
                it: "la condotta con meno semitoni"),
            ejemplo: ejemplo("armonia conduccion-minima Sol7 Do",
                             "armonia minimal-voice-leading G7 C")),
        // plr <tríada> <P, L, R…>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "plr <tríada> <P, L, R…>",
                "plr <triad> <P, L, R…>",
                ca: "plr <tríada> <P, L, R…>",
                gl: "plr <tríade> <P, L, R…>",
                eu: "plr <triadea> <P, L, R…>",
                pt: "plr <tríade> <P, L, R…>",
                fr: "plr <triade> <P, L, R…>",
                it: "plr <triade> <P, L, R…>"),
            descripcion: Traduccion(
                "transformaciones neorriemannianas",
                "neo-Riemannian transformations",
                ca: "transformacions neoriemannianes",
                gl: "transformacións neorriemannianas",
                eu: "eraldaketa neoerriemanndarrak",
                pt: "transformações neorriemannianas",
                fr: "transformations néo-riemanniennes",
                it: "trasformazioni neoriemanniane"),
            ejemplo: ejemplo("armonia plr Do PLR",
                             "armonia plr C PLR")),
        // plr <tríada> <tríada>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "plr <tríada> <tríada>",
                "plr <triad> <triad>",
                ca: "plr <tríada> <tríada>",
                gl: "plr <tríade> <tríade>",
                eu: "plr <triadea> <triadea>",
                pt: "plr <tríade> <tríade>",
                fr: "plr <triade> <triade>",
                it: "plr <triade> <triade>"),
            descripcion: Traduccion(
                "el camino más corto por P, L y R",
                "the shortest path through P, L and R",
                ca: "el camí més curt per P, L i R",
                gl: "o camiño máis curto por P, L e R",
                eu: "P, L eta R bidezko biderik laburrena",
                pt: "o caminho mais curto por P, L e R",
                fr: "le chemin le plus court par P, L et\nR",
                it: "il cammino più breve per P, L e R"),
            ejemplo: ejemplo("armonia plr Do Mibm",
                             "armonia plr C Ebm")),
        // plr <tríada> <ciclo>
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "plr <tríada> <ciclo>",
                "plr <triad> <cycle>",
                ca: "plr <tríada> <cicle>",
                gl: "plr <tríade> <ciclo>",
                eu: "plr <triadea> <zikloa>",
                pt: "plr <tríade> <ciclo>",
                fr: "plr <triade> <cycle>",
                it: "plr <triade> <ciclo>"),
            descripcion: Traduccion(
                "un ciclo: hexatonico (P, L),\noctatonico (P, R) o \"ciclo LR\"",
                "a cycle: hexatonic (P, L),\noctatonic (P, R) or \"LR cycle\"",
                ca: "un cicle: hexatonico (P, L),\noctatonico (P, R) o \"ciclo LR\"",
                gl: "un ciclo: hexatonico (P, L),\noctatonico (P, R) ou \"ciclo LR\"",
                eu: "ziklo bat: hexatonico (P, L),\noctatonico (P, R) edo \"ciclo LR\"",
                pt: "um ciclo: hexatonico (P, L),\noctatonico (P, R) ou \"ciclo LR\"",
                fr: "un cycle : hexatonico (P, L),\noctatonico (P, R) ou « ciclo LR »",
                it: "un ciclo: hexatonico (P, L),\noctatonico (P, R) o «ciclo LR»"),
            ejemplo: ejemplo("armonia plr Do hexatonico",
                             "armonia plr C hexatonic")),
        // digitaciones <cifrado>… [opciones]
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "digitaciones <cifrado>… [opciones]",
                "fingerings <symbol>… [options]",
                ca: "digitaciones <xifrat>… [opcions]",
                gl: "digitaciones <cifrado>… [opcións]",
                eu: "digitaciones <zifratua>… [aukerak]",
                pt: "digitaciones <cifra>… [opções]",
                fr: "digitaciones <chiffrage>… [options]",
                it: "digitaciones <sigla>… [opzioni]"),
            descripcion: Traduccion(
                "formas de tocar un acorde, de la más cómoda a la menos, en un\ninstrumento de cuerda con trastes (cuerdas de grave a agudo)\nopciones: --instrumento guitarra|bajo|ukelele|mandolina|…\n(también «guitarra de siete cuerdas», «bajo de 5 cuerdas»,\n«drop D»), --limite 5, --traste 12 (el más alto que se usa),\n--dedos 4 (los que se pueden usar), --completo (con todas las notas:\npor defecto la quinta puede faltar), --diagrama (una línea por cuerda)",
                "ways to play a chord, from the most comfortable to the least, on a\nfretted string instrument (strings from low to high)\noptions: --instrument guitar|bass|ukulele|mandolin|…\n(also \"seven-string guitar\", \"five-string bass\",\n\"drop D\"), --limit 5, --fret 12 (the highest one used),\n--fingers 4 (how many can be used), --complete (with every note:\nby default the fifth may be left out), --diagram (one line per string)",
                ca: "maneres de tocar un acord, de la més\ncòmoda a la menys, en un instrument\nde corda amb trasts\nopcions: --instrumento guitarra|bajo|ukelele|mandolina|… (també\n«guitarra de siete cuerdas», «bajo de 5 cuerdas», «drop D»),\n--limite 5, --traste 12 (el més alt que es fa servir), --dedos 4\n(els que es poden fer servir), --completo (amb totes les notes:\nper defecte la quinta pot faltar), --diagrama (una línia per\ncorda)",
                gl: "formas de tocar un acorde, da máis\ncómoda á menos, nun instrumento de\ncorda con trastes\nopcións: --instrumento guitarra|bajo|ukelele|mandolina|… (tamén\n«guitarra de siete cuerdas», «bajo de 5 cuerdas», «drop D»),\n--limite 5, --traste 12 (o máis alto que se usa), --dedos 4 (os\nque se poden usar), --completo (con todas as notas: por defecto\na quinta pode faltar), --diagrama (unha liña por corda)",
                eu: "akorde bat jotzeko moduak,\nerosoenetik gutxien erosora,\ntrasteak dituen hari-instrumentu\nbatean\naukerak: --instrumento guitarra|bajo|ukelele|mandolina|… (baita\n«guitarra de siete cuerdas», «bajo de 5 cuerdas», «drop D» ere),\n--limite 5, --traste 12 (erabiltzen den altuena), --dedos 4\n(erabil daitezkeenak), --completo (nota guztiekin: berez\nbosgarrena falta daiteke), --diagrama (lerro bat hari\nbakoitzeko)",
                pt: "formas de tocar um acorde, da mais\ncómoda à menos, num instrumento de\ncordas com trastes\nopções: --instrumento guitarra|bajo|ukelele|mandolina|… (também\n«guitarra de siete cuerdas», «bajo de 5 cuerdas», «drop D»),\n--limite 5, --traste 12 (o traste mais alto usado), --dedos 4 (os\nque se podem usar), --completo (com todas as notas: por omissão a\nquinta pode faltar), --diagrama (uma linha por corda)",
                fr: "façons de jouer un accord, de la\nplus commode à la moins commode, sur\nun instrument à cordes et à frettes\noptions : --instrumento guitarra|bajo|ukelele|mandolina|… (aussi\n« guitarra de siete cuerdas », « bajo de 5 cuerdas », « drop D\n»), --limite 5, --traste 12 (la case la plus haute utilisée),\n--dedos 4 (ceux qu'on peut utiliser), --completo (avec toutes\nles notes : par défaut la quinte peut manquer), --diagrama (une\nligne par corde)",
                it: "modi di suonare un accordo, dal più\ncomodo al meno comodo, su uno\nstrumento a corde con tasti\nopzioni: --instrumento guitarra|bajo|ukelele|mandolina|… (anche\n«guitarra de siete cuerdas», «bajo de 5 cuerdas», «drop D»),\n--limite 5, --traste 12 (il tasto più alto usato), --dedos 4\n(quelle che si possono usare), --completo (con tutte le note: di\nsolito la quinta può mancare), --diagrama (una riga per corda)"),
            ejemplo: ejemplo("armonia digitaciones Sol7/Si --instrumento ukelele",
                             "armonia fingerings G7/B --instrument ukulele")),
        // ayuda
        EntradaDeAyuda(
            sintaxis: Traduccion(
                "ayuda",
                "help",
                ca: "ayuda",
                gl: "ayuda",
                eu: "ayuda",
                pt: "ayuda",
                fr: "ayuda",
                it: "ayuda"),
            descripcion: Traduccion(
                "esta ayuda",
                "this help",
                ca: "aquesta ajuda",
                gl: "esta axuda",
                eu: "laguntza hau",
                pt: "esta ajuda",
                fr: "cette aide",
                it: "questo aiuto")),
    ]
}
