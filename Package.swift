// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Greycats.swiftUI",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "GreycatsPreference",
            targets: ["GreycatsPreference"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GreycatsPreference",
            path: "Sources",
            sources: ["Perference"]
        )
    ]
)
