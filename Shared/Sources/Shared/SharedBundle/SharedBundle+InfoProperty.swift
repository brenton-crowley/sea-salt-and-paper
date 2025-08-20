import Foundation

extension SharedBundle {
    public enum InfoProperty {
        case squiggleBaseURL
        case squiggleAssetURL
        case jsonPlaceholderBaseURL

        var key: String {
            switch self {
            case .squiggleBaseURL: "SQUIGGLE_BASE_URL"
            case .squiggleAssetURL: "SQUIGGLE_ASSET_URL"
            case .jsonPlaceholderBaseURL: "JSON_PLACEHOLDER_BASE_URL"
            }
        }
    }
}

// MARK: - Public API
extension SharedBundle {
    public func infoValue(for property: InfoProperty) -> Any? {
        dataProvider.infoDictionary()?[property.key]
    }

    public func baseURL(for property: InfoProperty) -> URL? {
        .init(bundle: self, infoProperty: property)
    }
}

// MARK: - Extensions

extension URL {
    package static func squiggleAPIBaseURL(bundle: SharedBundle) -> URL? {
        .init(bundle: bundle, infoProperty: .squiggleBaseURL)
    }

    fileprivate init?(bundle: SharedBundle, infoProperty: SharedBundle.InfoProperty) {
        guard let urlString = bundle.infoValue(for: infoProperty) as? String else { return nil }

        self.init(string: urlString)
    }
}
