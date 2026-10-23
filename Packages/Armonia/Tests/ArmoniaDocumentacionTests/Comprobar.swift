import Foundation
import XCTest

/// Comprueba que el valor de un ejemplo coincide con el texto de su comentario.
///
/// Se compara el texto del valor (`description`) sin espacios; las cadenas, con o sin comillas
/// (dentro de una lista, con comillas);
/// los opcionales, sin `Optional(…)`; las listas, con o sin corchetes y separadas por comas o por
/// espacios. Un número se compara con los decimales que tenga el comentario (`−13,69`), y `…`
/// en el comentario vale por cualquier tramo (`La4 … Sol♯5 La5`).
func comprobar<T>(_ valor: T, _ esperado: String, _ fichero: String, _ linea: Int,
                  file: StaticString = #filePath, line: UInt = #line) {
    let candidatos = descripciones(de: valor)
    if candidatos.contains(where: { coincide($0, con: esperado) }) { return }
    XCTFail("\(fichero):\(linea): el ejemplo da «\(candidatos[0])» y el comentario dice «\(esperado)»",
            file: file, line: line)
}

/// Comprueba un valor contra otro escrito en Swift en el comentario (`// .mayor`).
func comprobarIgual<T: Equatable>(_ valor: T, _ esperado: T, _ fichero: String, _ linea: Int,
                                  file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(valor, esperado, "\(fichero):\(linea)", file: file, line: line)
}

private func descripcion(_ valor: Any) -> String {
    var actual = valor
    while let opcional = actual as? OpcionalCualquiera {
        guard let interior = opcional.interior else { return "nil" }
        actual = interior
    }
    if let texto = actual as? String { return "\"\(texto)\"" }
    if let lista = actual as? [Any] { return "[" + lista.map(descripcion).joined(separator: ", ") + "]" }
    return String(describing: actual)
}

private func descripciones<T>(de valor: T) -> [String] {
    var actual: Any = valor
    while let opcional = actual as? OpcionalCualquiera {
        guard let interior = opcional.interior else { return ["nil"] }
        actual = interior
    }
    if let texto = actual as? String { return ["\"\(texto)\"", texto] }
    var resultado = [descripcion(actual)]
    if let lista = actual as? [Any] {
        let partes = lista.map(descripcion)
        resultado += [partes.joined(separator: " "), partes.joined(separator: ", ")]
    }
    return resultado
}

private func normalizar(_ texto: String) -> String {
    texto.replacingOccurrences(of: "−", with: "-").filter { !$0.isWhitespace }
}

private func coincide(_ obtenido: String, con esperado: String) -> Bool {
    let a = normalizar(obtenido), b = normalizar(esperado)
    if a == b { return true }
    // Números: con los decimales que muestre el comentario, y con coma o punto decimal.
    let numero = esperado.replacingOccurrences(of: "−", with: "-").replacingOccurrences(of: ",", with: ".")
        .split(separator: " ").first.map(String.init) ?? ""
    if let x = Double(obtenido), let y = Double(numero) {
        let decimales = numero.split(separator: ".").dropFirst().first?.count ?? 0
        return abs(x - y) <= 0.5 * pow(10, -Double(decimales)) + 1e-9
    }
    // «…» vale por cualquier tramo.
    guard b.contains("…") else { return false }
    let trozos = b.components(separatedBy: "…")
    guard a.hasPrefix(trozos.first!), a.hasSuffix(trozos.last!) else { return false }
    var resto = a.dropFirst(trozos.first!.count)
    for trozo in trozos.dropFirst().dropLast() {
        guard let rango = resto.range(of: trozo) else { return false }
        resto = resto[rango.upperBound...]
    }
    return resto.count >= trozos.last!.count
}

private protocol OpcionalCualquiera { var interior: Any? { get } }
extension Optional: OpcionalCualquiera {
    fileprivate var interior: Any? { self.map { $0 as Any } }
}
