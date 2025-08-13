import XCTest
import CoreData
@testable import Lamp___Light__Lamp___Light

final class RecapServiceTests: XCTestCase {

    func testWeeklyRecapGeneratesOnceWithMetrics() throws {
        let container = inMemoryContainer()
        let ctx = container.viewContext
        let profile = seedProfile(ctx)

        // Seed entries and plans for 3 days
        for d in 0..<3 {
            let e = Entry(context: ctx)
            e.id = UUID()
            e.createdAt = Calendar.current.date(byAdding: .day, value: -d, to: Date())
            e.kind = "prayer"
            e.content = "Prayed for peace."
            e.tags = ["peace"]
            e.profile = profile

            let p = DailyPlan(context: ctx)
            p.id = UUID()
            p.day = Calendar.current.date(byAdding: .day, value: -d, to: Date())
            p.scriptureRef = "Philippians 4:4-9"
            p.scriptureText = "Rejoice in the Lord alway..."
            p.application = "Reflect and rejoice."
            p.prayer = "Lord, grant peace."
            p.challenge = "Pray for five minutes."
            p.status = d == 0 ? "done" : "active"
            p.profile = profile
        }
        try ctx.save()

        let recap1 = try RecapService.generateThisWeek(context: ctx, profile: profile)
        let recap2 = try RecapService.generateThisWeek(context: ctx, profile: profile)
        XCTAssertEqual(recap1.objectID, recap2.objectID, "Should not duplicate recap for the same week")
        let metrics = (recap1.metrics as? [String: Any]) ?? [:]
        XCTAssertNotNil(metrics["prayers"])
        XCTAssertNotNil(metrics["completed"])
    }
} 