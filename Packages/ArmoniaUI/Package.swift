// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ArmoniaUI",
    // SwiftUI y Canvas piden estas versiones. En Linux solo compila la lógica que no usa
    // SwiftUI (la notación, las presentaciones y los ficheros para exportar): la interfaz está tras
    // `#if canImport(SwiftUI)`, para que el CI de Linux pueda construir y probar lo que se pueda.
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "ArmoniaUI", targets: ["ArmoniaUI"]),
        // Sin SwiftUI: las presentaciones del análisis y del coral, que comparten las apps y la línea de comandos.
        .library(name: "ArmoniaPresentacion", targets: ["ArmoniaPresentacion"]),
    ],
    dependencies: [
        .package(path: "../Armonia"),
        .package(path: "../Hexagonos"),
    ],
    targets: [
        .target(
            name: "ArmoniaPresentacion",
            dependencies: [
                .product(name: "Armonia", package: "Armonia"),
            ]),
        .target(
            name: "ArmoniaUI",
            dependencies: [
                "ArmoniaPresentacion",
                .product(name: "Armonia", package: "Armonia"),
                .product(name: "Hexagonos", package: "Hexagonos"),
            ]),
        .testTarget(
            name: "ArmoniaUITests",
            dependencies: [
                "ArmoniaUI",
                "ArmoniaPresentacion",
                .product(name: "Armonia", package: "Armonia"),
                .product(name: "Hexagonos", package: "Hexagonos"),
            ]),
    ]
)
