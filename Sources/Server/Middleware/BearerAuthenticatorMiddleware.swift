import Foundation
import HTTPTypes
import JWT
import OpenAPIRuntime
import SQLKit
import Vapor

struct BearerAuthenticatorMiddleware: ServerMiddleware {
  let app: Vapor.Application
  let excludeOperationIDs: [String]
  let logger: Logger

  init(
    app: Vapor.Application,
    excludeOperationIDs: [String]
  ) {
    self.app = app
    self.excludeOperationIDs = excludeOperationIDs
    self.logger = Logger(label: "Bearer Authenticator Middleware")
  }

  func intercept(
    _ request: HTTPTypes.HTTPRequest,
    body: OpenAPIRuntime.HTTPBody?,
    metadata: OpenAPIRuntime.ServerRequestMetadata,
    operationID: String,
    next: @Sendable (
      HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, OpenAPIRuntime.ServerRequestMetadata
    ) async throws -> (
      HTTPTypes.HTTPResponse,
      OpenAPIRuntime.HTTPBody?
    )
  ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
    logger.info("Start Bearer Authenticator")
    guard !excludeOperationIDs.contains(operationID) else {
      return try await next(request, body, metadata)
    }

    let header: HTTPHeaders = .init(request.headerFields.map { ($0.name.rawName, $0.value) })
    guard let token = header.bearerAuthorization?.token else {
      logger.warning("No Token in headers")
      return try await next(request, body, metadata)
    }

    let payload: UserPayload

    do {
      logger.info("Verifying token")
      payload = try await app.jwt.keys.verify(token, as: UserPayload.self)
      logger.info("Verified token id: \(payload.id)")
    } catch {
      logger.error("Failed to verifiy token")
      return try await next(request, body, metadata)
    }

    guard Date.now < payload.expiration.value else {
      logger.warning("Token is expired")
      return try await next(request, body, metadata)
    }

    guard
      let userToken = try await UserToken.find(
        UUID(uuidString: payload.id.value)!,
        on: app.db
      )
    else {
      logger.warning("Token is not registered")
      return try await next(request, body, metadata)
    }

    guard userToken.revokedDate == nil else {
      logger.warning("Token is revoked")
      return try await next(request, body, metadata)
    }

    let authenticateUser = BearerAuthenticateUser(userId: userToken.userId)

    return try await BearerAuthenticateUser.$current.withValue(authenticateUser) {
      try await next(request, body, metadata)
    }
  }
}
