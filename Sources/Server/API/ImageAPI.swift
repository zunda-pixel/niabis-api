import Foundation
import ImagesClient
import OpenAPIRuntime
import Vapor

extension APIHandler {
  func uploadImage(
    _ input: Operations.uploadImage.Input
  ) async throws -> Operations.uploadImage.Output {
    let logger = Logger(label: "Upload Image API request-id: \(UUID())")

    logger.info("Start Upload Image")

    guard BearerAuthenticateUser.current != nil else {
      logger.warning("Not Authorized")
      return .unauthorized(.init())
    }

    guard let body = input.body else {
      logger.warning("Requires Image Data or Image URL")
      return .badRequest(.init(body: .json(.init(message: "Requires Image Data or Image URL"))))
    }

    switch body {
    case .image__ast_(let body):
      logger.info("Upload image from Data")
      return await uploadImageData(imageBody: body, logger: logger)
    case .json(let image):
      guard let url = URL(string: image.url) else {
        logger.warning("Invalid URL Format")
        return .badRequest(.init(body: .json(.init(message: "Invalid URL Format"))))
      }
      logger.info("Upload image from URL")
      return await uploadImageURL(imageURL: url, logger: logger)
    }
  }

  private func uploadImageURL(
    imageURL: URL,
    logger: Logger
  ) async -> Operations.uploadImage.Output {
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
        "Invalid Content-Type. image must have image/jpeg, image/png, image/webp, image/gif or image/svg+xml content-type"
      )
      return .internalServerError(
        .init(
          body: .json(
            .init(
              message:
                "Invalid Content-Type. image must have image/jpeg, image/png, image/webp, image/gif or image/svg+xml content-type"
            )))
      )
    } catch {
      logger.error("Failed to upload Image to Cloudflare Images")
      return .internalServerError(
        .init(body: .json(.init(message: "Failed to upload Image to Cloudflare Images"))))
    }

    return .ok(.init(body: .json(.init(id: uploadedImage.id))))
  }

  private func uploadImageData(
    imageBody: HTTPBody,
    logger: Logger
  ) async -> Operations.uploadImage.Output {
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
        "Invalid Content-Type. image must have image/jpeg, image/png, image/webp, image/gif or image/svg+xml content-type"
      )
      return .internalServerError(
        .init(
          body: .json(
            .init(
              message:
                "Invalid Content-Type. image must have image/jpeg, image/png, image/webp, image/gif or image/svg+xml content-type"
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
