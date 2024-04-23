import Vapor

actor APIHandler: APIProtocol {
  let app: Application
  let tripadvisorApiKey: String
  let tripadvisorRefererURL = URL(string: "https://api.niabis.com")!

  init(
    app: Application,
    tripadvisorApiKey: String
  ) {
    self.app = app
    self.tripadvisorApiKey = tripadvisorApiKey
  }
}
