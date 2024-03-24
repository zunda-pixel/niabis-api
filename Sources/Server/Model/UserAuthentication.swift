import Vapor
import Foundation
import Fluent

struct UserAuthentication {
  static var schema: String = "user_authentications"
  
  var userID: UUID
  var bearerToken: String
  var timestamp: Date
}
