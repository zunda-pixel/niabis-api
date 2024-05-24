import Fluent
import Foundation

final class UserToken: Model {
  static let schema = "user_tokens"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "userId")
  var userId: UUID

  @Field(key: "revokedDate")
  var revokedDate: Date?

  init() {
    id = UUID()
  }

  init(
    id: UUID,
    userId: UUID,
    revokedDate: Date?
  ) {
    self.id = id
    self.userId = userId
    self.revokedDate = revokedDate
  }
}
