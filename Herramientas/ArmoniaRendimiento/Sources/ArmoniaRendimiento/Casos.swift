import Armonia

/// Lo que se mide: lo que hacen las apps y la línea de comandos, y, en lo que recorre una sucesión
/// (análisis, armonización, realización), con varias longitudes, para ver cómo crece el tiempo.
enum Casos {
    static let cifrados = ["Do", "Rem7", "Sol7/Si", "Fa#m7b5", "Sibmaj7", "Mi°7",
                           "G7(b9,#11)", "Dm11", "Sol13sus4", "Do6/9", "Fa7alt", "Mibmaj7#11"]
    static let acordesDesdeMIDI = [[60, 64, 68], [61, 65, 68], [60, 63, 66, 69], [55, 59, 62, 65, 68],
                                   [64, 67, 72], [62, 72, 76, 79]]
    static let progresion = ["Do", "Lam", "Rem7", "Sol7", "Do", "Mi7", "Lam", "Re7", "Sol", "Do"]
    static let melodia: [Altura] = ["Mi4", "Re4", "Do4", "Re4", "Mi4", "Mi4", "Mi4", "Re4",
                                    "Re4", "Re4", "Mi4", "Sol4", "Sol4", "Mi4", "Re4", "Do4"]
    static let coral = "Do3 Mi4 Sol4 Do5 | Fa3 Fa4 La4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5"

    static let longitudes = [4, 8, 16, 32]

    /// Los elementos de `base` uno tras otro, volviendo a empezar, hasta tener `n`.
    static func repetir<T>(_ base: [T], hasta n: Int) -> [T] {
        (0..<n).map { base[$0 % base.count] }
    }

    static func todos() -> [Caso] {
        let acordes = cifrados.compactMap { Acorde(texto: $0) }
        let doMayor = Tonalidad(.do)
        let sol7: Acorde = "Sol7/Si"
        let guitarra = Mastil(.guitarra)
        let ukelele = Mastil(.ukelele)
        let analisisLargo = try? AnalisisArmonico.analizar(leyendo: repetir(progresion, hasta: 64).joined(separator: " "))

        var casos: [Caso] = [
            Caso(grupo: "Acordes", nombre: "Leer \(cifrados.count) cifrados") {
                cifrados.reduce(0) { $0 + (Acorde(texto: $1)?.notas.count ?? 0) }
            },
            Caso(grupo: "Acordes", nombre: "Escribir \(acordes.count) cifrados") {
                acordes.reduce(0) { $0 + $1.cifrado.count }
            },
            Caso(grupo: "Acordes", nombre: "Identificar \(acordesDesdeMIDI.count) acordes desde MIDI") {
                acordesDesdeMIDI.reduce(0) { $0 + Acorde.candidatos(midi: $1).count }
            },
            Caso(grupo: "Escalas", nombre: "Identificar las escalas de 5 notas") {
                Escala.identificar([.do, .mi, .sol, .si, "Fa#"]).count
            },
            Caso(grupo: "Escalas", nombre: "Las \(TipoDeEscala.todos.count) del catálogo, en Do") {
                TipoDeEscala.todos.reduce(0) { $0 + Escala(.do, $1).notas.count }
            },
            Caso(grupo: "Escalas", nombre: "Ortografiar la escala cromática") {
                Escala(.do).ortografiar(midi: Array(60...72)).count
            },
            Caso(grupo: "Tonalidad", nombre: "Estimar la tonalidad de 12 notas") {
                Tonalidad.candidatos(midi: [69, 71, 72, 74, 76, 77, 80, 81, 80, 78, 77, 76]).count
            },
            Caso(grupo: "Conjuntos", nombre: "Forma prima de los 4096 conjuntos") {
                (0..<4096).reduce(0) { suma, mascara in
                    suma + ConjuntoDeClases((0..<12).filter { mascara & (1 << $0) != 0 }).formaPrima.count
                }
            },
        ]

        for n in [4, 16, 64] {
            let texto = repetir(progresion, hasta: n).joined(separator: " ")
            casos.append(Caso(grupo: "Análisis", nombre: "\(n) acordes") {
                (try? AnalisisArmonico.analizar(leyendo: texto))?.acordes.count ?? 0
            })
        }
        for n in longitudes {
            let notas = repetir(melodia, hasta: n).map(\.nota)
            casos.append(Caso(grupo: "Armonizar", nombre: "\(n) notas, 3 propuestas") {
                doMayor.armonizar(melodia: notas, propuestas: 3).count
            })
        }
        for n in longitudes {
            let alturas = repetir(melodia, hasta: n)
            casos.append(Caso(grupo: "Armonizar a cuatro voces", nombre: "\(n) notas") {
                doMayor.armonizarACuatroVoces(alturas)?.voces.acordes.count ?? 0
            })
        }
        for n in longitudes {
            let sucesion = repetir(progresion, hasta: n).compactMap { Acorde(texto: $0) }
            casos.append(Caso(grupo: "Realizar a cuatro voces", nombre: "\(n) acordes") {
                ConduccionDeVoces.realizar(sucesion, en: doMayor)?.acordes.count ?? 0
            })
        }

        casos += [
            Caso(grupo: "Conducción", nombre: "Revisar un coral de 4 acordes") {
                (try? ConduccionDeVoces(leyendo: coral))?.problemas.count ?? 0
            },
            Caso(grupo: "Digitaciones", nombre: "Sol7/Si en la guitarra") {
                guitarra.digitaciones(de: sol7).count
            },
            Caso(grupo: "Digitaciones", nombre: "Sol13 en la guitarra, sin quinta") {
                guitarra.digitaciones(de: "Sol13", exigirQuinta: false).count
            },
            Caso(grupo: "Digitaciones", nombre: "Rem7 en el ukelele") {
                ukelele.digitaciones(de: "Rem7").count
            },
            Caso(grupo: "Dibujos", nombre: "Tonnetz de Do mayor (SVG)") {
                Tonnetz(Escala(.do)).svg().count
            },
            Caso(grupo: "Dibujos", nombre: "Tabla armónica de Sol7/Si (SVG)") {
                TablaArmonica(sol7).svg().count
            },
            Caso(grupo: "Partituras", nombre: "MusicXML de 64 acordes analizados") {
                analisisLargo?.musicXML().count ?? 0
            },
            Caso(grupo: "Partituras", nombre: "MIDI de 64 acordes analizados") {
                analisisLargo?.midi().count ?? 0
            },
        ]
        return casos
    }
}
