// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - Package Definition

// Products define the executables and libraries a package produces, making them visible to other packages.
let products: [Product] = PresentationLayer.products
    + DataLayer.products
    + DomainLayer.products
    + Shared.products

// Targets are the basic building blocks of a package, defining a module or a test suite.
// Targets can depend on other targets in this package and products from dependencies.
let targets: [Target] = Shared.targets
    + Shared.testTargets
    + PresentationLayer.targets
    + PresentationLayer.testTargets
    + DomainLayer.targets
    + DomainLayer.testTargets
    + DataLayer.targets
    + DataLayer.testTargets

let package = Package(
    name: "Shared",
    platforms: [.iOS(.v17)],
    products: products,
    dependencies: External.packages,
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
    case concurrencyExtras = "swift-concurrency-extras"
    case swiftCollections = "swift-collections"
    case asyncAlgorithms = "swift-async-algorithms"
    case sideEffectIOAsyncExtensions = "asyncextensions"
    case pointFreeXCTestDynamicOverlay = "xctest-dynamic-overlay"
    case pointFreeDependencies = "swift-dependencies"

    var name: String { rawValue }

    var package: Package.Dependency {
        return switch self {
        case .swiftNavigation: .package(url: "https://github.com/pointfreeco/swift-navigation.git", exact: "2.3.0")
        case .httpTypes: .package(url: "https://github.com/apple/swift-http-types.git", exact: "1.4.0")
        case .concurrencyExtras: .package(url: "https://github.com/pointfreeco/swift-concurrency-extras.git", from: "1.3.1")
        case .swiftCollections: .package(url: "https://github.com/apple/swift-collections.git", from: "1.2.0")
        case .asyncAlgorithms: .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.4")
        case .sideEffectIOAsyncExtensions: .package(url: "https://github.com/sideeffect-io/AsyncExtensions.git", from: "0.5.3")
        case .pointFreeXCTestDynamicOverlay: .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay.git", from: "1.5.2")
        case .pointFreeDependencies: .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.9.5")
        }
    }

    static var packages: [Package.Dependency] { External.allCases.map(\.package) }
}

// Convenience properties to import external dependencies into targets in a type-safe way
extension External {
    static var swiftUINavigation: Target.Dependency { .product(name: "SwiftUINavigation", package: External.swiftNavigation.name) }

    static var swiftHTTPTypes: Target.Dependency { .product(name: "HTTPTypes", package: External.httpTypes.name) }
    static var swiftHTTPTypesFoundation: Target.Dependency { .product(name: "HTTPTypesFoundation", package: External.httpTypes.name) }
    static var swiftConcurrencyExtras: Target.Dependency { .product(name: "ConcurrencyExtras", package: External.concurrencyExtras.name) }
    static var swiftOrderedCollections: Target.Dependency { .product(name: "OrderedCollections", package: External.swiftCollections.name) }
    static var swiftAsyncAlgorithms: Target.Dependency { .product(name: "AsyncAlgorithms", package: External.asyncAlgorithms.name) }
    static var asyncExtensions: Target.Dependency { .product(name: "AsyncExtensions", package: External.sideEffectIOAsyncExtensions.name) }
    static var swiftIssueReporting: Target.Dependency { .product(name: "IssueReporting", package: External.pointFreeXCTestDynamicOverlay.name) }
    static var swiftDependencies: Target.Dependency { .product(name: "Dependencies", package: External.pointFreeDependencies.name) }
}

// MARK: - Shared

/// Shared dependencies ought to be standalone and can be imported by any other target.
private enum Shared: String {
    static let modulePath: String = "/Shared"

    case sharedNavigation = "SharedNavigation"
    case sharedNetworking = "SharedNetworking"
    case sharedBundle = "SharedBundle"
    case sharedDependency = "SharedDependency"
    case sharedFileStorage = "SharedFileStorage"
    case sharedLogger = "SharedLogger"
    case sharedID = "SharedID"
    // Probably add a shared storage so that a repository can cache
}

