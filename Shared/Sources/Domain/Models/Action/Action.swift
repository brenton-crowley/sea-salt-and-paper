import Foundation

public struct Action<S>: Sendable {
    var _rule: @Sendable () -> ValidationRule<S>
    var _command: @Sendable () -> ThrowingCommand<S>

    public init(rule: @Sendable @escaping () -> ValidationRule<S>, command: @Sendable @escaping () -> ThrowingCommand<S>) {
        _rule = rule
        _command = command
    }
}

extension Action {
    public func isValid(on input: S) -> Bool {
        _rule().validate(on: input)
    }

    public func execute(on input: inout S) throws {
        try _command().execute(on: &input)
    }
}
