import Vapor
import Foundation
import Fluent

final class UserAuthentication: Model {
  static var schema: String = "user_authentications"
  
  var id: UUID? {
    get {
      userID
    }
    set {
      userID = newValue ?? userID
    }
  }
  
  @Field(key: "userID")
  var userID: UUID
  
  @Field(key: "bearerToken")
  var bearerToken: String
  
  @Field(key: "timestamp")
  var timestamp: Date
  
  init() {
    userID = .init()
    bearerToken = ""
    timestamp = .now
  }
  
  init(
    userID: UUID,
    bearerToken: String,
    timestamp: Date
  ) {
    self.userID = userID
    self.bearerToken = bearerToken
    self.timestamp = timestamp
  }
}
