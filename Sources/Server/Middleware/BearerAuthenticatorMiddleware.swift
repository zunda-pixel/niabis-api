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
      throw Abort(.notAcceptable, reason: "No Token in headers")
    }

    let payload: UserPayload

    do {
      logger.info("Verifying token")
      payload = try await app.jwt.keys.verify(token, as: UserPayload.self)
      logger.info("Verified token id: \(payload.id)")
    } catch {
      logger.error("Failed to verifiy token")
      throw error
    }

    guard Date.now < payload.expiration.value else {
      logger.warning("Token is expired")
      throw Abort(.notAcceptable, reason: "Token is expired")
    }

    guard
      let userToken = try await UserToken.find(
        UUID(uuidString: payload.id.value)!,
        on: app.db
      )
    else {
      logger.warning("Token is not registered")
      throw Abort(.notAcceptable, reason: "Token is not registered")
    }

    guard userToken.revokedDate == nil else {
      logger.warning("Token is revoked")
      throw Abort(.notAcceptable, reason: "Token is revoked")
    }

    // override userID query parameter with the one in the token
    var components = request.path.map { URLComponents(string: $0)! }!
    if components.queryItems == nil {
      components.queryItems = [.init(name: "userID", value: payload.userId.value)]
    } else if components.queryItems!.contains(where: { $0.name == "userID" }) {
      components.queryItems!.removeAll { $0.name == "userID" }
      components.queryItems!.append(.init(name: "userID", value: payload.userId.value))
    } else {
      components.queryItems!.append(.init(name: "userID", value: payload.userId.value))
    }
    let request = HTTPRequest(
      method: request.method,
      scheme: request.scheme,
      authority: request.authority,
      path: components.url!.absoluteString,
      headerFields: request.headerFields
    )

    return try await next(request, body, metadata)
  }
}
