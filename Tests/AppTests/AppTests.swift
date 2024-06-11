import FluentPostgresDriver
import JWTKit
import Vapor
import XCTest

@testable import App

final class AppTests: XCTestCase {
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
      await app.jwt.keys.add(eddsa: privateKey)
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
    let authUser = BearerAuthenticateUser(
      userId: UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!
    )
    let response = try await BearerAuthenticateUser.$current.withValue(authUser) {
      try await handler.uploadImage(.init(body: .image__ast_(.init(imageData))))
    }
    _ = try response.ok.body.json.id
  }

  func testUploadImageWithURL() async throws {
    let imageURL = URL(string: "https://developer.apple.com/swift/images/swift-og.png")!
    let authUser = BearerAuthenticateUser(
      userId: UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!
    )
    let response = try await BearerAuthenticateUser.$current.withValue(authUser) {
      try await handler.uploadImage(
        .init(body: .json(.init(url: imageURL.absoluteString)))
      )
    }
    _ = try response.ok.body.json.id
  }

  func testGetUserById() async throws {
    let userID = UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!
    let authUser = BearerAuthenticateUser(userId: userID)
    let response = try await BearerAuthenticateUser.$current.withValue(authUser) {
      try await handler.getUserById(query: .init(userID: userID.uuidString))
    }
    let json = try response.ok.body.json
    XCTAssertEqual(json, .init(id: userID.uuidString, email: "test@niabis.com"))
  }

  func testGetLocation() async throws {
    let authUser = BearerAuthenticateUser(
      userId: UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!
    )
    let response = try await BearerAuthenticateUser.$current.withValue(authUser) {
      try await handler.getLocationDetail(
        query: .init(
          locationName: "Roscioli New York",
          language: .en
        )
      )
    }

    let location = try response.ok.body.json

    XCTAssertEqual(location.id, 789274)
    XCTAssertEqual(
      location.description,
      #"Ristorante Salumeria Roscioli is a multi-function delicatessen, an unconventional restaurant, and a rich and varied wine bar, where the cuisine is based on high quality materials selected over the years by the Roscioli brothers and an attentive and ready staff. The menu presents traditional starters and main dishes, as well as the results of conceptions from the national cuisine – raw fish from the Mediterranean and Tyrrhenian, selections of French or Italian Alpine cheeses, classified by typology and maturation, but also cold cuts of Spanish or native origin, all cut by hand."#
    )
    XCTAssertEqual(
      location.cuisines,
      [
        .init(name: "deli", localizedName: "Deli"),
        .init(name: "italian", localizedName: "Italian"),
        .init(name: "mediterranean", localizedName: "Mediterranean"),
        .init(name: "european", localizedName: "European"),
        .init(name: "romana", localizedName: "Romana"),
        .init(name: "lazio", localizedName: "Lazio"),
        .init(name: "centralitalian", localizedName: "Central-Italian"),
      ]
    )
    XCTAssertEqual(
      location.imageURLs,
      [
        URL(
          string:
            "https://media-cdn.tripadvisor.com/media/photo-m/1280/17/9f/ae/cb/a-multi-functional-deli.jpg"
        )!,
        URL(string: "https://media-cdn.tripadvisor.com/media/photo-o/12/1c/38/60/wines.jpg")!,
        URL(
          string: "https://media-cdn.tripadvisor.com/media/photo-o/12/1c/77/6e/cacio-e-pepe.jpg")!,
        URL(
          string:
            "https://media-cdn.tripadvisor.com/media/photo-o/12/1c/77/68/nabil-hassen-the-chef.jpg")!,
        URL(string: "https://media-cdn.tripadvisor.com/media/photo-o/12/1c/77/64/gnocchi.jpg")!,
      ].map(\.absoluteString)
    )
  }

  func testGenerateToken() async throws {
    let authUser = AuthenticateUser(name: "test@niabis.com")
    let response = try await AuthenticateUser.$current.withValue(authUser) {
      try await handler.generateToken(
        query: .init(userID: UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!.uuidString)
      )
    }
    _ = try response.ok.body.json
  }

  func testRevokeToken() async throws {
    let basicAuthUser = AuthenticateUser(name: "test@niabis.com")

    let tokenResponse = try await AuthenticateUser.$current.withValue(basicAuthUser) {
      try await handler.generateToken(
        query: .init(userID: UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!.uuidString)
      )
    }

    let tokenId = try tokenResponse.ok.body.json.id

    let authUser = BearerAuthenticateUser(
      userId: UUID(uuidString: "3cf9d5e6-2173-4d48-9a23-8906d0d48cab")!
    )
    let revokeResponse = try await BearerAuthenticateUser.$current.withValue(authUser) {
      try await handler.revokeToken(
        query: .init(tokenId: tokenId)
      )
    }
    _ = try revokeResponse.ok
  }
}
