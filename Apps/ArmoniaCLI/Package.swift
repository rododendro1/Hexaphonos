// swift-tools-version:5.9
import PackageDescription

// La herramienta de línea de comandos `armonia`: la lógica en una biblioteca, para poder probarla,
// y el ejecutable, que solo la llama.
//
//     swift run armonia acorde Sol7/Si
//     swift run armonia ayuda
let package = Package(
    name: "ArmoniaCLI",
    // Como `Armonia`: SwiftPM rechaza que un paquete con un mínimo más bajo dependa de otro con uno más alto.
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "armonia", targets: ["ArmoniaEjecutable"]),
        .library(name: "ArmoniaCLI", targets: ["ArmoniaCLI"]),
    ],
    dependencies: [
        .package(path: "../../Packages/Armonia"),
        // Solo `ArmoniaPresentacion`, sin SwiftUI: el análisis y el coral que también enseñan las apps.
        .package(path: "../../Packages/ArmoniaUI"),
    ],
    targets: [
        .target(
            name: "ArmoniaCLI",
            dependencies: [
                .product(name: "Armonia", package: "Armonia"),
                .product(name: "ArmoniaPresentacion", package: "ArmoniaUI"),
            ]),
        // El directorio del ejecutable no se llama `armonia`: en sistemas de ficheros que no
        // distinguen mayúsculas (macOS, Windows) chocaría con otros nombres. El producto
        // sigue llamándose `armonia`.
        .executableTarget(name: "ArmoniaEjecutable", dependencies: ["ArmoniaCLI"]),
        .testTarget(
            name: "ArmoniaCLITests",
            dependencies: [
                "ArmoniaCLI",
                .product(name: "Armonia", package: "Armonia"),
            ]),
    ]
)
