import Foundation
import JWTKit
import Vapor

extension APIHandler {
  func getToken(_ input: Operations.getToken.Input) async throws -> Operations.getToken.Output {
    guard let userID = UUID(uuidString: input.query.userID) else {
      throw Abort(.badRequest, reason: "Invalid UUID")
    }

    guard try await User.find(userID, on: app.db) != nil else {
      throw Abort(.notFound, reason: "User not found")
    }

    let userToken = UserToken(
      id: UUID(),
      userId: userID,
      invalidatedDate: nil
    )

    let payload = UserPayload(
      id: .init(value: userToken.id!.uuidString),
      userId: .init(value: input.query.userID),
      expiration: .init(value: .distantFuture)
    )

    try await userToken.create(on: app.db)

    let token = try await app.jwt.keys.sign(payload)

    return .ok(
      .init(
        body: .json(
          .init(
            token: token,
            expireDate: payload.expiration.value
          )
        )
      )
    )
  }
}
