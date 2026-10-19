import Foundation
import XCTest
@testable import AgentHUDCore

final class WindowsBalanceExportTests: XCTestCase {
    func testExport() throws {
        guard let file = ProcessInfo.processInfo.environment["WINDOWS_BALANCE_EXPORT"] else { throw XCTSkip("Contract build only") }
        let base: Double = 1_790_001_000
        let inputs: [[(Double, [String: String])]] = [
            [(200, ["CNY": "9"]), (100, ["CNY": "1.5"]), (2, ["CNY": "0.25", "USD": "0.04"]), (1, ["CNY": "0.25"])],
            [], [(1, ["CNY": "0", "USD": "0"])],
            [(0.25, ["CNY": "0.125", "USD": "0.02"]), (0, ["CNY": "0.125"])],
            [(23.99, ["CNY": "0.5"]), (24.01, ["CNY": "0.25"])],
            [(2, ["CNY": "1"]), (2, ["CNY": "0.5"])]]
        func string(_ value: Decimal?) -> Any {
            if let value { return NSDecimalNumber(decimal: value).stringValue }
            return NSNull()
        }
        var cases: [[String: Any]] = []
        for offset in [0.0, 321.0] {
            let now = Date(timeIntervalSince1970: base + offset)
            for input in inputs {
                let costs = input.map { CostBucket(start: Date(timeIntervalSince1970: base - $0.0 * 3600), amounts: $0.1.mapValues { Decimal(string: $0)! }) }
                let billing = APIBilling(vendor: "DeepSeek", balances: [], isAvailable: true, updatedAt: now, costs: costs, notice: nil)
                for (period, duration) in [("day", 86400.0), ("week", 604800.0), ("month", 2592000.0)] {
                    let end = ceil(now.timeIntervalSince1970 / 900) * 900
                    let interval = DateInterval(start: Date(timeIntervalSince1970: end-duration), end: Date(timeIntervalSince1970: end))
                    for currency in ["CNY", "USD"] {
                        let spend = billing.spend(currency: currency, during: interval, now: now)
                        cases.append(["now": now.timeIntervalSince1970, "period": period, "currency": currency,
                            "costs": costs.map { ["at": $0.start.timeIntervalSince1970, "amounts": $0.amounts.mapValues { NSDecimalNumber(decimal: $0).stringValue }] },
                            "cost": string(spend?.cost), "perDay": string(spend?.perDay), "span": spend?.span ?? 0,
                            "runsOut": spend?.runsOutAt(Decimal(string: "8.5")!, readAt: now.addingTimeInterval(-600))?.timeIntervalSince1970 as Any? ?? NSNull()])
                    }
                }
            }
        }
        let destination = URL(fileURLWithPath: file)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: ["cases": cases], options: [.sortedKeys]).write(to: destination)
    }
}
