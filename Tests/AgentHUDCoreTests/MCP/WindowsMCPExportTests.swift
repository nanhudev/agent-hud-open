import AgentHUDSupport
import Foundation
import XCTest
@testable import AgentHUDCore

/// Export the unchanged source contract for the Windows platform host.
final class WindowsMCPExportTests: XCTestCase {
    func testExport() throws {
        guard let path = ProcessInfo.processInfo.environment["WINDOWS_CONTRACT_EXPORT"] else {
            throw XCTSkip("Explicit source-contract export only")
        }
        let payload = JSONValue.object([
            "upstreamRevision": .string("bf19ac98da11fe0f5967f5a124d42f0da4bf2cf9"),
            "instructions": .string(MCPTools.instructions),
            "tools": .array(MCPTools.definitions),
            "handshakeRevisions": .array(MCPProtocol.handshakeRevisions.map(JSONValue.string)),
            "statelessRevisions": .array(MCPProtocol.statelessRevisions.map(JSONValue.string)),
            "approvalWaitChoices": .array(Settings.approvalWaitChoices.map { .integer(Int64($0)) }),
        ])
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(payload).write(to: url, options: .atomic)
    }
}
