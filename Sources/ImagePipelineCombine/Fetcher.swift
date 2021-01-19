import Foundation
import Combine

public enum FetchingError: Error {
  case cancel
  case urlError(URLError)
}

public protocol Fetching {
  func fetch(_ url: URL) -> AnyPublisher<CacheEntry, URLError>
}

open class Fetcher: Fetching {
  private let session: URLSession = .init(configuration: .ephemeral)

  private let queue = DispatchQueue(label: "com.d-date.ImageCache.fetcher", qos: .userInitiated)

  public init() {}

  deinit {
    session.invalidateAndCancel()
  }

  open func fetch(_ url: URL) -> AnyPublisher<CacheEntry, URLError> {
    session.dataTaskPublisher(for: .init(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
      .subscribe(on: queue)
      .tryMap { data, response in
        guard let response = response as? HTTPURLResponse, !data.isEmpty else {
          throw URLError(.badServerResponse)
        }

        let headers = response.allHeaderFields
        let timeToLive: TimeInterval? = (headers["Cache-Control"] as? String)
          .flatMap(parseCacheControlHeader)
          .flatMap { $0["max-age"] }
          .flatMap(TimeInterval.init)

        let contentType = headers["Content-Type"] as? String

        let now = Date()
        return .init(url: url, data: data, contentType: contentType, timeToLive: timeToLive, creationDate: now, modificationDate: now)
      }
      .mapError {
        if let error = $0 as? URLError { return error }
        return URLError(.unknown)
      }
      .eraseToAnyPublisher()
  }
}

private let regex = try! NSRegularExpression(pattern: """
              ([a-zA-Z][a-zA-Z_-]*)\\s*(?:=(?:"([^"]*)"|([^ \t",;]*)))?
              """, options: [])

func parseCacheControlHeader(_ cacheControl: String) -> [String: String] {
  let matches = regex.matches(in: cacheControl, options: [], range: NSRange(location: 0, length: cacheControl.utf16.count))
  return matches.reduce(into: [String: String]()) { (directives, result) in
    if let range = Range(result.range, in: cacheControl) {
      let directive = cacheControl[range]
      let pair = directive.split(separator: "=")
      if pair.count == 2 {
        directives[String(pair[0])] = String(pair[1])
      }
    }
  }
}
