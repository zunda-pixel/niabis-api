import Auth
import Supabase

extension APIHandler {
  func signUp(_ input: Operations.signUp.Input) async throws -> Operations.signUp.Output {
    try await supabase.auth.signUp(
      email: input.query.userName,
      password: input.query.password,
      redirectTo: nil
    )
    return .noContent(.init())
  }
  
  
  func login(_ input: Operations.login.Input) async throws -> Operations.login.Output {
    try await supabase.auth.signIn(
      email: input.query.userName,
      password: input.query.password
    )
    
    return .noContent(.init())
  }
}
