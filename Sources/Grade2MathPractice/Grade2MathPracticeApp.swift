import SwiftUI
import AppKit

@main
struct Grade2MathPracticeApp: App {
    @StateObject private var store: PracticeStore
    init() {
        if let iconURL = Bundle.main.url(forResource: "ArithmeticGlass", withExtension: "icns"), let image = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = image
        }
        do { let loaded = try PracticeStore(); _store = StateObject(wrappedValue: loaded) }
        catch {
            let alert = NSAlert()
            alert.messageText = "无法打开口算练习"
            alert.informativeText = "题库或本地数据目录读取失败：\(error.localizedDescription)"
            alert.runModal()
            exit(1)
        }
    }
    var body: some Scene {
        Window("口算练习", id: "practice") {
            ContentView(store: store)
                .frame(minWidth: 940, minHeight: 680)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in store.save() }
        }
        .defaultSize(width: 1160, height: 780)
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("重新开始练习") { store.requestRestart() }.keyboardShortcut("n")
                Button("练习记录") { store.showingHistory = true }.keyboardShortcut("h", modifiers: [.command, .shift])
            }
        }
    }
}

struct KeyboardInput: NSViewRepresentable {
    let enabled: Bool
    let input: (String) -> Void
    let next: () -> Void
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.view = view
        context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak coordinator = context.coordinator] event in
            let handled = MainActor.assumeIsolated {
                guard let coordinator, coordinator.enabled, event.window == coordinator.view?.window,
                      event.modifierFlags.intersection([.command, .control, .option]).isEmpty else { return false }
                if [36, 76].contains(event.keyCode) { coordinator.next(); return true }
                if event.keyCode == 51 { coordinator.input("delete"); return true }
                if event.keyCode == 117 { coordinator.input("clear"); return true }
                if let text = event.characters, text.count == 1, "0123456789<>=＞＜＝".contains(text) {
                    coordinator.input(["＞": ">", "＜": "<", "＝": "="][text] ?? text); return true
                }
                return false
            }
            return handled ? nil : event
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.enabled = enabled
        context.coordinator.input = input
        context.coordinator.next = next
    }
    func makeCoordinator() -> Coordinator { Coordinator(input: input, next: next) }
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let monitor = coordinator.monitor { NSEvent.removeMonitor(monitor) }
    }
    @MainActor final class Coordinator {
        weak var view: NSView?
        var monitor: Any?
        var enabled = true
        var input: (String) -> Void
        var next: () -> Void
        init(input: @escaping (String) -> Void, next: @escaping () -> Void) { self.input = input; self.next = next }
    }
}
