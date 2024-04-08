import Auth
import Foundation

struct EmptyAuthLocalStorage: AuthLocalStorage {
  func store(key: String, value: Data) throws {
  }
  
  func retrieve(key: String) throws -> Data? {
    return nil
  }
  
  func remove(key: String) throws {
  }
}
