import Foundation
import XCTest
@testable import AgentHUDCore

@MainActor
final class WindowsLayoutExportTests: XCTestCase {
    func testExport() throws {
        guard let file = ProcessInfo.processInfo.environment["WINDOWS_LAYOUT_EXPORT"] else { throw XCTSkip("Contract build only") }
        func json<T: Encodable>(_ value: T) throws -> Any {
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(value), options: [.fragmentsAllowed])
        }
        let inputs: [[String: Any]] = [
            [:], ["unknown": true, "style": ["width": 540, "spacing": "regular", "separators": true]],
            ["sections": ["sessions", "blocks", "sessions", "bad"], "hiddenSections": ["sessions", "blocks", "sessions"], "order": ["b", "a", "b", ""]],
            ["blocks": ["X": ["widget": "ring", "columns": 4, "ringSize": "medium", "span": "full", "period": "day", "countdown": true,
                              "measures": ["quota", "tokenTotal", "quota", "bad"], "accounts": ["b", "a", "a", ""], "rows": ["r2", "r1", "r2"], "hiddenRows": ["b", "a", "b", ""]], "Empty": [:]]],
            ["blocks": ["X": ["widget": "bogus", "columns": true, "hidden": 1, "countdown": 0, "measures": ["bad", 3], "ringSize": "x", "span": "x"], "bad": 4]],
            ["style": ["width": 640, "spacing": "compact", "separators": false], "countdown": false],
            ["style": ["width": 721, "spacing": "unknown", "separators": "no"]],
            ["sessions": ["limit": 5, "period": "day", "sort": "active", "states": ["ended", "running", "waiting"]]],
            ["sessions": ["limit": 10, "period": "3d", "sort": "date", "agents": ["ChatGPT", "Codex", "Claude", "ChatGPT", ""], "projects": ["z", "a", "z", ""], "states": ["ended", "waiting", "bad"]]],
            ["sessions": ["limit": true, "period": "6h", "sort": 3], "tokens": ["period": "month", "agents": ["Codex", "ChatGPT", "Claude"], "models": ["z", "a", "z", ""]]],
            ["hud": ["agents": ["Codex", "ChatGPT", "Grok CLI", "Grok", "OpenCode Go", "OpenCode", "Qoder", "Qoder CLI"]]],
            ["blocks": ["": ["hidden": true]], "sessions": ["limit": 2.0], "style": ["width": 640.0]]
        ]
        var cases: [[String: Any]] = []
        for input in inputs {
            let layout = try JSONDecoder().decode(PanelLayout.self, from: JSONSerialization.data(withJSONObject: input))
            cases.append(["input": input, "normalized": try json(layout.normalized())])
        }
        let suite = "AgentHUD-Windows-layout-export-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PanelLayoutStore(defaults: defaults)
        var trace: [[String: Any]] = []
        func capture(_ step: String) throws {
            let persisted: Any = try defaults.data(forKey: SettingsStore.Keys.panelLayout).map {
                try JSONSerialization.jsonObject(with: $0)
            } ?? NSNull()
            trace.append(["step": step, "revision": store.revision, "shared": try json(store.effective),
                "A": try json(store.effective(for: "A")), "B": try json(store.effective(for: "B")),
                "usesSharedA": store.usesShared("A"), "draftA": store.hasDraft(on: "A"),
                "draftB": store.hasDraft(on: "B"), "persisted": persisted])
        }
        try capture("initial")
        let first = PanelLayout(style: PanelStyle(width: 640))
        store.propose(first); try capture("propose-shared")
        store.propose(first); try capture("same-proposal")
        store.propose(.own(PanelLayout(tokens: .init(period: .week))), for: "A"); try capture("propose-own-A")
        store.savePanel(on: "B"); try capture("save-shared-on-B")
        store.savePanel(on: "A"); try capture("save-own-A")
        store.propose(PanelLayout()); store.propose(.shared, for: "A"); try capture("draft-shared-and-share-A")
        store.savePanel(on: "A"); try capture("save-share-A-leaves-shared-draft")
        store.discardPanel(on: "B"); try capture("discard-shared-on-B")
        store.revert(.screen("A")); try capture("revert-A")
        store.revert(.screen("A")); try capture("revert-A-again")
        store.revert(); try capture("revert-shared")
        store.reset(); try capture("reset-default-keeps-previous")
        let result: [String: Any] = ["upstreamRevision": "bf19ac98da11fe0f5967f5a124d42f0da4bf2cf9", "normalization": cases, "trace": trace]
        let target = URL(fileURLWithPath: file)
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]).write(to: target)
    }
}
