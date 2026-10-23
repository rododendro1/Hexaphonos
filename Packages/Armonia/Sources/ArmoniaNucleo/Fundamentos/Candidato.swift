// MARK: - Candidato

/// Una lectura posible de unos datos, con su coste: un acorde para unas notas, una tonalidad
/// para una melodía… Cuanto menor es el coste, más probable es la lectura, y las listas de
/// candidatos se devuelven ordenadas de menor a mayor coste.
///
///     let c = Acorde.candidatos([.do, .mi, "Sib"]).first!
///     c.valor.cifrado   // "Do7"
///     c.coste           // 1.0 (falta la quinta)
///     c.omitidas        // [Sol]
public struct Candidato<Valor: Hashable & Sendable>: Hashable, Sendable {
    public let valor: Valor
    /// Cuanto menor, más probable (0 = la lectura más habitual posible).
    public let coste: Double
    /// Notas que la lectura supone aunque falten. Solo tiene sentido en acordes (ver `omitidas`).
    package let notasOmitidas: [Nota]

    package init(_ valor: Valor, coste: Double, notasOmitidas: [Nota] = []) {
        self.valor = valor
        self.coste = coste
        self.notasOmitidas = notasOmitidas
    }
}
