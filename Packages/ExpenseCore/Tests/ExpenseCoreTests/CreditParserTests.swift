import XCTest
@testable import ExpenseCore

final class CreditParserTests: XCTestCase {
    let sample = "LKR 1,500.00 credited to Ac No:20902XXXXX47 on 29/09/26 21:47:35 Reason:CEFT-NETLFIX PAYMENT Bal:LKR 433,567.92 Protect from scams DO NOT SHARE ACCOUNT DETAILS /OTP Hotline 0112462462"

    func testParsesSampleCredit() throws {
        guard case .transaction(let tx) = BankMessageParser.parse(sample) else {
            return XCTFail("Expected a transaction")
        }
        XCTAssertEqual(tx.kind, .credit)
        XCTAssertEqual(tx.amount, Decimal(string: "1500.00"))
        XCTAssertEqual(tx.currency, "LKR")
        XCTAssertEqual(tx.account, "20902XXXXX47")
        XCTAssertEqual(tx.merchant, "CEFT-NETLFIX PAYMENT")
        XCTAssertEqual(tx.channel, "CEFT")
        XCTAssertEqual(tx.balance, Decimal(string: "433567.92"))

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = BankMessageParser.defaultTimeZone
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: tx.date)
        XCTAssertEqual(c.year, 2026)
        XCTAssertEqual(c.month, 9)
        XCTAssertEqual(c.day, 29)
        XCTAssertEqual(c.hour, 21)
        XCTAssertEqual(c.minute, 47)
        XCTAssertEqual(c.second, 35)
    }

    func testCreditIsNeverParsedAsDebit() throws {
        guard case .transaction(let tx) = BankMessageParser.parse(sample) else {
            return XCTFail("Expected a transaction")
        }
        XCTAssertNotEqual(tx.kind, .debit)
    }

    func testDebitIsNeverParsedAsCredit() throws {
        let debit = "HNB SMS ALERT:INTERNET, Account:2090***2047,Location:Dialog Axiata PLC, LK,Amount(Approx.):159.00 LKR,Av.Bal:433408.92 LKR,Date:01.10.26,Time:09:50, Hot Line:0112462462"
        guard case .transaction(let tx) = BankMessageParser.parse(debit) else {
            return XCTFail("Expected a transaction")
        }
        XCTAssertEqual(tx.kind, .debit)
    }

    func testCreditWithoutReasonStillParses() throws {
        let text = "LKR 250.00 credited to Ac No:20902XXXXX47 on 01/10/26 08:00:00 Bal:LKR 1,000.00"
        guard case .transaction(let tx) = BankMessageParser.parse(text) else {
            return XCTFail("Expected a transaction")
        }
        XCTAssertEqual(tx.merchant, "Credit")
        XCTAssertEqual(tx.amount, Decimal(string: "250.00"))
    }
}
