import ArmoniaNucleo
// Nombres de los tipos de escala occidentales en catalán, gallego y euskera. Los de otras
// tradiciones (Kafi, Hitzaz, Hirajoshi…) son nombres propios y se quedan como están. El resto de
// nombres que dependen del idioma, en `Texto/Idiomas.swift`.

// MARK: - TipoDeEscala

extension TipoDeEscala {
    /// Catalán, gallego y euskera de cada tipo de escala occidental del catálogo. Los modos llevan
    /// las alteraciones igual que en español ("lidi ♯2", "lidiarra ♯2").
    package static let nombresPeninsulares: [(tipo: TipoDeEscala, catalan: String, gallego: String, euskera: String)] = [
        (.mayor, "major", "maior", "maiorra"),
        (.dorico, "dòric", "dórico", "doriarra"),
        (.frigio, "frigi", "frixio", "frigiarra"),
        (.lidio, "lidi", "lidio", "lidiarra"),
        (.mixolidio, "mixolidi", "mixolidio", "mixolidiarra"),
        (.menorNatural, "menor natural", "menor natural", "minor naturala"),
        (.locrio, "locri", "locrio", "lokriarra"),
        (.menorArmonica, "menor harmònica", "menor harmónica", "minor harmonikoa"),
        (.menorMelodica, "menor melòdica", "menor melódica", "minor melodikoa"),
        (.menorMelodicaJazz, "menor melòdica de jazz", "menor melódica de jazz", "jazzeko minor melodikoa"),
        (.pentatonicaMayor, "pentatònica major", "pentatónica maior", "pentatoniko maiorra"),
        (.pentatonicaMenor, "pentatònica menor", "pentatónica menor", "pentatoniko minorra"),
        (.blues, "blues", "blues", "bluesa"),
        (.tonosEnteros, "tons sencers", "tons enteiros", "tonu osoak"),
        (.disminuida, "disminuïda to-semitò", "diminuída ton-semiton", "gutxitua tonu-tonuerdi"),
        (.dobleArmonica, "doble harmònica", "dobre harmónica", "harmoniko bikoitza"),
        (.menorHungara, "menor hongaresa", "menor húngara", "minor hungariarra"),
        (.mayorHungara, "major hongaresa", "maior húngara", "maior hungariarra"),
        (.napolitanaMenor, "napolitana menor", "napolitana menor", "minor napolitarra"),
        (.napolitanaMayor, "napolitana major", "napolitana maior", "maior napolitarra"),
        (.enigmatica, "enigmàtica", "enigmática", "enigmatikoa"),
        (.persa, "persa", "persa", "persiarra"),
        (.mayorLocria, "major lòcria", "maior locria", "maior lokriarra"),
        (.lidioMenor, "lidi menor", "lidio menor", "lidiar minorra"),
        (.prometeo, "Prometeu", "Prometeo", "Prometeo"),
        (.disminuidaSemitonoTono, "disminuïda semitò-to", "diminuída semiton-ton", "gutxitua tonuerdi-tonu"),
        (.aumentada, "augmentada", "aumentada", "gehitua"),
        (.bluesMayor, "blues major", "blues maior", "blues maiorra"),
        (.egipcia, "egípcia", "exipcia", "egiptoarra"),
        (.cromatica, "cromàtica", "cromática", "kromatikoa"),
        (.jonicoSinCuarta, "jònic sense 4a", "xónico sen 4ª", "joniarra 4.rik gabe"),
        (.mixolidioSinTercera, "mixolidi sense 3a", "mixolidio sen 3ª", "mixolidiarra 3.rik gabe"),
        (.doricoSinSexta, "dòric sense 6a", "dórico sen 6ª", "doriarra 6.rik gabe"),
        (.eolicoSinSegunda, "eòlic sense 2a", "eólico sen 2ª", "eoliarra 2.rik gabe"),
        (.hexatonicaDeDosTriadas, "hexatònica de dues tríades", "hexatónica de dúas tríades", "bi triadeko hexatonikoa"),
        (.hexatonicaMenorDeDosTriadas, "hexatònica menor de dues tríades", "hexatónica menor de dúas tríades", "bi triadeko hexatoniko minorra"),
        (.mayorRumana, "major romanesa", "maior romanesa", "maior errumaniarra"),
        (.argelina, "algeriana", "alxeriana", "aljeriarra"),
        (.petrushka, "Petrushka", "Petrushka", "Petrushka"),
        (.bebopMenorMelodica, "bebop menor melòdica", "bebop menor melódica", "bebop minor melodikoa"),
        (.bebopMenorArmonica, "bebop menor harmònica", "bebop menor harmónica", "bebop minor harmonikoa"),
        (.flamenca, "flamenca", "flamenca", "flamenkoa"),
        (.pentatonicaDominante, "pentatònica dominant", "pentatónica dominante", "pentatoniko dominantea"),
        (.pentatonicaMenorSexta, "pentatònica menor 6", "pentatónica menor 6", "pentatoniko minorra 6"),
        (.pentatonicaMayorSextaMenor, "pentatònica major ♭6", "pentatónica maior ♭6", "pentatoniko maiorra ♭6"),
        (.pentatonicaMenorQuintaDisminuida, "pentatònica menor ♭5", "pentatónica menor ♭5", "pentatoniko minorra ♭5"),
        (.pentatonicaMixolidia, "pentatònica mixolídia", "pentatónica mixolidia", "pentatoniko mixolidiarra"),
        (.pentatonicaLidia, "pentatònica lídia", "pentatónica lidia", "pentatoniko lidiarra"),
        (.pentatonicaEscocesa, "pentatònica escocesa", "pentatónica escocesa", "pentatoniko eskoziarra"),
        (.bluesDeNueveNotas, "blues de nou notes", "blues de nove notas", "bederatzi notako bluesa"),
        (.bluesMenorConSegunda, "blues menor amb 2a", "blues menor con 2ª", "blues minorra 2.arekin"),
        (.hexacordo, "hexacord", "hexacordo", "hexakordea"),
        (.messiaen3, "mode 3 de Messiaen", "modo 3 de Messiaen", "Messiaenen 3. modua"),
        (.messiaen4, "mode 4 de Messiaen", "modo 4 de Messiaen", "Messiaenen 4. modua"),
        (.messiaen5, "mode 5 de Messiaen", "modo 5 de Messiaen", "Messiaenen 5. modua"),
        (.messiaen6, "mode 6 de Messiaen", "modo 6 de Messiaen", "Messiaenen 6. modua"),
        (.messiaen7, "mode 7 de Messiaen", "modo 7 de Messiaen", "Messiaenen 7. modua"),
        (.locrioSextaNatural, "locri ♮6", "locrio ♮6", "lokriarra ♮6"),
        (.jonicoAumentado, "jònic ♯5", "xónico ♯5", "joniarra ♯5"),
        (.doricoCuartaAumentada, "dòric ♯4", "dórico ♯4", "doriarra ♯4"),
        (.frigioDominante, "frigi dominant", "frixio dominante", "frigiar dominantea"),
        (.lidioSegundaAumentada, "lidi ♯2", "lidio ♯2", "lidiarra ♯2"),
        (.ultralocrio, "ultralocri", "ultralocrio", "ultralokriarra"),
        (.doricoSegundaMenor, "dòric ♭2", "dórico ♭2", "doriarra ♭2"),
        (.lidioAumentado, "lidi augmentat", "lidio aumentado", "lidiar gehitua"),
        (.lidioDominante, "lidi dominant", "lidio dominante", "lidiar dominantea"),
        (.mixolidioSextaMenor, "mixolidi ♭6", "mixolidio ♭6", "mixolidiarra ♭6"),
        (.locrioSegundaNatural, "locri ♮2", "locrio ♮2", "lokriarra ♮2"),
        (.alterada, "alterada", "alterada", "alteratua"),
        (.mayorArmonica, "major harmònica", "maior harmónica", "maior harmonikoa"),
        (.bebopDominante, "bebop dominant", "bebop dominante", "bebop dominantea"),
        (.bebopMayor, "bebop major", "bebop maior", "bebop maiorra"),
        (.bebopDorico, "bebop dòric", "bebop dórico", "bebop doriarra"),
        (.doricoQuintaDisminuida, "dòric ♭5", "dórico ♭5", "doriarra ♭5"),
        (.frigioCuartaDisminuida, "frigi ♭4", "frixio ♭4", "frigiarra ♭4"),
        (.lidioTerceraMenor, "lidi ♭3", "lidio ♭3", "lidiarra ♭3"),
        (.mixolidioSegundaMenor, "mixolidi ♭2", "mixolidio ♭2", "mixolidiarra ♭2"),
        (.lidioAumentadoSegundaAumentada, "lidi augmentat ♯2", "lidio aumentado ♯2", "lidiar gehitua ♯2"),
        (.locrioSeptimaDisminuida, "locri ♭♭7", "locrio ♭♭7", "lokriarra ♭♭7"),
        (.lidioSegundaSextaAumentadas, "lidi ♯2 ♯6", "lidio ♯2 ♯6", "lidiarra ♯2 ♯6"),
        (.ultrafrigio, "ultrafrigi", "ultrafrixio", "ultrafrigiarra"),
        (.oriental, "oriental", "oriental", "ekialdekoa"),
        (.jonicoSegundaQuintaAumentadas, "jònic ♯2 ♯5", "xónico ♯2 ♯5", "joniarra ♯2 ♯5"),
        (.locrioTerceraSeptimaDisminuidas, "locri ♭♭3 ♭♭7", "locrio ♭♭3 ♭♭7", "lokriarra ♭♭3 ♭♭7"),
        (.lidioAumentadoSextaAumentada, "lidi augmentat ♯6", "lidio aumentado ♯6", "lidiar gehitua ♯6"),
        (.lidioDominanteAumentado, "lidi dominant augmentat", "lidio dominante aumentado", "lidiar dominante gehitua"),
        (.locrioSegundaNaturalCuartaDisminuida, "locri ♮2 ♭4", "locrio ♮2 ♭4", "lokriarra ♮2 ♭4"),
        (.superlocrioTerceraDisminuida, "superlocri ♭♭3", "superlocrio ♭♭3", "superlokriarra ♭♭3"),
        (.lidioSextaAumentada, "lidi ♯6", "lidio ♯6", "lidiarra ♯6"),
        (.mixolidioAumentado, "mixolidi augmentat", "mixolidio aumentado", "mixolidiar gehitua"),
        (.eolicoCuartaAumentada, "eòlic ♯4", "eólico ♯4", "eoliarra ♯4"),
        (.locrioDominante, "locri dominant", "locrio dominante", "lokriar dominantea"),
        (.jonicoSegundaAumentada, "jònic ♯2", "xónico ♯2", "joniarra ♯2"),
        (.ultralocrioTerceraDisminuida, "ultralocri ♭♭3", "ultralocrio ♭♭3", "ultralokriarra ♭♭3"),
        (.ultralocrioSextaDisminuida, "ultralocri ♭♭6", "ultralocrio ♭♭6", "ultralokriarra ♭♭6"),
        (.menorArmonicaQuintaDisminuida, "menor harmònica ♭5", "menor harmónica ♭5", "minor harmonikoa ♭5"),
        (.superlocrioSextaNatural, "superlocri ♮6", "superlocrio ♮6", "superlokriarra ♮6"),
        (.menorMelodicaQuintaAumentada, "menor melòdica ♯5", "menor melódica ♯5", "minor melodikoa ♯5"),
        (.doricoSegundaMenorCuartaAumentada, "dòric ♭2 ♯4", "dórico ♭2 ♯4", "doriarra ♭2 ♯4"),
        (.lidioAumentadoTerceraAumentada, "lidi augmentat ♯3", "lidio aumentado ♯3", "lidiar gehitua ♯3"),
    ]

    /// Tipo → (catalán, gallego, euskera).
    package static let nombrePeninsularPorTipo: [TipoDeEscala: (catalan: String, gallego: String, euskera: String)] = {
        var tabla: [TipoDeEscala: (catalan: String, gallego: String, euskera: String)] = [:]
        for fila in nombresPeninsulares where tabla[fila.tipo] == nil {
            tabla[fila.tipo] = (fila.catalan, fila.gallego, fila.euskera)
        }
        return tabla
    }()

    /// Nombres en catalán, gallego y euskera, normalizados → tipo, para leerlos con la tónica en esas
    /// lenguas ("re dòric", "re doriarra").
    package static let indicePeninsular: [String: TipoDeEscala] = {
        var indice: [String: TipoDeEscala] = [:]
        for fila in nombresPeninsulares {
            for nombre in [fila.catalan, fila.gallego, fila.euskera] where indice[normalizar(nombre)] == nil {
                indice[normalizar(nombre)] = fila.tipo
            }
        }
        return indice
    }()
}
