// swift-tools-version:5.9
import PackageDescription

// Los paquetes de `Packages/`, para usarlos desde otro proyecto por URL:
//
//     .package(url: "https://github.com/rododendro1/Hexaphonos.git", branch: "main")
//
// SwiftPM solo lee el `Package.swift` de la raíz de un repositorio, así que este reúne los tres con los
// mismos módulos y dependencias que cada uno declara en su carpeta. Dentro del repositorio se sigue
// trabajando con aquellos (`cd Packages/Armonia && swift test`): aquí no hay pruebas.
// `Scripts/comprobar_dependencias.py` vigila que los dos lados coincidan.

let package = Package(
    name: "Hexaphonos",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        // Packages/Hexagonos
        .library(name: "Hexagonos", targets: ["Hexagonos"]),
        // Packages/Armonia: el motor entero y una biblioteca por capa.
        .library(name: "Armonia", targets: ["Armonia"]),
        .library(name: "ArmoniaNucleo", targets: ["ArmoniaNucleo"]),
        .library(name: "ArmoniaTeoria", targets: ["ArmoniaTeoria"]),
        .library(name: "ArmoniaRepresentaciones", targets: ["ArmoniaRepresentaciones"]),
        .library(name: "ArmoniaPartitura", targets: ["ArmoniaPartitura"]),
        .library(name: "ArmoniaTrastes", targets: ["ArmoniaTrastes"]),
        // Packages/HexaphonosUI
        .library(name: "HexaphonosUI", targets: ["HexaphonosUI"]),
        .library(name: "HexaphonosPresentacion", targets: ["HexaphonosPresentacion"]),
    ],
    targets: [
        .target(name: "Hexagonos", path: "Packages/Hexagonos/Sources/Hexagonos"),

        .target(name: "ArmoniaNucleo", path: "Packages/Armonia/Sources/ArmoniaNucleo"),
        .target(name: "ArmoniaTeoria", dependencies: ["ArmoniaNucleo"], path: "Packages/Armonia/Sources/ArmoniaTeoria"),
        .target(
            name: "ArmoniaRepresentaciones",
            dependencies: ["ArmoniaNucleo", "ArmoniaTeoria", "Hexagonos"],
            path: "Packages/Armonia/Sources/ArmoniaRepresentaciones"),
        .target(
            name: "ArmoniaPartitura",
            dependencies: ["ArmoniaNucleo", "ArmoniaTeoria"],
            path: "Packages/Armonia/Sources/ArmoniaPartitura"),
        .target(
            name: "ArmoniaTrastes",
            dependencies: ["ArmoniaNucleo", "ArmoniaTeoria"],
            path: "Packages/Armonia/Sources/ArmoniaTrastes"),
        .target(
            name: "Armonia",
            dependencies: ["ArmoniaNucleo", "ArmoniaTeoria", "ArmoniaRepresentaciones", "ArmoniaPartitura", "ArmoniaTrastes"],
            path: "Packages/Armonia/Sources/Armonia"),

        .target(
            name: "HexaphonosPresentacion",
            dependencies: ["Armonia"],
            path: "Packages/HexaphonosUI/Sources/HexaphonosPresentacion"),
        .target(
            name: "HexaphonosUI",
            dependencies: ["HexaphonosPresentacion", "Armonia", "Hexagonos"],
            path: "Packages/HexaphonosUI/Sources/HexaphonosUI"),
    ]
)
