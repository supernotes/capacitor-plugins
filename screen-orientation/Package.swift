// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorScreenOrientation",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "CapacitorScreenOrientation",
            targets: ["ScreenOrientationPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "ScreenOrientationPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/ScreenOrientationPlugin"),
        .testTarget(
            name: "ScreenOrientationPluginTests",
            dependencies: ["ScreenOrientationPlugin"],
            path: "ios/Tests/ScreenOrientationPluginTests")
    ]
)
