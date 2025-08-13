import SwiftUI
import CoreData

struct TimelineView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var profile: Profile?
    @State private var timelineItems: [TimelineItem] = []
    
    var body: some View {
        NavigationView {
            AppBackground {
                Group {
                    if timelineItems.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "clock")
                                .font(.system(size: 60))
                                .foregroundColor(AppColor.slate.opacity(0.3))
                            Text("No timeline items yet")
                                .font(AppFont.headline())
                                .foregroundColor(AppColor.ink)
                            Text("Your journal entries and daily plans will appear here")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.slate)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(groupedItems.keys.sorted(by: >), id: \.self) { month in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(monthFormatter.string(from: month))
                                            .font(AppFont.headline())
                                            .foregroundColor(AppColor.ink)
                                            .padding(.horizontal, 4)
                                        
                                        ForEach(groupedItems[month] ?? [], id: \.id) { item in
                                            TimelineItemRow(item: item)
                                                .card()
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Timeline")
            .onAppear {
                loadProfile()
                loadTimelineItems()
            }
        }
    }
    
    private var groupedItems: [Date: [TimelineItem]] {
        Dictionary(grouping: timelineItems) { item in
            Calendar.current.dateInterval(of: .month, for: item.date)?.start ?? item.date
        }
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    private func loadProfile() {
        let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let profiles = try viewContext.fetch(fetchRequest)
            profile = profiles.first
        } catch {
            print("Error loading profile: \(error)")
        }
    }
    
    private func loadTimelineItems() {
        guard let profile = profile else { return }
        
        var items: [TimelineItem] = []
        
        // Load entries
        let entryFetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        entryFetchRequest.predicate = NSPredicate(format: "profile == %@", profile)
        entryFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)]
        
        do {
            let entries = try viewContext.fetch(entryFetchRequest)
            for entry in entries {
                items.append(TimelineItem(
                    id: entry.id?.uuidString ?? UUID().uuidString,
                    date: entry.createdAt ?? Date(),
                    type: .entry(entry)
                ))
            }
        } catch {
            print("Error loading entries: \(error)")
        }
        
        // Load daily plans
        let planFetchRequest: NSFetchRequest<DailyPlan> = DailyPlan.fetchRequest()
        planFetchRequest.predicate = NSPredicate(format: "profile == %@", profile)
        planFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DailyPlan.day, ascending: false)]
        
        do {
            let plans = try viewContext.fetch(planFetchRequest)
            for plan in plans {
                items.append(TimelineItem(
                    id: plan.id?.uuidString ?? UUID().uuidString,
                    date: plan.day ?? Date(),
                    type: .dailyPlan(plan)
                ))
            }
        } catch {
            print("Error loading daily plans: \(error)")
        }
        
        // Sort by date (newest first)
        timelineItems = items.sorted { $0.date > $1.date }
    }
}

struct TimelineItem: Identifiable {
    let id: String
    let date: Date
    let type: TimelineItemType
}

enum TimelineItemType {
    case entry(Entry)
    case dailyPlan(DailyPlan)
}

struct TimelineItemRow: View {
    let item: TimelineItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFont.headline())
                        .lineLimit(1)
                        .foregroundColor(AppColor.ink)
                    
                    Text(dateFormatter.string(from: item.date))
                        .font(AppFont.caption())
                        .foregroundColor(AppColor.slate.opacity(0.7))
                }
                
                Spacer()
                
                if case .entry(let entry) = item.type {
                    Badge(text: entry.kind?.capitalized ?? "", color: kindColor)
                }
            }
            
            Text(content)
                .font(AppFont.body())
                .lineLimit(3)
                .foregroundColor(AppColor.ink)
        }
        .padding(.vertical, 4)
    }
    
    private var iconName: String {
        switch item.type {
        case .entry:
            return "text.bubble.fill"
        case .dailyPlan:
            return "book.fill"
        }
    }
    
    private var iconColor: Color {
        switch item.type {
        case .entry:
            return AppColor.sky
        case .dailyPlan:
            return AppColor.primaryGreen
        }
    }
    
    private var title: String {
        switch item.type {
        case .entry(_):
            return "Journal Entry"
        case .dailyPlan(let plan):
            return "Daily Plan: \(plan.scriptureRef ?? "")"
        }
    }
    
    private var content: String {
        switch item.type {
        case .entry(let entry):
            return entry.content ?? ""
        case .dailyPlan(let plan):
            return plan.application ?? ""
        }
    }
    
    private var kindColor: Color {
        if case .entry(let entry) = item.type {
            switch entry.kind {
            case "prayer":
                return AppColor.sky
            case "journal":
                return AppColor.primaryGreen
            case "insight":
                return AppColor.sunshine
            default:
                return AppColor.slate
            }
        }
        return AppColor.slate
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    TimelineView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 