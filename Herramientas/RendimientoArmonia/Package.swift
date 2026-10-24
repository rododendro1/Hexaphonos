// swift-tools-version:5.9
import PackageDescription

// Cuánto tarda el motor en lo que hacen las apps y la línea de comandos. Se mide compilado con optimización:
//
//     swift run -c release RendimientoArmonia
//     swift run -c release RendimientoArmonia --json antes.json          # guardar los tiempos
//     swift run -c release RendimientoArmonia --comparar antes.json      # y compararlos después de un cambio
let package = Package(
    name: "RendimientoArmonia",
    // Como `Armonia`: SwiftPM rechaza que un paquete con un mínimo más bajo dependa de otro con uno más alto.
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "RendimientoArmonia", targets: ["RendimientoArmonia"]),
    ],
    dependencies: [
        .package(path: "../../Packages/Armonia"),
    ],
    targets: [
        .executableTarget(
            name: "RendimientoArmonia",
            dependencies: [.product(name: "Armonia", package: "Armonia")]),
    ]
)
