import Armonia
import Foundation

func titulo(_ texto: String) { print("\n== \(texto) ==") }

titulo("Línea de quintas")
for q in -8...8 {
    let n = Nota(pasosDeQuinta: q)
    print(String(q).padding(toLength: 4, withPad: " ", startingAt: 0), n)
}

titulo("Notas")
let la = Altura("La4")
print(la, "MIDI", la.midi, "→", la.frecuencia(), "Hz; coordenadas (\(la.pasosDeQuinta), \(la.pasosDeOctava))")
let doBemol = Altura("Dob4")
print(doBemol, "MIDI", doBemol.midi, "— enarmónica de", Altura(midi: 59))
print("Fa#4 ≠ Solb4:", Altura("Fa#4") != Altura("Solb4"), "· enarmónicas:", Altura("Fa#4").esEnarmonica(de: Altura("Solb4")))
print("Mi4 temperado vs pitagórico:", Altura("Mi4").frecuencia(), Altura("Mi4").frecuencia(en: TemperamentoRegular.pitagorico))

titulo("Intervalos")
let pares: [(String, String)] = [("Do4", "Mi4"), ("Fa4", "Si4"), ("Si3", "Fa4"), ("Do4", "Re5"), ("Sol4", "Do4"), ("Do4", "Do#4")]
for (a, b) in pares {
    let i = Altura(texto: b)! - Altura(texto: a)!
    print("\(a) → \(b):", i, "(\(i.abreviatura), \(i.semitonos) st, coords (\(i.pasosDeQuinta), \(i.pasosDeOctava)))")
}
print("Inversión de 3M:", Intervalo.terceraMayor.inversion)
print("3M + 3m =", Intervalo.terceraMayor + .terceraMenor)
print("Do + 4A =", Nota.do + .cuartaAumentada, "· Do + 5d =", Nota.do + .quintaDisminuida)

titulo("Acordes")
for cifrado in ["Do", "Rem7", "Sol7/Si", "Fa#m7b5", "Sibmaj7", "Mi°7"] {
    let acorde = Acorde(texto: cifrado)!
    print(cifrado.padding(toLength: 9, withPad: " ", startingAt: 0),
          acorde.notasDesdeElBajo.map(\.nombre).joined(separator: " "),
          "·", acorde.posicionCerrada(octava: 3).map(\.description).joined(separator: " "),
          "·", acorde.nombre)
}
let identificados = Acorde.identificar([Altura("Mi3"), Altura("Sol3"), Altura("Do4"), Altura("La3")])
print("Mi3 Sol3 La3 Do4 →", identificados.map(\.cifrado))

titulo("Cifrado generativo")
for texto in ["G7(b9,#11)", "Dm11", "Sol13sus4", "Do6/9", "Fa7alt", "Mibmaj7#11", "Do/Re", "La-7"] {
    let acorde: Acorde = Acorde(texto: texto)!
    print(texto.padding(toLength: 12, withPad: " ", startingAt: 0), "→", acorde.cifrado.padding(toLength: 22, withPad: " ", startingAt: 0),
          acorde.notasDesdeElBajo.map(\.nombre).joined(separator: " "))
}

titulo("Identificación tolerante")
let conjuntos: [[Nota]] = [["Do", "Mi", "Sib"], ["Do", "Mi", "Sib", "Reb"], ["Re", "Do", "Mi", "Sol"], ["Mi", "Sol", "Do", "Mi"]]
for notas in conjuntos {
    let lecturas = Acorde.candidatos(notas).prefix(3).map { c -> String in
        let faltan = c.omitidas.isEmpty ? "" : " sin " + c.omitidas.map(\.nombre).joined(separator: ",")
        return "\(c.valor.cifrado) (\(c.coste)\(faltan))"
    }
    print(notas.map(\.nombre).joined(separator: " "), "→", lecturas.joined(separator: " · "))
}

titulo("Errores de lectura")
for texto in ["Do7(b3)", "Do7 9", "Do/Xa", "Dom5", "Re dorian"] {
    do {
        if texto.contains(" d") { _ = try Escala(leyendo: texto) } else { _ = try Acorde(leyendo: texto) }
    } catch {
        print(error)
    }
}

