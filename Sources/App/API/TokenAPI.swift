import Foundation
import JWTKit
import Vapor

extension APIHandler {
  func generateToken(
    _ input: Operations.generateToken.Input
  ) async throws -> Operations.generateToken.Output {
    let logger = Logger(label: "Generate Token API request-id: \(UUID())")

    logger.info("Start Generate Token")

    guard let authUser = AuthenticateUser.current else {
      logger.warning("Not Authorized")
      return .unauthorized(.init())
    }

    guard let userID = UUID(uuidString: input.query.userID) else {
      logger.warning("Invalid UUID")
      return .badRequest(.init(body: .json(.init(message: "Invalid UUID"))))
    }

    do {
      logger.info("Loading User Data id: \(userID)")
      guard let user = try await User.find(userID, on: app.db) else {
        logger.warning("Not Found User")
        return .notFound(.init())
      }

      guard user.email == authUser.name else {
        logger.warning("Invalid User ID")
        return .badRequest(.init(body: .json(.init(message: "Invalid User ID"))))
      }

      logger.info("Found User Data id: \(userID)")
    } catch {
      logger.error("Failed to load from DB")
      return .internalServerError(.init(body: .json(.init(message: "Failed to load from DB"))))
    }

    let tokenId = UUID()

    let userToken = UserToken(
      id: tokenId,
      userId: userID,
      revokedDate: nil
    )

    let tokenPayload = UserTokenPayload(
      id: .init(value: tokenId.uuidString),
      userId: .init(value: input.query.userID),
      expiration: .init(value: .now.addingTimeInterval(60 * 10))
    )
    
    let refreshTokenPayload = UserTokenPayload(
      id: .init(value: tokenId.uuidString),
      userId: .init(value: input.query.userID),
      expiration: .init(value: .now.addingTimeInterval(60 * 60 * 24 * 30)) // 1 month(30 days)
    )

    do {
      logger.info("Inserting New User Token id: \(tokenId)")
      try await userToken.create(on: app.db)
      logger.info("Inserted New User Token id: \(tokenId)")
    } catch {
      logger.error("Failed to save token information")
      return .internalServerError(
        .init(
          body: .json(
            .init(
              message: "Failed to save token information"
            ))))
    }

    let token: String
    let refreshToken: String

    do {
      logger.info("Signing Payload with key")
      token = try await app.jwt.keys.sign(tokenPayload)
      refreshToken = try await app.jwt.keys.sign(refreshTokenPayload)
      logger.info("Signed Payload with key")
    } catch {
      logger.error("Failed to generate token")
      return .internalServerError(
        .init(
          body: .json(
            .init(
              message: "Failed to generate token"
            ))))
    }

    return .ok(
      .init(
        body: .json(
          .init(
            id: tokenId.uuidString,
            token: token,
            tokenExpireDate: tokenPayload.expiration.value,
            refreshToken: refreshToken,
            refreshTokenExpireDate: refreshTokenPayload.expiration.value
          )
        )
      )
    )
  }

  func revokeToken(
    _ input: Operations.revokeToken.Input
  ) async throws -> Operations.revokeToken.Output {
    let logger = Logger(label: "Rovoke Token API request-id: \(UUID())")
    logger.info("Start Revoke Token")

    guard let authUser = BearerAuthenticateUser.current else {
      logger.warning("Not Authorized")
      return .unauthorized(.init())
    }

    guard let tokenId = UUID(uuidString: input.query.tokenId) else {
      logger.warning("Invalid UUID")
      return .badRequest(.init(body: .json(.init(message: "Invalid UUID"))))
    }

    do {
      logger.info("Fetching User Token from DB")
      guard let token = try await UserToken.find(tokenId, on: app.db) else {
        logger.warning("Not Found Token in DB")
        return .notFound(.init())
      }
      guard token.userId == authUser.userId else {
        logger.warning("Invalid User ID")
        return .badRequest(.init(body: .json(.init(message: "Invalid User ID"))))
      }
      logger.info("Found User Token on DB")
    } catch {
      logger.error("Failed to load Token data from DB")
      return .internalServerError(
        .init(
          body: .json(
            .init(
              message: "Failed to load Token data from DB"
            )))
      )
    }

    var query = UserToken.query(on: app.db)
    query = query.set(\.$revokedDate, to: Date())

    do {
      logger.info("Upadating User Token's revoked Date id: \(tokenId)")
      try await query
        .filter(\UserToken.$id, .equal, tokenId)
        .update()
      logger.info("Uploaded User Token id: \(tokenId)")
    } catch {
      logger.error("Failed to update reveke date")
      return .internalServerError(
        .init(
          body: .json(
            .init(
              message: "Failed to update reveke date"
            )))
      )
    }

    return .ok(.init())
  }
}
