import Foundation
import JWTKit
import Vapor

extension APIHandler {
  func generateToken(_ input: Operations.generateToken.Input) async throws -> Operations.generateToken.Output {
    guard let userID = UUID(uuidString: input.query.userID) else {
      throw Abort(.badRequest, reason: "Invalid UUID")
    }

    guard try await User.find(userID, on: app.db) != nil else {
      throw Abort(.notFound, reason: "User not found")
    }

    let tokenId = UUID()

    let userToken = UserToken(
      id: tokenId,
      userId: userID,
      revokedDate: nil
    )

    let payload = UserPayload(
      id: .init(value: tokenId.uuidString),
      userId: .init(value: input.query.userID),
      expiration: .init(value: .distantFuture)
    )

    try await userToken.create(on: app.db)

    let token = try await app.jwt.keys.sign(payload)

    return .ok(
      .init(
        body: .json(
          .init(
            id: tokenId.uuidString,
            token: token,
            expireDate: payload.expiration.value
          )
        )
      )
    )
  }

  func revokeToken(
    _ input: Operations.revokeToken.Input
  ) async throws -> Operations.revokeToken.Output {
    guard let tokenId = UUID(uuidString: input.query.tokenId) else {
      throw Abort(.badRequest, reason: "Invalid UUID")
    }

    let tokenCount = try await UserToken.query(on: app.db)
      .filter(\UserToken.$id, .equal, tokenId)
      .limit(1)
      .count()

    guard tokenCount > 0 else {
      return .notFound(.init())
    }

    var query = UserToken.query(on: app.db)

    query = query.set(\.$revokedDate, to: Date())

    try await query
      .filter(\UserToken.$id, .equal, tokenId)
      .update()

    return .ok(.init())
  }
}
