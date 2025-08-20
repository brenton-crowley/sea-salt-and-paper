import Foundation

extension SharedFileStorage {
    struct DataProvider: Sendable {
        let directoryURL: URL
        let load: @Sendable (_ url: URL) throws -> Data
        let save: @Sendable (_ value: Data, _ toURL: URL) throws -> Void

        static func make(defaultDirectory: URL) -> Self {
            .init(
                directoryURL: defaultDirectory,
                load: { try Data(contentsOf: $0) },
                save: { try $0.write(to: $1) }
            )
        }
    }
}

extension SharedFileStorage.Config {
    var dataProvider: SharedFileStorage.DataProvider {
        switch self {
        case .documentsDirectory: .documentsDirectory
        }
    }
}

extension SharedFileStorage.DataProvider {
    static let documentsDirectory: Self = .make(defaultDirectory: .documentsDirectory)
}

