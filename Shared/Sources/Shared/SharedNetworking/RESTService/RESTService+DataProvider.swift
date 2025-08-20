import Foundation
import HTTPTypes
import HTTPTypesFoundation

extension RESTService {
    /// The dependencies that ``RESTService`` requires to be fulfilled.
    ///
    /// Any object that `RESTService` cannot control ought to be generalised and placed into this data provider.
    /// This allows us to create **live** and **mocked** default implementations.
    struct DataProvider: Sendable {
        /// Match with the signature of ``URLSession.data(for:)`` to fulfil this requirement.
        let data: @Sendable (_ httpRequest: HTTPRequest) async throws -> (data: Data, response: HTTPResponse)

        static func make(urlSession: URLSession) -> Self {
            return .init(data: urlSession.data(for:))
        }
    }
}

extension RESTService.Config {
    var dataProvider: RESTService.DataProvider {
        switch self {
        case .default: .default
        case .ephemeralURLSession: .ephemeral
        case let .delegate(delegate): .delegate(delegate)
        case .useProtocolCachePolicy: .useProtocolCachePolicy
        }
    }
}

extension RESTService.DataProvider {
    static let `default`: Self = .make(urlSession: .shared)

    static let ephemeral: Self = .make(urlSession: .init(configuration: .ephemeral))

    static func delegate(_ delegate: URLSessionDataDelegate) -> Self {
        .make(urlSession: .init(
            configuration: .default,
            delegate: delegate,
            delegateQueue: nil)
        )
    }

    static let useProtocolCachePolicy: Self = {
        var configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = .imageCache

        let urlSession = URLSession(configuration: configuration)

        return .make(urlSession: urlSession)
    }()
}

extension URLCache {
    fileprivate static let imageCache = URLCache(
        memoryCapacity: 512_000_000,
        diskCapacity: 10_000_000_000
    )
}
