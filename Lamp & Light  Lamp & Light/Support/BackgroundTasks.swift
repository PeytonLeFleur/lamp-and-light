import BackgroundTasks
import CoreData

enum BackgroundTasksManager {
    static let refreshID = "com.titanleadgen.lampandlight.refresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshID, using: nil) { task in
            handleRefresh(task: task as! BGAppRefreshTask)
        }
    }

    static func scheduleDaily() {
        let req = BGAppRefreshTaskRequest(identifier: refreshID)
        let cal = Calendar.current
        let now = Date()
        var next = cal.date(bySettingHour: 6, minute: 0, second: 0, of: now) ?? now
        if next <= now { next = cal.date(byAdding: .day, value: 1, to: next)! }
        req.earliestBeginDate = next
        do { try BGTaskScheduler.shared.submit(req) } catch {
            Log.error("BG submit failed \(error.localizedDescription)")
        }
    }

    private static func handleRefresh(task: BGAppRefreshTask) {
        scheduleDaily()
        let ctx = PersistenceController.shared.container.newBackgroundContext()
        task.expirationHandler = {
            ctx.reset()
        }
        Task {
            let ok = await PlanRefresher.refreshPlanForToday(context: ctx)
            task.setTaskCompleted(success: ok)
        }
    }
}

enum PlanRefresher {
    static func todayRange() -> (Date, Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    static func existingPlan(context: NSManagedObjectContext, profile: Profile) -> DailyPlan? {
        let (start, end) = todayRange()
        let r: NSFetchRequest<DailyPlan> = DailyPlan.fetchRequest()
        r.predicate = NSPredicate(format: "profile == %@ AND day >= %@ AND day < %@", profile, start as NSDate, end as NSDate)
        r.fetchLimit = 1
        return try? context.fetch(r).first
    }

    static func getProfile(context: NSManagedObjectContext) -> Profile? {
        let r: NSFetchRequest<Profile> = Profile.fetchRequest()
        r.fetchLimit = 1
        return try? context.fetch(r).first
    }

    static func refreshPlanForToday(context: NSManagedObjectContext) async -> Bool {
        guard let profile = getProfile(context: context) else { return false }
        if existingPlan(context: context, profile: profile) != nil { return true }
        let plan = await PlanService.generateOrFetchToday(context: context, profile: profile)
        do {
            try await context.perform {
                if context.hasChanges { try? context.save() }
            }
            Analytics.track("plan_generated", ["ref": plan.scriptureRef ?? "unknown"]) 
            return true
        } catch {
            Log.error("Background plan error \(error.localizedDescription)")
            return false
        }
    }
} 