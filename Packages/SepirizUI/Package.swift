// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SepirizUI",
    // SwiftUI y Canvas piden estas versiones. En Linux solo compila la lógica que no usa
    // SwiftUI (`Notacion`, `PresentacionDeMastil`): la interfaz está tras `#if canImport(SwiftUI)`, para que el
    // CI de Linux pueda construir y probar lo que se pueda.
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "SepirizUI", targets: ["SepirizUI"]),
    ],
    dependencies: [
        .package(path: "../Armonia"),
    ],
    targets: [
        .target(
            name: "SepirizUI",
            dependencies: [
                .product(name: "Armonia", package: "Armonia"),
            ]),
        .testTarget(
            name: "SepirizUITests",
            dependencies: [
                "SepirizUI",
                .product(name: "Armonia", package: "Armonia"),
            ]),
    ]
)
