import XCTest
import CommonCrypto
@testable import ImagePipelineCombine
import Combine

class PerformanceTests: XCTestCase {
  var pngData = [Data]()
  var jpegData = [Data]()
  var gifData = [Data]()
  var webpData = [Data]()

  var tempFile: String {
    return (NSTemporaryDirectory() as NSString).appendingPathComponent("temp.sqlite")
  }

  var cancellables: Set<AnyCancellable> = .init()

  override func setUp() {
    pngData.removeAll()
    jpegData.removeAll()
    gifData.removeAll()
    webpData.removeAll()

    for i in 1...99 {
      pngData.append(try! Data(contentsOf: Bundle.module.url(forResource: "\(i)", withExtension: "png")!))
      jpegData.append(try! Data(contentsOf: Bundle.module.url(forResource: "\(i)", withExtension: "jpg")!))
      gifData.append(try! Data(contentsOf: Bundle.module.url(forResource: "\(i)", withExtension: "gif")!))
      webpData.append(try! Data(contentsOf: Bundle.module.url(forResource: "\(i)", withExtension: "webp")!))
    }
  }

  override func tearDown() {
    try? FileManager().removeItem(atPath: tempFile)
  }

  func testDecodingPNGPerformance() {
    measure {
      Publishers.MergeMany(pngData.map { Just($0).decode() })
        .sink { (completion) in

        } receiveValue: { (output) in

        }
        .store(in: &cancellables)
    }
   }

  func testDecodingJPEGPerformance() {
    measure {
      Publishers.MergeMany(jpegData.map { Just($0).decode() })
        .sink { (completion) in

        } receiveValue: { (output) in

        }
        .store(in: &cancellables)
    }
  }

  func testDecodingGIFPerformance() {
    measure {
      Publishers.MergeMany(gifData.map { Just($0).decode() })
        .sink { (completion) in

        } receiveValue: { (output) in

        }
        .store(in: &cancellables)
    }
  }

  func testDecodingWebPPerformance() {
    measure {
      Publishers.MergeMany(webpData.map { Just($0).decode() })
        .sink { (completion) in

        } receiveValue: { (output) in

        }
        .store(in: &cancellables)
    }
  }
}
