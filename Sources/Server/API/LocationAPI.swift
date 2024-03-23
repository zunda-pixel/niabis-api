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

    return .ok(.init(body: .json(.init(location: locationDetail))))
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

    let location = try response.content.decode(TripadvisorKit.Location.self)

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

    let locationsResponse = try response.content.decode(TripadvisorKit.LocationsResponse.self)

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
