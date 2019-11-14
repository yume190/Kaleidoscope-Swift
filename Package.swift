// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kaleidoscope-Swift",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        // .package(url: "https://github.com/llvm-swift/LLVMSwift.git", from: "0.6.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "llvmPrac",
            dependencies: ["Lexer", "AST", "Parser"]),
        .target(
            name: "Lexer"),
        .target(
            name: "AST"),
        .target(
            name: "Parser",
            dependencies: ["AST"]),
        .testTarget(
            name: "llvmPracTests",
            dependencies: ["llvmPrac", "Lexer", "AST", "Parser"]),
    ]
)
