import Armonia

/// Los textos de la interfaz de las apps (pestañas, secciones, etiquetas, indicaciones), en los ocho idiomas de
/// los textos del motor.
///
/// Siguen el idioma de los textos de la notación elegida, igual que los nombres de acordes, escalas y avisos,
/// así que el selector de notación cambia la app entera. Cada caso da su `Traduccion`, que pide los ocho
/// idiomas: uno nuevo no compila hasta que los tiene. Los ejemplos de las indicaciones («Cifrado, por ejemplo
/// Sol7/Si») se escriben en la notación elegida («G7/B»).
///
///     Nomenclatura.ingles.texto(.digitaciones)    // "Fingerings"
public enum TextoDeLasApps: Hashable, Sendable {
    // Pestañas y títulos
    case acordes
    case escalas
    case analisis
    case coral

    // Acordes
    case acorde
    case campoDeCifrado
    case informacion
    case nombre
    case cifrado
    case notas
    case digitaciones
    case instrumentoYAfinacion
    case sinDigitaciones
    case calculando
    /// «3 dedos», o «4 dedos, cejilla en el traste 1».
    case dedos(Int, cejilla: Int?)

    // Escalas
    case escala
    case tonica
    case tipo
    case habituales
    case otrasTradiciones
    case acordesDeLaEscala
    case mastilDeGuitarra

    // Análisis
    case progresion
    case campoDeProgresion
    case resultado
    case acordeAAcorde
    case cadencias

    // Coral
    case tarea
    case campoDeTonalidad
    case tonalidad
    case armonizaciones
    case aCuatroVoces
    case conduccionDeLasVoces
    case avisos

    // Tonnetz
    case recorridoPLR
    case modo
    case red
    case noSeDibuja
    case campoDeTriadaInicial
    case reiniciar
    case deshacer
    case campoDeAcorde
    case campoDeEscala

    // Comunes
    case textos
    case comoLasNotas
    case exportar
    case escuchar

    public func texto(en notacion: Nomenclatura) -> String {
        traduccion(notacion).en(notacion)
    }

