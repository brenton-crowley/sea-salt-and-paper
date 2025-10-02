@preconcurrency import Combine
import ConcurrencyExtras
import Foundation

struct GameBroadcast: Sendable {
    public static let live = Self()

    private let subject = PassthroughSubject<GameEngine.Event, Never>()
    
    /// Generates an async stream to iterate over.
    ///
    /// Cancelling the task context of this async stream will also finish its continuation.
    func streamOfGameEvents() -> AsyncStream<GameEngine.Event> {
        let (stream, continuation) = AsyncStream<GameEngine.Event>.makeStream()

        let cancellable = subject.sink { continuation.yield($0) }

        continuation.onTermination = { _ in cancellable.cancel() }

        return stream.map {
            if Task.isCancelled { continuation.finish() }
            return $0
        }.eraseToStream()
    }

    func sendGameEvent(_ event: GameEngine.Event) {
        subject.send(event)
    }
}
