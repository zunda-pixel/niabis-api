import Foundation

struct AuthenticateUser: Hashable {
  @TaskLocal static var current: AuthenticateUser?

  var name: String
}
