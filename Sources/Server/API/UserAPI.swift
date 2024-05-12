import Vapor

extension APIHandler {
  func getUserById(
    _ input: Operations.getUserById.Input
  ) async throws -> Operations.getUserById.Output {
    let logger = Logger(label: "Get User API request-id: \(UUID())")

    logger.info("Start Get User by ID")

    guard let userID = UUID(uuidString: input.query.userID) else {
      logger.warning("Invalid UUID")
      return .badRequest(.init(body: .json(.init(message: "Invalid UUID"))))
    }

    do {
      logger.info("Fetching User Data from DB")
      guard let user = try await User.find(userID, on: app.db) else {
        logger.warning("Not Found User")
        return .notFound(.init())
      }
      logger.info("Fetched User Data id: \(user.id!)")

      return .ok(.init(body: .json(user.componentUser)))
    } catch {
      logger.error("Failed to load User from DB")
      throw error
    }
  }

  func updateUserByID(
    _ input: Operations.updateUserByID.Input
  ) async throws -> Operations.updateUserByID.Output {
    let logger = Logger(label: "Update User API request-id: \(UUID())")

    logger.info("Start Update User by ID")

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
      logger.info("Fetching User from DB")
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
      logger.info("Upading User Data")
      try await query
        .filter(\User.$id, .equal, userID)
        .update()
    } catch {
      logger.error("Failed to update User")
      throw error
    }

    do {
      logger.info("Fetching User Data from DB")

      guard let user = try await User.find(userID, on: app.db) else {
        logger.warning("Not Found User")
        return .notFound(.init())
      }
      logger.info("Fetched User Data id: \(user.id!)")

      return .ok(.init(body: .json(user.componentUser)))
    } catch {
      logger.error("Failed to load data from DB")
      throw error
    }
  }
}
