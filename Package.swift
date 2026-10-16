// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VisualDTB",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "VisualDTB",
            targets: ["VisualDTB"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VisualDTB",
            path: "VisualDTB",
            exclude: [
                "Resources/Info.plist"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
