// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Grade2MathPractice",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Grade2MathPractice", targets: ["Grade2MathPractice"])],
    targets: [
        .target(name: "PracticeCore"),
        .executableTarget(name: "Grade2MathPractice", dependencies: ["PracticeCore"], resources: [.process("Resources")]),
        .testTarget(name: "PracticeCoreTests", dependencies: ["PracticeCore"])
    ]
)
