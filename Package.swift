// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Chatterkill",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Chatterkill", targets: ["Chatterkill"])
    ],
    targets: [
        .executableTarget(
            name: "Chatterkill",
            path: "Sources/Chatterkill"
        )
    ]
)
