import SwiftUINavigation

@MainActor
public protocol RootViewModeling: HashableObject {
    associatedtype DelegateAction

    var delegate: (_ action: DelegateAction) -> Void { get set }
}
