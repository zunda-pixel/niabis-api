import Fluent
import FluentPostgresDriver
import JWT
import JWTKit
import Metrics
import OpenAPIVapor
import Prometheus
import Vapor

@main
struct App {
  static func main() async throws {
    var env = try Environment.detect()
    try LoggingSystem.bootstrap(from: &env)

    let app = Application(env)
    defer { app.shutdown() }

    app.get("openapi") { request in request.redirect(to: "openapi.html", redirectType: .permanent) }

    let registry = PrometheusCollectorRegistry()
    MetricsSystem.bootstrap(PrometheusMetricsFactory(registry: registry))

    let privateKey = try EdDSA.PrivateKey(
      x: Environment.get("EdDSA_PUBLIC_KEY")!,
      d: Environment.get("EdDSA_PRIVATE_KEY")!,
      curve: .ed25519
    )
    await app.jwt.keys.addEdDSA(key: privateKey)

    app.get("metrics") { request in
      var buffer: [UInt8] = []
      buffer.reserveCapacity(1024)
      registry.emit(into: &buffer)
      return String(decoding: buffer, as: UTF8.self)
    }

    var configuration: SQLPostgresConfiguration = .init(
      hostname: Environment.get("DATABASE_HOST")!,
      username: Environment.get("DATABASE_USERNAME")!,
      password: Environment.get("DATABASE_PASSWORD")!,
      database: Environment.get("DATABASE_NAME")!,
      tls: app.environment == .production
        ? .require(try! .init(configuration: .makePreSharedKeyConfiguration())) : .disable
    )

    configuration.searchPath = ["public", "auth"]

    app.databases.use(
      .postgres(configuration: configuration),
      as: .psql
    )

    let fileMiddleware = FileMiddleware(
      publicDirectory: app.directory.publicDirectory
    )
    app.middleware.use(fileMiddleware, at: .end)

    app.middleware.use(CORSMiddleware(), at: .beginning)

    let transport = VaporTransport(routesBuilder: app)

    let handler = APIHandler(
      app: app,
      tripadvisorApiKey: Environment.get("TRIPADVISOR_API_KEY")!,
      cloudflareApiToken: Environment.get("CLOUDFLARE_API_TOKEN")!,
      cloudflareAccountId: Environment.get("CLOUDFLARE_ACCOUNT_ID")!
    )

    try handler.registerHandlers(
      on: transport,
      middlewares: [
        LoggingMiddleware(bodyLoggingConfiguration: .upTo(maxBytes: 1024)),
        MetricsMiddleware(counterPrefix: "NiaBisServer"),
        BearerAuthenticatorMiddleware(app: app, excludeOperationIDs: ["generateToken"]),
        BasicAuthenticatorMiddleware(operationIDs: ["generateToken"]),
      ]
    )

    do {
      try await app.execute()
    } catch {
      app.logger.report(error: error)
      throw error
    }
  }
}
