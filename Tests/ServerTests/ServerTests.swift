import FluentPostgresDriver
import Vapor
import XCTest

@testable import Server

final class ServerTests: XCTestCase {
  let app: Application = {
    let app = Application()

    var configuration: SQLPostgresConfiguration = .init(
      hostname: Environment.get("DATABASE_HOST")!,
      username: Environment.get("DATABASE_USERNAME")!,
      password: Environment.get("DATABASE_PASSWORD")!,
      database: Environment.get("DATABASE_NAME")!,
      tls: .require(try! .init(configuration: .makePreSharedKeyConfiguration()))
    )
    
    configuration.searchPath = ["public", "auth"]

    app.databases.use(
      .postgres(configuration: configuration),
      as: .psql
    )
    return app
  }()

  deinit {
    app.shutdown()
  }

  var handler: some APIProtocol {
    return APIHandler(app: app)
  }

  func testGetUserById() async throws {
    let userID = UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!
    let response = try await handler.getUserById(query: .init(userID: userID.uuidString))
    let json = try response.ok.body.json
    XCTAssertEqual(json, .init(id: userID.uuidString, email: "niabis.official+ios@gmail.com"))
  }
}
