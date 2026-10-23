import ArmoniaNucleo
extension TipoDeEscala {
    // MARK: Escalas chinas
    //
    // Los nombres van en pinyin con sus tonos (gōng, shāng, jué, zhǐ, yǔ) y se aceptan sin ellos y
    // en caracteres chinos. Las cinco notas de la pentatónica (宫 商 角 徵 羽, do re mi sol la)
    // dan los cinco modos; las tres escalas heptatónicas son las del modo gōng con dos notas
    // añadidas.

    /// 宫: la pentatónica mayor (Do Re Mi Sol La).
    public static let gong = TipoDeEscala(
        nombre: "Gōng", intervalos: [.unisono, .segundaMayor, .terceraMayor, .quintaJusta, .sextaMayor],
        alias: ["Gong", "宫", "宮"])
    /// 商: desde el 2.º grado (Re Mi Sol La Do).
    public static let shang = TipoDeEscala(
        nombre: "Shāng", intervalos: [.unisono, .segundaMayor, .cuartaJusta, .quintaJusta, .septimaMenor],
        alias: ["Shang", "商"])
    /// 角: desde el 3.º grado (Mi Sol La Do Re).
    public static let jue = TipoDeEscala(
        nombre: "Jué", intervalos: [.unisono, .terceraMenor, .cuartaJusta, .sextaMenor, .septimaMenor],
        alias: ["Jue", "Jiao", "角"])
    /// 徵: desde el 5.º grado (Sol La Do Re Mi).
    public static let zhi = TipoDeEscala(
        nombre: "Zhǐ", intervalos: [.unisono, .segundaMayor, .cuartaJusta, .quintaJusta, .sextaMayor],
        alias: ["Zhi", "徵", "徴"])
    /// 羽: la pentatónica menor (La Do Re Mi Sol).
    public static let yu = TipoDeEscala(
        nombre: "Yǔ", intervalos: [.unisono, .terceraMenor, .cuartaJusta, .quintaJusta, .septimaMenor],
        alias: ["Yu", "羽"])
    /// 清乐, la escala «pura»: gōng con 4.º y 7.º grados (la escala mayor).
    public static let qingyue = TipoDeEscala(
        nombre: "Qīngyuè",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta, .quintaJusta, .sextaMayor, .septimaMayor],
        alias: ["Qingyue", "清乐", "清樂"])
    /// 雅乐, la escala «elegante» de la música cortesana: gōng con 4.º aumentado y 7.º (el lidio).
    public static let yayue = TipoDeEscala(
        nombre: "Yǎyuè",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaAumentada, .quintaJusta, .sextaMayor, .septimaMayor],
        alias: ["Yayue", "雅乐", "雅樂"])
    /// 燕乐, la escala de los banquetes: gōng con 4.º y 7.º menor (el mixolidio).
    public static let yanyue = TipoDeEscala(
        nombre: "Yànyuè",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta, .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["Yanyue", "燕乐", "燕樂"])

    /// Los cinco modos pentatónicos y las tres escalas heptatónicas chinas.
    public static let chinas: [TipoDeEscala] = [.gong, .shang, .jue, .zhi, .yu, .qingyue, .yayue, .yanyue]
}
