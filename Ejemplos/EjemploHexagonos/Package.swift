// swift-tools-version:5.9
import PackageDescription

// Un recorrido por la API de las rejillas hexagonales, para leerlo y ejecutarlo:
//
//     swift run EjemploHexagonos
let package = Package(
    name: "EjemploHexagonos",
    // Como `Hexagonos`: SwiftPM rechaza que un paquete con un mínimo más bajo dependa de otro con uno más alto.
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "EjemploHexagonos", targets: ["EjemploHexagonos"]),
    ],
    dependencies: [
        .package(path: "../../Packages/Hexagonos"),
    ],
    targets: [
        .executableTarget(
            name: "EjemploHexagonos",
            dependencies: [.product(name: "Hexagonos", package: "Hexagonos")]),
    ]
)
