import Foundation
import HTTPTypes
import OpenAPIRuntime
import SQLKit
import Vapor

struct BearerAuthenticatorMiddleware: ServerMiddleware {
  let app: Vapor.Application

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
    let header: HTTPHeaders = .init(request.headerFields.map { ($0.name.rawName, $0.value) })
    guard let token = header.bearerAuthorization?.token else {
      throw Abort(.notAcceptable)
    }
    let database = app.db as! SQLDatabase
    let row = try await database.select()
      .from("user_authentications")
      .columns("userID", "bearerToken", "timestamp")
      .where("bearerToken", .equal, token)
      .first()

    guard let row else {
      throw Abort(.forbidden)
    }

    let userAuthentication = UserAuthentication(
      userID: try row.decode(column: "userID", as: UUID.self),
      bearerToken: try row.decode(column: "bearerToken", as: String.self),
      timestamp: try row.decode(column: "timestamp", as: Date.self)
    )

    let expiredDate = userAuthentication.timestamp.addingTimeInterval(1_000_000)

    guard Date.now < expiredDate else {
      throw Abort(.forbidden)
    }

    return try await next(request, body, metadata)
  }
}
