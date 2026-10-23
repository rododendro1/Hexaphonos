// Pequeñas ayudas de texto que comparten las órdenes de la herramienta.

extension String {
    func replacingComa() -> String { String(map { $0 == "," ? "." : $0 }) }

    func trimmingCharacters(in caracteres: String) -> String {
        var resultado = Substring(self)
        while let ultimo = resultado.last, caracteres.contains(ultimo) { resultado = resultado.dropLast() }
        return String(resultado)
    }

    /// Rellena con espacios hasta `ancho` caracteres (o deja un espacio si ya los tiene).
    func padding(hasta ancho: Int) -> String {
        count >= ancho ? self + " " : self + String(repeating: " ", count: ancho - count)
    }
}
