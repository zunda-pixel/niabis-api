// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "niabis-api",
  platforms: [
    .macOS(.v13),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .visionOS(.v1)
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
    .package(url: "https://github.com/swift-server/swift-openapi-async-http-client", from: "1.0.0"),
    .package(url: "https://github.com/swift-server/swift-openapi-vapor", from: "1.0.0"),
    .package(url: "https://github.com/vapor/fluent-postgres-driver", from: "2.8.0"),
    .package(url: "https://github.com/vapor/fluent", from: "4.9.0"),
    .package(url: "https://github.com/apple/swift-format", from: "509.0.0"),
    .package(url: "https://github.com/apple/swift-metrics", from: "2.4.1"),
    .package(url: "https://github.com/swift-server/swift-prometheus", exact: "2.0.0-alpha.2"), // TODO
    .package(url: "https://github.com/zunda-pixel/tripadvisor-swift", from: "0.0.1"),
    .package(url: "https://github.com/vapor/jwt", from: "5.0.0-beta.2"), // TODO
  ],
  targets: [
    .executableTarget(
      name: "Server",
      dependencies: [
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
        .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
        .product(name: "OpenAPIVapor", package: "swift-openapi-vapor"),
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "Fluent", package: "fluent"),
        .product(name: "Metrics", package: "swift-metrics"),
        .product(name: "Prometheus", package: "swift-prometheus"),
        .product(name: "TripadvisorKit", package: "tripadvisor-swift"),
        .product(name: "JWT", package: "jwt")
      ],
      plugins: [
        .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
      ]
    ),
    .testTarget(
      name: "ServerTests",
      dependencies: [
        .target(name: "Server")
      ]
    ),
  ]
)
