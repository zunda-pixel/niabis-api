import FluentPostgresDriver
import JWTKit
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
    get async throws {
      let privateKey = try! EdDSA.PrivateKey(curve: .ed25519)
      await app.jwt.keys.addEdDSA(key: privateKey)
      return APIHandler(app: app)
    }
  }

  func testGetUserById() async throws {
    let userID = UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!
    let response = try await handler.getUserById(query: .init(userID: userID.uuidString))
    let json = try response.ok.body.json
    XCTAssertEqual(json, .init(id: userID.uuidString, email: "niabis.official+ios@gmail.com"))
  }

  func testGetLocation() async throws {
    let response = try await handler.getLocation(
      query: .init(
        locationName: "Old Ebbitt Grill",
        language: .en
      )
    )

    let location = try response.ok.body.json

    XCTAssertEqual(location.id, 450339)
    XCTAssertEqual(
      location.description,
      "Indoor Dining<br />Private Events<br />Carryout<br /><br />Chef Joseph Allen<br />Around the corner from The White House<br />"
    )
    XCTAssertEqual(
      location.cuisines,
      [
        .init(name: "american", localizedName: "American"),
        .init(name: "bar", localizedName: "Bar"),
        .init(name: "seafood", localizedName: "Seafood"),
        .init(name: "soups", localizedName: "Soups"),
      ]
    )
    XCTAssertEqual(
      location.photoURLs,
      [
        URL(
          string: "https://media-cdn.tripadvisor.com/media/photo-o/06/09/b0/2d/old-ebbitt-grill.jpg"
        )!,
        URL(
          string: "https://media-cdn.tripadvisor.com/media/photo-o/07/e2/65/1a/old-ebbitt-grill.jpg"
        )!,
        URL(
          string: "https://media-cdn.tripadvisor.com/media/photo-o/05/bc/2b/37/old-ebbitt-grill.jpg"
        )!,
        URL(
          string: "https://media-cdn.tripadvisor.com/media/photo-o/07/e2/65/31/old-ebbitt-grill.jpg"
        )!,
        URL(
          string: "https://media-cdn.tripadvisor.com/media/photo-o/07/e2/65/2b/old-ebbitt-grill.jpg"
        )!,
      ].map(\.absoluteString)
    )
  }

  func testGetToken() async throws {
    let response = try await handler.getToken(
      query: .init(userID: UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!.uuidString)
    )
    _ = try response.ok.body.json
  }
}