    func traduccion(_ notacion: Nomenclatura) -> Traduccion {
        switch self {
        case .acordes:
            return Traduccion("Acordes", "Chords", ca: "Acords", gl: "Acordes", eu: "Akordeak",
                              pt: "Acordes", fr: "Accords", it: "Accordi")
        case .escalas:
            return Traduccion("Escalas", "Scales", ca: "Escales", gl: "Escalas", eu: "Eskalak",
                              pt: "Escalas", fr: "Gammes", it: "Scale")
        case .analisis:
            return Traduccion("Análisis", "Analysis", ca: "Anàlisi", gl: "Análise", eu: "Analisia",
                              pt: "Análise", fr: "Analyse", it: "Analisi")
        case .coral:
            return Traduccion("Coral", "Chorale", ca: "Coral", gl: "Coral", eu: "Korala",
                              pt: "Coral", fr: "Choral", it: "Corale")
        case .acorde:
            return Traduccion("Acorde", "Chord", ca: "Acord", gl: "Acorde", eu: "Akordea",
                              pt: "Acorde", fr: "Accord", it: "Accordo")
        case .campoDeCifrado:
            let ejemplo = Self.cifrado("Sol7/Si", notacion)
            return Traduccion("Cifrado, por ejemplo \(ejemplo)", "Chord symbol, for example \(ejemplo)",
                              ca: "Xifratge, per exemple \(ejemplo)", gl: "Cifrado, por exemplo \(ejemplo)",
                              eu: "Zifratua, adibidez \(ejemplo)", pt: "Cifra, por exemplo \(ejemplo)",
                              fr: "Chiffrage, par exemple \(ejemplo)", it: "Sigla, per esempio \(ejemplo)")
        case .informacion:
            return Traduccion("Información", "Information", ca: "Informació", gl: "Información", eu: "Informazioa",
                              pt: "Informação", fr: "Informations", it: "Informazioni")
        case .nombre:
            return Traduccion("Nombre", "Name", ca: "Nom", gl: "Nome", eu: "Izena",
                              pt: "Nome", fr: "Nom", it: "Nome")
        case .cifrado:
            return Traduccion("Cifrado", "Symbol", ca: "Xifratge", gl: "Cifrado", eu: "Zifratua",
                              pt: "Cifra", fr: "Chiffrage", it: "Sigla")
        case .notas:
            return Traduccion("Notas", "Notes", ca: "Notes", gl: "Notas", eu: "Notak",
                              pt: "Notas", fr: "Notes", it: "Note")
        case .digitaciones:
            return Traduccion("Digitaciones", "Fingerings", ca: "Digitacions", gl: "Dixitacións", eu: "Hatz-jarrerak",
                              pt: "Dedilhações", fr: "Doigtés", it: "Diteggiature")
        case .instrumentoYAfinacion:
            return Traduccion("Instrumento y afinación", "Instrument and tuning", ca: "Instrument i afinació",
                              gl: "Instrumento e afinación", eu: "Instrumentua eta afinazioa",
                              pt: "Instrumento e afinação", fr: "Instrument et accord", it: "Strumento e accordatura")
        case .sinDigitaciones:
            return Traduccion("No hay digitaciones cómodas para este acorde en este instrumento.",
                              "There are no comfortable fingerings for this chord on this instrument.",
                              ca: "No hi ha digitacions còmodes per a aquest acord en aquest instrument.",
                              gl: "Non hai dixitacións cómodas para este acorde neste instrumento.",
                              eu: "Ez dago akorde honetarako hatz-jarrera erosorik instrumentu honetan.",
                              pt: "Não há dedilhações confortáveis para este acorde neste instrumento.",
                              fr: "Aucun doigté confortable pour cet accord sur cet instrument.",
                              it: "Nessuna diteggiatura comoda per questo accordo su questo strumento.")
        case .calculando:
            return Traduccion("Calculando…", "Calculating…", ca: "Calculant…", gl: "Calculando…", eu: "Kalkulatzen…",
                              pt: "A calcular…", fr: "Calcul en cours…", it: "Calcolo in corso…")
        case .dedos(let n, let cejilla):
            let dedos = Traduccion(n == 1 ? "1 dedo" : "\(n) dedos", n == 1 ? "1 finger" : "\(n) fingers",
                                   ca: n == 1 ? "1 dit" : "\(n) dits", gl: n == 1 ? "1 dedo" : "\(n) dedos",
                                   eu: "\(n) hatz", pt: n == 1 ? "1 dedo" : "\(n) dedos",
                                   fr: n == 1 ? "1 doigt" : "\(n) doigts", it: n == 1 ? "1 dito" : "\(n) dita")
            guard let t = cejilla else { return dedos }
            return Traduccion("\(dedos.espanol), cejilla en el traste \(t)", "\(dedos.ingles), barre at fret \(t)",
                              ca: "\(dedos.catalan), celleta al trast \(t)", gl: "\(dedos.gallego), pestana no traste \(t)",
                              eu: "\(dedos.euskera), zeja \(t). trastean", pt: "\(dedos.portugues), pestana no traste \(t)",
                              fr: "\(dedos.frances), barré à la case \(t)", it: "\(dedos.italiano), barré al tasto \(t)")
        case .escala:
            return Traduccion("Escala", "Scale", ca: "Escala", gl: "Escala", eu: "Eskala",
                              pt: "Escala", fr: "Gamme", it: "Scala")
        case .tonica:
            return Traduccion("Tónica", "Tonic", ca: "Tònica", gl: "Tónica", eu: "Tonika",
                              pt: "Tónica", fr: "Tonique", it: "Tonica")
        case .tipo:
            return Traduccion("Tipo", "Type", ca: "Tipus", gl: "Tipo", eu: "Mota",
                              pt: "Tipo", fr: "Type", it: "Tipo")
        case .habituales:
            return Traduccion("Habituales", "Common", ca: "Habituals", gl: "Habituais", eu: "Ohikoak",
                              pt: "Habituais", fr: "Courantes", it: "Comuni")
        case .otrasTradiciones:
            return Traduccion("Otras tradiciones", "Other traditions", ca: "Altres tradicions", gl: "Outras tradicións",
                              eu: "Beste tradizio batzuk", pt: "Outras tradições", fr: "Autres traditions",
                              it: "Altre tradizioni")
        case .acordesDeLaEscala:
            return Traduccion("Acordes de la escala", "Chords of the scale", ca: "Acords de l'escala",
                              gl: "Acordes da escala", eu: "Eskalaren akordeak", pt: "Acordes da escala",
                              fr: "Accords de la gamme", it: "Accordi della scala")
        case .mastilDeGuitarra:
            return Traduccion("Mástil de guitarra", "Guitar fretboard", ca: "Mànec de guitarra", gl: "Mástil de guitarra",
                              eu: "Gitarraren mastila", pt: "Braço da guitarra", fr: "Manche de guitare",
                              it: "Manico della chitarra")
        case .progresion:
            return Traduccion("Progresión", "Progression", ca: "Progressió", gl: "Progresión", eu: "Progresioa",
                              pt: "Progressão", fr: "Progression", it: "Progressione")
        case .campoDeProgresion:
            return Traduccion("Acordes separados por espacios", "Chords separated by spaces",
                              ca: "Acords separats per espais", gl: "Acordes separados por espazos",
                              eu: "Akordeak, zuriunez bereizita", pt: "Acordes separados por espaços",
                              fr: "Accords séparés par des espaces", it: "Accordi separati da spazi")
        case .resultado:
            return Traduccion("Resultado", "Result", ca: "Resultat", gl: "Resultado", eu: "Emaitza",
                              pt: "Resultado", fr: "Résultat", it: "Risultato")
        case .acordeAAcorde:
            return Traduccion("Acorde a acorde", "Chord by chord", ca: "Acord a acord", gl: "Acorde a acorde",
                              eu: "Akordez akorde", pt: "Acorde a acorde", fr: "Accord par accord",
                              it: "Accordo per accordo")
        case .cadencias:
            return Traduccion("Cadencias", "Cadences", ca: "Cadències", gl: "Cadencias", eu: "Kadentziak",
                              pt: "Cadências", fr: "Cadences", it: "Cadenze")
        case .tarea:
            return Traduccion("Tarea", "Task", ca: "Tasca", gl: "Tarefa", eu: "Zeregina",
                              pt: "Tarefa", fr: "Tâche", it: "Attività")
        case .campoDeTonalidad:
            return Traduccion("Tonalidad (vacío: la que mejor encaje)", "Key (empty: the best fit)",
                              ca: "Tonalitat (buit: la que millor encaixi)", gl: "Tonalidade (baleiro: a que mellor encaixe)",
                              eu: "Tonalitatea (hutsik: hoberen egokitzen dena)",
                              pt: "Tonalidade (vazio: a que melhor encaixar)", fr: "Tonalité (vide : la plus adaptée)",
                              it: "Tonalità (vuoto: quella più adatta)")
        case .tonalidad:
            return Traduccion("Tonalidad", "Key", ca: "Tonalitat", gl: "Tonalidade", eu: "Tonalitatea",
                              pt: "Tonalidade", fr: "Tonalité", it: "Tonalità")
        case .armonizaciones:
            return Traduccion("Armonizaciones, de mejor a peor", "Harmonizations, best first",
                              ca: "Harmonitzacions, de millor a pitjor", gl: "Harmonizacións, de mellor a peor",
                              eu: "Harmonizazioak, onenetik txarrenera", pt: "Harmonizações, da melhor para a pior",
                              fr: "Harmonisations, de la meilleure à la moins bonne",
                              it: "Armonizzazioni, dalla migliore alla peggiore")
        case .aCuatroVoces:
            return Traduccion("A cuatro voces, de grave a agudo", "In four parts, from low to high",
                              ca: "A quatre veus, de greu a agut", gl: "A catro voces, de grave a agudo",
                              eu: "Lau ahotsetara, baxuenetik altuenera", pt: "A quatro vozes, do grave ao agudo",
                              fr: "À quatre voix, du grave à l'aigu", it: "A quattro voci, dal grave all'acuto")
        case .conduccionDeLasVoces:
            return Traduccion("Conducción de las voces", "Voice leading", ca: "Conducció de les veus",
                              gl: "Condución das voces", eu: "Ahots-eramatea", pt: "Condução das vozes",
                              fr: "Conduite des voix", it: "Condotta delle parti")
        case .avisos:
            return Traduccion("Avisos", "Warnings", ca: "Avisos", gl: "Avisos", eu: "Oharrak",
                              pt: "Avisos", fr: "Avertissements", it: "Avvisi")
        case .recorridoPLR:
            return Traduccion("Recorrido P·L·R", "P·L·R path", ca: "Recorregut P·L·R", gl: "Percorrido P·L·R",
                              eu: "P·L·R ibilbidea", pt: "Percurso P·L·R", fr: "Parcours P·L·R", it: "Percorso P·L·R")
        case .modo:
            return Traduccion("Modo", "Mode", ca: "Mode", gl: "Modo", eu: "Modua",
                              pt: "Modo", fr: "Mode", it: "Modalità")
        case .red:
            return Traduccion("Red", "Grid", ca: "Xarxa", gl: "Rede", eu: "Sarea",
                              pt: "Rede", fr: "Réseau", it: "Rete")
        case .noSeDibuja:
            return Traduccion("No se puede dibujar: revisa el texto.", "Can't draw it: check the text.",
                              ca: "No es pot dibuixar: revisa el text.", gl: "Non se pode debuxar: revisa o texto.",
                              eu: "Ezin da marraztu: berrikusi testua.", pt: "Não é possível desenhar: revê o texto.",
                              fr: "Impossible de dessiner : vérifie le texte.", it: "Impossibile disegnare: controlla il testo.")
        case .campoDeTriadaInicial:
            let ejemplo = Self.cifrado("Do", notacion) + ", " + Self.cifrado("Lam", notacion) + "…"
            return Traduccion("Tríada inicial (\(ejemplo))", "Starting triad (\(ejemplo))",
                              ca: "Tríada inicial (\(ejemplo))", gl: "Tríade inicial (\(ejemplo))",
                              eu: "Hasierako hirukia (\(ejemplo))", pt: "Tríade inicial (\(ejemplo))",
                              fr: "Triade de départ (\(ejemplo))", it: "Triade iniziale (\(ejemplo))")
        case .reiniciar:
            return Traduccion("Reiniciar", "Restart", ca: "Reinicia", gl: "Reiniciar", eu: "Berrabiarazi",
                              pt: "Reiniciar", fr: "Recommencer", it: "Ricomincia")
        case .deshacer:
            return Traduccion("Deshacer", "Undo", ca: "Desfés", gl: "Desfacer", eu: "Desegin",
                              pt: "Desfazer", fr: "Annuler", it: "Annulla")
        case .campoDeAcorde:
            let ejemplo = Self.cifrado("Dom7", notacion) + ", " + Self.cifrado("Fa#m7b5", notacion) + "…"
            return TextoDeLasApps.cifrado.traduccion(notacion).aplicando { "\($0) (\(ejemplo))" }
        case .campoDeEscala:
            let ejemplos = [Escala(.re, .dorico), Escala(.la, .menorArmonica)].map { $0.nombre(en: notacion) }
            let ejemplo = ejemplos.joined(separator: ", ") + "…"
            return TextoDeLasApps.escala.traduccion(notacion).aplicando { "\($0) (\(ejemplo))" }
        case .textos:
            return Traduccion("Textos", "Texts", ca: "Textos", gl: "Textos", eu: "Testuak",
                              pt: "Textos", fr: "Textes", it: "Testi")
        case .comoLasNotas:
            return Traduccion("Como las notas", "Same as the notes", ca: "Com les notes", gl: "Como as notas",
                              eu: "Notak bezala", pt: "Como as notas", fr: "Comme les notes", it: "Come le note")
        case .escuchar:
            return Traduccion("Escuchar", "Listen", ca: "Escolta", gl: "Escoitar", eu: "Entzun",
                              pt: "Ouvir", fr: "Écouter", it: "Ascolta")
        case .exportar:
            return Traduccion("Exportar", "Export", ca: "Exporta", gl: "Exportar", eu: "Esportatu",
                              pt: "Exportar", fr: "Exporter", it: "Esporta")
        }
    }

