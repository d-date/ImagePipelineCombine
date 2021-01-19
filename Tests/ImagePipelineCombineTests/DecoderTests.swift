import XCTest
import SnapshotTesting
import Combine
@testable import ImagePipelineCombine

class DecoderTests: XCTestCase {

    var cancellables: Set<AnyCancellable> = .init()

    func testDecodePNG() {
        let fixture = try! Data(contentsOf: Bundle.module.url(forResource: "200x150", withExtension: "png")!)

        let expectation = XCTestExpectation()
        Just(fixture)
            .decode()
            .sink { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { (image) in
              if let image = image {
                assertSnapshot(matching: image, as: .image)
                expectation.fulfill()
              } else {
                XCTFail()
              }
            }
            .store(in: &cancellables)
        wait(for: [expectation], timeout: 10)
    }

    func testDecodeJPEG() {
        let fixture = try! Data(contentsOf: Bundle.module.url(forResource: "200x150", withExtension: "jpg")!)

        let expectation = XCTestExpectation()
        Just(fixture)
            .decode()
            .sink { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { (image) in
              if let image = image {
                assertSnapshot(matching: image, as: .image)
                expectation.fulfill()
              } else {
                XCTFail()
              }
            }
            .store(in: &cancellables)
    }

    func testDecodeGIF() {
        let fixture = try! Data(contentsOf: Bundle.module.url(forResource: "200x150", withExtension: "gif")!)

        let expectation = XCTestExpectation()
        Just(fixture)
            .decode()
            .sink { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { (image) in
              if let image = image {
                assertSnapshot(matching: image, as: .image)
                expectation.fulfill()
              } else {
                XCTFail()
              }
            }
            .store(in: &cancellables)
    }

    func testDecodeWebP() {
        let fixture = try! Data(contentsOf: Bundle.module.url(forResource: "200x150", withExtension: "webp")!)

        let expectation = XCTestExpectation()
        Just(fixture)
            .decode()
            .sink { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { (image) in
              if let image = image {
                assertSnapshot(matching: image, as: .image)
                expectation.fulfill()
              } else {
                XCTFail()
              }
            }
            .store(in: &cancellables)
    }
}
