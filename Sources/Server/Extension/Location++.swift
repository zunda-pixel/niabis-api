import Foundation
import TripadvisorKit

extension Components.Schemas.Location {
  init(location: Location, photoURLs: [URL]) {
    self.init(
      id: location.id.rawValue,
      description: location.description ?? "",
      cuisines: location.cuisines?.map { .init(name: $0.name, localizedName: $0.localizedName) }
      ?? [],
      photoURLs: photoURLs.map(\.absoluteString)
    )
  }
}
