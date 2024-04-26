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

    let uploadedImage: Image

    if case .image__ast_(let body) = input.body {
      let imageData = try await Data(collecting: body, upTo: .max)
      uploadedImage = try await clinet.upload(imageData: imageData)
    } else if let urlString = input.query.url {
      if let url = URL(string: urlString) {
        uploadedImage = try await clinet.upload(imageURL: url)
      } else {
        throw Abort(.badRequest)
      }
    } else {
      throw Abort(.badRequest)
    }

    guard let imageURL = uploadedImage.variants.first else {
      throw Abort(.badRequest)
    }

    return .ok(.init(body: .json(.init(url: imageURL.absoluteString))))
  }
}
