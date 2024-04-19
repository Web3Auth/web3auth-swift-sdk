// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Web3Auth",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "Web3Auth",
            targets: ["Web3Auth"])
    ],
    dependencies: [
        .package(name: "KeychainSwift", url: "https://github.com/evgenyneu/keychain-swift.git", from: "20.0.0"),
        .package(name: "web3.swift", url: "https://github.com/argentlabs/web3.swift", from: "1.6.0"),
        .package(name:"SessionManager",url: "https://github.com/Web3Auth/session-manager-swift.git",from: "4.0.1"),
        .package(name: "curvelib.swift", url: "https://github.com/tkey/curvelib.swift", from: "1.0.1"),
    ],
    targets: [
        .target(
            name: "Web3Auth",
            dependencies: ["KeychainSwift", "web3.swift",  .product(name: "curveSecp256k1", package: "curvelib.swift"), "SessionManager"]),
        .testTarget(
            name: "Web3AuthTests",
            dependencies: ["Web3Auth"])
    ],
    swiftLanguageVersions: [.v5]
)
