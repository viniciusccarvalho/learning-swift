// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CliApp",
    dependencies: [
        //.package(url: "https://github.com/ShawnMoore/XMLParsing.git", from: "0.0.3"),
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "5.0.0"),
        .package(url: "https://github.com/Moya/Moya.git", from: "11.0.0"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", .branch("master")),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0")
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CliApp",
            dependencies: ["SwiftCLI","Moya","SwiftyTextTable", "Rainbow"]),
        .testTarget(
            name: "CliAppTests",
            dependencies: ["CliApp"]),
    ]
)
