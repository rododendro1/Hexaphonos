import ArmoniaNucleo
extension TipoDeEscala {
    // MARK: Dromoi (música popular griega)

    public static let ousak = TipoDeEscala(
        nombre: "Ousák", intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaJusta,
                                       .quintaJusta, .sextaMenor, .septimaMenor], alias: ["Usak", "Oussak"])
    public static let hitzaz = TipoDeEscala(
        nombre: "Hitzáz", intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaJusta,
                                        .quintaJusta, .sextaMenor, .septimaMenor], alias: ["Hijaz", "Hicaz"])
    public static let hitzazkiar = TipoDeEscala(
        nombre: "Hitzazkiár", intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaJusta,
                                            .quintaJusta, .sextaMenor, .septimaMayor], alias: ["Hijazkiar", "Hicazkar"])
    public static let pireotikos = TipoDeEscala(
        nombre: "Pireótikos", intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaAumentada,
                                            .quintaJusta, .sextaMenor, .septimaMayor], alias: ["Piraiotikos", "Pireaiotikos"])
    public static let tabahaniotikos = TipoDeEscala(
        nombre: "Tabahaniótikos", intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta,
                                                .quintaJusta, .sextaMenor, .septimaMayor])
    public static let niavent = TipoDeEscala(
        nombre: "Niavént", intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaAumentada,
                                         .quintaJusta, .sextaMenor, .septimaMayor], alias: ["Nihavent"])
    public static let nikriz = TipoDeEscala(
        nombre: "Nikríz", intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaAumentada,
                                        .quintaJusta, .sextaMayor, .septimaMenor], alias: ["Souzinak", "Susinak", "Poimeniko"])
    public static let kartzigar = TipoDeEscala(
        nombre: "Kartzigár", intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                                           .quintaDisminuida, .sextaMayor, .septimaMenor], alias: ["Kartsigar", "Karcigar"])
    public static let sabah = TipoDeEscala(
        nombre: "Sabáh", intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaDisminuida,
                                       .quintaJusta, .sextaMenor, .septimaMenor], alias: ["Sabach", "Sampah"])
    public static let houzam = TipoDeEscala(
        nombre: "Houzám", intervalos: [.unisono, .segundaAumentada, .terceraMayor, .cuartaJusta,
                                        .quintaJusta, .sextaMayor, .septimaMayor], alias: ["Huzam"])
    public static let sengah = TipoDeEscala(
        nombre: "Sengáh", intervalos: [.unisono, .segundaAumentada, .terceraMayor, .cuartaJusta,
                                        .quintaJusta, .sextaMenor, .septimaMayor], alias: ["Segah", "Sengiach"])
    public static let tsinganikos = TipoDeEscala(
        nombre: "Tsingánikos", intervalos: [.unisono, .segundaMenor, .terceraMayor, .cuartaJusta,
                                             .quintaDisminuida, .sextaMayor, .septimaMenor])

    // Dromoi que suben y bajan distinto.

    /// Sube como la mayor y baja con la 7ª menor (en la práctica, la 3ª y la 7ª son microtonales).
    public static let rast = TipoDeEscala(
        nombre: "Rast",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta, .quintaJusta, .sextaMayor, .septimaMayor],
        descenso: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta, .quintaJusta, .sextaMayor, .septimaMenor])
    /// Sube como Kartzigár y baja como la menor natural.
    public static let kiourdi = TipoDeEscala(
        nombre: "Kiourdí",
        intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta, .quintaDisminuida, .sextaMayor, .septimaMenor],
        descenso: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta, .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["Kiourdi", "Kurdi", "Kioúrdi"])
    /// Sube como el mixolidio y baja como la menor natural.
    public static let houseini = TipoDeEscala(
        nombre: "Houseïní",
        intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta, .quintaJusta, .sextaMayor, .septimaMenor],
        descenso: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta, .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["Houseini", "Huseyni", "Houséïni"])

    /// Los dromoi más habituales, en su versión temperada.
    public static let dromoi: [TipoDeEscala] = [
        .ousak, .hitzaz, .hitzazkiar, .pireotikos, .tabahaniotikos, .niavent, .nikriz,
        .kartzigar, .sabah, .houzam, .sengah, .tsinganikos, .rast, .kiourdi, .houseini,
    ]

    // MARK: Grecia antigua
    //
    // Los tetracordos de Aristóxeno, de grave a agudo (semitono, tono, tono en el diatónico;
    // semitono, semitono y tercera menor en el cromático), y las harmoniai de dos tetracordos
    // disjuntos. El género enarmónico, con cuartos de tono, no está.

    /// Mi Fa Sol La.
    public static let tetracordoDiatonico = TipoDeEscala(
        nombre: "tetracordo diatónico", intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaJusta],
        alias: ["tetracordo dorio"])
    /// Mi Fa Sol♭ La: la lichanós baja medio tono.
    public static let tetracordoCromatico = TipoDeEscala(
        nombre: "tetracordo cromático", intervalos: [.unisono, .segundaMenor, .terceraDisminuida, .cuartaJusta])
    /// De Mi a Mi: dos tetracordos diatónicos (el frigio moderno).
    public static let harmoniaDoria = TipoDeEscala(
        nombre: "harmonía doria", intervalos: [.unisono, .segundaMenor, .terceraMenor, .cuartaJusta,
                                                .quintaJusta, .sextaMenor, .septimaMenor],
        alias: ["harmonia doria", "doria antigua"])
    /// De Mi a Mi en el género cromático (Mi Fa Sol♭ La Si Do Re♭).
    public static let harmoniaDoriaCromatica = TipoDeEscala(
        nombre: "harmonía doria cromática", intervalos: [.unisono, .segundaMenor, .terceraDisminuida, .cuartaJusta,
                                                          .quintaJusta, .sextaMenor, .septimaDisminuida],
        alias: ["harmonia doria cromatica"])
    /// De Re a Re (el dórico moderno).
    public static let harmoniaFrigia = TipoDeEscala(
        nombre: "harmonía frigia", intervalos: [.unisono, .segundaMayor, .terceraMenor, .cuartaJusta,
                                                 .quintaJusta, .sextaMayor, .septimaMenor],
        alias: ["harmonia frigia", "frigia antigua"])
    /// De Do a Do (la mayor).
    public static let harmoniaLidia = TipoDeEscala(
        nombre: "harmonía lidia", intervalos: [.unisono, .segundaMayor, .terceraMayor, .cuartaJusta,
                                                .quintaJusta, .sextaMayor, .septimaMayor],
        alias: ["harmonia lidia", "lidia antigua"])

    public static let griegasAntiguas: [TipoDeEscala] = [
        .tetracordoDiatonico, .tetracordoCromatico, .harmoniaDoria, .harmoniaDoriaCromatica, .harmoniaFrigia, .harmoniaLidia,
    ]
}
