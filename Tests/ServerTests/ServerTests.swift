import FluentPostgresDriver
import JWTKit
import Vapor
import XCTest

@testable import Server

final class ServerTests: XCTestCase {
  let app: Application = {
    var env = try! Environment.detect()
    let app = Application(env)

    var configuration: SQLPostgresConfiguration = .init(
      hostname: Environment.get("DATABASE_HOST")!,
      username: Environment.get("DATABASE_USERNAME")!,
      password: Environment.get("DATABASE_PASSWORD")!,
      database: Environment.get("DATABASE_NAME")!,
      tls: .disable
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
      let privateKey = try EdDSA.PrivateKey(
        x: "UlSOo+Q5hOtiSQjSc7HnOaMv5FiXhKG5HMaliNcIN7o=",
        d: "T8s3Xh9Aulyq0UqIkggCgDyyXQKzPgIWH0w4Cb1O3Yg=",
        curve: .ed25519
      )
      await app.jwt.keys.addEdDSA(key: privateKey)
      return APIHandler(
        app: app,
        tripadvisorApiKey: Environment.get("TRIPADVISOR_API_KEY")!,
        cloudflareApiToken: Environment.get("CLOUDFLARE_API_TOKEN")!,
        cloudflareAccountId: Environment.get("CLOUDFLARE_ACCOUNT_ID")!
      )
    }
  }

  func testUploadImageWithData() async throws {
    let filePath = Bundle.module.url(forResource: "Swift_logo", withExtension: "svg")!
    let imageData = try Data(contentsOf: filePath)
    let response = try await handler.uploadImage(.init(body: .image__ast_(.init(imageData))))
    _ = try response.ok.body.json.id
  }

  func testGetUserById() async throws {
    let userID = UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!
    let response = try await handler.getUserById(query: .init(userID: userID.uuidString))
    let json = try response.ok.body.json
    XCTAssertEqual(json, .init(id: userID.uuidString, email: "test@niabis.com"))
  }

  func testGetLocation() async throws {
    let response = try await handler.getLocationDetail(
      query: .init(
        locationName: "Old Ebbitt Grill",
        language: .en
      )
    )

    let location = try response.ok.body.json

    XCTAssertEqual(location.id, 450339)
    XCTAssertEqual(
      location.description,
      "Indoor DiningPrivate EventsCarryoutChef Joseph AllenAround the corner from The White House"
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
    XCTAssertEqual(location.photoIDs.compactMap { UUID(uuidString: $0) }.count, 5)
  }

  func testGetToken() async throws {
    let response = try await handler.generateToken(
      query: .init(userID: UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!.uuidString)
    )
    _ = try response.ok.body.json
  }

  func testRevokeToken() async throws {
    let tokenResponse = try await handler.generateToken(
      query: .init(userID: UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!.uuidString)
    )

    let tokenId = try tokenResponse.ok.body.json.id

    let revokeResponse = try await handler.revokeToken(
      query: .init(tokenId: tokenId)
    )
    _ = try revokeResponse.ok
  }
}
