// @testable import Repositories
// @testable import SharedNetworking
// @testable import SharedBundle
// import Testing
// 
// struct TeamsRepositoryTests {
//     private struct MockError: Error {}
// 
//     @Test("Success - Make with dependencies")
//     func makeMethodMappingDependencies() async throws {
//         // GIVEN
//         let testSubject = TeamsRepository(
//             dataProvider: .make(
//                 restService: try .mockModel(TeamsEndpoint.Teams.mockTeams),
//                 bundle: .mockTeams
//             )
//         )
// 
//         // WHEN
//         let result = try await testSubject.fetchTeams()
// 
//         // THEN
//         #expect(result.count == 1)
// 
//         let team = try #require(result.first)
// 
//         #expect(team.id == 0)
//         #expect(team.debut == 1)
//         #expect(team.abbreviation == "Te")
//         #expect(team.retirement == 2)
//         #expect(team.name == "Team")
//         #expect(team.logoPath == "logo.png")
//     }
// 
//     @Test("Success - Make with Convenience")
//     func convenientTestSubject() async throws {
//         // GIVEN
//         let testSubject = TeamsRepository(
//             dataProvider: .init(
//                 getTeamsResponse: { .mockTeams }
//             )
//         )
// 
//         // WHEN
//         let result = try await testSubject.fetchTeams()
// 
//         // THEN
//         #expect(result.count == 1)
// 
//         let team = try #require(result.first)
// 
//         #expect(team.id == 0)
//         #expect(team.debut == 1)
//         #expect(team.abbreviation == "Te")
//         #expect(team.retirement == 2)
//         #expect(team.name == "Team")
//         #expect(team.logoPath == "logo.png")
//     }
// 
//     @Test("Error - Fail with Convenience")
//     func convenientTestSubjectError() async throws {
//         // GIVEN
//         let testSubject = TeamsRepository(
//             dataProvider: .init(
//                 getTeamsResponse: { throw MockError() }
//             )
//         )
// 
//         // WHEN
//         await #expect(
//             throws: MockError.self,
//             performing: {
//                 _ = try await testSubject.fetchTeams()
//             }
//         )
//     }
// }
// 
// extension TeamsEndpoint.Teams {
//     fileprivate static let mockTeams: Self = .init(teams: [.mockTeam])
// }
// 
// extension TeamsEndpoint.Team {
//     fileprivate static let mockTeam: Self = .init(
//         id: 0,
//         debut: 1,
//         abbreviation: "Te",
//         retirement: 2,
//         name: "Team",
//         logoPath: "logo.png"
//     )
// }
// 
// extension SharedBundle {
//     fileprivate static let mockBaseURLString: String = "https://mock.com"
//     fileprivate static let mockBaseAssetURLString: String = "https://mockAsset.com"
// 
//     fileprivate static let mockTeams: Self = .init(
//         dataProvider: .init(
//             infoDictionary: {
//                 [
//                     SharedBundle.InfoProperty.squiggleBaseURL.key: mockBaseURLString,
//                     SharedBundle.InfoProperty.squiggleAssetURL.key: mockBaseAssetURLString
//                 ]
//             },
//             url: SharedBundle.mock.dataProvider.url
//         )
//     )
// }
