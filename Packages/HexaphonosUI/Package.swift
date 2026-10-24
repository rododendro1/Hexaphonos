// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HexaphonosUI",
    // SwiftUI y Canvas piden estas versiones. En Linux solo compila la lógica que no usa
    // SwiftUI (la notación, las presentaciones y los ficheros para exportar): la interfaz está tras
    // `#if canImport(SwiftUI)`, para que el CI de Linux pueda construir y probar lo que se pueda.
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "HexaphonosUI", targets: ["HexaphonosUI"]),
    ],
    dependencies: [
        .package(path: "../Armonia"),
        .package(path: "../Hexagonos"),
    ],
    targets: [
        .target(
            name: "HexaphonosUI",
            dependencies: [
                .product(name: "Armonia", package: "Armonia"),
                .product(name: "Hexagonos", package: "Hexagonos"),
            ]),
        .testTarget(
            name: "HexaphonosUITests",
            dependencies: [
                "HexaphonosUI",
                .product(name: "Armonia", package: "Armonia"),
                .product(name: "Hexagonos", package: "Hexagonos"),
            ]),
    ]
)
