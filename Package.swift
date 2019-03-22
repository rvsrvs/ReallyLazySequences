// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReallyLazySequences",
    products: [
        .library(name: "ReallyLazySequences", targets: ["ReallyLazySequences"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "ReallyLazySequences", dependencies: []),
        .testTarget(name: "ReallyLazySequencesTests", dependencies: ["ReallyLazySequences"]),
    ]
)
