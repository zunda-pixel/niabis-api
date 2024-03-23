import Vapor

actor APIHandler: APIProtocol {
  let app: Application
  let tripadvisorApiKey: String
  let tripadvisorRefererURL = URL(string: "https://api.niabis.com")!

  init(app: Application) {
    self.app = app
    self.tripadvisorApiKey = Environment.get("TRIPADVISOR_API_KEY")!
  }
}
