import Auth

extension APIHandler {
  func signUp(_ input: Operations.signUp.Input) async throws -> Operations.signUp.Output {
    return .noContent(.init())
  }
  
  
  func login(_ input: Operations.login.Input) async throws -> Operations.login.Output {
    return .noContent(.init())
  }
}
