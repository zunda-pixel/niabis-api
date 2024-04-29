import Vapor

private let logger = Logger(label: "User API")

extension APIHandler {
  func getUserById(
    _ input: Operations.getUserById.Input
  ) async throws -> Operations.getUserById.Output {
    guard let userID = UUID(uuidString: input.query.userID) else {
      logger.warning("Inavlid UUID")
      return .badRequest(.init(body: .json(.init(message: "Invalid UUID"))))
    }

    do {
      guard let user = try await User.find(userID, on: app.db) else {
        logger.warning("Not Found User")
        return .notFound(.init())
      }
      
      return .ok(.init(body: .json(user.componentUser)))
    } catch {
      logger.error("Failed to load User from DB")
      throw error
    }
  }

  func updateUserByID(
    _ input: Operations.updateUserByID.Input
  ) async throws -> Operations.updateUserByID.Output {
    guard let userID = UUID(uuidString: input.query.userID) else {
      logger.warning("Invalid UUID")
      return .badRequest(.init(body: .json(.init(message: "Invalid UUID"))))
    }
    guard case .json(let user) = input.body else {
      logger.warning("Requires Users Body")
      return .badRequest(.init(body: .json(.init(message: "Requires Users Body"))))
    }

    let userCount: Int
    do {
      userCount = try await User.query(on: app.db)
        .filter(\.$id, .equal, userID).limit(1).count()
    } catch {
      logger.error("Failed to load data from DB")
      throw error
    }

    guard userCount > 0 else {
      logger.warning("Not Found User")
      return .notFound(.init())
    }

    var query = User.query(on: app.db)

    if let email = user.email {
      query = query.set(\.$email, to: email)
    }

    do {
      try await query
        .filter(\User.$id, .equal, userID)
        .update()
    } catch {
      logger.error("Failed to update User")
      throw error
    }

    do {
      guard let user = try await User.find(userID, on: app.db) else {
        logger.warning("Not Found User")
        return .notFound(.init())
      }
      
      return .ok(.init(body: .json(user.componentUser)))
    } catch {
      logger.error("Failed to load data from DB")
      throw error
    }
  }
}