    /// Un cifrado de ejemplo en la notación: «Sol7/Si» → «G7/B».
    static func cifrado(_ texto: String, _ notacion: Nomenclatura) -> String {
        (try? Acorde(leyendo: texto))?.cifrado(en: notacion) ?? texto
    }

    /// Alturas de ejemplo en la notación: «Mi4 Fa4 Re4 Do4» → «E4 F4 D4 C4».
    static func alturas(_ texto: String, _ notacion: Nomenclatura) -> String {
        texto.split(separator: " ", omittingEmptySubsequences: false).map { palabra in
            let coma = palabra.hasSuffix(",")
            let limpia = coma ? String(palabra.dropLast()) : String(palabra)
            return ((try? Altura(leyendo: limpia))?.nombre(en: notacion) ?? limpia) + (coma ? "," : "")
        }.joined(separator: " ")
    }
}

extension Traduccion {
    /// La misma frase en los ocho idiomas, cambiada igual en todos.
    func aplicando(_ cambio: (String) -> String) -> Traduccion {
        Traduccion(cambio(espanol), cambio(ingles), ca: cambio(catalan), gl: cambio(gallego), eu: cambio(euskera),
                   pt: cambio(portugues), fr: cambio(frances), it: cambio(italiano))
    }
}

extension Nomenclatura {
    /// Un texto de la interfaz de las apps en el idioma de los textos de esta notación.
    public func texto(_ texto: TextoDeLasApps) -> String {
        texto.texto(en: self)
    }
}

