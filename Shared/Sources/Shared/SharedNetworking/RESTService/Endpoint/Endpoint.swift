import Foundation
import HTTPTypes

public struct Endpoint<Response>: Sendable {
    public let method: HTTPRequest.Method
    public let path: String
    public let queryItems: [URLQueryItem]
    public let headers: HTTPFields
    public let body: Data?

    public init(
        method: HTTPRequest.Method,
        path: String,
        queryItems: [URLQueryItem],
        headers: HTTPFields,
        body: Data?
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }
}

extension Endpoint {
    public func request(baseURL: URL?) throws -> HTTPRequest {
        guard let baseURL else { throw URLError(.badURL) }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = path
        if !queryItems.isEmpty { components.queryItems = queryItems }

        guard let url = components.url else { throw URLError(.badURL) }

        return .init(
            method: method,
            url: url,
            headerFields: headers
        )
       
        // return .init(
        //     method: method,
        //     scheme: url.scheme ?? "https",
        //     authority: url.host(),
        //     path: url.path() + (url.query() ?? ""),
        //     headerFields: headers
        // )
    }
}

// extension URL {
//     static var teams: Self {
//         var components = URLComponents()
//         components.scheme = "https"
//         components.host = "api.squiggle.com.au"
//         components.path = "/"
//         components.queryItems = [.teams]
// 
//         guard let url = components.url else { fatalError("Could not build URL") }
// 
//         return url
//     }
// }
// 
// extension HTTPRequest {
//     static let teamsEndpoint: Self = .init(
//         method: .get,
//         url: .teams,
//         headerFields: .teams
//     )
// }
