import AsyncAlgorithms
import AsyncExtensions
import Foundation
import SharedDependency
import HTTPTypes
import HTTPTypesFoundation

/// Exposes an update stream that consumers use to listen for updates via Server-Sent Events (SSE)
public actor SSEService: Sendable {
    public typealias AsyncShareSequenceOfData = AsyncShareSequence<SubjectOfData>
    public typealias SubjectOfData = AsyncThrowingPassthroughSubject<Data, Error>

    public enum Config {
        case `default`
        case urlSession(configuration: URLSessionConfiguration?)
    }

    let dataProvider: SSEService.DataProvider

    var openConnections: [URL?: Connection] = [:]

    init(dataProvider: SSEService.DataProvider) {
        self.dataProvider = dataProvider
    }
}

// MARK: - Public API

extension SSEService {
    public func streamedData(forConnection httpRequest: HTTPRequest) async -> (
        stream: AsyncStream<Data>,
        terminateConnection: @Sendable () -> Void
    ) {
        let (stream, continuation) = AsyncStream<Data>.makeStream(bufferingPolicy: .bufferingNewest(1))

        let task = Task {
            do {
                for try await value in try await sharedStream(httpRequest: httpRequest) {
                    continuation.yield(value)
                }
            } catch {
                print("\(#function) - Error with shared stream. Ending child connection.")
            }

            continuation.finish()
        }

        continuation.onTermination = { @Sendable [weak self] _ in
            Task {
                await print("SSEConnection - Cancelling PIPELINE sse stream: \(String(describing: httpRequest.url)); Root connection is still live: \(String(describing: self?.rootConnectionIsAlive(url: httpRequest.url)))")
            }
            task.cancel()
        }

        return (stream, { continuation.finish() })
    }
}

// MARK: - Private API

extension SSEService {
    private func rootConnectionIsAlive(url: URL?) -> Bool {
        openConnections.keys.contains { $0 == url }
    }

    private func sharedStream(httpRequest: HTTPRequest) async throws -> AsyncShareSequenceOfData {
        guard let connection = openConnections[httpRequest.url]?.sharedStream else {
            print("SSEConnection - Creating new connection for url: \(String(describing: httpRequest.url))")
            return try openConnection(httpRequest: httpRequest)
        }

        print("SSEConnection - Using existing connection for url: \(String(describing: httpRequest.url)))")
        return connection
    }

    /// - Requests a connection from the data provider
    /// - Iterates over the data provider's stream in a new task.
    /// - Uses the newly created subject to send values.
    /// - Exposes an AsyncSharedStream based on the subject that serves as the root for all child pipelines pinned to this one connection.
    /// - Means that we only ever have ONE connection, but exposes multiple AsyncStreams from that connection.
    /// - The shared stream is like the trunk of a tree and each branch is a new async stream.
    private func openConnection(httpRequest: HTTPRequest) throws -> AsyncShareSequenceOfData {
        // Otherwise, create a new connection
        let connection = try dataProvider.sseConnection(httpRequest) // data provider
        let subject = SubjectOfData()
        let asyncShareSequence = subject.share()
        let urlKey = httpRequest.url

        // Need a way to cancel this task although
        let task = Task {
            for try await value in connection { subject.send(value) }

            print("SSEConnection - URL Connection closed")

            // data provider connection has finished, so clear connection
            subject.send(.finished)
            openConnections[urlKey]?.task.cancel()
            openConnections[urlKey] = nil
        }

        // Create the broadcast and store it
        openConnections[urlKey] = .init(
            subject: subject,
            sharedStream: asyncShareSequence,
            task: task
        )

        return asyncShareSequence
    }
}

extension SSEService: DependencyModeKey {
    public static let live: SSEService = .init(dataProvider: .default)

    public static let mock: SSEService = .init(
        dataProvider: .init(
            sseConnection: { _ in AsyncThrowingStream<Data, Error>.makeStream().stream }
        )
    )

    public static let mockError: SSEService = .init(
        dataProvider: .init(
            sseConnection: { _ in throw MockError() }
        )
    )
}
