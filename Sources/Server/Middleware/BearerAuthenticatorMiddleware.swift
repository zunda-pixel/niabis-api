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
      logger.warning("Verifying token")
      payload = try await app.jwt.keys.verify(token, as: UserPayload.self)
    } catch {
      throw error
    }

    logger.info("Verified token id: \(payload.id)")

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
    let url = request.path.map { URL(string: "http://localhost")!.appendingPathComponent($0) }
    var components = url.map { URLComponents(url: $0, resolvingAgainstBaseURL: false)! }
    components?.queryItems = [.init(name: "userID", value: payload.userId.value)]
    let request = components?.url.map { HTTPRequest(url: $0) } ?? request

    return try await next(request, body, metadata)
  }
}
