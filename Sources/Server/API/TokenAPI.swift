import Foundation
import JWTKit
import Vapor

private let logger = Logger(label: "Token API")

extension APIHandler {
  func generateToken(
    _ input: Operations.generateToken.Input
  ) async throws -> Operations.generateToken.Output {
    guard let userID = UUID(uuidString: input.query.userID) else {
      logger.warning("Invalid UUID")
      return .badRequest(.init(body: .json(.init(message: "Inavlid UUID"))))
    }

    do {
      guard try await User.find(userID, on: app.db) != nil else {
        logger.warning("Not Found User")
        return .notFound(.init())
      }
    } catch {
      logger.error("Failed to load from DB")
      throw error
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

    do {
      try await userToken.create(on: app.db)
    } catch {
      logger.error("Failed to save token information")
      return .internalServerError(.init(body: .json(.init(
        message: "Failed to save token information"
      ))))
    }

    let token: String

    do {
      token = try await app.jwt.keys.sign(payload)
    } catch {
      logger.error("Failed to generate token")
      return .internalServerError(.init(body: .json(.init(
        message: "Failed to generate token"
      ))))
    }

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
      logger.warning("Invalid UUID")
      return .badRequest(.init(body: .json(.init(message: "Invalid UUID"))))
    }

    let tokenCount: Int
    do {
      tokenCount = try await UserToken.query(on: app.db)
        .filter(\UserToken.$id, .equal, tokenId)
        .limit(1)
        .count()
    } catch {
      logger.error("Failed to load Token data from DB")
      throw error
    }

    guard tokenCount > 0 else {
      logger.warning("Not Found Token in DB")
      return .notFound(.init())
    }

    var query = UserToken.query(on: app.db)

    query = query.set(\.$revokedDate, to: Date())

    do {
      try await query
        .filter(\UserToken.$id, .equal, tokenId)
        .update()
    } catch {
      logger.error("Failed to update reveke date")
      throw error
    }

    return .ok(.init())
  }
}
