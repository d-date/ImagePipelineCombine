import SwiftUI
import Combine
#if os(macOS)
import AppKit
public typealias OSImage = NSImage
#elseif os(iOS) || os(tvOS) || os(watchOS)
import UIKit
public typealias OSImage = UIImage
#endif

open class ImagePipeline {
  public static let shared = ImagePipeline()

  private let fecther: Fetching
  private let memoryCache: ImageCaching

  private let queue = DispatchQueue(label: "com.d-date.ImageCache", qos: .userInitiated)

  public init(
    fecther: Fetching = Fetcher(),
    memoryCache: ImageCaching = MemoryCache()
  ) {
    self.fecther = fecther
    self.memoryCache = memoryCache
  }

  open func load(_ url: URL) -> AnyPublisher<OSImage?, Error> {
    if let image = memoryCache.load(for: url) {
      return Result.Publisher(image)
        .eraseToAnyPublisher()
    }

    return fecther.fetch(url)
      .subscribe(on: queue)
      .map(\.data)
      .decode()
      .handleEvents(receiveOutput: { [weak self] in
        if let image = $0 {
          self?.memoryCache.store(image, for: url)
        }
      })
      .eraseToAnyPublisher()
  }
}
