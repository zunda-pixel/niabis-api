import Auth
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Supabase
import Vapor

struct BasicAuthenticatorMiddleware: ServerMiddleware {
  let operationIDs: [String]
  let logger: Logger
  let supabase: SupabaseClient

  init(
    operationIDs: [String],
    supabaseURL: URL,
    supabaseKey supabaseApiKey: String
  ) {
    self.operationIDs = operationIDs
    self.logger = Logger(label: "Basic Authenticator Middleware")
    self.supabase = SupabaseClient(
      supabaseURL: supabaseURL,
      supabaseKey: supabaseApiKey,
      options: .init(auth: .init(storage: EmptyAuthLocalStorage()))
    )
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
    logger.info("Start Basic Authenticator")

    guard operationIDs.contains(operationID) else {
      return try await next(request, body, metadata)
    }

    let httpHeader = HTTPHeaders(request.headerFields.map { ($0.name.rawName, $0.value) })
    guard let basicAuthorization = httpHeader.basicAuthorization else {
      logger.warning("No Basic Authorization in Headers")
      return try await next(request, body, metadata)
    }

    do {
      logger.info("Start Supabase SignIn userName: \(basicAuthorization.username)")
      try await self.supabase.auth.signIn(
        email: basicAuthorization.username,
        password: basicAuthorization.password
      )
    } catch {
      logger.error(
        """
        Not Accept on Supabase
        Error: \(error)
        """)
      return try await next(request, body, metadata)
    }

    let user = AuthenticateUser(name: basicAuthorization.username)
    return try await AuthenticateUser.$current.withValue(user) {
      try await next(request, body, metadata)
    }
  }
}
