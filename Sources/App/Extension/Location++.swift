import Foundation
import TripadvisorKit

extension Components.Schemas.Location {
  init(location: Location, imageURLs: [URL]) {
    let cuisines: [Components.Schemas.LabelContent]? = location.cuisines?.map {
      .init(name: $0.name, localizedName: $0.localizedName)
    }

    self.init(
      id: location.id.rawValue,
      description: location.description ?? "",
      cuisines: cuisines ?? [],
      imageURLs: imageURLs.map(\.absoluteString)
    )
  }
}
