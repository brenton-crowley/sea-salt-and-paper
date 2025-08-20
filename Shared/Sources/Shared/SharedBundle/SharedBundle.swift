import Foundation
import SharedDependency
import OSLog

public struct SharedBundle: Sendable {
    public struct DataProvider: Sendable {
        let infoDictionary: @Sendable () -> [String : Any]?
        let url: @Sendable (_ forResourceName: String?, _ withExtension: String?) -> URL?
        let identifier: @Sendable () -> String?
    }

    let dataProvider: DataProvider
}

// MARK: - Public API

extension SharedBundle {
    public var identifier: String? { dataProvider.identifier() }

    public func infoValue(key: String) -> String? {
        dataProvider.infoDictionary()?[key] as? String
    }

    public func url(forResource name: String?, withExtension ext: String?) -> URL? {
        dataProvider.url(name, ext)
    }
}

// MARK: - DependencyKeyMode Conformance

extension SharedBundle: DependencyModeKey {
    /// Use this member to reference `Bundle.main`
    public static let live: SharedBundle = .live(bundle: .main)

    /// Call this method when you need to use the bundle of a module
    public static func live(bundle: Bundle) -> Self {
        .init(
            dataProvider: .init(
                infoDictionary: { bundle.infoDictionary },
                url: bundle.url(forResource:withExtension:),
                identifier: { bundle.bundleIdentifier }
            )
        )
    }

    #if DEBUG

    public static let mock: SharedBundle = .init(
        dataProvider: .init(
            infoDictionary: { [:] },
            url: { resourceName, ext in
                guard let resourceName, let ext else { return nil }
                return URL(string: "file:///MockBundle/\(resourceName).\(ext)")
            },
            identifier: { "mock.bundle.identifier" }
        )
    )

    public static let mockError: SharedBundle = .init(
        dataProvider: .init(
            infoDictionary: { nil },
            url: { _, _ in nil },
            identifier: { nil }
        )
    )

    #endif
}
