import Foundation

/// Runtime controls for async localization work shared across providers.
public struct LocalizationExecutionPolicy: Sendable, Hashable {
    public let maxConcurrentAsyncRequests: Int
    public let batchWindow: Duration
    public let maxBatchSize: Int

    public init(
        maxConcurrentAsyncRequests: Int = 4,
        batchWindow: Duration = .milliseconds(30),
        maxBatchSize: Int = 16
    ) {
        self.maxConcurrentAsyncRequests = max(1, maxConcurrentAsyncRequests)
        self.batchWindow = batchWindow
        self.maxBatchSize = max(1, maxBatchSize)
    }
}
