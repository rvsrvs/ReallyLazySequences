// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReallyLazySequences",
    products: [
        .library(name: "ReallyLazySequences", targets: ["ReallyLazySequences"]),
    ],
    dependencies: [
	.package(url: "https://github.com/ComputeCycles/PromiseKit.git", .branch("Swift-Only")),
    ],
    targets: [
        .target(name: "ReallyLazySequences", dependencies: ["PromiseKit"]),
        .testTarget(name: "ReallyLazySequencesTests", dependencies: ["ReallyLazySequences"]),
    ]
)
