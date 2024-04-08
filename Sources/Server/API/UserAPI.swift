import Vapor

extension APIHandler {
  func getUserById(_ input: Operations.getUserById.Input) async throws
    -> Operations.getUserById.Output
  {
    guard let userID = UUID(uuidString: input.query.userID) else {
      throw Abort(.badRequest, reason: "Invalid UUID")
    }
    guard let user = try await User.find(userID, on: app.db) else {
      return .notFound(.init())
    }

    return .ok(.init(body: .json(user.componentUser)))
  }

  func updateUserByID(_ input: Operations.updateUserByID.Input) async throws
    -> Operations.updateUserByID.Output
  {
    guard let userID = UUID(uuidString: input.query.userID) else {
      throw Abort(.badRequest, reason: "Invalid UUID")
    }
    guard case .json(let user) = input.body else {
      throw Abort(.badRequest, reason: "Invalid User body")
    }

    let userCount = try await User.query(on: app.db)
      .filter(\.$id, .equal, userID).limit(1).count()

    guard userCount > 0 else {
      return .notFound(.init())
    }

    var query = User.query(on: app.db)

    if let email = user.email {
      query = query.set(\.$email, to: email)
    }

    try await query
      .filter(\User.$id, .equal, userID)
      .update()

    guard let user = try await User.find(userID, on: app.db) else {
      return .notFound(.init())
    }

    return .ok(.init(body: .json(user.componentUser)))
  }
}
