// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AeroSpaceMenuBar",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "AeroSpaceMenuBar", targets: ["AeroSpaceMenuBar"])],
    targets: [
        .executableTarget(name: "AeroSpaceMenuBar"),
        .testTarget(name: "AeroSpaceMenuBarTests", dependencies: ["AeroSpaceMenuBar"]),
    ]
)
