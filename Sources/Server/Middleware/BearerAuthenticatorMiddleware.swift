import Foundation
import HTTPTypes
import JWT
import OpenAPIRuntime
import SQLKit
import Vapor

struct BearerAuthenticatorMiddleware: ServerMiddleware {
  let app: Vapor.Application
  let excludeOperationIDs: [String]

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
    guard !excludeOperationIDs.contains(operationID) else {
      return try await next(request, body, metadata)
    }

    let header: HTTPHeaders = .init(request.headerFields.map { ($0.name.rawName, $0.value) })
    guard let token = header.bearerAuthorization?.token else {
      throw Abort(.notAcceptable, reason: "No Token")
    }

    let payload = try await app.jwt.keys.verify(token, as: UserPayload.self)

    guard Date.now < payload.expiration.value else {
      throw Abort(.notAcceptable, reason: "Token expired")
    }

    guard let userToken = try await UserToken.find(UUID(uuidString: payload.id.value)!, on: app.db)
    else {
      throw Abort(.notAcceptable, reason: "Token not registered")
    }

    guard userToken.invalidatedDate == nil else {
      throw Abort(.notAcceptable, reason: "Token invalidated")
    }

    // override userID query parameter with the one in the token
    let url = request.path.map { URL(string: "http://localhost")!.appending(path: $0) }?
      .appending(queryItems: [.init(name: "userID", value: payload.userId.value)])
    let request = url.map { HTTPRequest(url: $0) } ?? request

    return try await next(request, body, metadata)
  }
}
