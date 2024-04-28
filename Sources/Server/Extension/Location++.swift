import Foundation
import TripadvisorKit

extension Components.Schemas.Location {
  init(location: Location, photoIDs: [UUID]) {
    let cuisines: [Components.Schemas.LabelContent]? = location.cuisines?.map {
      .init(name: $0.name, localizedName: $0.localizedName)
    }

    self.init(
      id: location.id.rawValue,
      description: location.description ?? "",
      cuisines: cuisines ?? [],
      photoIDs: photoIDs.map(\.uuidString)
    )
  }
}
