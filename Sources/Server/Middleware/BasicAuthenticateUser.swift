import Foundation

struct BasicAuthenticateUser: Hashable {
  @TaskLocal static var current: BasicAuthenticateUser?

  var name: String

  init(name: String) {
    self.name = name
  }
}
