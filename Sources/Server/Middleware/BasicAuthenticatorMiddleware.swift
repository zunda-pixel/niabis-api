import Auth
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Supabase
import Vapor

struct BasicAuthenticatorMiddleware: ServerMiddleware {
  let operationIDs: [String]
  let logger: Logger

  init(operationIDs: [String]) {
    self.operationIDs = operationIDs
    self.logger = Logger(label: "Basic Authenticator Middleware")
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

    let supabase = SupabaseClient(
      supabaseURL: URL(string: Environment.get("SUPABASE_PROJECT_URL")!)!,
      supabaseKey: Environment.get("SUPABASE_API_KEY")!,
      options: .init(auth: .init(storage: EmptyAuthLocalStorage()))
    )

    do {
      logger.info("Start Supabase SignIn userName: \(basicAuthorization.username)")
      try await supabase.auth.signIn(
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
    
    let user = BasicAuthenticateUser(name: basicAuthorization.username)
    return try await BasicAuthenticateUser.$current.withValue(user) {
      try await next(request, body, metadata)
    }
  }
}
