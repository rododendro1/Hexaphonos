import ArmoniaNucleo
import Foundation

extension TipoDeEscala {
    // MARK: Nombres internacionales

    /// Nombre en inglés (el primero de cada lista) y otras formas aceptadas al leer.
    package static let internacionales: [(tipo: TipoDeEscala, nombres: [String])] = [
        (.mayor, ["major", "ionian"]),
        (.dorico, ["dorian"]),
        (.frigio, ["phrygian"]),
        (.lidio, ["lydian"]),
        (.mixolidio, ["mixolydian"]),
        (.menorNatural, ["natural minor", "minor", "aeolian"]),
        (.locrio, ["locrian"]),
        (.menorArmonica, ["harmonic minor"]),
        (.menorMelodica, ["melodic minor", "classical melodic minor"]),
        (.menorMelodicaJazz, ["jazz minor", "ascending melodic minor", "melodic minor ascending"]),
        (.pentatonicaMayor, ["major pentatonic", "pentatonic major", "pentatonic"]),
        (.pentatonicaMenor, ["minor pentatonic", "pentatonic minor"]),
        (.blues, ["blues"]),
        (.tonosEnteros, ["whole tone", "auxiliary augmented"]),
        (.disminuida, ["whole half diminished", "diminished", "octatonic", "whole half", "auxiliary diminished"]),
        (.mayorArmonica, ["harmonic major"]),
        (.locrioSextaNatural, ["locrian natural 6", "locrian #6"]),
        (.jonicoAumentado, ["ionian augmented", "ionian #5"]),
        (.doricoCuartaAumentada, ["dorian #4", "ukrainian dorian", "Romanian minor"]),
        (.frigioDominante, ["phrygian dominant", "spanish phrygian", "dominant b9 b13"]),
        (.lidioSegundaAumentada, ["lydian #2"]),
        (.ultralocrio, ["ultralocrian", "superlocrian bb7", "altered diminished"]),
        (.doricoSegundaMenor, ["dorian b2", "phrygian natural 6"]),
        (.lidioAumentado, ["lydian augmented", "lydian #5"]),
        (.lidioDominante, ["lydian dominant", "lydian b7", "acoustic", "overtone", "Bartok", "Nordestina"]),
        (.mixolidioSextaMenor, ["mixolydian b6", "aeolian dominant", "melodic major"]),
        (.locrioSegundaNatural, ["locrian natural 2", "half diminished"]),
        (.alterada, ["altered", "superlocrian"]),
        (.bebopDominante, ["bebop dominant", "bebop"]),
        (.bebopMayor, ["bebop major"]),
        (.bebopDorico, ["bebop dorian", "bebop minor"]),
        (.doricoQuintaDisminuida, ["dorian b5"]),
        (.frigioCuartaDisminuida, ["phrygian b4", "superphrygian"]),
        (.lidioTerceraMenor, ["lydian b3", "lydian diminished"]),
        (.mixolidioSegundaMenor, ["mixolydian b2"]),
        (.lidioAumentadoSegundaAumentada, ["lydian augmented #2"]),
        (.locrioSeptimaDisminuida, ["locrian bb7"]),
        (.dobleArmonica, ["double harmonic major", "double harmonic", "byzantine", "gypsy major"]),
        (.menorHungara, ["hungarian minor", "gypsy minor", "double harmonic minor"]),
        (.mayorHungara, ["hungarian major"]),
        (.napolitanaMenor, ["neapolitan minor"]),
        (.napolitanaMayor, ["neapolitan major"]),
        (.enigmatica, ["enigmatic"]),
        (.persa, ["persian"]),
        (.mayorLocria, ["major locrian", "arabian"]),
        (.lidioMenor, ["lydian minor"]),
        (.prometeo, ["Prometheus", "mystic"]),
        (.disminuidaSemitonoTono, ["half whole diminished", "half whole", "dominant diminished", "auxiliary diminished blues"]),
        (.aumentada, ["augmented", "symmetric augmented"]),
        (.bluesMayor, ["major blues"]),
        (.egipcia, ["Egyptian", "suspended pentatonic"]),
        (.cromatica, ["chromatic"]),
        (.bebopMenorMelodica, ["bebop melodic minor"]),
        (.bebopMenorArmonica, ["bebop harmonic minor"]),
        (.flamenca, ["flamenco", "Spanish eight tone", "Spanish 8 tone", "Andalusian", "Spanish gypsy"]),
        (.argelina, ["Algerian"]),
        (.jonicoSinCuarta, ["Ionian no 4", "hexatonic Ionian"]),
        (.mixolidioSinTercera, ["Mixolydian no 3", "hexatonic Mixolydian"]),
        (.doricoSinSexta, ["Dorian no 6", "hexatonic Dorian"]),
        (.eolicoSinSegunda, ["Aeolian no 2", "hexatonic Aeolian"]),
        (.hexatonicaDeDosTriadas, ["two triad hexatonic", "triad pair"]),
        (.hexatonicaMenorDeDosTriadas, ["minor two triad hexatonic", "minor triad pair"]),
        (.mayorRumana, ["Romanian major"]),
        (.petrushka, ["Petrushka", "tritone"]),
        (.messiaen3, ["Messiaen mode 3", "Tcherepnin", "nine tone"]),
        (.messiaen4, ["Messiaen mode 4"]),
        (.messiaen5, ["Messiaen mode 5"]),
        (.messiaen6, ["Messiaen mode 6"]),
        (.messiaen7, ["Messiaen mode 7"]),
        (.lidioSegundaSextaAumentadas, ["lydian #2 #6"]),
        (.ultrafrigio, ["ultraphrygian"]),
        (.oriental, ["oriental"]),
        (.jonicoSegundaQuintaAumentadas, ["ionian #2 #5"]),
        (.locrioTerceraSeptimaDisminuidas, ["locrian bb3 bb7"]),
        (.lidioAumentadoSextaAumentada, ["leading whole tone", "lydian augmented #6"]),
        (.lidioDominanteAumentado, ["lydian augmented dominant", "lydian dominant #5"]),
        (.locrioSegundaNaturalCuartaDisminuida, ["half diminished b4", "locrian natural 2 b4"]),
        (.superlocrioTerceraDisminuida, ["altered bb3", "superlocrian bb3"]),
        (.lidioSextaAumentada, ["lydian #6"]),
        (.mixolidioAumentado, ["mixolydian augmented", "mixolydian #5"]),
        (.eolicoCuartaAumentada, ["Hungarian gypsy", "aeolian #4"]),
        (.locrioDominante, ["locrian dominant"]),
        (.jonicoSegundaAumentada, ["ionian #2"]),
        (.ultralocrioTerceraDisminuida, ["ultralocrian bb3"]),
        (.pentatonicaDominante, ["dominant pentatonic"]),
        (.pentatonicaMenorSexta, ["minor 6 pentatonic", "dorian pentatonic"]),
        (.pentatonicaMayorSextaMenor, ["major b6 pentatonic", "Coltrane pentatonic"]),
        (.pentatonicaMenorQuintaDisminuida, ["minor b5 pentatonic"]),
        (.pentatonicaMixolidia, ["Mixolydian pentatonic"]),
        (.pentatonicaLidia, ["Lydian pentatonic"]),
        (.pentatonicaEscocesa, ["Scottish pentatonic"]),
        (.ultralocrioSextaDisminuida, ["ultralocrian bb6"]),
        (.menorArmonicaQuintaDisminuida, ["harmonic minor b5"]),
        (.superlocrioSextaNatural, ["superlocrian natural 6", "altered natural 6"]),
        (.menorMelodicaQuintaAumentada, ["melodic minor #5", "jazz minor #5"]),
        (.doricoSegundaMenorCuartaAumentada, ["Dorian b2 #4", "Dorian b9 #11"]),
        (.lidioAumentadoTerceraAumentada, ["lydian augmented #3"]),
        (.bluesDeNueveNotas, ["nine tone blues", "9 tone blues"]),
        (.bluesMenorConSegunda, ["minor blues with 2", "blues with 2"]),
        (.hexacordo, ["hexachord", "Guidonian hexachord"]),
    ]

    /// Nombre en español ("dórico"), inglés ("dorian"), catalán ("dòric"), gallego ("dórico") o
    /// euskera ("doriarra"). Un tipo sin nombre conocido en ese idioma (como un modo de una escala
    /// propia) usa su nombre español.
    public func nombre(en notacion: Nomenclatura) -> String {
        // Los nombres propios de otras tradiciones (Kafi, Hitzaz…) son los mismos en todos los idiomas.
        guard !TipoDeEscala.nombresTradicionales.contains(nombre) else { return nombre }
        switch notacion.idioma {
        case .espanol, .portugues: return nombre
        case .ingles, .aleman, .frances, .italiano: return TipoDeEscala.nombreInglesPorTipo[self] ?? nombre
        case .catalan: return TipoDeEscala.nombrePeninsularPorTipo[self]?.catalan ?? nombre
        case .gallego: return TipoDeEscala.nombrePeninsularPorTipo[self]?.gallego ?? nombre
        case .euskera: return TipoDeEscala.nombrePeninsularPorTipo[self]?.euskera ?? nombre
        }
    }
}