extension PresentacionDeCoral.Tarea {
    /// El nombre de la tarea en el selector: «Armonizar», «Harmonize»…
    public func titulo(en notacion: Nomenclatura) -> String {
        let traduccion: Traduccion
        switch self {
        case .armonizar:
            traduccion = Traduccion("Armonizar", "Harmonize", ca: "Harmonitzar", gl: "Harmonizar", eu: "Harmonizatu",
                                    pt: "Harmonizar", fr: "Harmoniser", it: "Armonizzare")
        case .realizar:
            traduccion = Traduccion("Realizar", "Realize", ca: "Realitzar", gl: "Realizar", eu: "Gauzatu",
                                    pt: "Realizar", fr: "Réaliser", it: "Realizzare")
        case .revisar:
            traduccion = Traduccion("Revisar", "Check", ca: "Revisar", gl: "Revisar", eu: "Berrikusi",
                                    pt: "Rever", fr: "Vérifier", it: "Controllare")
        }
        return traduccion.en(notacion)
    }

    /// Qué se escribe en el campo de texto, con los ejemplos en la notación.
    public func indicacion(en notacion: Nomenclatura) -> String {
        let traduccion: Traduccion
        switch self {
        case .armonizar:
            let e = TextoDeLasApps.alturas("Mi4 Fa4 Re4 Do4", notacion)
            traduccion = Traduccion("Melodía (\(e), o sin octavas)", "Melody (\(e), or without octaves)",
                                    ca: "Melodia (\(e), o sense octaves)", gl: "Melodía (\(e), ou sen oitavas)",
                                    eu: "Melodia (\(e), edo zortzidunik gabe)", pt: "Melodia (\(e), ou sem oitavas)",
                                    fr: "Mélodie (\(e), ou sans octaves)", it: "Melodia (\(e), o senza ottave)")
        case .realizar:
            let e = ["Do", "Fa", "Sol7", "Do"].map { TextoDeLasApps.cifrado($0, notacion) }.joined(separator: " ")
            traduccion = TextoDeLasApps.acordes.traduccion(notacion).aplicando { "\($0) (\(e))" }
        case .revisar:
            let e = TextoDeLasApps.alturas("Do3 Mi4 Sol4 Do5, Sol2 Re4 Sol4 Si4", notacion)
            traduccion = Traduccion("Voces de grave a agudo (\(e))", "Voices from low to high (\(e))",
                                    ca: "Veus de greu a agut (\(e))", gl: "Voces de grave a agudo (\(e))",
                                    eu: "Ahotsak, baxuenetik altuenera (\(e))", pt: "Vozes do grave ao agudo (\(e))",
                                    fr: "Voix du grave à l'aigu (\(e))", it: "Voci dal grave all'acuto (\(e))")
        }
        return traduccion.en(notacion)
    }
}

extension FicheroParaExportar.Formato {
    /// Cómo se llama el formato en el menú: «Partitura MusicXML», «MusicXML score»…
    public func titulo(en notacion: Nomenclatura) -> String {
        let traduccion: Traduccion
        switch self {
        case .musicXML:
            traduccion = Traduccion("Partitura MusicXML", "MusicXML score", ca: "Partitura MusicXML",
                                    gl: "Partitura MusicXML", eu: "MusicXML partitura", pt: "Partitura MusicXML",
                                    fr: "Partition MusicXML", it: "Partitura MusicXML")
        case .midi:
            return "MIDI"
        case .svg:
            traduccion = Traduccion("Dibujo SVG", "SVG drawing", ca: "Dibuix SVG", gl: "Debuxo SVG", eu: "SVG marrazkia",
                                    pt: "Desenho SVG", fr: "Dessin SVG", it: "Disegno SVG")
        }
        return traduccion.en(notacion)
    }
}
