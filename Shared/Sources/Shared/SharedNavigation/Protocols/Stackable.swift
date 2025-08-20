import SwiftUINavigation

/// Types that conform to `Stackable` become equipped with `NavigationStack` functionality.
@MainActor
public protocol Stackable: AnyObject, HashableObject {
    /// Define an enum called `Path` inside the view model that subclasses `StackableViewModel`.
    associatedtype PathItem: Hashable

    /// Assign the view model of the root of the stack. This will be linked to the view
    /// that's defined as the root of the `NavigationStack`.
    associatedtype RootViewModel: RootViewModeling

    /// The navigation stack stored in an array of `PathItem`
    var path: [PathItem] { get set }

    /// The view model of the root view of the stack.
    var rootViewModel: RootViewModel { get }

    /// Pushes a `PathItem` onto the stack and triggers a push animation
    func push(pathItem: PathItem)

    /// Removes the most recent item from the `path` and returns the popped item.
    func popLast() -> PathItem?

    /// Removes all items from the `path`.
    func popToRoot()

    /// Binds the delegate for the specified `StackablePathType`
    func bindDelegate(for pathType: StackablePathType<PathItem>)
}

/// `StackablePathType` defines a type of root path that can exist within a `Stackable`. We need this because root screens are treated differently then pushed screens in that they.
/// 1. Don't have an associated path (they are just the root)
/// 2. Due to 1, cannot be mapped to a viewmodel using a path, requiring us to hold onto a reference to the rootViewModel directly.
public enum StackablePathType<PathItemType: Hashable> {
    case root
    case pathItem(pathItem: PathItemType)
}

extension Stackable {
    public func push(pathItem: PathItem) {
        path.append(pathItem)
    }

    @discardableResult
    public func popLast() -> PathItem? {
        path.popLast()
    }

    public func popToRoot() {
        path.removeAll()
    }

    public func bindDelegates() {
        bindDelegate(for: .root)
        for pathItem in path {
            bindDelegate(for: .pathItem(pathItem: pathItem))
        }
    }
}
