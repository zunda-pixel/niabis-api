import Foundation
import ImagesClient
import Vapor

private let logger = Logger(label: "Image API")

extension APIHandler {
  func uploadImage(
    _ input: Operations.uploadImage.Input
  ) async throws -> Operations.uploadImage.Output {
    logger.info("Start Upload Image")

    let clinet = ImagesClient(
      apiToken: cloudflareApiToken,
      accountId: cloudflareAccountId
    )

    guard case .image__ast_(let body) = input.body else {
      logger.warning("Requires Image data or Image url")
      return .badRequest(.init(body: .json(.init(message: "Requires Image data or Image url"))))
    }

    let imageData: Data
    do {
      imageData = try await Data(collecting: body, upTo: .max)
    } catch {
      logger.error("Failed to convert to Data from HTTP Body")
      throw error
    }

    let uploadedImage: Image
    do {
      logger.info("Uploading Image Data")
      uploadedImage = try await clinet.upload(imageData: imageData)
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
      throw error
    }

    return .ok(.init(body: .json(.init(id: uploadedImage.id))))
  }
}
