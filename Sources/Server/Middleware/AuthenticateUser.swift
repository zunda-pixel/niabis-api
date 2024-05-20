import Foundation

struct AuthenticateUser: Hashable {
  @TaskLocal static var current: AuthenticateUser?

  var name: String

  init(name: String) {
    self.name = name
  }
}
