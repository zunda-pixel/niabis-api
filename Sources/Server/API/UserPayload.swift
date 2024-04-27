import JWTKit

struct UserPayload: JWTPayload {
  var id: SubjectClaim
  var userId: SubjectClaim
  var expiration: ExpirationClaim

  func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {
    try self.expiration.verifyNotExpired()
  }
}
