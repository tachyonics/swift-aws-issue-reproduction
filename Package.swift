// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "swift-aws-issue-reproduction",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/awslabs/aws-sdk-swift.git", from: "1.0.0"),
    ],
    targets: [
        .testTarget(
            name: "ReproTests",
            dependencies: [
                .product(name: "AWSDynamoDB", package: "aws-sdk-swift"),
            ]
        ),
    ]
)
