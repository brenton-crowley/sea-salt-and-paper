@testable import SharedNetworking
import Testing

struct AsyncGateConnectionTests {
    private let waitForFirstValueTimeoutDuration = Duration.seconds(0.05)

    @Test("Success - Connect and resume immediately once connected, then complete stream.")
    func connectToStreamAndResumeImmediatelyThenCompleteStream() async throws {
        // GIVEN
        let (mockStream, mockContinuation) = AsyncThrowingStream<Int, Error>.makeStream()
        let testSubject = AsyncGateConnection(waitForFirstValueTimeoutDuration)

        // WHEN
        let task = Task {
            try await testSubject.connectIfNeeded(
                toStream: {
                    await #expect(testSubject.state == .connecting)
                    return mockStream
                },
                onReceiveValue: { _ in Issue.record("Should not receive a value") },
                resumeImmediatelyOnceConnected: true
            )
        }

        try await task.value

        // THEN
        await #expect(testSubject.waitingContinuations.count == 0)
        await #expect(testSubject.state == .connected)
        await #expect(testSubject.connectionTask != nil)

        // WHEN - The stream finishes internally.
        mockContinuation.finish()

        try await testSubject.connectionTask?.value

        // THEN
        await #expect(testSubject.state == .disconnected)
        await #expect(testSubject.connectionTask == nil)
    }

    @Test("Success - Connect and wait until first value times out")
    func connectToStreamAndWaitForFirstValueTimeout() async throws {
        // GIVEN
        let (mockStream, mockContinuation) = AsyncThrowingStream<Int, Error>.makeStream()
        let testSubject = AsyncGateConnection(.seconds(0.05))

        // WHEN
        let task = Task {
            try await testSubject.connectIfNeeded(
                toStream: {
                    await #expect(testSubject.state == .connecting)
                    return mockStream
                },
                onReceiveValue: { _ in Issue.record("Should not receive a value") },
                resumeImmediatelyOnceConnected: false
            )
        }

        try await task.value

        // THEN
        await #expect(testSubject.waitingContinuations.count == 0)
        await #expect(testSubject.state == .connected)
        await #expect(testSubject.connectionTask != nil)

        // WHEN - The stream finishes internally.
        mockContinuation.finish()

        try await testSubject.connectionTask?.value

        // THEN
        await #expect(testSubject.state == .disconnected)
        await #expect(testSubject.connectionTask == nil)
    }

    @Test("Success - Connect and resume when first value is received, then complete stream.")
    func connectToStreamAndResumeAfterFirstValueThenCompleteStream() async throws {
        // GIVEN
        let (mockStream, mockContinuation) = AsyncThrowingStream<Int, Error>.makeStream()
        let testSubject = AsyncGateConnection(waitForFirstValueTimeoutDuration)

        // WHEN
        let task = Task {
            try await confirmation(expectedCount: 1) { confirmation in
                try await testSubject.connectIfNeeded(
                    toStream: {
                        await #expect(testSubject.state == .connecting)
                        return mockStream
                    },
                    onReceiveValue: { _ in confirmation() }, // Confirm once a value is sent
                    resumeImmediatelyOnceConnected: false
                )
            }
        }

        // Send a value to resume
        _ = Task { mockContinuation.yield(0) }

        try await task.value

        // THEN
        await #expect(testSubject.waitingContinuations.count == 0)
        await #expect(testSubject.state == .connected)
        await #expect(testSubject.connectionTask != nil)

        // WHEN - The stream finishes internally.
        mockContinuation.finish()

        try await testSubject.connectionTask?.value

        // THEN
        await #expect(testSubject.state == .disconnected)
        await #expect(testSubject.connectionTask == nil)
    }

    @Test("Success - Await multiple access requests")
    func awaitMultipleAccessRequests() async throws {
        // GIVEN
        let (mockStream, mockContinuation) = AsyncThrowingStream<Int, Error>.makeStream()
        let testSubject = AsyncGateConnection(waitForFirstValueTimeoutDuration)


        await #expect(testSubject.state == .disconnected)

        // WHEN
        let taskAccess = Task {
            try await confirmation(expectedCount: 2) { confirmation in
                let toStream: @Sendable () async throws -> AsyncThrowingStream<Int, Error> = {
                    await #expect(testSubject.state == .connecting)
                    // One confirmation for opening the connections
                    confirmation()

                    return mockStream
                }
                // Second confirmation for receiving the value
                let onReceiveValue: @Sendable (Int) async -> Void = { _ in confirmation() }

                let firstAccess = Task {
                    try await testSubject.connectIfNeeded(
                        toStream: toStream,
                        onReceiveValue: onReceiveValue,
                        resumeImmediatelyOnceConnected: false
                    )
                }

                let secondAccess = Task {
                    try await testSubject.connectIfNeeded(
                        toStream: toStream,
                        onReceiveValue: onReceiveValue,
                        resumeImmediatelyOnceConnected: false
                    )
                }

                // Send a value to resume
                _ = Task { mockContinuation.yield(0) }

                try await firstAccess.value
                try await secondAccess.value
            }
        }

        try await taskAccess.value


        // THEN
        await #expect(testSubject.waitingContinuations.count == 0)
        await #expect(testSubject.state == .connected)
        await #expect(testSubject.connectionTask != nil)

        // WHEN - The stream finishes internally.
        mockContinuation.finish()

        try await testSubject.connectionTask?.value

        // THEN
        await #expect(testSubject.state == .disconnected)
        await #expect(testSubject.connectionTask == nil)
    }
}
