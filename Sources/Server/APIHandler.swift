import Supabase
import Vapor

actor APIHandler: APIProtocol {
  let app: Application
  let supabase: SupabaseClient

  init(app: Application) {
    self.app = app
    self.supabase = SupabaseClient(
      supabaseURL: URL(string: Environment.get("SUPABASE_PROJECT_URL")!)!,
      supabaseKey: Environment.get("SUPABASE_PUBLIC_API_KEY")!,
      options: .init(auth: .init())
    )
  }
}
