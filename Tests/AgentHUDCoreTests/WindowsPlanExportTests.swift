import Foundation
import XCTest
@testable import AgentHUDCore

final class WindowsPlanExportTests: XCTestCase {
    func testExport() throws {
        guard let file = ProcessInfo.processInfo.environment["WINDOWS_PLAN_EXPORT"] else { throw XCTSkip("Contract build only") }
        let blocks: [PanelBlockInfo] = [
            .init(key: "A", kind: .quota, rowKeys: ["5h", "week"], accounts: [.init(id: "a", rowKeys: ["5h", "week"])]),
            .init(key: "B", kind: .quota, rowKeys: ["day"], accounts: [.init(id: "b", rowKeys: ["day"])]),
            .init(key: "api:Example", kind: .billing, accounts: [.init(id: "wallet")])
        ]
        func blockJSON(_ block: PanelBlockPlan) -> [String: Any] {
            ["key": block.key, "kind": block.kind.rawValue, "widget": block.widget.rawValue,
             "measures": block.measures.map(\.rawValue), "hiddenRows": block.hiddenRows.sorted(), "rows": block.rowOrder,
             "accounts": block.accounts.sorted(), "countdown": block.countdown, "columns": block.columns,
             "ringSize": block.ringSize.rawValue, "span": block.span.rawValue, "period": block.period.rawValue]
        }
        var cases: [[String: Any]] = []
        let variants: [[String: Any]] = [
            ["blocks": ["A": ["widget": "ring", "span": "half"], "B": ["widget": "number", "span": "half"]]],
            ["blocks": ["A": ["widget": "bar", "span": "half"], "B": ["widget": "ring", "span": "half"]]],
            ["tokens": ["period": "month"], "blocks": ["A": ["widget": "chart", "span": "half", "measures": ["quota"]], "B": ["widget": "number", "span": "half", "columns": 6], "api:Example": ["widget": "ring", "span": "half"]]],
            ["order": ["api:Example", "A"], "blocks": ["A": ["hiddenRows": ["5h", "week"]], "B": ["accounts": ["absent"]], "api:Example": ["widget": "chart", "measures": ["quota", "cost"], "period": "week"]]]
        ]
        for width in [480, 502, 506, 510, 540, 720] {
            for spacing in ["compact", "regular", "roomy"] {
                for pairs in [false, true] {
                    for variant in variants {
                        var input = variant
                        input["style"] = ["width": width, "spacing": spacing]
                        let layout = try JSONDecoder().decode(PanelLayout.self, from: JSONSerialization.data(withJSONObject: input))
                        let content = Double(width - 36)
                        let plan = PanelLayoutPlan(layout: layout, blocks: blocks, contentWidth: content, pairs: pairs)
                        cases.append(["layout": input, "contentWidth": content, "pairs": pairs,
                            "halvesFit": plan.halvesFit, "sections": plan.sections.map(\.rawValue),
                            "lines": plan.lines.map { $0.map(blockJSON) }])
                    }
                }
            }
        }
        let descriptors: [[String: Any]] = blocks.map { block in
            ["key": block.key, "kind": block.kind.rawValue, "rowKeys": block.rowKeys,
             "accounts": block.accounts.map { ["id": $0.id, "rowKeys": $0.rowKeys] as [String: Any] }]
        }
        var grids: [[String: Any]] = []
        for width in [218.0, 230.0, 247.0, 337.0, 404.0, 684.0] {
            for columns in 2...6 {
                grids.append(["width": width, "columns": columns, "cellWidth": PanelLines.cellWidth(in: width, columns: columns),
                              "fittingColumns": PanelLines.columns(fitting: width)])
            }
        }
        let result: [String: Any] = ["upstreamRevision": "bf19ac98da11fe0f5967f5a124d42f0da4bf2cf9",
            "blocks": descriptors, "cases": cases, "grids": grids, "narrowestHalf": PanelLines.narrowestHalf,
            "narrowestCell": PanelLines.narrowestCell]
        let target = URL(fileURLWithPath: file)
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]).write(to: target)
    }
}
