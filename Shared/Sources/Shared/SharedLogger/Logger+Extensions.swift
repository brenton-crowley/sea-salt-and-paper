@_exported import OSLog

// TODO: Move out into its own module
extension Logger {
    public init<T>(for type: T.Type) {
        self.init(
            subsystem: Bundle.main.bundleIdentifier ?? "UnknownBundleIdentifier",
            category: String(describing: type)
        )
    }
}
