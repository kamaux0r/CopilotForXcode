import ChatContextCollector
import Foundation
import OpenAIService

public final class SystemInfoChatContextCollector: ChatContextCollector {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, yyyy-MM-dd HH:mm:ssZ"
        return formatter
    }()

    public init() {}

    public func generateContext(
        history: [ChatMessage],
        scopes: Set<String>,
        content: String,
        configuration: ChatGPTConfiguration
    ) -> ChatContext? {
        return .init(
            systemPrompt: """
            Current Time: \(Self.dateFormatter.string(from: Date())) (You can use it to calculate time in another time zone)
            """,
            functions: []
        )
    }
}