titulo("Estilos de cifrado")
let muestra: [Acorde] = ["Sib7(b9)/Re", "Do#m7b5", "Mibmaj7", "Fa+", "Rem(add9)"]
let estilos: [(String, EstiloDeCifrado)] = [("predeterminado", .predeterminado), ("ascii", .ascii),
                                          ("internacional", .ingles), ("jazz", .jazz), ("palabras", .palabras)]
for (nombre, estilo) in estilos {
    print(nombre.padding(toLength: 15, withPad: " ", startingAt: 0),
          muestra.map { $0.cifrado(estilo: estilo) }.joined(separator: "  "))
}

titulo("Estructura del acorde")
let alterado: Acorde = "Sol13(b9)"
for componente in alterado.componentes {
    print("  \(componente.nota.nombre.padding(toLength: 4, withPad: " ", startingAt: 0)) \(componente.intervalo.nombre) — \(componente.papel)")
}
print("  tercera:", alterado.tercera!, "· séptima:", alterado.septima!, "· tensiones:", alterado.tensiones,
      "· tríada:", alterado.estructura.calidadDeTriada)

titulo("Identificación desde MIDI")
for midi in [[60, 64, 68], [61, 65, 68], [60, 63, 66, 69], [55, 59, 62, 65, 68], [64, 67, 72], [62, 72, 76, 79]] {
    let lecturas = Acorde.candidatos(midi: midi).prefix(3)
    guard let mejor = lecturas.first?.valor else { continue }
    print("\(midi) →", lecturas.map(\.valor.cifrado).joined(separator: " · "),
          "  escrito:", mejor.ortografiar(midi: midi).map(\.description).joined(separator: " "))
}
print("[66, 70, 73] en Sol♭ mayor →", Acorde.identificar(midi: [66, 70, 73], tonalidad: Tonalidad("Solb mayor")).first!)

titulo("Notación internacional")
let ejemploAcorde: Acorde = "Sib7(b9)/Re"
print(ejemploAcorde.cifrado(en: .ingles), "·", ejemploAcorde.cifrado(estilo: .inglesUnicode), "·", ejemploAcorde.nombre(en: .ingles))
print(Intervalo.cuartaAumentada.abreviatura(en: .ingles), "·", Intervalo.novenaMenor.nombre(en: .ingles),
      "·", Intervalo("P5"), "·", Altura("Fa#3").nombre(en: .ingles), "·", Escala("Re dórico").nombre(en: .ingles),
      "·", Escala("Bb harmonic minor"))

titulo("Escalas")
for texto in ["Do mayor", "Mib mayor", "La menor armónica", "Re dórico", "Fa# lidio", "Do tonos enteros"] {
    let e = Escala(texto: texto)!
    let armadura = e.armadura.map { String($0) } ?? "—"
    print(e.nombre.padding(toLength: 20, withPad: " ", startingAt: 0),
          e.notas.map(\.nombre).joined(separator: " "), "· armadura:", armadura)
}

titulo("Armonización")
for e in [Escala(.do), Escala(.la, .menorArmonica), Escala(.la, .menorMelodica)] {
    let acordes = e.armonizar(cuatriadas: true).map { $0?.cifrado ?? "?" }
    let romanos = e.cifradosRomanos(cuatriadas: true).map { $0 ?? "?" }
    print(e)
    print("  ", acordes.joined(separator: "  "))
    print("  ", romanos.joined(separator: "  "))
}
print("Modos de Do mayor:", (1...7).map { Escala(.do).rotacion($0).nombre })
print("La menor armónica (ref. menor natural):",
      Escala(.la, .menorArmonica).cifradosRomanos(referencia: .menorNatural).map { $0 ?? "?" })
print("La menor melódica bajando:", Escala("La menor melódica").alturas(octava: 4, direccion: .descendente))

