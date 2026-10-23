// swift-tools-version:5.9
import PackageDescription

// Rejillas hexagonales: coordenadas (axiales, cúbicas, desplazadas y dobladas), vecinos, distancias,
// líneas, regiones, rotaciones y el paso a píxeles. Solo usa la biblioteca estándar: compila y se
// prueba igual en Linux que en macOS, y no depende de ningún otro paquete del repositorio.
let package = Package(
    name: "Hexagonos",
    // Las mismas que `Armonia` y las apps, para que cualquiera de ellas pueda depender de este paquete.
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "Hexagonos", targets: ["Hexagonos"]),
    ],
    targets: [
        .target(name: "Hexagonos"),
        .testTarget(name: "HexagonosTests", dependencies: ["Hexagonos"]),
    ]
)
