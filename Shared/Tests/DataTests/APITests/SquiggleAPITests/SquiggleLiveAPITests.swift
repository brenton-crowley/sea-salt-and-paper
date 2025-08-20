@testable import API
@testable import SharedBundle
@testable import SharedNetworking
import ConcurrencyExtras
import Foundation
import HTTPTypes
import IssueReporting
import Testing

extension SquiggleLiveAPI.DataProvider {
    fileprivate static var mockTest: Self {
        .init(
            baseURL: unimplemented("\(Self.self) called but not set", placeholder: nil),
            streamOfSquiggleEventUpdates: unimplemented("\(Self.self) called but not set", placeholder: .finished())
        )
    }
}

struct SquiggleLiveAPITests {
    private struct MockError: Error {}

    @Test("Success - Data provider's make() method")
    func dataProviderSuccess() async throws {
        // GIVEN
        let testSubject = SquiggleLiveAPI.DataProvider.make(
            sseService: SSEService(
                dataProvider: .init(
                    sseConnection: { _ in
                        AsyncThrowingStream<Data, Error> { cont in
                            _ = Data.mockGamesData.map { cont.yield($0) }
                            cont.finish()
                        }
                    }
                )
            ),
            mainBundle: .squiggleMock
        )

        // THEN
        #expect(testSubject.baseURL() == URL(string: .mockBaseURLString))

        // Test the mapping of the async stream
        for try await updates in try await testSubject.streamOfSquiggleEventUpdates(.squiggleMock()) {
            for value in updates {
                #expect(value.event == .mockEventDataString)
                #expect(value.id == .mockIDDataString)
                #expect(value.dataString == .mockGamesSuccessDataString)
            }
        }
    }

    @Test("Success - Data provider's make() method text event games frist message")
    func dataProviderSuccessGamesFirstMessage() async throws {
        // GIVEN
        let testSubject = SquiggleLiveAPI.DataProvider.make(
            sseService: SSEService(
                dataProvider: .init(
                    sseConnection: { _ in
                        AsyncThrowingStream<Data, Error> { cont in
                            _ = Data.mockFirstGamesData.map { cont.yield($0) } // Mock first message
                            cont.finish()
                        }
                    }
                )
            ),
            mainBundle: .squiggleMock
        )

        // THEN
        #expect(testSubject.baseURL() == URL(string: .mockBaseURLString))

        // Test the mapping of the async stream
        for try await updates in try await testSubject.streamOfSquiggleEventUpdates(.squiggleMock()) {
            for value in updates {
                #expect(value.event == .mockEventDataString)
                #expect(value.id == .mockIDDataString)
                #expect(value.dataString == .mockGamesFirstMessageDataString)
            }
        }
    }

    @Test("Nil - Data provider's make() method")
    func dataProviderError() async throws {
        // GIVEN
        let testSubject = SquiggleLiveAPI.DataProvider.make(
            sseService: SSEService(
                dataProvider: .init(
                    sseConnection: { _ in
                        AsyncThrowingStream<Data, Error> { cont in
                            cont.yield(Data()) // no update should propagate
                            cont.finish()
                        }
                    }
                )
            ),
            mainBundle: .squiggleMock
        )

        // THEN
        #expect(testSubject.baseURL() == URL(string: .mockBaseURLString))

        // Test the mapping of the async stream
        for try await _ in try await testSubject.streamOfSquiggleEventUpdates(.squiggleMock()) {
            Issue.record("No updates should be received")
        }
    }

    @Test("Success - Data Provider Stream of game updates")
    func streamOfGameUpdatesSuccess() async throws {
        // GIVEN
        let mockEvent = SquiggleAPI.Event.mock()
        var testSubject = SquiggleLiveAPI.DataProvider.mockTest
        testSubject.streamOfSquiggleEventUpdates = { _ in
            .init {
                $0.yield([mockEvent])
                $0.finish()
            }
        }
       
        // WHEN
        for try await updates in try await testSubject.streamOfSquiggleEventUpdates(.squiggleMock()) {
            for value in updates {
                // THEN
                #expect(value.event == mockEvent.event)
                #expect(value.id == mockEvent.id)
                #expect(value.dataString == mockEvent.dataString)
            }
        }
    }

