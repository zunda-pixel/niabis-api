import Foundation
import JWTKit
import Vapor

extension APIHandler {
  func generateToken(
    _ input: Operations.generateToken.Input
  ) async throws -> Operations.generateToken.Output {
    guard let basicAuthUser = AuthenticateUser.current else {
      return .unauthorized(.init())
    }

    let logger = Logger(label: "Generate Token API request-id: \(UUID())")

    logger.info("Start Generate Token")

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
      
      guard user.email == basicAuthUser.name else {
        return .badRequest(.init(body: .json(.init(message: "Invalid User ID"))))
      }
      
      logger.info("Found User Data id: \(userID)")
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

    do {
      logger.info("Signing Payload with key")
      token = try await app.jwt.keys.sign(payload)
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
            expireDate: payload.expiration.value
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

    guard let tokenId = UUID(uuidString: input.query.tokenId) else {
      logger.warning("Invalid UUID")
      return .badRequest(.init(body: .json(.init(message: "Invalid UUID"))))
    }

    let tokenCount: Int
    do {
      logger.info("Fetching User Token from DB")
      tokenCount = try await UserToken.query(on: app.db)
        .filter(\UserToken.$id, .equal, tokenId)
        .limit(1)
        .count()
      logger.info("Found User Token on DB")
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
      logger.info("Upadating User Token's revoked Date id: \(tokenId)")
      try await query
        .filter(\UserToken.$id, .equal, tokenId)
        .update()
      logger.info("Uploaded User Token id: \(tokenId)")
    } catch {
      logger.error("Failed to update reveke date")
      throw error
    }

    return .ok(.init())
  }
}