extension Shared: Modular {
    /// Products define the executables and libraries a package produces, making them visible to other packages.
    var product: Product {
        switch self {
        case .sharedNetworking,
            .sharedNavigation,
            .sharedBundle,
            .sharedDependency,
            .sharedFileStorage,
            .sharedLogger,
            .sharedID: .library(name: name, targets: [name])
        }
    }

    /// Targets are the basic building blocks of a package, defining a module or a test suite.
    /// Targets can depend on other targets in this package and products from dependencies.
    ///
    /// A `Shared` target should never depend on anything other than a third-party library.
    var target: Target {
        switch self {
        case .sharedDependency, .sharedLogger, .sharedID: .target(name: name, path: sourcePath) // Must not have any dependencies
        case .sharedNavigation: .target(name: name, dependencies: [External.swiftUINavigation], path: sourcePath)
        case .sharedBundle: .target(name: name, dependencies: [Shared.sharedDependency.dependency], path: sourcePath)

        case .sharedNetworking: .target(
            name: name,
            dependencies: [
                External.swiftHTTPTypes,
                External.swiftHTTPTypesFoundation,
                External.swiftAsyncAlgorithms,
                External.asyncExtensions,

                Shared.sharedDependency.dependency,
                Shared.sharedLogger.dependency
            ],
            path: sourcePath
        )

        case .sharedFileStorage: .target(
            name: name,
            dependencies: [
                Shared.sharedDependency.dependency,
                External.swiftConcurrencyExtras
            ],
            path: sourcePath
        )
        }
    }

    var testTarget: Target {
        switch self {
        case .sharedDependency,
            .sharedNavigation,
            .sharedBundle,
            .sharedFileStorage,
            .sharedLogger,
            .sharedID:
                .testTarget(name: testName, dependencies: [dependency], path: testPath)

        case .sharedNetworking: .testTarget(
            name: testName,
            dependencies: [
                External.asyncExtensions,
                External.swiftConcurrencyExtras,
                External.swiftHTTPTypes,

                dependency,
            ],
            path: testPath
        )
        }
    }
}

// MARK: - Data Dependencies

/// Data Dependencies interact with the network, storage and third-party libraries.
private enum DataLayer: String {
    static let modulePath: String = "/Data"

    case api = "API"
    case repositories = "Repositories"
}

extension DataLayer: Modular {
    /// Products define the executables and libraries a package produces, making them visible to other packages.
    var product: Product {
        switch self {
        case .api, .repositories: .library(name: name, targets: [name])
        }
    }

    /// Targets are the basic building blocks of a package, defining a module or a test suite.
    /// Targets can depend on other targets in this package and products from dependencies.
    ///
    /// ⚠️ A `DataLayer` target should only depend on targets from `Shared`
    var target: Target {
        switch self {
        case .api: .target(
            name: name,
            dependencies: [
                External.swiftConcurrencyExtras,
                External.asyncExtensions,

                Shared.sharedDependency.dependency,
                Shared.sharedNetworking.dependency,
                Shared.sharedBundle.dependency,
            ],
            path: sourcePath
        )

        case .repositories: .target(
            name: name,
            dependencies: [
                External.swiftConcurrencyExtras,

                Shared.sharedDependency.dependency,
                Shared.sharedBundle.dependency,
                Shared.sharedFileStorage.dependency,
                Shared.sharedLogger.dependency
            ],
            path: sourcePath,
            resources: [.process("Resources")]
        )
        }
    }

    var testTarget: Target {
        switch self {
        case .api, .repositories: .testTarget(
            name: testName,
            dependencies: [
                External.asyncExtensions,
                External.swiftConcurrencyExtras,
                External.swiftIssueReporting,

                dependency
            ],
            path: testPath
        )
        }
    }
}

// MARK: - Domain Layer (Business Logic)

/// The root of the application that contains the business logic and interfaces.
///
/// ⚠️  The domain layer does not depend on any other layer.
private enum DomainLayer: String {
    static let modulePath: String = "/Domain"

