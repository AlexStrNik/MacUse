import Claude
import Foundation

@Tool
struct Wait {
    /// Pauses execution for specified number of seconds
    ///
    /// - Parameter seconds: Number of seconds to wait
    ///
    /// Use this tool when:
    /// - Waiting for UI elements to appear
    /// - Allowing animations to complete
    /// - Giving application time to process actions
    ///
    /// Returns confirmation message after wait completes
    func invoke(seconds: Double) async throws -> String {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        return "Waited for \(seconds) seconds"
    }
}
