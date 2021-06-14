import CoreGraphics
import Combine
import Foundation
import WebPDecoder

extension Publisher where Output == Data {
  public func decode() -> Publishers.ImageDecode<Self> {
    return .init(upstream: self)
  }
}

extension Publishers {
  public struct ImageDecode<Upstream>: Publisher where Upstream: Publisher, Upstream.Output == Data {

    public typealias Output = OSImage?
    public typealias Failure = Error

    public let upstream: Upstream

    public let _imageDecode: (Upstream.Output) throws -> OSImage?
    public init(upstream: Upstream, imageDecode: @escaping (Upstream.Output) throws -> OSImage? = ImagePipelineCombine.decode) {
      self.upstream = upstream
      self._imageDecode = imageDecode
    }

    public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
      upstream.subscribe(Inner(downstream: subscriber, imageDecode: _imageDecode))
    }
  }
}

public func decode(_ data: Data) throws -> OSImage? {
  guard data.count > 12 else {
    return nil
  }

  let bytes = Array(data)
  if !bytes.isWebP, let image = OSImage(data: data) {
    return image
  }

  return data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
    guard let bytes = buffer.bindMemory(to: UInt8.self).baseAddress else {
      return nil
    }

    var width: Int32 = 0
    var height: Int32 = 0

    guard WebPGetInfo(bytes, data.count, &width, &height) != 0 else {
      return nil
    }
    guard let raw = WebPDecodeRGBA(bytes, data.count, &width, &height) else {
      return nil
    }
    guard let provider = CGDataProvider(dataInfo: nil,
                                        data: raw,
                                        size: Int(width * height * 4),
                                        releaseData: { (_, data, _) in free(UnsafeMutableRawPointer(mutating: data)) }) else {
      return nil
    }

    let bitsPerComponent = 8
    let bitsPerPixel = bitsPerComponent * 4
    let bytesPerRow = Int(4 * width)
    let space = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
    guard let cgImage = CGImage(width: Int(width), height: Int(height),
                                bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow,
                                space: space, bitmapInfo: bitmapInfo,
                                provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
      return nil
    }

    #if os(macOS)
    return OSImage(cgImage: cgImage, size: NSSize(width: CGFloat(width), height: CGFloat(height)))
    #else
    return OSImage(cgImage: cgImage)
    #endif
  }
}

private extension Array where Element == UInt8 {
  var isJPEG: Bool {
    self[0...2] == [0xFF, 0xD8, 0xFF]
  }

  var isPNG: Bool {
    self[0...3] == [0x89, 0x50, 0x4E, 0x47]
  }

  var isGIF: Bool {
    self[0...2] == [0x47, 0x49, 0x46]
  }

  var isWebP: Bool {
    self[8...11] == [0x57, 0x45, 0x42, 0x50]
  }
}

extension Publishers.ImageDecode {
  private final class Inner<Downstream: Subscriber>
  : Subscriber,
    Subscription,
    CustomStringConvertible,
    CustomReflectable,
    CustomPlaygroundDisplayConvertible
  where Downstream.Input == Output, Downstream.Failure == Error
  {
    typealias Input = Upstream.Output

    typealias Failure = Upstream.Failure

    private let downstream: Downstream

    private let imageDecode: (Upstream.Output) throws -> Output

    private var lock: NSLock? = .init()

    private var finished = false

    private var subscription: Subscription?

    fileprivate init(
      downstream: Downstream,
      imageDecode: @escaping (Upstream.Output) throws -> Output
    ) {
      self.downstream = downstream
      self.imageDecode = imageDecode
    }

    deinit {
      lock = nil
    }

    func receive(subscription: Subscription) {
      lock?.lock()
      if finished || self.subscription != nil {
        lock?.unlock()
        subscription.cancel()
        return
      }
      self.subscription = subscription
      lock?.unlock()
      downstream.receive(subscription: self)
    }

    func receive(_ input: Input) -> Subscribers.Demand {
      lock?.lock()
      if finished {
        lock?.unlock()
        return .none
      }
      lock?.unlock()
      do {
        return try downstream.receive(imageDecode(input))
      } catch {
        lock?.lock()
        finished = true
        let subscription = self.subscription
        self.subscription = nil
        lock?.unlock()
        subscription?.cancel()
        downstream.receive(completion: .failure(error))
        return .none
      }
    }

    func receive(completion: Subscribers.Completion<Failure>) {
      lock?.lock()
      if finished {
        lock?.unlock()
        return
      }
      finished = true
      subscription = nil
      lock?.unlock()
      downstream.receive(completion: completion.eraseError())
    }

    func request(_ demand: Subscribers.Demand) {
      lock?.lock()
      let subscription = self.subscription
      lock?.unlock()
      subscription?.request(demand)
    }

    func cancel() {
      lock?.lock()
      guard !finished, let subscription = self.subscription else {
        lock?.unlock()
        return
      }
      self.subscription = nil
      finished = true
      lock?.unlock()
      subscription.cancel()
    }

    var description: String { return "ImageDecode" }

    var customMirror: Mirror {
      let children: [Mirror.Child] = [
        ("downstream", downstream),
        ("finished", finished),
        ("upstreamSubscription", subscription as Any)
      ]
      return Mirror(self, children: children)
    }

    var playgroundDescription: Any { return description }
  }
}

extension Subscribers.Completion {

  /// Erases the `Failure` type to `Swift.Error`. This function exists
  /// because in Swift user-defined generic types are always
  /// [invariant](https://en.wikipedia.org/wiki/Covariance_and_contravariance_(computer_science)).
  func eraseError() -> Subscribers.Completion<Error> {
    switch self {
    case .finished:
      return .finished
    case .failure(let error):
      return .failure(error)
    }
  }
}
