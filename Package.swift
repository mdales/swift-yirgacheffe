// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Yirgacheffe",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Yirgacheffe",
            targets: ["Yirgacheffe"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: "https://github.com/mdales/LibTIFF", branch: "mwd-lazy"),
        .package(path: "../LibTIFF"),
        .package(path: "../swift-graphics"),
        .package(path: "../swift.geopackage")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Yirgacheffe",
            dependencies: [
                "LibTIFF",
                .product(name: "PlatformGraphics", package: "swift-graphics"),
                .product(name: "GeoPackage", package: "swift.geopackage"),
                .product(name: "CairoGraphics", package: "swift-graphics"),
            ]
        ),
        .testTarget(
            name: "YirgacheffeTests",
            dependencies: ["Yirgacheffe"],
            resources: [
                .copy("Resources/small_made_with_gdal.tif")
            ]
        ),
    ]
)
