import Fluent
import Foundation

final class UserToken: Model {
  static let schema = "user_tokens"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "userId")
  var userId: UUID

  @Field(key: "invalidatedDate")
  var invalidatedDate: Date?

  init() {
    id = UUID()
  }

  init(
    id: UUID,
    userId: UUID,
    invalidatedDate: Date?
  ) {
    self.id = id
    self.userId = userId
    self.invalidatedDate = invalidatedDate
  }
}
