import TripadvisorKit
import Vapor

extension APIHandler {
  func getLocation(_ input: Operations.getLocation.Input) async throws
    -> Operations.getLocation.Output
  {
    let language: Language = .init(rawValue: input.query.language.rawValue)!

    guard
      let location = try await searchLocation(query: input.query.locationName, language: language)
    else {
      return .notFound(.init())
    }

    let locationDetail = try await locationDetail(locationId: location.id, language: language)

    let photosURL = try await locationPhotoURLs(locationId: location.id, language: language)
    
    return .ok(.init(body: .json(.init(location: locationDetail, photoURLs: photosURL))))
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

    let photosResponse = try response.content.decode(TripadvisorKit.PhotosResponse.self, using: JSONDecoder.tripadvisor)

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

    let location = try response.content.decode(TripadvisorKit.Location.self, using: JSONDecoder.tripadvisor)

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

    let locationsResponse = try response.content.decode(TripadvisorKit.LocationsResponse.self, using: JSONDecoder.tripadvisor)

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
