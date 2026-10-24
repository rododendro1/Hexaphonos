// swift-tools-version:5.9
import PackageDescription

// Cuánto tarda el motor en lo que hacen las apps y la línea de comandos. Se mide compilado con optimización:
//
//     swift run -c release ArmoniaRendimiento
//     swift run -c release ArmoniaRendimiento --json antes.json          # guardar los tiempos
//     swift run -c release ArmoniaRendimiento --comparar antes.json      # y compararlos después de un cambio
let package = Package(
    name: "ArmoniaRendimiento",
    // Como `Armonia`: SwiftPM rechaza que un paquete con un mínimo más bajo dependa de otro con uno más alto.
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ArmoniaRendimiento", targets: ["ArmoniaRendimiento"]),
    ],
    dependencies: [
        .package(path: "../../Packages/Armonia"),
    ],
    targets: [
        .executableTarget(
            name: "ArmoniaRendimiento",
            dependencies: [.product(name: "Armonia", package: "Armonia")]),
    ]
)
