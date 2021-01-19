import Foundation
import Combine

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public protocol ImageCaching {
  func store(_ image: OSImage, for url: URL)
  func load(for url: URL) -> OSImage?
  func remove(for url: URL)
  func removeAll()
}

public class MemoryCache: ImageCaching {

  public static let shared = MemoryCache()

  public var totalCostLimit: Int {
    get { cache.totalCostLimit }
    set { cache.totalCostLimit = newValue }
  }

  public var countLimit: Int {
    get { cache.countLimit }
    set { cache.countLimit = newValue }
  }

  private let cache: NSCache<NSURL, OSImage>

  private var defaultLimit: Int {
    let physicalMemory = ProcessInfo().physicalMemory
    let ratio = physicalMemory <= (1024 * 1024 * 512) ? 0.1 : 0.2
    let limit = physicalMemory / UInt64(1 / ratio)

    return limit > UInt64(Int.max) ? Int.max : Int(limit)
  }

  public init() {
    cache = .init()
    cache.totalCostLimit = defaultLimit
  }

  public func store(_ image: OSImage, for url: URL) {
    let size = image.size
    let bytesPerRow = Int(size.width * 4)
    let cost = bytesPerRow * Int(size.height)

    cache.setObject(image, forKey: url as NSURL, cost: cost)
  }

  public func load(for url: URL) -> OSImage? {
    cache.object(forKey: url as NSURL)
  }

  public func remove(for url: URL) {
    cache.removeObject(forKey: url as NSURL)
  }

  public func removeAll() {
    cache.removeAllObjects()
  }
}
