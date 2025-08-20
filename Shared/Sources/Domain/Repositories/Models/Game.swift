import Foundation

// MARK: - Definition

public struct Game: Codable, Hashable, Sendable {
    public let id: Int
    public let round: Int
    public let homeTeamID: Int?
    public let awayTeamID: Int?
    public let date: String
    public let year: Int
    public let timezone: String?
    public let timeValue: String?
    public let roundName: String?
    public let updated: String?
    public let homeScore: Int?
    public let complete: Int?
    public let awayGoals: Int?
    public let awayBehinds: Int?
    public let awayTeamName: String?
    public let unixTime: Int?
    public let localTime: String?
    public let venue: String?
    public let homeTeamName: String?
    public let homeBehinds: Int?
    public let homeGoals: Int?
    public let awayScore: Int?
    public let winnerTeamID: Int?
    public let isFinal: Bool?
    public let winner: String?
    public let isGrandFinal: Bool?
}

// MARK: - Computed Properties

extension Game {}

// MARK: - Mapping

extension Game {
}

// MARK: - Mocks

#if DEBUG

extension Game {
    public static func mock(id: Int = 0, homeTeamID: Int = 1, awayTeamID: Int = 2, complete: Int? = 100) -> Self {
        .init(
            id: id,
            round: 5,
            homeTeamID: homeTeamID,
            awayTeamID: awayTeamID,
            date: "2025-06-19 20:10:00",
            year: 2025,
            timezone: "+10:00",
            timeValue: "Full Time",
            roundName: "Round 15",
            updated: "2025-06-19 22:49:02",
            homeScore: 104,
            complete: complete,
            awayGoals: 9,
            awayBehinds: 9,
            awayTeamName: "Essendon",
            unixTime: 1750327800,
            localTime: "2025-06-19 18:10:00",
            venue: "Perth Stadium",
            homeTeamName: "Fremantle",
            homeBehinds: 8,
            homeGoals: 16,
            awayScore: 63,
            winnerTeamID: 6,
            isFinal: false,
            winner: "Fremantle",
            isGrandFinal: false
        )
    }
}

extension Array where Element == Game {
    public static let mockGames: Self = [
        .mock(id: 0, homeTeamID: 1, awayTeamID: 2)
    ]
}

#endif