titulo("Comodidades")
let tritono: Intervalo = "4A"
let acordeLiteral: Acorde = "Sol7/Si"
print("Re + 3M =", Nota.re + "3M", "· 4A < 5d:", tritono < Intervalo.quintaDisminuida, "·", acordeLiteral.nombre)
let json = try! JSONEncoder().encode([acordeLiteral, "Fa#m7b5"])
print("JSON:", String(decoding: json, as: UTF8.self))

titulo("Ortografía y detección de tonalidad")
let melodia = [69, 71, 72, 74, 76, 77, 80, 81, 80, 78, 77, 76]
let estimacion = Tonalidad.candidatos(midi: melodia)
print("Tonalidad estimada:", estimacion.prefix(3).map { "\($0.valor) (\(String(format: "%.2f", $0.correlacion)))" }
        .joined(separator: " · "))
if let tonalidad = estimacion.first?.valor {
    print("Escrita en \(tonalidad):", tonalidad.ortografiar(midi: melodia).map(\.description).joined(separator: " "))
}
print("Cromática en Do mayor ↑:", Escala(.do).ortografiar(midi: Array(60...72)).map(\.nota.nombre).joined(separator: " "))
print("Cromática en Do mayor ↓:", Escala(.do).ortografiar(midi: Array((60...72).reversed())).map(\.nota.nombre).joined(separator: " "))

titulo("Afinaciones")
let afinaciones: [(String, any Afinacion)] = [
    ("igual", TemperamentoRegular.igual), ("pitagórico", TemperamentoRegular.pitagorico),
    ("mesotónico ¼", TemperamentoRegular.mesotonicoCuartoDeComa), ("31 divisiones", TemperamentoRegular.igual(divisiones: 31)),
    ("justa en Do", EntonacionJusta(tonica: .do)),
]
for (nombre, afinacion) in afinaciones {
    let notas: [Altura] = ["Do4", "Mi4", "Sol4", "La4", "Sol#4", "Lab4"]
    print(nombre.padding(toLength: 14, withPad: " ", startingAt: 0),
          notas.map { "\($0) " + String(format: "%.2f", afinacion.frecuencia(de: $0)) }.joined(separator: "  "))
}
print("Razones justas:", [Intervalo.terceraMayor, .terceraMenor, .septimaMayor, .cuartaAumentada]
        .map { "\($0.abreviatura) \($0.razonJusta)" }.joined(separator: " · "))

titulo("Tonalidades y escalas")
print("Círculo de quintas:", Escala.circuloDeQuintas().map(\.tonica.nombre).joined(separator: " "))
print("Armadura de Mi♭ mayor:", Escala("Mib mayor").notasDeLaArmadura!.map(\.nombre))
print("Vecinas de Do mayor:", Tonalidad(.do).vecinas.map(\.nombre))
print("Do♯ mayor →", Escala("Do# mayor").enarmonicaMasSimple)
print("Modos de La menor melódica:", (1...7).map { Escala(.la, .menorMelodica).rotacion($0).nombre })
print("Escalas con Do Mi Sol Si Fa♯:", Escala.identificar([.do, .mi, .sol, .si, "Fa#"]).prefix(6).map(\.nombre))
print("Nombres de los grados en Do mayor:", (1...7).map { Escala(.do).nombreDeGrado($0)!.nombre })

titulo("Intervalos: clase y consonancia")
for intervalo in [Intervalo.terceraMayor, .cuartaJusta, .cuartaAumentada, .segundaAumentada, .novenaMenor] {
    print("  \(intervalo.nombre): clase \(intervalo.claseIntervalica), \(intervalo.consonancia())")
}

titulo("Pentagrama")
for (clave, notas) in [(Clave.sol, ["Do4", "Sol4", "La5"]), (.fa, ["Sol2", "Do4"]), (.doEnTercera, ["Do4", "Fa3"])] as [(Clave, [Altura])] {
    print("  \(clave):", notas.map { "\($0) → \(clave.posicion(de: $0))" }.joined(separator: " · "))
}
print("  Clave para Do2–Mi2–Sol2:", Clave.masAdecuada(para: ["Do2", "Mi2", "Sol2"])!)

