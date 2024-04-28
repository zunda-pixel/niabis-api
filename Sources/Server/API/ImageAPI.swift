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
      return .badRequest(.init(body: .json(.init(message: "Requires Image data or Image url"))))
    }

    let imageData = try await Data(collecting: body, upTo: .max)
    let uploadedImage: Image
    do {
      uploadedImage = try await clinet.upload(imageData: imageData)
    } catch RequestError.invalidContentType {
      return .internalServerError(.init(body: .json(.init(
        message: "Inavlid Content-Type. image must have image/jpeg, image/png, image/webp, image/gif or image/svg+xml content-type"))))
    }

    return .ok(.init(body: .json(.init(id: uploadedImage.id))))
  }
}
