import IssueReporting

public struct Command<S>: Sendable {
    var _execute: @Sendable (inout S) -> Void
    var _executeAsync: @Sendable (inout S) async -> Void
    var _undo: @Sendable (inout S) -> Void
    var _undoAsync: @Sendable (inout S) async -> Void

    public init(
        execute: @Sendable @escaping (inout S) -> Void,
        undo: @Sendable @escaping (inout S) -> Void = unimplemented("\(#function) - Undo called but not implemented"),
        executeAsync: @Sendable @escaping (inout S) async -> Void = unimplemented("\(#function) - ExecuteAsync called but not implemented"),
        undoAsync: @Sendable @escaping (inout S) async -> Void = unimplemented("\(#function) - UndoAsync called but not implemented")

    ) {
        _execute = execute
        _undo = undo
        _executeAsync = executeAsync
        _undoAsync = undoAsync
    }

    public func execute(on state: inout S) {
        _execute(&state)
    }

    public func execute(on state: inout S) async {
        await _executeAsync(&state)
    }

    public func undo(on state: inout S) {
        _undo(&state)
    }

    public func undo(on state: inout S) async {
        await _undoAsync(&state)
    }
}

public struct ThrowingCommand<S>: Sendable {
    var _execute: @Sendable (inout S) throws -> Void
    var _executeAsync: @Sendable (inout S) async throws -> Void
    var _undo: @Sendable (inout S) throws -> Void
    var _undoAsync: @Sendable (inout S) async throws -> Void

    public init(
        execute: @Sendable @escaping (inout S) throws -> Void,
        undo: @Sendable @escaping (inout S) throws -> Void = unimplemented("\(#function) - Undo called but not implemented"),
        executeAsync: @Sendable @escaping (inout S) async throws -> Void = unimplemented("\(#function) - ExecuteAsync called but not implemented"),
        undoAsync: @Sendable @escaping (inout S) async throws -> Void = unimplemented("\(#function) - UndoAsync called but not implemented")

    ) {
        _execute = execute
        _undo = undo
        _executeAsync = executeAsync
        _undoAsync = undoAsync
    }

    public func execute(on state: inout S) throws {
        try _execute(&state)
    }

    public func execute(on state: inout S) async throws {
        try await _executeAsync(&state)
    }

    public func undo(on state: inout S) throws {
        try _undo(&state)
    }

    public func undo(on state: inout S) async throws {
        try await _undoAsync(&state)
    }
}
