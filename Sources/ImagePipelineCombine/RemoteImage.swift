import SwiftUI
import Combine

public struct RemoteImage: View {
  @ObservedObject var imageModel: ImageModel
  var defaultImage: OSImage

  public init(url: URL, defaultImage: OSImage) {
    self.imageModel = .init(url: url)
    self.defaultImage = defaultImage
  }

  public var body: some View {
    image()
  }

  public func image() -> Image {
    imageModel.image
      .map { SwiftUI.Image($0).resizable() } ?? SwiftUI.Image(defaultImage).resizable()
  }
}

class ImageModel: ObservableObject {
  @Published var image: OSImage? = nil
  var subscription: AnyCancellable?

  init(url: URL, imageCache: ImagePipeline = .shared) {
    subscription = imageCache
      .load(url)
      .replaceError(with: nil)
      .receive(on: RunLoop.main)
      .assign(to: \.image, on: self)
  }
}

extension SwiftUI.Image {
  public init(_ image: OSImage) {
    #if os(macOS)
    self = .init(nsImage: image)
    #else
    self = .init(uiImage: image)
    #endif
  }
}
