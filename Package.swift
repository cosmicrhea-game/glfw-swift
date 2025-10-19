// swift-tools-version: 5.8

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "glfw-swift",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: "GLFW", targets: ["GLFW"])
  ],
  dependencies: [
    // .package(url: "https://github.com/thepotatoking55/CGLFW3.git", branch: "main")
    .package(url: "https://github.com/cosmicrhea-game/glfw", branch: "main")
    //.package(path: "../glfw")
  ],
  targets: [
    .target(
      name: "GLFW",
      dependencies: [
        .product(name: "CGLFW3", package: "glfw")
      ],
      cSettings: [
        .define("_GLFW_COCOA", .when(platforms: [.macOS])),
        .define("GLFW_EXPOSE_NATIVE_COCOA", .when(platforms: [.macOS])),
        .define("GLFW_EXPOSE_NATIVE_NSGL", .when(platforms: [.macOS])),
        .define("_GLFW_WIN32", .when(platforms: [.windows])),
        .define("GLFW_EXPOSE_NATIVE_WIN32", .when(platforms: [.windows])),
        .define("GLFW_EXPOSE_NATIVE_WGL", .when(platforms: [.windows])),
        .define("_GLFW_X11", .when(platforms: [.linux])),
        .define("GLFW_EXPOSE_NATIVE_X11", .when(platforms: [.linux])),
        .define("_DEFAULT_SOURCE", .when(platforms: [.linux])),
      ],
      swiftSettings: [
//        .enableUpcomingFeature("StrictConcurrency"),
        //.swiftLanguageMode(.v5),
        // TODO: Remove when glfw-swift has been annotated for Swift 6 concurrency
//        .enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
//        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
//        .enableUpcomingFeature("InferIsolatedConformances"),
        .unsafeFlags(["-Xfrontend", "-disable-actor-data-race-checks"])
        // TODO: Uncomment when https://github.com/glfw/glfw/pull/1778 is merged into master
        //.define("GLFW_METAL_LAYER_SUPPORT", .when(platforms: [.macOS]))
      ]
    ),
    .testTarget(name: "GLFWTests", dependencies: ["GLFW"]),
  ]
)
