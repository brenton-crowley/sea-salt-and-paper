@testable import Repositories
import AsyncExtensions
import Foundation
import HTTPTypes
import SharedNetworking
import Testing

struct LiveScoreRepositoryTests {
    private struct Mocks: Sendable {
        var baseURL: URL? = URL(string: "http://mock-base.url")
        var streamOfGameUpdates = AsyncThrowingStream<[LiveUpdate.GameStatusKind], Error>.makeStream()
        var streamOfLiveUpdates = AsyncThrowingStream<[LiveUpdate.EventKind], Error>.makeStream()
        var gateConnectionTimeout = Duration.seconds(0.05)
    }

    private func makeTestSubject(mocks: Mocks = .init()) -> LiveScoreRepository {
        LiveScoreRepository(
            dataProvider: .init(
                streamOfGameUpdates: { _ in
                    defer { mocks.streamOfGameUpdates.continuation.yield([]) }
                    return mocks.streamOfGameUpdates.stream
                },
                streamOfLiveUpdates: { _ in mocks.streamOfLiveUpdates.stream },
                gateConnectionFirstValueTimeout: { mocks.gateConnectionTimeout }
            ),
            config: .events
        )
    }

    @Test("Nil - No last game update for game id")
    func lastLiveUpdateNilForGameID() async throws {
        // GIVEN
        let gameID = 0
        let mocks = Mocks()
        let testSubject = makeTestSubject(mocks: mocks)

        // WHEN
        let result = try await testSubject.lastLiveUpdate(gameID: gameID)

        // THEN
        #expect(result == nil)
    }

    @Test("Success - Live game update for ID when requested")
    func lastLiveUpdateExistsForGameID() async throws {
        // GIVEN
        let gameID = 0
        let mockGameUpdates = AsyncThrowingStream<[LiveUpdate.GameStatusKind], Error>.makeStream()
        let mocks = Mocks(streamOfGameUpdates: mockGameUpdates)
        let testSubject = LiveScoreRepository(
            dataProvider: .init(
                streamOfGameUpdates: { _ in
                    // after we return the stream, yield an update with a valid live game
                    defer {
                        mockGameUpdates.continuation.yield([.games(
                            [.mock(id: gameID, complete: nil)]
                        )])
                    }
                    return mockGameUpdates.stream
                },
                streamOfLiveUpdates: { _ in mocks.streamOfLiveUpdates.stream },
                gateConnectionFirstValueTimeout: { mocks.gateConnectionTimeout }
            ),
            config: .events
        )

        // WHEN
        let result = try await testSubject.lastLiveUpdate(gameID: gameID)

        // THEN
        let expectedGame: Game = .mock(id: gameID, complete: nil)

        #expect(result == .mock(gameID: gameID, update: [.game(expectedGame)]))
        try await #expect(testSubject.gameUpdatesAvailable(gameID: gameID) == true)
    }

    @Test("Success - Map LiveScoreEventUpdateKind")
    func liveScoreEventUpdateKindMappings() async throws {
        // GIVEN
        let gameID = 0
        let mocks = Mocks()
        let (mockStream, mockContinuation) = AsyncThrowingStream<[LiveUpdate.EventKind], Error>.makeStream()
        let testSubject = LiveScoreRepository(
            dataProvider: .init(
                streamOfGameUpdates: { _ in mocks.streamOfGameUpdates.stream },
                streamOfLiveUpdates: { _ in mockStream },
                gateConnectionFirstValueTimeout: { mocks.gateConnectionTimeout }
            ),
            config: .test
        )

        // Send mock updates
        let _ = Task {
            mockContinuation.yield([.game(.mock(id: gameID, complete: nil))])
            mockContinuation.yield([.complete(.mock(gameID: gameID))])
            mockContinuation.yield([.score(.mock(gameID: gameID))])
            mockContinuation.yield([.time(.mock(gameID: gameID))])
            mockContinuation.yield([.winner(.mock(gameID: gameID))])

            mockContinuation.finish()
        }

        // WHEN - A live update value is received
        for try await value in try await testSubject.streamOfLiveScoreUpdates(gameID: 0) {
            // THEN - Should equal the one that's sent from the mock async stream
            for updateKind in value.updateKinds {
                switch updateKind {
                case let .game(gameUpdate): #expect(gameUpdate == .mock(id: gameID, complete: nil))
                case let .complete(completeUpdate): #expect(completeUpdate == .mock(gameID: gameID))
                case let .score(scoreUpdate): #expect(scoreUpdate == .mock(gameID: gameID))
                case let .winner(winnerUpdate): #expect(winnerUpdate == .mock(gameID: gameID))
                case let .time(timeUpdate): #expect(timeUpdate == .mock(gameID: gameID))
                }
            }
        }
    }

    // Write a test that has two updates in an array,
    // and check that the changes are merged into one update
}

extension Array where Element == Game {
    fileprivate static func mock(gameID: Int = 0) -> Self {
        [.mock(id: gameID, complete: nil)]
    }
}

extension Data {
    private struct MockError: Error {}

    fileprivate func jsonString() throws -> String {
        guard let json = String(data: self, encoding: .utf8) else { throw MockError() }
        return json
    }

    fileprivate static func gameStatusGames(_ liveGameID: Int) throws -> Self {
        try LiveUpdate.GameStatusKind.games([.mock(id: liveGameID, complete: nil)]).mockData()
    }
}

extension LiveUpdate.EventKind {
    private struct MockError: Error {}

    fileprivate func mockData() throws -> Data {
        let dataString = switch self {
        case .game: try mockLiveUpdateDataString()
        case .complete: try mockLiveUpdateDataString()
        case .time: try mockLiveUpdateDataString()
        case .score: try mockLiveUpdateDataString()
        case .winner: try mockLiveUpdateDataString()
        }

        guard let data = dataString.data(using: .utf8) else { throw MockError() }

        return data
    }

    fileprivate func mockLiveUpdateDataString() throws -> String {
        let (eventName, updateJSON) = switch self {
        case let .game(update): ("game", try JSONEncoder().encode(update).jsonString())
        case let .complete(update): ("complete", try JSONEncoder().encode(update).jsonString())
        case let .time(update): ("time", try JSONEncoder().encode(update).jsonString())
        case let .score(update): ("score", try JSONEncoder().encode(update).jsonString())
        case let .winner(update): ("winner", try JSONEncoder().encode(update).jsonString())
        }

        return """
        event:\(eventName)
        id:abcd1234
        data:\(updateJSON)
        """
    }
}

extension LiveUpdate.GameStatusKind {
    private struct MockError: Error {}

    fileprivate func mockData() throws -> Data {
        let dataString = switch self {
        case .games: try mockLiveUpdateDataString()
        case .gameAdded: try mockLiveUpdateDataString()
        case .gameRemoved: try mockLiveUpdateDataString()
        }

        guard let data = dataString.data(using: .utf8) else { throw MockError() }

        return data
    }

    fileprivate func mockLiveUpdateDataString() throws -> String {
        let (eventName, updateJSON) = switch self {
        case let .games(update): ("games", try JSONEncoder().encode(update).jsonString())
        case let .gameAdded(update): ("addedGame", try JSONEncoder().encode(update).jsonString())
        case let .gameRemoved(update): ("removedGame", try JSONEncoder().encode(update).jsonString())
        }

        return .mockUpdateString(eventName: eventName, updateJSONString: updateJSON)
    }
}

extension String {
    fileprivate static func mockUpdateString(eventName: String, updateJSONString: String) -> Self {
        """
        event:\(eventName)
        id:abcd1234
        data:\(updateJSONString)
        """
    }
}
