import Foundation
import HTTPTypes
import HTTPTypesFoundation
import OSLog
import SharedDependency

public struct RESTService: Sendable {
    public enum Error: Swift.Error, Hashable {
        case invalidResponse(HTTPResponse)
        case invalidBaseURL(URL?)

        public static let notFound: Self = .invalidResponse(.init(status: .notFound))

        static func statusCode(_ statusCode: HTTPResponse.Status) -> Self {
            .invalidResponse(.init(status: statusCode))
        }
    }

    public enum Config: Sendable {
        case `default`
        case ephemeralURLSession
        case useProtocolCachePolicy
        case delegate(any URLSessionDataDelegate)
    }

    static let logger = Logger(subsystem: "SharedNetworking", category: "RESTService")

    private let dataProvider: DataProvider

    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
    }

    /// Attempts to download `Data` from the supplied `HTTPRequest`.
    ///
    /// - Throws: ``NetworkService.Error.invalidResponse`` when the status code of the response
    /// is not 2xx.
    public func data(httpRequest: HTTPRequest) async throws -> Data {
        RESTService.logger.info("Making network call: \(String(describing: httpRequest.url))")
        let (data, response) = try await dataProvider.data(httpRequest)

        guard (200..<300).contains(response.status.code) else {
            RESTService.logger.error("Error making network call: \(response.status), url: \(String(describing: httpRequest.url))")
            throw RESTService.Error.invalidResponse(response)
        }

        return data
    }

    /// Wrapping method for ``data(httpRequest:)`` that attempts to decode the data into the linked model object.
    public func model<Model>(httpRequest: HTTPRequest) async throws -> Model where Model: Decodable & Sendable {
        try JSONDecoder().decode(
            Model.self,
            from: try await data(httpRequest: httpRequest)
        )
    }

    public func model<Model>(baseURL: URL?, endpoint: Endpoint<Model>) async throws -> Model where Model: Decodable & Sendable {
        guard let baseURL else { throw RESTService.Error.invalidBaseURL(baseURL) }
   
        return try await model(httpRequest: endpoint.request(baseURL: baseURL))
    }
}

extension RESTService: DependencyModeKey {
    /// The static member whose constant value uses the pre-filled `URLSession.shared`
    ///
    /// Call this instance over the method when no custom URLSession is required.
    public static let live: Self = live(.default)

    public static let liveUsesProtocolCachePolicy: Self = live(.useProtocolCachePolicy)

    public static func live(_ config: Config) -> Self {
        .init(dataProvider: config.dataProvider)
    }

    #if DEBUG

    /// Use the static member for a success response.
    ///
    /// > Important:
    /// This will only return an empty `Data()`. If you require custom `Data`, then use another mock and pass in the object.
    public static let mock: Self = .mock(Data())

    /// Use the static member for an error response that defaults to `.notFound`.
    public static let mockError: Self = .mockError()


    /// Use when you want control the returned data of the mock. The response returns a `.ok` status code.
    /// - Parameters:
    ///   - mockData: The custom `Data` you want returned when its instance methods are called.
    /// - Returns: An instance that's ready to return the supplied `Data` when its instance methods are called.
    public static func mock(
        _ mockData: Data
    ) -> Self {
        .init(
            dataProvider: .init(
                data: { _ in (mockData, .init(status: .ok)) }
            )
        )
    }

    /// Use this mock when you want the `NetworkService` to throw an error when its instance methods are called..
    /// - Parameter networkError: Defaults to `.notFound`.
    /// - Returns: An instance that's prepared to throw the supplied error when its instance methods are called.
    public static func mockError(_ networkError: RESTService.Error = .notFound) -> Self {
        .init(
            dataProvider: .init(
                data: { _ in throw networkError }
            )
        )
    }

    /// Use this mock to pass in a model that you want to use as the return data when ``data(httpRequest:)`` is called.
    /// - Parameter mockModel: Ensure your model conforms to `Codable` so that it can be encoded as `Data`.
    /// - Returns: An instance that will return a `Data` object of the supplied model when the instance's methods are called.
    public static func mockModel<M>(_ mockModel: M) throws -> Self where M: Sendable, M: Codable {
        try .mock(JSONEncoder().encode(mockModel))
    }

    #endif
}

extension URL? {
    fileprivate static let mockBaseURL = URL(string: "https://api.example.com")
}