titulo("Instrumentos transpositores")
let concierto = Escala("Mib mayor")
for instrumento in [Instrumento.clarineteEnSib, .saxofonAlto, .trompaEnFa, .saxofonTenor] {
    print("  \(instrumento): Mi♭ mayor de concierto se escribe en \(instrumento.escritura(de: concierto)),",
          "Do5 escrito suena \(instrumento.sonido(de: Altura("Do5")))")
}

titulo("Melodías")
let tema: Melodia = ["Do4", "Re4", "Mi4", "Do4", "Sol4"]
print("  original:   ", tema)
print("  inversión:  ", tema.invertir())
print("  retrógrado: ", tema.retrogradar())
print("  +2M real:   ", tema.transponer(.segundaMayor))
print("  +1 grado:   ", tema.transponer(grados: 1, en: Escala(.do))!)
print("  desde MIDI: ", Melodia(midi: [62, 64, 65, 67, 69, 70, 73, 74]))

titulo("Base 40, 54 y 600")
let notasHewlett: [Altura] = ["Do4", "Fa#4", "Solb4", "Si#3"]
for base in [BaseDeHewlett.base40, .base54, .base600] {
    let pares = notasHewlett.map { nota -> String in
        let numero = nota.numero(en: base).map { String($0) } ?? "—"
        return "\(nota)=\(numero)"
    }
    let quinta = Intervalo.quintaJusta.numero(en: base) ?? 0
    print("  \(base):", pares.joined(separator: " "), "· 5ª justa =", quinta)
}

titulo("Alteraciones y colores de las notas")
print("  Alteraciones:", (-3...3).map { Alteracion($0).nombre }.joined(separator: ", "))
for correspondencia in CorrespondenciaDeColores.allCases {
    let colores = Escala(.do).colores(segun: correspondencia).map(\.hexadecimal)
    print("  \(correspondencia):", colores.joined(separator: " "))
}

titulo("Otras lenguas")
for notacion in [Nomenclatura.aleman, .frances, .italiano, .catalan, .gallego, .euskera, .portugues] {
    let notas = ["Do#", "Mib", "Sib", "Si"].map { Nota(texto: $0)!.nombre(en: notacion) }
    print("  \(notacion):", notas.joined(separator: ", "), "·", Tonalidad("Fa# mayor").nombre(en: notacion),
          "·", Acorde("Sim7").cifrado(en: notacion))
}

titulo("Escalas de la India y dromoi griegos")
for tipo in [TipoDeEscala.melakarta(15)!, .todi, .hitzaz, .houzam] {
    print("  \(Escala(.re, tipo).nombre):", Escala(.re, tipo).notas.map(\.nombre).joined(separator: " "))
}
print("  La escala mayor es el melakarta", TipoDeEscala.mayor.numeroDeMelakarta ?? 0)
let rast = Escala(.re, .rast)
print("  \(rast.nombre): sube", rast.alturas(octava: 4).map(\.description).joined(separator: " "),
      "· baja", rast.alturas(octava: 4, direccion: .descendente).map(\.description).joined(separator: " "))
print("  Otros nombres de la escala mayor:", TipoDeEscala.mayor.equivalentes.map(\.nombre).joined(separator: ", "))

titulo("Ritmo")
if let voz = try? Voz(leyendo: "Do4:4 Re4:8 Mi4:8 Fa4:2. Sol4:4", compas: "3/4") {
    print("  Voz:", voz)
    print("  Compases:", voz.compases.map { $0.map(\.texto).joined(separator: " ") }.joined(separator: " | "))
    print("  Duración:", voz.duracion, "· a", Tempo(90), "dura", voz.segundos(tempo: Tempo(90)), "s")
}
if let sincopa = try? Voz(leyendo: "Do4:8 Re4:4 Mi4:8 Fa4:4 Sol4:2 La4:4 Si4:4", compas: "4/4") {
    print("  Escritura con métrica:", sincopa.grafia.map { $0.map(\.texto).joined(separator: " ") }.joined(separator: " | "))
}
print("  7/8:", Compas("7/8").agrupacion, "· 3+2+2/8:", Compas("3+2+2/8").agrupacion)
print("  Figuras:", Figura.allCases.map { "\($0.nombre) (\($0.duracion.texto))" }.joined(separator: ", "))

