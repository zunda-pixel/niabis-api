import Foundation
import TripadvisorKit

extension Components.Schemas.Location {
  init(location: Location, photoURLs: [URL]) {
    let cuisines: [Components.Schemas.LabelContent]? = location.cuisines?.map {
      .init(name: $0.name, localizedName: $0.localizedName)
    }

    self.init(
      id: location.id.rawValue,
      description: location.description ?? "",
      cuisines: cuisines ?? [],
      photoURLs: photoURLs.map(\.absoluteString)
    )
  }
}
