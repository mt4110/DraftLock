import SwiftUI

struct ContentView: View {
    @StateObject private var promptStudio: PromptStudioViewModel
    @StateObject private var settings: SettingsViewModel
    @StateObject private var underBar: UnderBarViewModel
    @StateObject private var mainVM: MainViewModel

    init() {
        let promptStudio = PromptStudioViewModel()
        let settings = SettingsViewModel()
        let underBar = UnderBarViewModel()
        let mainVM = MainViewModel(
            promptStudio: promptStudio,
            settings: settings,
            underBar: underBar
        )

        _promptStudio = StateObject(wrappedValue: promptStudio)
        _settings = StateObject(wrappedValue: settings)
        _underBar = StateObject(wrappedValue: underBar)
        _mainVM = StateObject(wrappedValue: mainVM)
    }

    var body: some View {
        TabView {
            MainView(vm: mainVM, promptStudio: promptStudio, underBar: underBar)
                .tabItem { Label("Draft", systemImage: "square.and.pencil") }

            PromptStudioView(vm: promptStudio)
                .tabItem { Label("Prompts", systemImage: "list.bullet.rectangle") }

            SettingsView(vm: settings)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .frame(minWidth: 1280, minHeight: 620)
        .task {
            mainVM.bootstrap()
        }
    }
}
