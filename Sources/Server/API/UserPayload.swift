import JWTKit

struct UserPayload: JWTPayload {
  var id: SubjectClaim
  var userId: SubjectClaim
  var expiration: ExpirationClaim

  func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {
    try self.expiration.verifyNotExpired()
  }

  // TODO remain for Linux(Heroku Publish)
  func verify(using key: JWTAlgorithm) throws {
    try self.expiration.verifyNotExpired()
  }
}
