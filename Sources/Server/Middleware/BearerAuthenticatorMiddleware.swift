import Foundation
import OpenAPIRuntime
import Vapor
import HTTPTypes

struct BearerAuthenticatorMiddleware: ServerMiddleware {
  let app: Vapor.Application
  
  func intercept(
    _ request: HTTPTypes.HTTPRequest,
    body: OpenAPIRuntime.HTTPBody?,
    metadata: OpenAPIRuntime.ServerRequestMetadata,
    operationID: String,
    next: @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, OpenAPIRuntime.ServerRequestMetadata) async throws -> (
      HTTPTypes.HTTPResponse,
      OpenAPIRuntime.HTTPBody?
    )
  ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
    let header: HTTPHeaders = .init(request.headerFields.map { ($0.name.rawName, $0.value) })
    guard let token = header.bearerAuthorization?.token else {
      throw Abort(.notAcceptable)
    }
    let userAuthentication = try await UserAuthentication.query(on: app.db).filter(\.$bearerToken, .equal, token).first()
    guard let userAuthentication else {
      throw Abort(.forbidden)
    }
    guard userAuthentication.timestamp.addingTimeInterval(1_000_000) < Date.now else {
      throw Abort(.forbidden)
    }
    // Add user id to header
    var request = request
    request.headerFields[.userID] = userAuthentication.userID.uuidString
    return try await next(request, body, metadata)
  }
}
