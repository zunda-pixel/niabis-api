// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "niabis-api",
  platforms: [
    .macOS(.v14)
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.3.1"),
    .package(url: "https://github.com/swift-server/swift-openapi-async-http-client", from: "1.0.0"),
    .package(url: "https://github.com/swift-server/swift-openapi-vapor", from: "1.0.1"),
    .package(url: "https://github.com/vapor/fluent-postgres-driver", from: "2.8.0"),
    .package(url: "https://github.com/vapor/fluent", from: "4.9.0"),
    .package(url: "https://github.com/apple/swift-metrics", from: "2.4.1"),
    .package(url: "https://github.com/swift-server/swift-prometheus", from: "2.0.0"),
    .package(url: "https://github.com/vapor/jwt", from: "5.0.0"),
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.20.2"),
    .package(url: "https://github.com/zunda-pixel/tripadvisor-swift", from: "0.5.0"),
    .package(url: "https://github.com/zunda-pixel/cloudflare-swift", from: "0.6.0"),
  ],
  targets: [
    .executableTarget(
      name: "App",
      dependencies: [
        .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
        .product(name: "OpenAPIVapor", package: "swift-openapi-vapor"),
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "Fluent", package: "fluent"),
        .product(name: "Metrics", package: "swift-metrics"),
        .product(name: "Prometheus", package: "swift-prometheus"),
        .product(name: "TripadvisorKit", package: "tripadvisor-swift"),
        .product(name: "JWT", package: "jwt"),
        .product(name: "Auth", package: "supabase-swift"),
        .product(name: "Supabase", package: "supabase-swift"),
        .product(name: "ImagesClient", package: "cloudflare-swift"),
      ],
      plugins: [
        .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
      ]
    ),
    .testTarget(
      name: "AppTests",
      dependencies: [
        .target(name: "App")
      ],
      resources: [
        .process("Resources")
      ]
    ),
  ]
)
