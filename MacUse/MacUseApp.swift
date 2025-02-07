import Claude
import SwiftUI

struct TestAuthenticator: Claude.Authenticator {
    var apiKey: Claude.APIKey? {
        let key =
            "sk-ant-api03--XXX"

        return Claude.APIKey(key)
    }
}

@main
struct MacUseApp: App {
    private func initClaude() -> Claude {
        let claude = Claude(
            authenticator: TestAuthenticator()
        )

        return claude
    }

    var body: some Scene {
        WindowGroup {
            ContentView(claude: initClaude())
        }
    }
}
