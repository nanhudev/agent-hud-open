import Foundation
import XCTest
@testable import AgentHUDCore

final class WindowsMCPWireExportTests: XCTestCase {
    func testExport() throws {
        guard let file = ProcessInfo.processInfo.environment["WINDOWS_MCP_WIRE_EXPORT"] else { throw XCTSkip("Contract build only") }
        let base = "\"jsonrpc\":\"2.0\",\"id\":1"
        var raw = ["", " \t\r", "{", "null", "true", "1", "[]", "[1]",
            "{\(base),\"method\":\"initialize\"}",
            "{\(base),\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2099\"}}",
            "{\(base),\"method\":\"ping\"}",
            "{\(base),\"method\":\"tools/list\"}",
            "{\(base),\"method\":\"tools/list\",\"params\":{\"cursor\":\"unknown\"}}",
            "{\(base),\"method\":\"unknown\"}",
            "{\(base),\"method\":\"server/discover\"}",
            "{\(base),\"method\":\"tools/call\"}",
            "{\(base),\"method\":\"tools/call\",\"params\":{\"name\":\"unknown\"}}",
            "{\(base),\"method\":\"tools/call\",\"params\":{\"name\":\"get_hud\",\"arguments\":[]}}",
            "{\(base),\"method\":\"tools/call\",\"params\":{\"name\":\"get_hud\",\"arguments\":{\"screen\":\"示例🎮\"}}}",
            #"{"jsonrpc":"2.0","method":"tools/call","params":{"name":"get_hud"}}"#,
            #"{"jsonrpc":"2.0","id":2,"result":{}}"#,
            #"{"jsonrpc":"1.0","method":"ping"}"#,
            #"{"jsonrpc":"2.0","id":null,"method":"ping"}"#,
            #"{"jsonrpc":"2.0","id":true,"method":"ping"}"#,
            #"{"jsonrpc":"2.0","id":1.0,"method":"ping"}"#,
            #"{"jsonrpc":"2.0","id":1e0,"method":"ping"}"#,
            #"{"jsonrpc":"2.0","id":1.5,"method":"ping"}"#,
            #"{"jsonrpc":"2.0","id":9223372036854775808,"method":"ping"}"#,
            #"{"jsonrpc":"2.0","id":1,"method":"ping","method":"unknown"}"#,
            #"{"jsonrpc":"2.0","id":"\ud800","method":"ping"}"#,
            #"{"jsonrpc":"2.0","id":1,"method":"ping","params":1}"#]
        let versionKey = "io.modelcontextprotocol/protocolVersion", capsKey = "io.modelcontextprotocol/clientCapabilities"
        for method in ["ping", "tools/list", "server/discover", "subscriptions/listen", "tools/call"] {
            for meta in ["{}", "{\"\(versionKey)\":\"2025-06-18\"}", "{\"\(versionKey)\":\"2026-07-28\"}", "{\"\(versionKey)\":\"2026-07-28\",\"\(capsKey)\":{}}", "{\"\(versionKey)\":\"2099\",\"\(capsKey)\":{}}"] {
                raw.append("{\(base),\"method\":\"\(method)\",\"params\":{\"name\":\"get_hud\",\"_meta\":\(meta)}}")
            }
        }
        raw.append("[\(raw[10]),\(raw[19]),\(raw.last!)]")
        raw.append("[\(raw[19])]")
        var cases: [[String: Any]] = []
        let valid = "{\(base),\"method\":\"tools/call\",\"params\":{\"name\":\"get_hud\"}}"
        for (state, lines) in [("result", raw), ("off", [valid]), ("notRunning", [valid]), ("unanswered", [valid]), ("failure", [valid]), ("image", [valid])] {
            for input in lines {
                var calls = 0
                let server = MCPServer(version: "wire-test") { request in
                    calls += 1
                    switch state {
                    case "off": return .off
                    case "notRunning": return .notRunning
                    case "unanswered": return .unanswered
                    case "failure": return .reply(.failure("Fixture failure."))
                    case "image": return .reply(.result(["fixture": .bool(true)], images: [MCPImage(mimeType: "image/png", data: Data([1, 2, 3]))]))
                    default: return .reply(.result(["echo": .object(["tool": .string(request.tool), "arguments": .object(request.arguments)])]))
                    }
                }
                let answers = server.lines(for: input)
                cases.append(["input": input, "state": state, "answers": answers, "calls": calls])
            }
        }
        let destination = URL(fileURLWithPath: file)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: ["cases": cases], options: [.sortedKeys]).write(to: destination)
    }
}
