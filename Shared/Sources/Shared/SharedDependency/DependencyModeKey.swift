import Foundation

/// Requires three static properties ``live``, ``mock``, and ``mockError`` on the conforming object.
///
/// These are the three minimum values, but you are not limited to them.
///
///  >Tip:
///  > If you require customisation of the live value, either create more static instances that are pre-filled,
///  > or write a static func called `.live()`
public protocol DependencyModeKey {
    /// Represents the production implementation that this object uses.
    static var live: Self { get }
    
    /// Stubs out a mock of the object in a `success` case.
    ///
    /// A success case is some data we would expect to receive on the happy path should nothing go wrong.
    static var mock: Self { get }

    
    /// Stubs out a mock of the object in a `failure` case.
    ///
    /// A `failure` case should throw some error.
    ///
    /// > Tip:
    /// > Create a mock error that's private to the object and throw that error.
    /// >
    /// > You could even inline this in the closure itself.
    ///
    /// If the object does not have a ``mockError``, then return the ``mock`` instance.
    static var mockError: Self { get }
}

public protocol ConfigDependencyMode {
    associatedtype Config
    associatedtype DataProvider

    func currentConfig(_ config: Config) -> DataProvider
}

extension DependencyMode {
    /// Convenience property that uses type inference to return the value based on the current dependency mode.
    /// ### <Dependency>
    /// A generic type that conforms to `DependencyModeKey`. The generic type is fulfilled when assigned to a property with a type.
    ///
    /// ### Example
    /// You would call this method on a dependency when you want to assign a value to a property.
    ///
    /// ```
    /// // Given a property
    /// struct Interactors: DependencyModeKey { ... }
    ///
    /// let interactors: Interactors
    /// 
    /// init(dependencyMode: DependencyMode = .live) {
    ///     interactors = dependencyMode.current() // .live version
    /// }
    /// ```
    /// - Returns: On of either `live`, `mock` or `mockError` depending on the `DependencyMode`
    public func current<Dependency: DependencyModeKey>() -> Dependency {
        switch self {
        case .live: Dependency.live
        case .mock: Dependency.mock
        case .mockError: Dependency.mockError
        }
    }

    public func currentConfig<Config, DataProvider>(_ config: Config, perform: @escaping @Sendable (_ config: Config) -> DataProvider) -> DataProvider {
        perform(config)
    }
}

public enum DependencyMode: Sendable {
    case live // Potentially add associated value here
    case mock
    case mockError
}

#if DEBUG

public struct MockError: Error { public init() {} }

#endif
