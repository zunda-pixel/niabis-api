extension APIHandler {
  func signIn(_ input: Operations.signIn.Input) async throws -> Operations.signIn.Output {
    return .noContent(.init())
  }
}
