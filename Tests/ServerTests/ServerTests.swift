import Vapor
import XCTest
import FluentPostgresDriver

@testable import Server

final class ServerTests: XCTestCase {
  let app: Application = {
    let app = Application()

    let configuration: SQLPostgresConfiguration = .init(
      hostname: Environment.get("DATABASE_HOST")!,
      username: Environment.get("DATABASE_USERNAME")!,
      password: Environment.get("DATABASE_PASSWORD")!,
      database: Environment.get("DATABASE_NAME")!,
      tls: .require(try! .init(configuration: .makePreSharedKeyConfiguration()))
    )

    app.databases.use(
      .postgres(configuration: configuration),
      as: .psql
    )
    return app
  }()

  deinit {
    app.shutdown()
  }

  var handler: any APIProtocol {
    return APIHandler(app: app)
  }

  func testPostUser() async throws {
    let user: Components.Schemas.User = .init(
      id: UUID().uuidString,
      firstName: "fisrtName",
      lastName: "lastName",
      age: 21
    )

    let response = try await handler.postUser(.init(body: .json(user)))

    try XCTAssertEqual(response.ok.body.json, user)
  }

  func testGetUserById() async throws {
    let user: Components.Schemas.User = .init(
      id: UUID().uuidString,
      firstName: "fisrtName",
      lastName: "lastName",
      age: 21
    )

    _ = try await handler.postUser(.init(body: .json(user)))

    let response2 = try await handler.getUserById(query: .init(userID: user.id))
    try XCTAssertEqual(response2.ok.body.json, user)
  }

  func testDeleteUserById() async throws {
    let user: Components.Schemas.User = .init(
      id: UUID().uuidString,
      firstName: "fisrtName",
      lastName: "lastName",
      age: 21
    )

    _ = try await handler.postUser(.init(body: .json(user)))
    let response2 = try await handler.deleteUserByID(.init(query: .init(userID: user.id)))

    try XCTAssertEqual(response2.noContent, .init())
  }

  func testSignUpAndLogin() async throws {
    let userName = "test@test.com"
    let password = UUID().uuidString
    _ = try await handler.signUp(.init(query: .init(userName: userName, password: password)))
  }
}
