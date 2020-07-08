// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kaleidoscope",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .executable(name: "kaleidoscope", targets: ["Kaleidoscope"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/yume190/LLVMSwift.git", from: "0.6.0"),
        // .package(url: "https://github.com/llvm-swift/LLVMSwift.git", from: "0.6.0")

        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.2.0")
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Kaleidoscope",
            dependencies: ["Lexer", "AST", "Parser", "IRGen", "ArgumentParser"]),
        .target(
            name: "IRGen",
            dependencies: ["AST", "LLVM", "Parser", "Tool"]),
        .target(
            name: "Token"),
        .target(
            name: "Lexer",
            dependencies: ["Token"]),
        .target(
            name: "AST",
            dependencies: ["Token"]),
        .target(
            name: "Parser",
            dependencies: ["AST", "Lexer", "Token", "Tool"]),
        .target(
            name: "Tool",
            dependencies: []),
        .testTarget(
            name: "KaleidoscopeTests",
            dependencies: ["Kaleidoscope", "Lexer", "AST", "Parser", "IRGen"]),
    ]
)
