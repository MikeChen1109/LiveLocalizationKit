// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LiveLocalizationKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "LiveLocalizationCore",
            targets: ["LiveLocalizationCore"]
        ),
        .library(
            name: "LiveLocalizationUI",
            targets: ["LiveLocalizationUI"]
        ),
        .library(
            name: "LiveLocalizationTranslationSupport",
            targets: ["LiveLocalizationTranslationSupport"]
        )
    ],
    targets: [
        .target(
            name: "LiveLocalizationCore"
        ),
        .target(
            name: "LiveLocalizationUI",
            dependencies: ["LiveLocalizationCore"]
        ),
        .target(
            name: "LiveLocalizationTranslationSupport",
            dependencies: ["LiveLocalizationCore"]
        ),
        .testTarget(
            name: "LiveLocalizationCoreTests",
            dependencies: [
                "LiveLocalizationCore",
                "LiveLocalizationUI",
                "LiveLocalizationTranslationSupport"
            ]
        )
    ]
)
