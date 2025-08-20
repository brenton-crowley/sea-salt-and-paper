// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - Package Definition
private func feature<Feature: Modular>(_ type: Feature.Type) -> (products: [Product], targets: [Target]) {
    (type.products, type.allTargets)
}

let features = [
    feature(AppFeature.self)
]
// Products define the executables and libraries a package produces, making them visible to other packages.
let products: [Product] = features.flatMap(\.products)

// Targets are the basic building blocks of a package, defining a module or a test suite.
// Targets can depend on other targets in this package and products from dependencies.

let targets = features.flatMap(\.targets)

let package = Package(
    name: "Features",
    platforms: [.iOS(.v18)],
    products: products,
    dependencies: External.packages + Shared.packages,
    targets: targets
)

/// # Dependency Hierarchy
///
/// Sources
/// |— Shared - Shared amongst all the other dependencies
/// |— PresentationLayer - UI layer depends on
///   |— DomainLayer - Business logic layer depends on
///     |— DataLayer - Data layer

// MARK: - External Dependencies (Third-party)

private enum External: String, CaseIterable {
    case swiftNavigation = "swift-navigation"
    case httpTypes = "swift-http-types"
    case urlRouting = "swift-url-routing"
    case asyncAlgorithms = "swift-async-algorithms"
    case concurrencyExtras = "swift-concurrency-extras"
    case pointFreeXCTestDynamicOverlay = "xctest-dynamic-overlay"

    var name: String { rawValue }

    var package: Package.Dependency {
        return switch self {
        case .swiftNavigation: .package(url: "https://github.com/pointfreeco/swift-navigation.git", exact: "2.3.0")
        case .httpTypes: .package(url: "https://github.com/apple/swift-http-types.git", exact: "1.4.0")
        case .urlRouting: .package(url: "https://github.com/pointfreeco/swift-url-routing.git", exact: "0.6.2")
        case .asyncAlgorithms: .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.4")
        case .concurrencyExtras: .package(url: "https://github.com/pointfreeco/swift-concurrency-extras.git", from: "1.3.1")
        case .pointFreeXCTestDynamicOverlay: .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay.git", from: "1.5.2")
        }
    }

    static var packages: [Package.Dependency] { External.allCases.map(\.package) }
}

// Convenience properties to import external dependencies into targets in a type-safe way
extension External {
    static var swiftUINavigation: Target.Dependency { .product(name: "SwiftUINavigation", package: External.swiftNavigation.name) }
    static var swiftIssueReporting: Target.Dependency { .product(name: "IssueReporting", package: External.pointFreeXCTestDynamicOverlay.name) }
    static var swiftURLRouting: Target.Dependency { .product(name: "URLRouting", package: External.urlRouting.name) }
    static var swiftHTTPTypes: Target.Dependency { .product(name: "HTTPTypes", package: External.httpTypes.name) }
    static var swiftHTTPTypesFoundation: Target.Dependency { .product(name: "HTTPTypesFoundation", package: External.httpTypes.name) }
    static var swiftAsyncAlgorithms: Target.Dependency { .product(name: "AsyncAlgorithms", package: "swift-async-algorithms") }
    static var swiftConcurrencyExtras: Target.Dependency { .product(name: "ConcurrencyExtras", package: External.concurrencyExtras.name) }
}

private enum Shared: String, CaseIterable {
    static let packageName = "Shared"
    static var packages: [Package.Dependency] { [.package(path: "../\(Self.packageName)")] }

    case navigation = "SharedNavigation"
    case repositories = "Repositories"
    case dependency = "SharedDependency"
    case networking = "SharedNetworking"
    case bundle = "SharedBundle"
    case fileStorage = "SharedFileStorage"
    case componentsUI = "ComponentsUI"

    var name: String { rawValue }
    var dependency: Target.Dependency { .product(name: name, package: Self.packageName) }
}

// MARK: - Common Dependencies

/// Group dependencies that are commonly exposed between the layers.
private enum Common {
    case presentation, domain, data

    /// ⚠️ Only include dependencies from ``Shared`` or ``External``
    ///
    /// Any dependency added to each layer's array will expose that dependency to ALL features.
    /// Only add a dependency here if EVERY feature needs access to it.
    var dependencies: [Target.Dependency] {
        switch self {
        case .presentation: [
            External.swiftUINavigation, /// Each feature's view model needs ``HashableOject``
            External.swiftURLRouting, /// For deeplinking and routing

            Shared.dependency.dependency, /// Access to ``DependencyKeyMode``
            Shared.navigation.dependency, /// Access to ``StackableViewModel``
            Shared.componentsUI.dependency, /// Access to common UI elements
        ]

        case .domain: [Shared.dependency.dependency]
        case .data: [Shared.dependency.dependency]
        }
    }
}

