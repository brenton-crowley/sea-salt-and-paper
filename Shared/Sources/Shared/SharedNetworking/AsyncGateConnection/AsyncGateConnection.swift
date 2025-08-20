import Foundation
import BeamLog

/// Waits for a stream to open and receive the first value before resuming suspension.
public final actor AsyncGateConnection: Sendable {
    public enum State: Hashable, Sendable {
        case disconnected, connecting, connected
    }

    private(set) var state = State.disconnected
    private(set) var connectionTask: Task<(), Error>?
    private(set) var waitingContinuations: [CheckedContinuation<Void, Never>] = []

    private let logger = Logger(for: AsyncGateConnection.self)
    private let waitForFirstValueTimeoutDuration: Duration

    public init(_ waitForFirstValueTimeoutDuration: Duration) {
        self.waitForFirstValueTimeoutDuration = waitForFirstValueTimeoutDuration
    }

    deinit { connectionTask?.cancel() }
}

// MARK: - Public API

extension AsyncGateConnection {
    /// Opens a self-monitoring `AsyncStream<Value>` that suspends execution until the first value is received.
    /// - Parameters:
    ///   - stream: Supply a closure to an `AsyncStream<Value>` that will listen for values.
    ///   - onReceiveValue: Supply a handler when a value from the `AsyncStream<Value>` is received.
    ///   - resumeImmediatelyOnceConnected: When `true`, will immediately resume from its async context. When `false`, will await until the first value is received from its stream.
    ///
    /// ### Resume Immedaitely Once Connected
    /// If you have a stream where the presence of an initial value is important, then leave this value as false.
    /// However, if you want the background thread to resume as soon as the connection is made, then set this value to `true`.
    public func connectIfNeeded<Value: Sendable>(
        toStream stream: @Sendable @escaping () async throws -> AsyncThrowingStream<Value, Error>,
        onReceiveValue: @Sendable @escaping (_ value: Value) async -> Void,
        resumeImmediatelyOnceConnected: Bool = false
    ) async throws {
        switch state {
        case .disconnected:
            logger.info("1. Async gate is disconnected")
            state = .connecting
            logger.info("2. Awaiting stream")
            let stream = try await stream()
            connectionTask = Task {
                logger.info("3. Stream is connected")
                state = .connected
                if resumeImmediatelyOnceConnected {
                    clearWaitingContinuations()
                } else {
                    waitForFirstValueTimeoutThenClearContinuations()
                }
                for try await value in stream {
                    await onReceiveValue(value)
                    if hasWaitingContinuations {
                        logger.info("4. Received first value. Clear continuations.")
                        clearWaitingContinuations()
                    }
                }

                logger.info("6. Stream ended. Disconnect.")
                disconnect()
            }

            logger.info("2a. Waiting until stream is connected.")
            await waitUntilConnected()

        case .connecting:
            logger.info("2b. Waiting until stream is connected.")
            await waitUntilConnected()

        case .connected:
            logger.info("5. Stream already connected.")
            return // No action as already connected.
        }
    }
    
    /// Stops the open connection and resets the state to disconnected.
    public func disconnect() {
        connectionTask?.cancel()
        connectionTask = nil
        waitingContinuations.removeAll()
        state = .disconnected
        logger.info("Stream disconnected.")
    }
}

// MARK: - Private API

extension AsyncGateConnection {
    private var hasWaitingContinuations: Bool { !waitingContinuations.isEmpty }

    private func clearWaitingContinuations() {
        for continuation in waitingContinuations { continuation.resume() }
        waitingContinuations.removeAll()
    }

    private func waitUntilConnected() async {
        await withCheckedContinuation { waitingContinuations.append($0) }
    }

    private func waitForFirstValueTimeoutThenClearContinuations() {
        Task {
            try? await Task.sleep(for: waitForFirstValueTimeoutDuration)
            clearWaitingContinuations()
        }
    }
}
