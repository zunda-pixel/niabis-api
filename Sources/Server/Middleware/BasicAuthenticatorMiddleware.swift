import Auth
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Supabase
import Vapor

struct BasicAuthenticatorMiddleware: ServerMiddleware {
  let operationIDs: [String]

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
    guard operationIDs.contains(operationID) else {
      return try await next(request, body, metadata)
    }

    let httpHeader = HTTPHeaders(request.headerFields.map { ($0.name.rawName, $0.value) })
    guard let basicAuthorization = httpHeader.basicAuthorization else {
      throw Abort(.notAcceptable)
    }

    let supabase = SupabaseClient(
      supabaseURL: URL(string: Environment.get("SUPABASE_PROJECT_URL")!)!,
      supabaseKey: Environment.get("SUPABASE_API_KEY")!,
      options: .init(auth: .init(storage: EmptyAuthLocalStorage()))
    )

    try await supabase.auth.signIn(
      email: basicAuthorization.username,
      password: basicAuthorization.password
    )

    return try await next(request, body, metadata)
  }
}