// MARK: - Features

private enum AppFeature: String, Modular {
    static let modulePath: String = "/AppFeature"

    case presentation = "AppUI"
    case domain = "AppDomain"
    case data = "AppData"

    /// Products define the executables and libraries a package produces, making them visible to other packages.
    var product: Product {
        switch self {
        case .presentation, .domain, .data: .library(name: name, targets: [name])
        }
    }

    var dependencies: [Target.Dependency] {
        switch self {
        case .presentation: Common.presentation.dependencies + [
            External.swiftConcurrencyExtras,
            AppFeature.domain.dependency
        ]

        case .domain: Common.domain.dependencies +  [
            External.swiftConcurrencyExtras,

            AppFeature.data.dependency,
        ]

        case .data: Common.data.dependencies + []
        }
    }

    var testDependencies: [Target.Dependency] {
        switch self {
        case .presentation, .domain, .data: [
            External.swiftIssueReporting,

            dependency
        ]
        }
    }
}

// MARK: - Private General Functionality

/// Generates default properties for package modules to expose.
private protocol Modular: CaseIterable, RawRepresentable {
    /// The name of the folder in which the module is located. Should contain a forward slash `/` as the first character.
    ///
    /// This path will be appended to `Sources` or `Tests` folder.
    ///
    ///Eg.
    /// ```
    /// // For a module called features, we assign `/Feature` and that becomes:
    /// Sources/Features
    /// Tests/Features
    /// ```
    static var modulePath: String { get }
    static var products: [Product] { get }
    static var targets: [Target] { get }

    var name: String { get }

    /// Exposes a target's API so that other targets can consume it.
    ///
    /// Switch over `self` when an enum and return products for each case.
    var product: Product { get }

    /// Creates a target within the module.
    ///
    /// Switch over `self` when an enum and return targets for each case.
    ///
    /// Make sure that the target has its own folder that's named the same as the `rawValue` of its case,
    /// and it's located at the first level inside them module's folder..
    var target: Target { get }

    /// Creates test a target within the module.
    ///
    /// Switch over `self` when an enum and return test targets for each case.
    ///
    /// Make sure that the test target has its own folder that's named the same as the `rawValue` of its case with `Tests` appended to the folder name.
    /// The folder must be located at the first level inside them module's test folder.
    var testTarget: Target { get }
    var dependency: Target.Dependency { get }

    var sourcePath: String { get }
    var testPath: String { get }

    var dependencies: [Target.Dependency] { get }
    var testDependencies: [Target.Dependency] { get }
}

private extension Modular {
    static var products: [Product] { Self.allCases.map(\.product) }
    static var targets: [Target] { Self.allCases.map(\.target) }
    static var testTargets: [Target] { Self.allCases.map(\.testTarget) }
    static var allTargets: [Target] { targets + testTargets }
}

private extension Modular where RawValue == String {
    /// The `rawValue` of the enum's case.
    var name: String { rawValue }

    /// The `rawValue` of the enum's case appended with **'Tests'**
    ///
    /// Eg.
    /// ```
    /// case competitions = "Competitions"
    /// testName == "CompetitionsTests"
    /// ```
    var testName: String { rawValue + "Tests" }

    /// Convenience property that wraps the target's name in a `Target.Dependency`
    /// so that it's enum case can be used as a dependency.
    ///
    ///Eg.
    /// ```
    /// dependencies: [Features.competitions.dependency]
    /// ```
    var dependency: Target.Dependency { .byName(name: rawValue) }

    /// Generates a path to the target's folder location that includes the module's folder in which it's located.
    ///
    /// Uses the target's **`name`** property to generate the target's folder location.
    ///
    /// For example, if this target is called `Competitions` and is within the `Features` module, then the following is true:
    /// ```
    /// // Returns source path:
    /// Sources/Features/Competitions
    /// ```
    /// The folder structure should resemble this path.
    var sourcePath: String { "Sources\(Self.modulePath)/\(name)" }

    /// Generates a path to the test target's folder location that includes the module's folder in which it's located.
    ///
    /// Uses the target's **`testName`** property to generate the test target's folder location.
    ///
    /// For example, if this tests target is called `CompetitionsTests` and is within the `FeaturesTests` module, then the following is true:
    /// ```
    /// // Returns source path:
    /// Tests/FeaturesTests/CompetitionsTests
    /// ```
    /// The folder structure should resemble this path.
    var testPath: String { "Tests\(Self.modulePath)Tests/\(testName)" }

    var target: Target { .target(name: name, dependencies: dependencies, path: sourcePath) }

    var testTarget: Target { .testTarget(name: testName, dependencies: testDependencies, path: testPath) }
}
