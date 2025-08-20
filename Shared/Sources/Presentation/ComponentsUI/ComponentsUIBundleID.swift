import Foundation
import SharedBundle

public struct ComponentsUIModule: Sendable {
    public static let bundle = Bundle.module

    public static func pngURL(name: String) -> URL? {
        bundle.url(forResource: name, withExtension: "png")
    }
}
