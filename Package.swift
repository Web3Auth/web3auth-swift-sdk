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
        .package(name:"SessionManager",url: "https://github.com/Web3Auth/session-manager-swift.git",from: "6.0.2"),
        .package(name: "curvelib.swift", url: "https://github.com/tkey/curvelib.swift", from: "2.0.0"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
        .package(url: "https://github.com/torusresearch/torus-utils-swift.git", from: "10.0.1"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
        .package(url: "https://github.com/auth0/JWTDecode.swift.git", from: "3.2.0")
    ],
    targets: [
        .target(
            name: "Web3Auth",
            dependencies: ["KeychainSwift", .product(name: "curveSecp256k1", package: "curvelib.swift"), "SessionManager", "BigInt"]),
        .testTarget(
            name: "Web3AuthTests",
            dependencies: ["Web3Auth"])
    ],
    swiftLanguageVersions: [.v5]
)
