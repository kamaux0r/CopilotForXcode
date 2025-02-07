import SwiftUI
import ComposableArchitecture

struct ServiceView: View {
    let store: StoreOf<HostApp>
    @State var tag = 0
    
    var body: some View {
        SidebarTabView(tag: $tag) {
            ScrollView {
                CopilotView().padding()
            }.sidebarItem(
                tag: 0,
                title: "GitHub Copilot",
                subtitle: "Suggestion",
                image: "globe"
            )
            
            ScrollView {
                CodeiumView().padding()
            }.sidebarItem(
                tag: 1,
                title: "Codeium",
                subtitle: "Suggestion",
                image: "globe"
            )
            
            ChatModelManagementView(store: store.scope(
                state: \.chatModelManagement,
                action: HostApp.Action.chatModelManagement
            )).sidebarItem(
                tag: 2,
                title: "Chat Models",
                subtitle: "Chat, Prompt to Code",
                image: "globe"
            )
            
            EmbeddingModelManagementView(store: store.scope(
                state: \.embeddingModelManagement,
                action: HostApp.Action.embeddingModelManagement
            )).sidebarItem(
                tag: 3,
                title: "Embedding Models",
                subtitle: "Chat, Prompt to Code",
                image: "globe"
            )
            
            ScrollView {
                BingSearchView().padding()
            }.sidebarItem(
                tag: 4,
                title: "Bing Search",
                subtitle: "Search Chat Plugin",
                image: "globe"
            )
        }
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        ServiceView(store: .init(initialState: .init(), reducer: HostApp()))
    }
}
