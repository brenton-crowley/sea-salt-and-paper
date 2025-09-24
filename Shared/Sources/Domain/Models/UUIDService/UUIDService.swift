import Foundation

public struct UUIDService: Sendable {
    struct DataProvider: Sendable {
        var id: @Sendable () -> UUID
    }

    let dataProvider: Self.DataProvider

    public func generateUUID() -> UUID {
        return dataProvider.id()
    }
}

extension UUIDService {
    public static let live: Self = .init(
        dataProvider: .init(id: { UUID() })
    )

    #if DEBUG

    public enum IntValue: Int, Hashable, Sendable {
        case zero = 0, one, two, three, four, five, six, seven, eight, nine
    }

    public static func test(intValue: IntValue) -> Self {
        .init(
            dataProvider: .init(
                id: {
                    UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", intValue.rawValue))")!
                }
            )
        )
    }

    #endif
}
