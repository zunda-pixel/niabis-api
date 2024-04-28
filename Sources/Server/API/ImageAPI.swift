import Foundation
import ImagesClient
import Vapor

extension APIHandler {
  func uploadImage(
    _ input: Operations.uploadImage.Input
  ) async throws -> Operations.uploadImage.Output {
    let clinet = ImagesClient(
      apiToken: cloudflareApiToken,
      accountId: cloudflareAccountId
    )

    guard case .image__ast_(let body) = input.body else {
      throw Abort(.badRequest, reason: "Requires Image data or Image url")
    }
    let imageData = try await Data(collecting: body, upTo: .max)
    let uploadedImage: Image
    do {
      uploadedImage = try await clinet.upload(imageData: imageData)
    } catch RequestError.invalidContentType {
      throw Abort(
        .internalServerError,
        reason:
          "Inavlid Content-Type. image must have image/jpeg, image/png, image/webp, image/gif or image/svg+xml content-type"
      )
    }

    return .ok(.init(body: .json(.init(id: uploadedImage.id))))
  }
}