    case models = "Models"
    case scoring = "Scoring"
    case gameEngine = "GameEngine"
}

extension DomainLayer: Modular {
    /// Products define the executables and libraries a package produces, making them visible to other packages.
    var product: Product {
        switch self {
        case .models,
            .scoring,
            .gameEngine: .library(name: name, targets: [name])
        }
    }

    /// Targets are the basic building blocks of a package, defining a module or a test suite.
    /// Targets can depend on other targets in this package and products from dependencies.
    ///
    /// A `DomainLayer` target should only depend on targets from Data
    var target: Target {
        switch self {
        case .models: .target(
            name: name,
            dependencies: [
                External.swiftConcurrencyExtras,
                External.swiftOrderedCollections,
                External.asyncExtensions,

                Shared.sharedDependency.dependency,
                Shared.sharedNetworking.dependency,
                Shared.sharedBundle.dependency,

                DataLayer.repositories.dependency
            ],
            path: sourcePath
        )

        case .scoring, .gameEngine: .target(
            name: name,
            dependencies: [
                External.swiftConcurrencyExtras,
                External.swiftOrderedCollections,
                External.asyncExtensions,
                External.swiftDependencies,

                Shared.sharedDependency.dependency,
                Shared.sharedBundle.dependency,
                Shared.sharedID.dependency,

                DataLayer.repositories.dependency,

                DomainLayer.models.dependency
            ],
            path: sourcePath
        )
        }
    }

    var testTarget: Target {
        switch self {
        case .models: .testTarget(
            name: testName,
            dependencies: [
                dependency,
                External.swiftConcurrencyExtras,
                External.swiftIssueReporting,

                DataLayer.repositories.dependency
            ],
            path: testPath
        )

        case .scoring, .gameEngine: .testTarget(
            name: testName,
            dependencies: [
                dependency,
                External.swiftConcurrencyExtras,
                External.swiftIssueReporting,
                External.swiftDependencies,
                External.swiftOrderedCollections,

                DataLayer.repositories.dependency,

                DomainLayer.models.dependency
            ],
            path: testPath
        )
        }
    }
}

// MARK: - Presentation Layer (UI Components)

/// Features are the UI and depend on domain layer to provide their data.
enum PresentationLayer: String {
    static let modulePath: String = "/Presentation"

    case componentsUI = "ComponentsUI"
    case controlsUI = "ControlsUI"
}

extension PresentationLayer: Modular {
    /// Products define the executables and libraries a package produces, making them visible to other packages.
    var product: Product {
        switch self {
        case .componentsUI,
            .controlsUI: .library(name: name, targets: [name])
        }
    }

    /// Targets are the basic building blocks of a package, defining a module or a test suite.
    /// Targets can depend on other targets in this package and products from dependencies.
    ///
    /// ⚠️  A `Feature` target should only contain dependencies from `DomainLayer`, `Shared`, and never from `DataDependency`
    ///
    /// - `ComponentsUI` General components that have a 1:1 mapping with a common repository. Can depend on controls.
    /// - `ControlsUI` Simple controls with minor functionality that expose bindings. Think of UI controls such as a Toggle where its data source is outsourced external.
    var target: Target {
        switch self {
        case .componentsUI: .target(
            name: name,
            dependencies: [
                External.swiftUINavigation, // Hashable Object

                Shared.sharedDependency.dependency,

                PresentationLayer.controlsUI.dependency
            ],
            path: sourcePath
        )

        case .controlsUI: .target( // No dependencies as only takes bindings
            name: name,
            path: sourcePath
        )
        }
    }

    var testTarget: Target {
        switch self {
        case .componentsUI, .controlsUI:
            .testTarget(
                name: testName,
                dependencies: [dependency],
                path: testPath
            )
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
}

private extension Modular {
    static var products: [Product] { Self.allCases.map(\.product) }
    static var targets: [Target] { Self.allCases.map(\.target) }
    static var testTargets: [Target] { Self.allCases.map(\.testTarget) }
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
}
