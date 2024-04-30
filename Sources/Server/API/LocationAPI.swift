import ImagesClient
import TripadvisorKit
import Vapor

private let logger = Logger(label: "Location API")

extension APIHandler {
  func getLocationDetail(
    _ input: Operations.getLocationDetail.Input
  ) async throws -> Operations.getLocationDetail.Output {
    logger.info("Start Get Location Detail")

    guard let language: Language = .init(rawValue: input.query.language.rawValue) else {
      logger.warning("Invalid Language")
      return .badRequest(.init(body: .json(.init(message: "Inavlid Language"))))
    }

    let location: Location

    do {
      logger.info("Seaching Locaiton on Tripadvisor")
      guard
        let fetchedLocation = try await searchLocation(
          query: input.query.locationName,
          language: language
        )
      else {
        logger.warning("Not Found Location")
        return .notFound(.init())
      }
      logger.info("Searched Location id: \(fetchedLocation.id)")
      location = fetchedLocation
    } catch {
      logger.error("Failed to fetch Location from Tripadvisor")
      throw error
    }

    let locationDetail: Location
    do {
      logger.info("Fetching Locaiton Detail from Tripadvisor")
      locationDetail = try await self.locationDetail(
        locationId: location.id,
        language: language
      )
      logger.info("Fetched Location Detail id: \(locationDetail.id)")
    } catch {
      logger.error("Failed to load Location Detail")
      throw error
    }

    let tripadvisorPhotoURLs: [URL]

    do {
      logger.info("Fetching Location Photo URLs from Tripadvisor")
      tripadvisorPhotoURLs = try await locationPhotoURLs(
        locationId: location.id,
        language: language
      )
      logger.info("Fetched Location Photo URLs")
    } catch {
      logger.error("Failed to load Location Photo URLs")
      throw error
    }

    let photoIDs: [UUID]
    do {
      let client = ImagesClient(
        apiToken: cloudflareApiToken,
        accountId: cloudflareAccountId
      )
      logger.info("Uploading Image URLs to Cloudflare Images")
      photoIDs = try await client.upload(imageURLs: tripadvisorPhotoURLs)
      logger.info("Uploaded Image URLs")
    } catch {
      logger.error("Failed to upload photo ids")
      throw error
    }

    return .ok(
      .init(
        body: .json(
          .init(
            location: locationDetail,
            photoIDs: photoIDs
          )
        )
      )
    )
  }

  fileprivate func locationPhotoURLs(
    locationId: TripadvisorKit.Location.ID,
    language: Language
  ) async throws -> [URL] {
    let request = LocationPhotosRequest(
      apiKey: tripadvisorApiKey,
      locationId: locationId,
      referer: tripadvisorRefererURL,
      language: language
    )

    let response = try await app.client.get(for: request)

    let photosResponse = try response.content.decode(
      TripadvisorKit.PhotosResponse.self,
      using: JSONDecoder.tripadvisor
    )

    let images = photosResponse.photos.map { $0.image.original ?? $0.image.large }

    return images.map(\.url)
  }

  fileprivate func locationDetail(
    locationId: TripadvisorKit.Location.ID,
    language: Language
  ) async throws -> TripadvisorKit.Location {
    let request = LocationDetailRequest(
      apiKey: tripadvisorApiKey,
      locationId: locationId,
      referer: tripadvisorRefererURL,
      language: language
    )

    let response = try await app.client.get(for: request)

    let location = try response.content.decode(
      TripadvisorKit.Location.self,
      using: JSONDecoder.tripadvisor
    )

    return location
  }

  fileprivate func searchLocation(
    query: String,
    language: Language
  ) async throws -> TripadvisorKit.Location? {
    let request = SearchLocationsRequest(
      apiKey: tripadvisorApiKey,
      searchQuery: query,
      referer: tripadvisorRefererURL,
      language: language
    )

    let response = try await app.client.get(for: request)

    let locationsResponse = try response.content.decode(
      TripadvisorKit.LocationsResponse.self,
      using: JSONDecoder.tripadvisor
    )

    return locationsResponse.locations.first
  }
}

extension Client {
  func get(for request: some TripadvisorKit.Request) async throws -> ClientResponse {
    let uri = URI(string: request.url.absoluteString)
    let heaers: [(String, String)] = request.headers.map { ($0.name.rawName, $0.value) }
    return try await self.get(uri, headers: .init(heaers))
  }
}

extension ImagesClient {
  func upload(imageURLs: [URL]) async throws -> [UUID] {
    try await withThrowingTaskGroup(of: String.self) { group in
      for imageURL in imageURLs {
        group.addTask {
          return try await self.upload(imageURL: imageURL).id
        }
      }

      var imageIDs: [UUID] = []
      for try await imageID in group {
        imageIDs.append(UUID(uuidString: imageID)!)
      }
      return imageIDs
    }
  }
}
