import Vapor

actor APIHandler: APIProtocol {
  let app: Application
  let tripadvisorApiKey: String
  let tripadvisorRefererURL = URL(string: "https://api.niabis.com")!
  let cloudflareApiToken: String
  let cloudflareAccountId: String
  init(
    app: Application,
    tripadvisorApiKey: String,
    cloudflareApiToken: String,
    cloudflareAccountId: String
  ) {
    self.app = app
    self.tripadvisorApiKey = tripadvisorApiKey
    self.cloudflareApiToken = cloudflareApiToken
    self.cloudflareAccountId = cloudflareAccountId
  }
}
