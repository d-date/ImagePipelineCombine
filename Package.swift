// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ImagePipelineCombine",
  platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "ImagePipelineCombine",
      targets: ["ImagePipelineCombine"])
  ],
  dependencies: [
    .package(url: "https://github.com/kishikawakatsumi/webpdecoder.git", from: "1.1.0"),
    .package(name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.8.2"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "ImagePipelineCombine",
      dependencies: ["webpdecoder"]),
    .testTarget(
      name: "ImagePipelineCombineTests",
      dependencies: ["ImagePipelineCombine", "SnapshotTesting"],
      resources: [
        .process("Fixtures"),
        .process("__Snapshots__")
      ])
  ]
)
