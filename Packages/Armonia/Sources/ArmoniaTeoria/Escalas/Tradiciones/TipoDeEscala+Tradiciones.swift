import ArmoniaNucleo
// MARK: - Escalas de la India, dromoi griegos, maqamat, dastgāh, escalas chinas, japonesas, coreanas,
// etíopes, de Indonesia, andinas, klezmer y de la Grecia antigua
//
// Escalas de otras tradiciones, en su aproximación al temperamento igual: los 72 melakarta de
// la música carnática y algunos de sus ragas janya, los 10 thaat de la indostánica y los dromoi del rebético y la música
// popular griega. En la práctica varias usan microtonos (sobre todo los dromoi, que vienen de
// los makam otomanos); aquí se escriben con los intervalos de la escala temperada.
//
// Los nombres indios siguen el AITS (Alfabeto Internacional de Transliteración Sánscrita, IAST);
// los griegos llevan el acento de la palabra griega. La búsqueda no distingue diacríticos, y la
// transliteración habitual sin ellos (Mayamalavagowla, Hijaz…) se acepta como alias.
//
// No forman parte de `TipoDeEscala.todos`, para no cambiar las búsquedas de escalas habituales,
// pero `buscar(nombre:)` y `Escala("Re hitzaz")` las encuentran.
//
// Cada tradición está en su fichero: `TipoDeEscala+India.swift`, `+Grecia`, `+China`, `+Japon`,
// `+Corea`, `+Etiopia`, `+MaqamatYDastgah`, `+Indonesia`, `+Klezmer` y `+Andes`.

extension TipoDeEscala {
    /// Escalas de otras tradiciones: thaat, dromoi, melakarta, janya, chinas, japonesas, etíopes,
    /// maqamat, de Indonesia, klezmer, ragas indostánicos, dastgāh, coreanas, andinas y de la
    /// Grecia antigua.
    public static let tradicionales: [TipoDeEscala] = thaats + dromoi + melakartas + janyas + chinas + japonesas
        + etiopes + maqamat + indonesias + klezmer + ragasIndostanicos + dastgah + coreanas + andinas
        + griegasAntiguas
}