    @Test("Error - Stream of event updates")
    func streamOfEventError() async throws {
        // GIVEN
        let testSubject = SquiggleLiveAPI(
            dataProvider: .init(
                baseURL: { URL(string: .mockBaseURLString) },
                streamOfSquiggleEventUpdates: { _ in
                    .init { $0.finish(throwing: MockError()) }
                }
            )
        )

        // WHEN
        await #expect(
            throws: MockError.self,
            performing: {
                for try await _ in try await testSubject.streamOfEventUpdates(.test) {}
            }
        )
    }

    @Test("Error - Stream of games status updates")
    func streamOfGameUpdatesError() async throws {
        // GIVEN
        let testSubject = SquiggleLiveAPI(
            dataProvider: .init(
                baseURL: { URL(string: .mockBaseURLString) },
                streamOfSquiggleEventUpdates: { _ in
                    .init { $0.finish(throwing: MockError()) }
                }
            )
        )

        // WHEN
        await #expect(
            throws: MockError.self,
            performing: {
                for try await _ in try await testSubject.streamOfGameStatusUpdates(.test) {}
            }
        )
    }
}

extension SSEService {
    fileprivate static let squiggleLiveGamesMock: SSEService = SSEService(
        dataProvider: .init(
            sseConnection: { _ in .mockGamesThrowingStream }
        )
    )
}

extension SharedBundle {
    fileprivate static let squiggleMock = SharedBundle(
        dataProvider: .init(
            infoDictionary: {
                [
                    SharedBundle.InfoProperty.squiggleBaseURL.key: String.mockBaseURLString
                ]
            },
            url: { _, _ in nil }, // unused
            identifier: { nil } // unused
        )
    )
}

extension HTTPRequest {
    private struct MockError: Error {}
    fileprivate static func squiggleMock() throws -> Self {
        guard let url = URL(string: .mockBaseURLString) else { throw MockError() }

        return .init(url: url)
    }
}

extension AsyncThrowingStream where Element == Data, Failure == Error {
    fileprivate static let mockGamesThrowingStream = Self { continuation in
        _ = Data.mockGamesData.map { continuation.yield($0) }
    }
}

extension Data {
    fileprivate static let mockGamesData: Data? = {
            """
            event:\(String.mockEventDataString)
            id:\(String.mockIDDataString)
            data:\(String.mockGamesSuccessDataString)
            """
            .data(using: .utf8)
    }()

    fileprivate static let mockFirstGamesData: Data? = {
            """
            retry:2000
            
            event:\(String.mockEventDataString)
            id:\(String.mockIDDataString)
            data:\(String.mockGamesFirstMessageDataString)
            
            event:message
            id:19b41f0d-6451-4d7c-8424-fb46a6229cba
            data:"Hello and welcome to the games list channel."
            """
            .data(using: .utf8)
    }()
}

extension String {
    fileprivate static let mockBaseURLString = "http://mock-base.url"

    fileprivate static let mockEventDataString = "games"
    fileprivate static let mockIDDataString = "d8013623"
    fileprivate static let mockGamesSuccessDataString = """
        [{ "id":8706, "year":2022, "round":5, "hteam":10, "ateam":7, "date":"2022-04-18T05:20:00.000Z", "tz":"+10:00", "complete":64, "winner":null, "hscore":64, "ascore":62, "hgoals":10, "hbehinds":4, "agoals":9, "abehinds":8, "venue":"M.C.G.", "timestr":"Q3 17:49", "updated":"2022-04-18T07:08:02.000Z", "is_final":0,"is_grand_final":0 }]
        """

    fileprivate static let mockGamesFirstMessageDataString = "[]"
}
