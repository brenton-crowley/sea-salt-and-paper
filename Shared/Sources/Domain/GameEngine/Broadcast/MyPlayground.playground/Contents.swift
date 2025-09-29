import AsyncAlgorithms
import ConcurrencyExtras
@preconcurrency import Combine
import Foundation
import PlaygroundSupport
import UIKit

var greeting = "Hello, playground"

public enum GameEvent: Hashable, Sendable {
    case gameUpdated
    case chooseDiscardPile
    case choosePlayerToSteal
}

struct GameBroadcast {
    public static let live = Self()

    private let subject = PassthroughSubject<GameEvent, Never>()

    public func streamOfGameEvents() -> AsyncStream<GameEvent> {
        let (stream, continuation) = AsyncStream<GameEvent>.makeStream()

        let cancellable = subject.sink { continuation.yield($0) }

        continuation.onTermination = { _ in
            cancellable.cancel()
            print("Continuation terminated")
        }

        return stream.map {
            if Task.isCancelled { continuation.finish() }
            return $0
        }.eraseToStream()
    }

    public func sendGameEvent(_ event: GameEvent) {
        subject.send(event)
    }
}

let task = Task {
    // Do the work in here.
    let task = Task {
        let broadcast = GameBroadcast.live

        for await event in broadcast.streamOfGameEvents() {
            print("Task: Received event: \(event)")
        }
    }

    let second = Task {
        let broadcast = GameBroadcast.live

        for await event in broadcast.streamOfGameEvents() {
            print("Task2: Received event: \(event)")
        }
    }

    let events = Task {
        let broadcast = GameBroadcast.live
        broadcast.sendGameEvent(.gameUpdated)
        try? await Task.sleep(for: .seconds(0.05))
        broadcast.sendGameEvent(.chooseDiscardPile)
        try? await Task.sleep(for: .seconds(0.05))
        task.cancel()
        broadcast.sendGameEvent(.choosePlayerToSteal)
        try? await Task.sleep(for: .seconds(0.05))


        broadcast.sendGameEvent(.choosePlayerToSteal)
    }

    // need to be able to cancel the task
}

Thread.sleep(forTimeInterval: 0.2)
