// swift-tools-version:6.0
// SebaroDesign: the SwiftUI parts of the sebaro design system for iOS (D88, D91 I1–I10; spec/12-platform-ios.md).
// Swift 6 language mode (strict concurrency; OR-10, 2026-10-25): needs Xcode 16.0 or later (Swift 6.0; the iOS 26
// SDK symbols are behind `#if compiler(>=6.2)`, spec/12 §1); the generated SebaroTokens.swift is Sendable from token
// contract 1.10 on.
//
// In sebaroDesign the generated and shipped inputs are symbolic links into the system (one source per fact,
// AGENTS.md §6): Generated/SebaroTokens.swift -> dist/, Resources/Fonts -> fonts/desktop/, Resources/Icons/* ->
// icons/dist/, Resources/Signs -> brand/inline/. `tools/export_system.py sebaro --target ios` copies the same package
// with real files into an app repository. Never edit the linked files here; rebuild them with their tools.
import Foundation
import PackageDescription

// The tests live only in sebaroDesign; an export ships the package without Tests/ (they need every product's sign).
let hasTests = FileManager.default.fileExists(
    atPath: URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Tests").path)

let package = Package(
    name: "SebaroDesign",
    defaultLocalization: "de",
    // The parts are built for iOS. macOS is listed only so `swift build` on a Mac compiles the package (the UIKit
    // parts are behind `#if canImport(UIKit)`); no macOS screen of sebaro uses this package (spec/12 §1).
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SebaroDesign", targets: ["SebaroDesign"]),
    ],
    targets: [
        .target(
            name: "SebaroDesign",
            path: "Sources/SebaroDesign",
            resources: [
                .copy("Resources/Fonts"),
                // one entry per file: a copied folder would keep the workshop's relative links unresolved
                .copy("Resources/Icons/sprite.svg"),
                .copy("Resources/Icons/icons.json"),
                .copy("Resources/Signs"),
            ]
        ),
    ] + (hasTests ? [
        .testTarget(
            name: "SebaroDesignTests",
            dependencies: ["SebaroDesign"],
            path: "Tests/SebaroDesignTests"
        ),
    ] : [])
)
