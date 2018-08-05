// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "PlaidProvider",
    products: [
        .library(
            name: "Plaid",
            targets: ["Plaid"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "Plaid",
            dependencies: ["Vapor"]),
        .testTarget(
            name: "PlaidTests",
            dependencies: ["Plaid", "Vapor"]),
    ]
)
