// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Web3Auth",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Web3Auth",
            targets: ["Web3Auth"]),
    ],
    dependencies: [
        .package(name:"KeychainSwift",url: "https://github.com/evgenyneu/keychain-swift.git",.branch("master"))
    ],
    targets: [
        .target(
            name: "Web3Auth",
            dependencies: ["KeychainSwift"]),
        .testTarget(
            name: "Web3AuthTests",
            dependencies: ["Web3Auth"])
    ]
)
