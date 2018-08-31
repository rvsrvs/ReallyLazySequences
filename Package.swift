// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReallyLazySequences",
    products: [
        .library(name: "ReallyLazySequences", targets: ["ReallyLazySequences"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(name: "ReallyLazySequences", dependencies: []),
        .testTarget(name: "ReallyLazySequencesTests", dependencies: ["ReallyLazySequences"]),
    ]
)
