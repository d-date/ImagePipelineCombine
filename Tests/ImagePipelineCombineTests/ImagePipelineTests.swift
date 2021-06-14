import XCTest
import SnapshotTesting
import Combine
import SwiftUI
@testable import ImagePipelineCombine

class ImagePipelineTests: XCTestCase {

  var cancellables = Set<AnyCancellable>.init()
  func testImagePipelineSuccess() {
    let defaultImage = OSImage(data: try! Data(contentsOf: Bundle.module.url(forResource: "200x150", withExtension: "png")!))!

    let url = URL(string: "https://satyr.io/80x60?flag=svk&type=webp&delay=1000")!
    let remoteImage = RemoteImage(url: url, defaultImage: defaultImage)

    XCTAssertEqual(remoteImage.image(), SwiftUI.Image(defaultImage).resizable())

    RunLoop.main.run(until: Date(timeIntervalSinceNow: 10))

    assertSnapshot(matching: remoteImage.imageModel.image!, as: .image)
  }

  func testImagePipelineCallbackSuccess() {
    let ex = expectation(description: "")

    let pipeline = ImagePipeline()
    pipeline.load(URL(string: "https://satyr.io/80x60?flag=svk&type=webp&delay=1000")!)
      .sink { (completion) in
        switch completion {
          case .failure:
            XCTFail()
          default:
            break
        }
      } receiveValue: { (image) in
        if let image = image {
          assertSnapshot(matching: image, as: .image)
          ex.fulfill()
        } else {
          XCTFail()
        }
      }
      .store(in: &cancellables)

    wait(for: [ex], timeout: 5)
  }

  func testImagePipelineCallbackFailure() {
    let ex = expectation(description: "")

    let url = URL(string: "https://httpbin.org/status/400")!
    let pipeline = ImagePipeline()
    pipeline.load(url)
      .sink { (completion) in
        switch completion {
          case .finished:
            // When not specified failure image, nil will return as output.
            ex.fulfill()
          default:
            XCTFail()
        }
      } receiveValue: { (image) in
        if image != nil {
          XCTFail()
        }
      }
      .store(in: &cancellables)

    wait(for: [ex], timeout: 2)
  }

  func testImagepipelineDeallocatedBeforeFinished() {
    weak var weakPipeline: ImagePipeline?

    do {
      let pipeline = ImagePipeline()
      weakPipeline = pipeline

      XCTAssertNotNil(weakPipeline)

      for _ in 0..<100 {
        pipeline.load(URL(string: "https://satyr.io/200x150?type=webp&delay=1000")!)
          .sink { (completion) in

          } receiveValue: { (image) in

          }
          .store(in: &cancellables)
      }

      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
    }

    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
    XCTAssertNil(weakPipeline)

    RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
    XCTAssertNil(weakPipeline)

    RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
    XCTAssertNil(weakPipeline)

    RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
    XCTAssertNil(weakPipeline)
  }

  class SpyFetcher: Fetching {
    var called: (() -> Void)?

    func fetch(_ url: URL) -> AnyPublisher<CacheEntry, URLError> {
      let data = try! Data(contentsOf: Bundle.module.url(forResource: "200x150", withExtension: "png")!)
      let now = Date()
      let completion = Result<CacheEntry, URLError>.Publisher(CacheEntry(url: url, data: data, contentType: "image/png", timeToLive: 6, creationDate: now, modificationDate: now))
        .eraseToAnyPublisher()
      called?()
      return completion
    }

    func cancel(_ url: URL) {}
    func cancelAll() {}
  }

  class NullCache: ImageCaching {
    func store(_ image: OSImage, for url: URL) {}
    func load(for url: URL) -> OSImage? { return nil }
    func remove(for url: URL) {}
    func removeAll() {}
  }
}
