// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "OpenLogin",
    products: [
        .library(
            name: "OpenLogin",
            targets: ["OpenLogin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.8.0")
    ],
    targets: [
        .target(
            name: "OpenLogin",
            dependencies: ["PromiseKit"])
    ]
)
