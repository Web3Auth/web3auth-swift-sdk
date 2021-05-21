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
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "OpenLogin",
            dependencies: []),
    ]
)
