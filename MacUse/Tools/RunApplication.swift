import Claude
import AppKit

@Tool
struct RunApplication {
    /// Launches an application at the specified URL. Use `InstalledApplications` before running any app.
    ///
    /// - Parameter url: Path to the application bundle (.app)
    ///
    /// Returns Application Name - Process Identifier
    func invoke(url: String) async throws -> String {
        let applicationURL = URL(filePath: url)
        
        return await withCheckedContinuation { continuation in
            NSWorkspace.shared.openApplication(
                at: applicationURL,
                configuration: NSWorkspace.OpenConfiguration()
            ) { application, error in
                if let error = error {
                    continuation.resume(returning: "Failed to launch application: \(error.localizedDescription)")
                } else if let application = application {
                    continuation.resume(
                        returning: "Successfully launched \(application.localizedName ?? "application") - \(application.processIdentifier)"
                    )
                } else {
                    continuation.resume(returning: "Failed to launch application: unknown error")
                }
            }
        }
    }
}
