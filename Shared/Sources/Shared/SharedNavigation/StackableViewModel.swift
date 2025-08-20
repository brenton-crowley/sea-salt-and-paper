import SwiftUINavigation

/// Inherit this class to get view model functionality tailored for a `NavigationStack`.
///
/// Each time the path changes, this view model will bind delegate handlers for each item in the `path` and the the `rootViewModel`
///
/// You should override the `bindDelegate` and the `bindRootDelegate` methods to handle the delegation of logic from child to the parent.
/// It's best to store these handlers as private functions with the same signatures that the delegates require.
///
/// See ``bindDelegate(for pathItem:)``
/// and ``bindRootDelegate(_ action:)`` for examples.
@MainActor
@Observable
open class StackableViewModel<PathItem: Hashable, RootViewModel: RootViewModeling>: Stackable {
    public let rootViewModel: RootViewModel
    public var path: [PathItem] = [] { didSet { bindDelegates() } }

    public init(path: [PathItem] = [], rootViewModel: RootViewModel) {
        self.rootViewModel = rootViewModel
        self.path = path

        bindDelegates()
    }

    ///  Override this method to map the cases in the corresponding `PathType` case.
    ///
    ///  When you receive the view model through case deconstruction, then you can assign the delegate handler.
    ///
    ///  See the example below.
    /// - Parameter pathType: Either root, or an enum that you can switch over and extract the associated view model value.
    ///
    /// ```
    /// switch pathType {
    ///    case .root: rootViewModel.delegate = handleDelegateAction(_:)
    ///    case .pathItem(.settings(let viewModel)): viewModel.delegate = handleDelegateAction(_:)
    /// }
    /// ```
    open func bindDelegate(for pathType: StackablePathType<PathItem>) {
        fatalError("\(#function) - Subclass should override")
    }
}
