import Fluent
import Foundation

final class User: Model, @unchecked Sendable {
  static let schema = "users"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "email")
  var email: String

  init() {
    id = UUID()
  }

  init(
    id: UUID,
    email: String
  ) {
    self.id = id
    self.email = email
  }

  var componentUser: Components.Schemas.User {
    .init(
      id: self.id!.uuidString,
      email: self.email
    )
  }
}

extension Components.Schemas.User {
  var dbUser: User {
    .init(
      id: UUID(uuidString: self.id)!,
      email: self.email
    )
  }
}
