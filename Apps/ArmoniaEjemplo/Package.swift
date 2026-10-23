// swift-tools-version:5.9
import PackageDescription

// Un recorrido por la API del motor, para leerlo y ejecutarlo:
//
//     swift run ArmoniaEjemplo
let package = Package(
    name: "ArmoniaEjemplo",
    // Como `Armonia`: SwiftPM rechaza que un paquete con un mínimo más bajo dependa de otro con uno más alto.
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ArmoniaEjemplo", targets: ["ArmoniaEjemplo"]),
    ],
    dependencies: [
        .package(path: "../../Packages/Armonia"),
    ],
    targets: [
        .executableTarget(
            name: "ArmoniaEjemplo",
            dependencies: [.product(name: "Armonia", package: "Armonia")]),
    ]
)
