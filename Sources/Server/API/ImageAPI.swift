import Foundation
import ImagesClient
import OpenAPIRuntime
import Vapor

private let logger = Logger(label: "Image API")

extension APIHandler {
  func uploadImage(
    _ input: Operations.uploadImage.Input
  ) async throws -> Operations.uploadImage.Output {
    logger.info("Start Upload Image")

    if case .image__ast_(let body) = input.body {
      return await uploadImageData(imageBody: body)
    } else if let imageURL = input.query.imageURL {
      guard let url = URL(string: imageURL) else {
        return .badRequest(.init(body: .json(.init(message: "Invalid URL Format"))))
      }
      return await uploadImageURL(imageURL: url)
    } else {
      logger.warning("Requires Image Data or Image URL")
      return .badRequest(.init(body: .json(.init(message: "Requires Image Data or Image URL"))))
    }
  }

  private func uploadImageURL(imageURL: URL) async -> Operations.uploadImage.Output {
    let client = ImagesClient(
      apiToken: cloudflareApiToken,
      accountId: cloudflareAccountId
    )

    let uploadedImage: Image
    do {
      let client = ImagesClient(
        apiToken: cloudflareApiToken,
        accountId: cloudflareAccountId
      )
      logger.info("Uploading Image URL")
      uploadedImage = try await client.upload(imageURL: imageURL)
      logger.info("Uploaed Image Data id: \(uploadedImage.id)")
    } catch RequestError.invalidContentType {
      logger.warning(
        "Inavlid Content-Type. image must have image/jpeg, image/png, image/webp, image/gif or image/svg+xml content-type"
      )
      return .internalServerError(
        .init(
          body: .json(
            .init(
              message:
                "Inavlid Content-Type. image must have image/jpeg, image/png, image/webp, image/gif or image/svg+xml content-type"
            )))
      )
    } catch {
      logger.error("Failed to upload Image to Cloudflare Images")
      return .internalServerError(
        .init(body: .json(.init(message: "Failed to upload Image to Cloudflare Images"))))
    }

    return .ok(.init(body: .json(.init(id: uploadedImage.id))))
  }

  private func uploadImageData(imageBody: HTTPBody) async -> Operations.uploadImage.Output {
    let imageData: Data

    do {
      imageData = try await Data(collecting: imageBody, upTo: .max)
    } catch {
      logger.error("Failed to convert to Data from HTTP Body")
      return .internalServerError(
        .init(body: .json(.init(message: "Failed to convert to Data from HTTP Body"))))
    }

    let uploadedImage: Image
    do {
      let client = ImagesClient(
        apiToken: cloudflareApiToken,
        accountId: cloudflareAccountId
      )
      logger.info("Uploading Image Data")
      uploadedImage = try await client.upload(imageData: imageData)
      logger.info("Uploaed Image Data id: \(uploadedImage.id)")
    } catch RequestError.invalidContentType {
      logger.warning(
        "Inavlid Content-Type. image must have image/jpeg, image/png, image/webp, image/gif or image/svg+xml content-type"
      )
      return .internalServerError(
        .init(
          body: .json(
            .init(
              message:
                "Inavlid Content-Type. image must have image/jpeg, image/png, image/webp, image/gif or image/svg+xml content-type"
            )))
      )
    } catch {
      logger.error("Failed to upload Image to Cloudflare Images")
      return .internalServerError(
        .init(body: .json(.init(message: "Failed to upload Image to Cloudflare Images"))))
    }

    return .ok(.init(body: .json(.init(id: uploadedImage.id))))
  }
}
