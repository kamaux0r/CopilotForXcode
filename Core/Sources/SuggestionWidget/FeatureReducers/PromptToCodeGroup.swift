import ComposableArchitecture
import Foundation
import PromptToCodeService
import SuggestionModel
import Environment

public struct PromptToCodeGroup: ReducerProtocol {
    public struct State: Equatable {
        public var promptToCodes: IdentifiedArrayOf<PromptToCode.State> = []
        public var activeDocumentURL: PromptToCode.State.ID?
        public var activePromptToCode: PromptToCode.State? {
            get {
                if let detached = promptToCodes.first(where: { !$0.isAttachedToSelectionRange }) {
                    return detached
                }
                guard let id = activeDocumentURL else { return nil }
                return promptToCodes[id: id]
            }
            set { activeDocumentURL = newValue?.id }
        }
    }

    public struct PromptToCodeInitialState: Equatable {
        public var code: String
        public var selectionRange: CursorRange?
        public var language: CodeLanguage
        public var identSize: Int
        public var usesTabsForIndentation: Bool
        public var documentURL: URL
        public var projectRootURL: URL
        public var allCode: String
        public var isContinuous: Bool
        public var commandName: String?
        public var defaultPrompt: String
        public var extraSystemPrompt: String?
        public var generateDescriptionRequirement: Bool?

        public init(
            code: String,
            selectionRange: CursorRange?,
            language: CodeLanguage,
            identSize: Int,
            usesTabsForIndentation: Bool,
            documentURL: URL,
            projectRootURL: URL,
            allCode: String,
            isContinuous: Bool,
            commandName: String?,
            defaultPrompt: String,
            extraSystemPrompt: String?,
            generateDescriptionRequirement: Bool?
        ) {
            self.code = code
            self.selectionRange = selectionRange
            self.language = language
            self.identSize = identSize
            self.usesTabsForIndentation = usesTabsForIndentation
            self.documentURL = documentURL
            self.projectRootURL = projectRootURL
            self.allCode = allCode
            self.isContinuous = isContinuous
            self.commandName = commandName
            self.defaultPrompt = defaultPrompt
            self.extraSystemPrompt = extraSystemPrompt
            self.generateDescriptionRequirement = generateDescriptionRequirement
        }
    }

    public enum Action: Equatable {
        case createPromptToCode(PromptToCodeInitialState)
        case updatePromptToCodeRange(id: PromptToCode.State.ID, range: CursorRange)
        case discardAcceptedPromptToCodeIfNotContinuous(id: PromptToCode.State.ID)
        case updateActivePromptToCode(documentURL: URL)
        case discardExpiredPromptToCode(documentURLs: [URL])
        case promptToCode(PromptToCode.State.ID, PromptToCode.Action)
    }

    @Dependency(\.promptToCodeServiceFactory) var promptToCodeServiceFactory

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case let .createPromptToCode(s):
                let newPromptToCode = PromptToCode.State(
                    code: s.code,
                    prompt: s.defaultPrompt,
                    language: s.language,
                    indentSize: s.identSize,
                    usesTabsForIndentation: s.usesTabsForIndentation,
                    projectRootURL: s.projectRootURL,
                    documentURL: s.documentURL,
                    allCode: s.allCode,
                    commandName: s.commandName,
                    isContinuous: s.isContinuous,
                    selectionRange: s.selectionRange,
                    extraSystemPrompt: s.extraSystemPrompt,
                    generateDescriptionRequirement: s.generateDescriptionRequirement
                )
                // insert at 0 so it has high priority then the other detached prompt to codes
                state.promptToCodes.insert(newPromptToCode, at: 0)
                return .run { send in
                    if !newPromptToCode.prompt.isEmpty {
                        await send(.promptToCode(newPromptToCode.id, .modifyCodeButtonTapped))
                    }
                }.cancellable(
                    id: PromptToCode.CancellationKey.modifyCode(newPromptToCode.id),
                    cancelInFlight: true
                )

            case let .updatePromptToCodeRange(id, range):
                if let p = state.promptToCodes[id: id], p.isAttachedToSelectionRange {
                    state.promptToCodes[id: id]?.selectionRange = range
                }
                return .none

            case let .discardAcceptedPromptToCodeIfNotContinuous(id):
                state.promptToCodes.removeAll { $0.id == id && !$0.isContinuous }
                return .none

            case let .updateActivePromptToCode(documentURL):
                state.activeDocumentURL = documentURL
                return .none

            case let .discardExpiredPromptToCode(documentURLs):
                for url in documentURLs {
                    state.promptToCodes.remove(id: url)
                }
                return .none

            case let .promptToCode(id, action):
                switch action {
                case .cancelButtonTapped:
                    state.promptToCodes.remove(id: id)
                    return .run { _ in
                        try await Environment.makeXcodeActive()
                    }
                default:
                    return .none
                }
            }
        }
        .forEach(\.promptToCodes, action: /Action.promptToCode, element: {
            PromptToCode()
                .dependency(\.promptToCodeService, promptToCodeServiceFactory())
        })
    }
}

