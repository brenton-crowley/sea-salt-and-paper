import AsyncExtensions
import Foundation
import HTTPTypes

extension SSEService {
    struct DataProvider: Sendable {
        let sseConnection: @Sendable (_ httpRequest: HTTPRequest) throws -> AsyncThrowingStream<Data, Error>

        static func makeLiveURLSession(
            config: URLSessionConfiguration
        ) -> Self {
            .init(
                sseConnection: { httpRequest in
                    let delegate = ConnectionDataDelegate()
                    let urlSession = URLSession(
                        configuration: config,
                        delegate: delegate,
                        delegateQueue: nil
                    )

                    guard let urlRequest = URLRequest(httpRequest: httpRequest) else { throw URLError(.badURL) }

                    defer {
                        urlSession.dataTask(with: urlRequest).resume()
                    }

                    return delegate.stream
                }
            )
        }
    }
}

// MARK: - Delegate

extension SSEService {
    private final class ConnectionDataDelegate: NSObject, Sendable, URLSessionDataDelegate {
        let (stream, continuation) = AsyncThrowingStream<Data, Error>.makeStream()

        func urlSession( _ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            continuation.yield(data)
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let error { continuation.finish(throwing: error) }

            continuation.finish()
        }
    }
}

extension SSEService.Config {
    var dataProvider: SSEService.DataProvider {
        switch self {
        case .default: .default
        case let .urlSession(configuration): .urlSessionConfiguration(configuration)
        }
    }
}

extension SSEService.DataProvider {
    static let `default`: Self = urlSessionConfiguration()

    static func urlSessionConfiguration(_ config: URLSessionConfiguration? = nil) -> Self {
        .makeLiveURLSession(config: config ?? .sseConfig)
    }
}

extension URLSessionConfiguration {
    static let sseConfig: URLSessionConfiguration = {
        let oneMinute = Double(Duration.seconds(60).components.seconds)
        var config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = oneMinute
        config.timeoutIntervalForResource = .infinity

        return config
    }()
}

// MARK: - Models

extension SSEService {
    struct Connection: Sendable {
        let subject: SubjectOfData
        let sharedStream: AsyncShareSequence<SubjectOfData>
        let task: Task<(), Error>
    }
}
