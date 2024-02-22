import HTTPTypes
import OpenAPIRuntime

/// A server middleware that authenticates the incoming user based on the value of
/// the `Authorization` header field and injects the identifier `User` information
/// into a task local value, allowing the request handler to use it.
struct AuthenticationServerMiddleware: Sendable {

  /// Information about an authenticated user.
  struct User: Hashable {

    /// The name of the authenticated user.
    var name: String

    /// The task local value of the currently authenticated user.
    @TaskLocal static var current: User?
  }

  /// The closure that authenticates the user based on the value of the `Authorization`
  /// header field.
  private let authenticate: @Sendable (String) -> User?

  /// Creates a new middleware.
  /// - Parameter authenticate: The closure that authenticates the user based on the value
  ///   of the `Authorization` header field.
  init(authenticate: @Sendable @escaping (String) -> User?) {
    self.authenticate = authenticate
  }
}

extension AuthenticationServerMiddleware: ServerMiddleware {
  func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    metadata: ServerRequestMetadata,
    operationID: String,
    next: @Sendable (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (
      HTTPResponse, HTTPBody?
    )
  ) async throws -> (HTTPResponse, HTTPBody?) {
    // Extracts the `Authorization` value, if present.
    // If no `Authorization` header field value was provided, no User is injected into
    // the task local.
    guard let authorizationHeaderFieldValue = request.headerFields[.authorization] else {
      return try await next(request, body, metadata)
    }
    // Delegate the authentication logic to the closure.
    let user = authenticate(authorizationHeaderFieldValue)
    // Inject the authenticated user into the task local and call the next middleware.
    return try await User.$current.withValue(user) {
      try await next(request, body, metadata)
    }
  }
}
