import CoreData
import Foundation

enum StreakService {
    static func markActive(context: NSManagedObjectContext, profile: Profile, date: Date = Date()) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)
        if let last = profile.lastActive {
            let lastDay = cal.startOfDay(for: last)
            if let diff = cal.dateComponents([.day], from: lastDay, to: today).day {
                if diff == 1 { profile.streakCount += 1 }
                else if diff > 1 { profile.streakCount = 1 }
            }
        } else {
            profile.streakCount = 1
        }
        profile.lastActive = date
        try? context.save()
        if profile.streakCount == 7 || profile.streakCount == 14 {
            Ratings.maybeAsk(for: "streak")
        }
    }

    static func incrementWeekly(context: NSManagedObjectContext, profile: Profile) {
        profile.weeklyCompleted += 1
        try? context.save()
    }

    static func resetWeeklyIfNewWeek(context: NSManagedObjectContext, profile: Profile, now: Date = Date()) {
        let cal = Calendar.current
        let key = "lamp.week.\(cal.component(.yearForWeekOfYear, from: now))-\(cal.component(.weekOfYear, from: now))"
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: key) == false {
            profile.weeklyCompleted = 0
            try? context.save()
            defaults.set(true, forKey: key)
        }
    }
} 