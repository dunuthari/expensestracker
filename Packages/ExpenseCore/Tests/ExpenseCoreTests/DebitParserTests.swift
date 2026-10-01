import XCTest
@testable import ExpenseCore

final class DebitParserTests: XCTestCase {
    let sample = "HNB SMS ALERT:INTERNET, Account:2090***2047,Location:Dialog Axiata PLC, LK,Amount(Approx.):159.00 LKR,Av.Bal:433408.92 LKR,Date:01.10.26,Time:09:50, Hot Line:0112462462"

    private func components(_ date: Date) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = BankMessageParser.defaultTimeZone
        return calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }

    func testParsesSampleDebit() throws {
        guard case .transaction(let tx) = BankMessageParser.parse(sample) else {
            return XCTFail("Expected a transaction")
        }
        XCTAssertEqual(tx.kind, .debit)
        XCTAssertEqual(tx.amount, Decimal(string: "159.00"))
        XCTAssertEqual(tx.currency, "LKR")
        XCTAssertEqual(tx.account, "2090***2047")
        XCTAssertEqual(tx.merchant, "Dialog Axiata PLC")
        XCTAssertEqual(tx.channel, "INTERNET")
        XCTAssertEqual(tx.balance, Decimal(string: "433408.92"))
        let c = components(tx.date)
        XCTAssertEqual(c.year, 2026)
        XCTAssertEqual(c.month, 10)
        XCTAssertEqual(c.day, 1)
        XCTAssertEqual(c.hour, 9)
        XCTAssertEqual(c.minute, 50)
    }

    func testLocationWithCommaKeepsFullName() throws {
        let text = "HNB SMS ALERT:POS, Account:2090***2047,Location:Keells Super, Colombo 07, LK,Amount(Approx.):4,820.50 LKR,Av.Bal:100.00 LKR,Date:30.09.26,Time:18:05, Hot Line:0112462462"
        guard case .transaction(let tx) = BankMessageParser.parse(text) else {
            return XCTFail("Expected a transaction")
        }
        XCTAssertEqual(tx.merchant, "Keells Super, Colombo 07")
        XCTAssertEqual(tx.amount, Decimal(string: "4820.50"))
        XCTAssertEqual(tx.channel, "POS")
    }

    func testSameMessageHasSameFingerprint() throws {
        guard case .transaction(let a) = BankMessageParser.parse(sample),
              case .transaction(let b) = BankMessageParser.parse("  " + sample + "\n") else {
            return XCTFail("Expected transactions")
        }
        XCTAssertEqual(a.fingerprint, b.fingerprint)
    }

    func testHnbAlertWithoutAmountIsUnrecognized() {
        XCTAssertEqual(BankMessageParser.parse("HNB SMS ALERT:Your OTP is 123456"), .unrecognized)
    }

    func testRandomTextIsUnrecognized() {
        XCTAssertEqual(BankMessageParser.parse("Hello, are we still meeting at 5?"), .unrecognized)
        XCTAssertEqual(BankMessageParser.parse(""), .unrecognized)
    }
}
