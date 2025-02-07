import Claude
import SwiftUI

public struct ContentView: View {
    @State
    private var input = ""

    @State
    private var conversation = Conversation()

    private let claude: Claude
    
    public init(claude: Claude) {
        self.claude = claude
    }

    public var body: some View {
        VStack {
            ScrollView {
                VStack {
                    ForEach(conversation.messages) { message in
                        switch message {
                        case .user(let user):
                            Text(user.text)
                                .padding(20)
                                .foregroundStyle(.white)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 20)))
                        case .assistant(let assistant):
                            ForEach(assistant.currentContentBlocks) { block in
                                switch block {
                                case .textBlock(let textBlock):
                                    Text(textBlock.currentText)
                                        .padding(20)
                                        .foregroundStyle(.white)
                                        .background(Color.green)
                                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 20)))
                                case .toolUseBlock(let toolUseBlock):
                                    VStack {
                                        Text("[Invoking \(toolUseBlock.toolUse.toolName)]")
                                        Text("[\(toolUseBlock.toolUse.currentInputJSON)]")
                                        if let output = toolUseBlock.toolUse.currentOutput {
                                            Text("\(output)]")
                                        }
                                    }
                                    .padding(20)
                                    .foregroundStyle(.white)
                                    .background(Color.black)
                                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 20)))
                                }
                            }
                        }
                    }
                }
                .rotationEffect(.degrees(180))
            }
            .rotationEffect(.degrees(180))
            
            Divider()
            
            switch conversation.currentState {
            case .ready(for: let nextStep):
                switch nextStep {
                case .user:
                    HStack {
                        TextField("Enter text", text: $input)
                        
                        Button("Run") {
                            submit()
                        }
                    }
                    .padding(20)
                case .toolUseResult:
                    Button("Provide tool invocation results") {
                        submit()
                    }
                }
            case .responding:
                ProgressView()
                    .padding(20)
            case .failed(let error):
                VStack {
                    HStack {
                        TextField("Enter text", text: $input)
                        
                        Button("Run") {
                            submit()
                        }
                    }
                    
                    Text("Failed: \(error)")
                        .foregroundStyle(.red)
                }
                .padding(20)
            }
        }
    }

    private func submit() {
        for window in NSApplication.shared.windows {
            window.level = .floating
        }
        
        conversation.messages.append(
            .user("\(input)")
        )
        input = ""
        Task {
            repeat {
                let message = claude.nextMessage(
                    in: conversation,
                    model: .claude35Sonnet20241022,
                    tools: Tools {
                        Wait()
                        Memory()
                        InstalledApplications()
                        RunningApplications()
                        RunApplication()
                        ApplicationWindows()
                        PrintWindowTree()
                        ClickWindowElement()
                        FocusWindowElement()
                        FocusWindow()
                        SendKeystrokesToWindowElement()
                        GetWindowElementsOfRole()
                        GetWindowElementsWithText()
                    },
                    invokeTools: .whenInputAvailable
                )
                conversation.messages.append(.assistant(message))

                for try await block in message.contentBlocks {
                    switch block {
                    case .textBlock(let textBlock):
                        for try await textFragment in textBlock.textFragments {
                            print(textFragment, terminator: "")
                            fflush(stdout)
                        }
                    case .toolUseBlock(let toolUseBlock):
                        try print("[Using \(toolUseBlock.toolName): \(await toolUseBlock.inputJSON())]")
                        try print("[\(await toolUseBlock.output())]")
                    }
                }
                print()
            } while try await conversation.nextStep() == .toolUseResult
        }
    }

    private func reset() {
        input = ""
        conversation = Conversation()
    }
}

private struct Conversation: Claude.Conversation {
    var messages: [Message] = []

    typealias ToolOutput = String
    
    var systemPrompt: SystemPrompt {
"""
You are an AI assistant helping users automate macOS UI interactions. You have access to several tools for interacting with applications and UI elements. Its very important to use `Memory` tool to save and load information about application!

## UI Interaction Flow

1. Check Memory tool for known patterns for the app (REQUIRED)
2. Check if app already running with `RunningApplications`
3. List `InstalledApplications` and launch app with `RunApplication` if needed. 
4. Focus window with `FocusWindow` (REQUIRED)
5. Wait for UI to load if needed
6. Find elements using `PrintWindowTree`, `GetWindowElementsOfRole`, `GetWindowElementsWithText` or `QueryWindowElement`
7. Store successful element paths and steps with Memory tool (REQUIRED)
8. Interact using `FocusWindowElement`, `ClickWindowElement`, or `SendKeystrokesToWindowElement`
"""
    }
}
