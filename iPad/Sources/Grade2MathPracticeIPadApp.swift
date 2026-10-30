import SwiftUI

@main
struct Grade2MathPracticeIPadApp: App {
    private let store: PracticeStore?
    private let startupError: String?
    @Environment(\.scenePhase) private var phase

    init() {
        do { store = try PracticeStore(); startupError = nil }
        catch { store = nil; startupError = error.localizedDescription }
    }
    var body: some Scene {
        WindowGroup {
            if let store {
                TabletPracticeView(store: store)
                    .onChange(of: phase) { _, value in if value != .active { store.save() } }
            } else {
                ContentUnavailableView("无法打开练习", systemImage: "exclamationmark.triangle", description: Text(startupError ?? "题库读取失败"))
            }
        }
    }
}
