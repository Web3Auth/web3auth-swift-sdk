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
        .package(name:"KeychainSwift",url: "https://github.com/evgenyneu/keychain-swift.git",.branch("master")),
        .package(name:"web3.swift", url: "https://github.com/argentlabs/web3.swift", from:"0.9.3"),
        .package(name:"CryptoSwift",url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.5.1"),
        .package(name:"secp256k1.swift",url: "https://github.com/GigaBitcoin/secp256k1.swift.git",from: "0.8.1")
    ],
    targets: [
        .target(
            name: "Web3Auth",
            dependencies: ["KeychainSwift","web3.swift","CryptoSwift"]),
        .testTarget(
            name: "Web3AuthTests",
            dependencies: ["Web3Auth"])
    ],
    swiftLanguageVersions: [.v5]
)
