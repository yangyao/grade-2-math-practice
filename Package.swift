// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MentalMathGlass",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "MentalMathGlass", targets: ["MentalMathGlass"])],
    targets: [
        .target(name: "PracticeCore"),
        .executableTarget(name: "MentalMathGlass", dependencies: ["PracticeCore"], resources: [.process("Resources")]),
        .testTarget(name: "PracticeCoreTests", dependencies: ["PracticeCore"])
    ]
)
