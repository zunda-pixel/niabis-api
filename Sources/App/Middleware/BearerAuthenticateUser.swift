import Foundation

struct BearerAuthenticateUser: Hashable {
  @TaskLocal static var current: BearerAuthenticateUser?

  var userId: UUID
}
