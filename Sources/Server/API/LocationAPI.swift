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

    let (data, _) = try await URLSession.shared.data(for: request)

    let location = try JSONDecoder.tripadvisor.decode(TripadvisorKit.Location.self, from: data)

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

    let (data, _) = try await URLSession.shared.data(for: request)

    let response = try JSONDecoder.tripadvisor.decode(LocationsResponse.self, from: data)

    return response.locations.first
  }
}
