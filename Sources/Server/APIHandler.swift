import Vapor

actor APIHandler: APIProtocol {
  let app: Application
  let tripadvisorApiKey: String
  var tripadvisorRefererURL: URL? {
    #if DEBUG
      return URL(string: "https://api.niabis.com")!
    #else
      return nil
    #endif
  }

  init(app: Application) {
    self.app = app
    self.tripadvisorApiKey = Environment.get("TRIPADVISOR_API_KEY")!
  }
}
