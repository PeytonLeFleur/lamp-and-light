import XCTest
import CoreData
@testable import Lamp___Light__Lamp___Light

final class PlanServiceTests: XCTestCase {

    func testGenerateOrFetchTodayIsIdempotentAndThemeAware() async throws {
        let container = inMemoryContainer()
        let ctx = container.viewContext
        let profile = seedProfile(ctx)

        // Seed entries with anxiety tag
        for i in 0..<3 {
            let e = Entry(context: ctx)
            e.id = UUID()
            e.createdAt = Calendar.current.date(byAdding: .day, value: -i, to: Date())
            e.kind = "journal"
            e.content = "Feeling anxious but hopeful."
            e.tags = ["anxiety"]
            e.profile = profile
        }
        try ctx.save()

        let plan1 = await PlanService.generateOrFetchToday(context: ctx, profile: profile)
        let plan2 = await PlanService.generateOrFetchToday(context: ctx, profile: profile)

        XCTAssertEqual(plan1.objectID, plan2.objectID, "Should not duplicate today’s plan")
        XCTAssertFalse((plan1.scriptureRef ?? "").isEmpty)
        XCTAssertFalse((plan1.prayer ?? "").isEmpty)
    }
} 