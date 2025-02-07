import AIModel
import ComposableArchitecture
import SwiftUI

struct EmbeddingModelManagementView: View {
    let store: StoreOf<EmbeddingModelManagement>

    var body: some View {
        AIModelManagementView<EmbeddingModelManagement, _>(store: store)
            .sheet(store: store.scope(
                state: \.$editingModel,
                action: EmbeddingModelManagement.Action.embeddingModelItem
            )) { store in
                EmbeddingModelEditView(store: store)
                    .frame(minWidth: 400)
            }
    }
}

// MARK: - Previews

class EmbeddingModelManagementView_Previews: PreviewProvider {
    static var previews: some View {
        EmbeddingModelManagementView(
            store: .init(
                initialState: .init(
                    models: IdentifiedArray<String, EmbeddingModel>(uniqueElements: [
                        EmbeddingModel(
                            id: "1",
                            name: "Test Model",
                            format: .openAI,
                            info: .init(
                                apiKeyName: "key",
                                baseURL: "google.com",
                                maxTokens: 3000,
                                modelName: "gpt-3.5-turbo"
                            )
                        ),
                        EmbeddingModel(
                            id: "2",
                            name: "Test Model 2",
                            format: .azureOpenAI,
                            info: .init(
                                apiKeyName: "key",
                                baseURL: "apple.com",
                                maxTokens: 3000,
                                modelName: "gpt-3.5-turbo"
                            )
                        ),
                        EmbeddingModel(
                            id: "3",
                            name: "Test Model 3",
                            format: .openAICompatible,
                            info: .init(
                                apiKeyName: "key",
                                baseURL: "apple.com",
                                maxTokens: 3000,
                                modelName: "gpt-3.5-turbo"
                            )
                        ),
                    ]),
                    editingModel: .init(
                        model: EmbeddingModel(
                            id: "3",
                            name: "Test Model 3",
                            format: .openAICompatible,
                            info: .init(
                                apiKeyName: "key",
                                baseURL: "apple.com",
                                maxTokens: 3000,
                                modelName: "gpt-3.5-turbo"
                            )
                        )
                    )
                ),
                reducer: EmbeddingModelManagement()
            )
        )
    }
}
