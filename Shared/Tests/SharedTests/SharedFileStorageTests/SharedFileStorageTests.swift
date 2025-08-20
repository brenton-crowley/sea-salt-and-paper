@testable import SharedFileStorage
import Testing

struct SharedFileStorageTests {
    private struct MockModel: Codable, Hashable {
        let id: Int
    }

    @Test("Error - Load data from a url that doesn't exist.")
    func loadDataError() throws {
        // GIVEN
        let testSubject = SharedFileStorage.test

        // WHEN
        #expect(throws: (any Error).self, performing: {
            let _: MockModel? = try testSubject.load(path: .mockPath)
        })
    }

    @Test("Success - Save data to a url doesn't throw")
    func saveDataSuccess() throws {
        // GIVEN
        let model = MockModel(id: 1)
        let testSubject = SharedFileStorage.test

        // WHEN
        try testSubject.save(model, path: .mockPath)
    }

    @Test("Success - Save data to a url then load data from the same URL")
    func loadDataSuccess() throws {
        // GIVEN
        let model = MockModel(id: 1)
        let testSubject = SharedFileStorage.test

        // WHEN
        try testSubject.save(model, path: .mockPath)
        let result: MockModel? = try testSubject.load(path: .mockPath)

        // THEN
        #expect(result == model)
    }

    @Test("Error - Live value does not contain mock path")
    func loadDataErrorWithLiveValue() throws {
        // GIVEN
        let testSubject = SharedFileStorage.live

        // WHEN
        #expect(throws: (any Error).self, performing: {
            let _: MockModel? = try testSubject.load(path: .mockPath)
        })
    }
}

extension String {
    fileprivate static let mockPath = "mockPath"
}
