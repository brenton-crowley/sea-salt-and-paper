@testable import SharedNetworking
import AsyncExtensions
import ConcurrencyExtras
import HTTPTypes
import Foundation
import Testing

struct SSEServiceTests {
    private actor UpdateReceiver {
        private(set) var receivedUpdates: [Data] = []

        func addUpdate(_ data: Data) {
            receivedUpdates.append(data)
        }
    }

    @Test(
        "Success - Calling eventUpdates returns a connection for that request",
        arguments: [
            HTTPRequest.mock(),
            .mock(.mockSSEURL(.mockSSEURLString() + "/2"))
        ]
    )
    func callingMakeStreamOpensChannelForThatStream(request: HTTPRequest) async throws {
        await withMainSerialExecutor {
            // GIVEN
            let testSubject = SSEService(dataProvider: .mock)

            // Expect no open channels
            await #expect(testSubject.openConnections.keys.isEmpty)
            await #expect(testSubject.openConnections.values.isEmpty)

            // WHEN
            _ = await testSubject.streamedData(forConnection: request)

            // THEN - A connection should be set up for the update request
            let subscriberTask = Task {
                await #expect(testSubject.openConnections.keys.first == request.url)
                await #expect(testSubject.openConnections.values.first != nil)
            }

            await subscriberTask.value
        }
    }

    @Test("Success - Call make stream with multiple unique http requests generates a channel for each request")
    func callingMakeStreamOpensChannelForThatStream() async throws {
        // GIVEN
        let requests = [HTTPRequest.mock(), .mock(.mockSSEURL(.mockSSEURLString() + "/2"))]
        let testSubject = SSEService(dataProvider: .mock)

        // Expect no open channels
        await #expect(testSubject.openConnections.keys.isEmpty)
        await #expect(testSubject.openConnections.values.isEmpty)

        // WHEN
        for request in requests {
            _ = await testSubject.streamedData(forConnection: request)
        }

        // THEN - We should have two channels
        let expectationTask = Task {
            let keys = Set(await testSubject.openConnections.keys.map(\.?.absoluteURL))
            let connections = await testSubject.openConnections.values.map(\.self)
            #expect(keys == Set(requests.map(\.url)))
            #expect(connections.count == 2)
        }

        await expectationTask.value
    }

    @Test(
        "Success - Making a stream and finishing continuation leaves channel open.",
        arguments: [
            HTTPRequest.mock(),
            .mock(.mockSSEURL(.mockSSEURLString() + "/2"))
        ]
    )
    func callingMakeStreamThenCancelling(request: HTTPRequest) async throws {
        // GIVEN
        let testSubject = SSEService(dataProvider: .mock)

        // Expect no open channels
        await #expect(testSubject.openConnections.keys.isEmpty)
        await #expect(testSubject.openConnections.values.isEmpty)

        // WHEN
        let (_, terminateConnection) = await testSubject.streamedData(forConnection: request)

        // THEN - Cancelling the continuation of the stream, leaves the channel open
        let expectationTask = Task {
            terminateConnection()

            await #expect(testSubject.openConnections.keys.first == request.url)
            await #expect(testSubject.openConnections.values.first != nil)
        }

        await expectationTask.value
    }

    @Test("Success - Duel subscribers to channel receive same updates.")
    func duelConnectionToChannel() async throws {
        await withMainSerialExecutor {
            // GIVEN
            let mockSSEConnection = AsyncThrowingStream<Data, Error>.makeStream()
            let request: HTTPRequest = .mock()
            let testSubject = SSEService(dataProvider: .init(
                sseConnection: { _ in mockSSEConnection.stream }
            ))

            // Expect no open channels
            await #expect(testSubject.openConnections.keys.isEmpty)
            await #expect(testSubject.openConnections.values.isEmpty)

            // WHEN
            let consumer1 = await testSubject.streamedData(forConnection: request)
            let consumer2 = await testSubject.streamedData(forConnection: request)

            // THEN - Just one connection for the two subscribers
            let openConnectionExpectationTask = Task {
                await #expect(testSubject.openConnections.keys.count == 1)
                await #expect(testSubject.openConnections.keys.first == request.url)
            }

            await openConnectionExpectationTask.value

            // Set up some subscribers
            let updateReceiver1 = UpdateReceiver()
            let consumer1Task = Task {
                for await update in consumer1.stream {
                    await updateReceiver1.addUpdate(update)
                }
            }

            let updateReceiver2 = UpdateReceiver()
            let consumer2Task = Task {
                for await update in consumer2.stream {
                    await updateReceiver2.addUpdate(update)
                }
            }

            // Set up the mock updates to send
            let mockUpdates = [Data(), Data()]
            let updatesTask = Task {
                mockUpdates.forEach { mockSSEConnection.continuation.yield($0) }
                mockSSEConnection.continuation.finish()
            }

            // Wait for the async tasks to complete
            await updatesTask.value
            await consumer1Task.value
            await consumer2Task.value

            // THEN - Expect each received updates to have same sequence as origin
            await #expect(updateReceiver1.receivedUpdates == mockUpdates)
            await #expect(updateReceiver2.receivedUpdates == mockUpdates)
        }
    }

    @Test("Success - Send finish update before events")
    func earlyFinishConnection() async throws {
        try await withMainSerialExecutor {
            // GIVEN
            let mockSSEConnection = AsyncThrowingStream<Data, Error>.makeStream()
            let request: HTTPRequest = .mock()
            let testSubject = SSEService(dataProvider: .init(
                sseConnection: { _ in mockSSEConnection.stream }
            ))

            // WHEN
            let subscriber = await testSubject.streamedData(forConnection: request)

            // Set up some subscribers
            let subscriberUpdates = UpdateReceiver()
            let subscriberTask = Task {
                for await update in subscriber.stream {
                    await subscriberUpdates.addUpdate(update)
                }
            }

            // Set up the mock updates to send
            let mockUpdates = [Data(), Data()]
            let updatesTask = Task {
                mockSSEConnection.continuation.finish()
                mockUpdates.forEach { mockSSEConnection.continuation.yield($0) } // No updates should be sent
            }

            // Wait for the async tasks to complete
            await updatesTask.value
            await subscriberTask.value
            try await testSubject.openConnections[request.url]?.task.value

            // THEN - Connection closed and only received the one update
            await #expect(subscriberUpdates.receivedUpdates.isEmpty)
            await #expect(testSubject.openConnections[request.url] == nil)
        }
    }
}

// MARK: - Mock values

extension String {
    fileprivate static func mockSSEURLString(_ value: String = "https://mock.com/sse") -> Self {
        value
    }
}

extension URL {
    fileprivate static func mockSSEURL(_ urlString: String = .mockSSEURLString()) -> Self {
        .init(string: urlString)!
    }
}

extension HTTPRequest {
    fileprivate static func mock(_ url: URL = .mockSSEURL(.mockSSEURLString())) -> Self {
        .init(url: url)
    }
}

extension SSEService.DataProvider {
    fileprivate static let mock: Self = .init(
        sseConnection: { _ in AsyncThrowingStream<Data, Swift.Error>.makeStream().stream }
    )
}
