import ConcurrencyExtras
import Foundation
import SharedDependency

public struct SharedFileStorage: Sendable {
    public enum Config {
        case documentsDirectory
    }

    let dataProvider: Self.DataProvider
}

// MARK: - Public API

extension SharedFileStorage {
    // public endpoints
    public func load<Value: Codable>(path: String) throws -> Value? {
        try JSONDecoder().decode(Value.self, from: dataProvider.load(dataProvider.directoryURL.appending(path: path)))
    }

    public func save<Value: Codable>(_ value: Value, path: String) throws {
        try dataProvider.save(JSONEncoder().encode(value), dataProvider.directoryURL.appending(path: path))
    }
}

extension SharedFileStorage: DependencyModeKey
 {
    public static func live(_ config: Config) -> Self {
        .init(dataProvider: config.dataProvider)
    }

    public static let live: Self = .init(dataProvider: .documentsDirectory)

    public static let mock: Self = .test

    public static let mockError: Self = .init(
        dataProvider: .init(
            directoryURL: SharedFileStorage.mock.dataProvider.directoryURL,
            load: { _ in throw MockError() },
            save: { _, _ in throw MockError() }
        )
    )
    
    /// Uses a lock isolated dictionary as its temporary storage.
    ///
    /// # Discussion
    /// - Best for usage in tests so actual data is not persisted to disk.
    /// - Returns a new instance each time it's called to support running tests repeatedly.
    /// - If a temporary AND persistent version is needed, store a static member in the test suite  or use ``mock``.
    public static var test: Self {
        let fileSystem = LockIsolated<[URL: Data]>([:])

        return .init(
            dataProvider: .init(
                directoryURL: URL(string: "file:///dictionary-directory/")!,
                load: { url in
                    guard let data = fileSystem[url] else {
                        struct MockLoadError: Error{}
                        throw MockLoadError()
                    }
                    return data
                },
                save: { value, url in fileSystem.withValue { $0[url] = value } }
            )
        )
    }
}

