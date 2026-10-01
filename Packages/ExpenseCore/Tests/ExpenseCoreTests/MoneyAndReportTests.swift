import XCTest
@testable import ExpenseCore

final class MoneyAndReportTests: XCTestCase {
    func testFormatsAmounts() {
        XCTAssertEqual(Money.format(Decimal(string: "159")!), "LKR 159.00")
        XCTAssertEqual(Money.format(Decimal(string: "1500")!), "LKR 1,500.00")
        XCTAssertEqual(Money.format(Decimal(string: "433408.92")!), "LKR 433,408.92")
        XCTAssertEqual(Money.format(Decimal(string: "1500")!, signed: true), "+LKR 1,500.00")
        XCTAssertEqual(Money.format(Decimal(string: "-20.5")!), "-LKR 20.50")
        XCTAssertEqual(Money.format(Decimal(string: "9.5")!, currency: "USD"), "USD 9.50")
    }

    func testTotalsPerGroupSortedLargestFirst() {
        let items = [
            ReportItem(groupID: "food", amount: 100),
            ReportItem(groupID: "transport", amount: 300),
            ReportItem(groupID: "food", amount: 250),
            ReportItem(groupID: nil, amount: 50)
        ]
        let totals = Report.totals(items)
        XCTAssertEqual(totals.map(\.id), ["transport", "food", Report.ungroupedID])
        XCTAssertEqual(totals[1].total, 350)
        XCTAssertEqual(totals[1].count, 2)
        XCTAssertEqual(Report.sum(items), 700)
    }

    func testGroupTotalsAddUpToPeriodTotal() {
        let items = (1...20).map { ReportItem(groupID: $0 % 3 == 0 ? nil : "g\($0 % 4)", amount: Decimal($0) * 10) }
        let grouped = Report.totals(items).reduce(Decimal(0)) { $0 + $1.total }
        XCTAssertEqual(grouped, Report.sum(items))
    }

    func testShareHandlesZeroTotal() {
        XCTAssertEqual(Report.share(10, of: 0), 0)
        XCTAssertEqual(Report.share(25, of: 100), 0.25, accuracy: 0.0001)
    }
}
