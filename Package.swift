// swift-tools-version: 5.10
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
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
    ],
    targets: [
        .target(
            name: "VaporRateLimiter",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
            ]
        ),
        .testTarget(
            name: "VaporRateLimiterTests",
            dependencies: [
                .target(name: "VaporRateLimiter"),
                .product(name: "VaporTesting", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
            ]
        )
    ]
)
