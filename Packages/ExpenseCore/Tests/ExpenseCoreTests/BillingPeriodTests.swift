import XCTest
@testable import ExpenseCore

final class BillingPeriodTests: XCTestCase {
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    func testDateAfterStartDayBelongsToThisMonthsPeriod() {
        let p = BillingPeriod.containing(date(2026, 9, 27), startDay: 25, calendar: calendar)
        XCTAssertEqual(p.start, date(2026, 9, 25, 0))
        XCTAssertEqual(p.end, date(2026, 10, 25, 0))
    }

    func testDateBeforeStartDayBelongsToPreviousMonthsPeriod() {
        let p = BillingPeriod.containing(date(2026, 10, 1), startDay: 25, calendar: calendar)
        XCTAssertEqual(p.start, date(2026, 9, 25, 0))
        XCTAssertEqual(p.end, date(2026, 10, 25, 0))
        XCTAssertEqual(p.label(calendar: calendar), "25 Sep – 24 Oct")
    }

    func testStartDayItselfStartsANewPeriod() {
        let p = BillingPeriod.containing(date(2026, 10, 25, 0), startDay: 25, calendar: calendar)
        XCTAssertEqual(p.start, date(2026, 10, 25, 0))
    }

    func testCrossesYearBoundary() {
        let p = BillingPeriod.containing(date(2026, 1, 3), startDay: 25, calendar: calendar)
        XCTAssertEqual(p.start, date(2025, 12, 25, 0))
        XCTAssertEqual(p.end, date(2026, 1, 25, 0))
    }

    func testCalendarMonthLabel() {
        let p = BillingPeriod.containing(date(2026, 10, 15), startDay: 1, calendar: calendar)
        XCTAssertEqual(p.label(calendar: calendar), "October 2026")
    }

    func testShiftedMovesByMonths() {
        let p = BillingPeriod.containing(date(2026, 10, 1), startDay: 25, calendar: calendar)
        let previous = p.shifted(by: -1, calendar: calendar)
        XCTAssertEqual(previous.start, date(2026, 8, 25, 0))
        XCTAssertEqual(previous.end, date(2026, 9, 25, 0))
        XCTAssertEqual(previous.shifted(by: 1, calendar: calendar), p)
    }

    func testContainsIsHalfOpen() {
        let p = BillingPeriod.containing(date(2026, 10, 1), startDay: 25, calendar: calendar)
        XCTAssertTrue(p.contains(p.start))
        XCTAssertFalse(p.contains(p.end))
    }

    func testStartDayIsClamped() {
        XCTAssertEqual(BillingPeriod.containing(date(2026, 10, 15), startDay: 40, calendar: calendar).startDay, 28)
        XCTAssertEqual(BillingPeriod.containing(date(2026, 10, 15), startDay: 0, calendar: calendar).startDay, 1)
    }
}
