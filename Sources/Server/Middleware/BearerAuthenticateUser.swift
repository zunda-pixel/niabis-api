import Foundation

struct BearerAuthenticateUser: Hashable {
  @TaskLocal static var current: BearerAuthenticateUser?

  var userID: UUID

  init(userID: UUID) {
    self.userID = userID
  }
}
