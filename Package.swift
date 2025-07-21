// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "VaporRateLimiter",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "VaporRateLimiter", targets: ["VaporRateLimiter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
    ],
    targets: [
        .target(
            name: "VaporRateLimiter",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
            ]
        ),
        .testTarget(
            name: "VaporRateLimiterTests",
            dependencies: ["VaporRateLimiter"]
        ),
    ]
)
