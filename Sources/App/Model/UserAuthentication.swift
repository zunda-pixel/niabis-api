import Fluent
import Foundation
import Vapor

struct UserAuthentication {
  static let schema: String = "user_authentications"

  var userID: UUID
  var bearerToken: String
  var timestamp: Date
}