titulo("Conjuntos de clases de altura")
for (nombre, conjunto) in [("Do mayor", Acorde("Do").conjuntoDeClases), ("Sol7", Acorde("Sol7").conjuntoDeClases),
                           ("diatónica", Escala(.re).conjuntoDeClases), ("[0,1,4,6]", ConjuntoDeClases([0, 1, 4, 6]))] {
    print("  \(nombre): forma prima \(conjunto.formaPrima), \(conjunto.numeroDeForte ?? "—"),",
          "vector \(conjunto.vectorIntervalico)\(conjunto.nombreComun.map { ", " + $0 } ?? "")")
}

titulo("Protocolos comunes")
func subirQuinta<T: Transponible>(_ valor: T) -> T { valor + .quintaJusta }
print("  Una quinta más arriba:", subirQuinta(Nota.do), "·", subirQuinta(Acorde("Do7/Mi")), "·",
      subirQuinta(Escala(.re, .dorico)), "·", subirQuinta(Melodia(["Do4", "Mi4", "Sol4"])))
print("  Secuencia de quintas:", Nota.do.secuencia(.quintaJusta, veces: 11).map(\.nombre).joined(separator: " "))
let nombrables: [any Nombrable] = [Intervalo.cuartaAumentada, TipoDeAcorde.semidisminuido, Escala("Mi frigio dominante"),
                                   NombreDeGrado.sensible, Clave.doEnTercera, Instrumento.saxofonAlto]
for valor in nombrables {
    print("  \(valor.nombre(en: .espanol)) — \(valor.nombre(en: .ingles))")
}
let textos: [any RepresentableComoTexto] = [Nota("Fa#"), Intervalo.septimaMenor, Acorde("Sib7(b9)/Re")]
print("  En notación internacional:", textos.map { $0.texto(.ingles) }.joined(separator: " · "))
print("  Misma clase de conjuntos:", Acorde("Sol7").esDeLaMismaClase(que: Acorde("Sim7b5")))

titulo("Tonalidad")
let laMenor: Tonalidad = "La menor"
print("  \(laMenor): armadura \(laMenor.armadura), relativa \(laMenor.relativa), homónima \(laMenor.homonima)")
print("  Armonía:", laMenor.armonizar(cuatriadas: true).map(\.cifrado).joined(separator: " "))
print("  Cifrado romano:", laMenor.cifradosRomanos(cuatriadas: true).joined(separator: " "))
print("  Sol y Sol♯:", laMenor.nombreDeGrado(de: .sol)!, "/", laMenor.nombreDeGrado(de: "Sol#")!)
print("  Tonos vecinos:", laMenor.vecinas.map(\.nombre).joined(separator: ", "))
print("  En inglés:", laMenor.nombre(en: .ingles), "·", Tonalidad.circuloDeQuintas().map { $0.tonica.nombre(en: .ingles) }.joined(separator: " "))

titulo("Análisis de progresiones")
for progresion in ["Do Lam Re7 Sol7 Do", "Sim7(b5) Mi7 Lam", "Do Fa/La Sol7/Si Do", "Do Lab Sib Do", "Do Reb/Fa Sol7 Do"] {
    let analisis = try! AnalisisArmonico.analizar(leyendo: progresion)
    let funciones = analisis.funciones.map { $0?.abreviatura ?? "–" }.joined(separator: " ")
    print("  \(progresion): \(analisis)  (\(funciones))")
}

titulo("Conducción de voces")
for coral in ["Do3 Mi4 Sol4 Do5 | Fa3 Fa4 La4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5",
              "Do3 Sol3 Mi4 Do5 | Re3 La3 Fa4 Re5 | Fa3 Do4 La4 Fa5"] {
    let conduccion = try! ConduccionDeVoces(leyendo: coral)
    print("  \(coral)")
    if conduccion.esCorrecta { print("    correcta") }
    for problema in conduccion.problemas { print("    \(problema)") }
}
