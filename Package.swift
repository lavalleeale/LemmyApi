// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LemmyApi",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "LemmyApi",
            targets: ["LemmyApi"]),
    ],
    dependencies: [
        .package(url: "https://github.com/cx-org/CXShim", .upToNextMinor(from: "0.4.0")),
        .package(url: "https://github.com/lavalleeale/CombineX", branch: "master"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LemmyApi",
            dependencies: [
                .product(name: "CXShim", package: "CXShim"),
                .product(name: "CombineX", package: "CombineX"),
            ],
            swiftSettings: [.enableUpcomingFeature("BareSlashRegexLiterals")]),
    ]
)
