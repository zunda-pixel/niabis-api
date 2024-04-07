import JWTKit

struct UserPayload: JWTPayload {
  var id: SubjectClaim
  var userId: SubjectClaim
  var expiration: ExpirationClaim
  
  func verify(using key: JWTAlgorithm) throws {
    try self.expiration.verifyNotExpired()
  }
}
