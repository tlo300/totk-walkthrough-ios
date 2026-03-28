// TOTKWalkthroughApp.swift — App entry point. Injects shared stores into the environment.
import SwiftUI

@main
struct TOTKWalkthroughApp: App {
    @StateObject private var contentStore = ContentStore()
    @StateObject private var progressStore = ProgressStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(contentStore)
                .environmentObject(progressStore)
                .task {
                    try? await contentStore.load()
                }
        }
    }
}
