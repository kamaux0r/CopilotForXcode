import AppKit
import ComposableArchitecture
import Foundation

public struct PanelFeature: ReducerProtocol {
    public struct State: Equatable {
        public var content: SharedPanelFeature.Content {
            get { sharedPanelState.content }
            set {
                sharedPanelState.content = newValue
                suggestionPanelState.content = newValue.suggestion
            }
        }

        // MARK: SharedPanel

        var sharedPanelState = SharedPanelFeature.State()

        // MARK: SuggestionPanel

        var suggestionPanelState = SuggestionPanelFeature.State()
    }

    public enum Action: Equatable {
        case presentSuggestion
        case presentSuggestionProvider(SuggestionProvider, displayContent: Bool)
        case presentError(String)
        case presentPromptToCode(PromptToCodeGroup.PromptToCodeInitialState)
        case displayPanelContent
        case discardSuggestion
        case removeDisplayedContent
        case switchToAnotherEditorAndUpdateContent

        case sharedPanel(SharedPanelFeature.Action)
        case suggestionPanel(SuggestionPanelFeature.Action)
    }

    @Dependency(\.suggestionWidgetControllerDependency) var suggestionWidgetControllerDependency
    @Dependency(\.xcodeInspector) var xcodeInspector
    var windows: WidgetWindows { suggestionWidgetControllerDependency.windows }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.suggestionPanelState, action: /Action.suggestionPanel) {
            SuggestionPanelFeature()
        }

        Scope(state: \.sharedPanelState, action: /Action.sharedPanel) {
            SharedPanelFeature()
        }

        Reduce { state, action in
            switch action {
            case .presentSuggestion:
                return .run { send in
                    guard let provider = await fetchSuggestionProvider(
                        fileURL: xcodeInspector.activeDocumentURL
                    ) else { return }
                    await send(.presentSuggestionProvider(provider, displayContent: true))
                }

            case let .presentSuggestionProvider(provider, displayContent):
                state.content.suggestion = provider
                if displayContent {
                    return .run { send in
                        await send(.displayPanelContent)
                    }.animation(.easeInOut(duration: 0.2))
                }
                return .none

            case let .presentError(errorDescription):
                state.content.error = errorDescription
                return .run { send in
                    await send(.displayPanelContent)
                }.animation(.easeInOut(duration: 0.2))

            case let .presentPromptToCode(initialState):
                return .run { send in
                    await send(.sharedPanel(.promptToCodeGroup(.createPromptToCode(initialState))))
                }

            case .displayPanelContent:
                if !state.sharedPanelState.isEmpty {
                    state.sharedPanelState.isPanelDisplayed = true
                }

                if state.suggestionPanelState.content != nil {
                    state.suggestionPanelState.isPanelDisplayed = true
                }

                return .none

            case .discardSuggestion:
                state.content.suggestion = nil
                return .none

            case .switchToAnotherEditorAndUpdateContent:
                state.content.error = nil
                return .run { send in
                    let fileURL = xcodeInspector.activeDocumentURL
                    if let suggestion = await fetchSuggestionProvider(fileURL: fileURL) {
                        await send(.presentSuggestionProvider(suggestion, displayContent: false))
                    }

                    await send(.sharedPanel(
                        .promptToCodeGroup(
                            .updateActivePromptToCode(documentURL: fileURL)
                        )
                    ))
                }

            case .removeDisplayedContent:
                state.content.error = nil
                state.content.promptToCodeGroup.activePromptToCode = nil
                state.content.suggestion = nil
                return .none

            case .sharedPanel(.promptToCodeGroup(.createPromptToCode)):
                let hasPromptToCode = state.content.promptToCode != nil
                return .run { send in
                    await send(.displayPanelContent)

                    if hasPromptToCode {
                        // looks like we need a delay.
                        try await Task.sleep(nanoseconds: 150_000_000)
                        await NSApplication.shared.activate(ignoringOtherApps: true)
                        await windows.sharedPanelWindow.makeKey()
                    }
                }.animation(.easeInOut(duration: 0.2))

            case .sharedPanel:
                return .none

            case .suggestionPanel:
                return .none
            }
        }
    }

    func fetchSuggestionProvider(fileURL: URL) async -> SuggestionProvider? {
        guard let provider = await suggestionWidgetControllerDependency
            .suggestionWidgetDataSource?
            .suggestionForFile(at: fileURL) else { return nil }
        return provider
    }
}

