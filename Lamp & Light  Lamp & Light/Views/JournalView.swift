import SwiftUI
import CoreData

struct JournalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedKind = "prayer"
    @State private var content = ""
    @State private var emotion = ""
    @State private var tags = ""
    @State private var profile: Profile?
    @State private var todayEntries: [Entry] = []
    
    private let entryKinds = ["prayer", "journal", "insight"]
    
    var body: some View {
        AppScaffold(title: "Journal") {
            // Composer
            VStack(alignment: .leading, spacing: 16) {
                Badge(text: "New Entry", color: S.mint)
                Picker("Entry Type", selection: $selectedKind) {
                    ForEach(entryKinds, id: \.self) { kind in
                        Text(kind.capitalized).tag(kind)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content").font(AppFontV3.h2())
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(16)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emotion").font(AppFontV3.h2())
                        TextField("How are you feeling?", text: $emotion)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags").font(AppFontV3.h2())
                        TextField("faith, trust, hope", text: $tags)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                PillButton(title: "Save", style: .primary, systemImage: "tray.and.arrow.down.fill") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { saveEntry() }
                }
                .disabled(content.isEmpty)
                .accessibilityHint(Text("Saves your journal entry"))
            }
            .card()
            
            // Today’s entries card
            VStack(alignment: .leading, spacing: 12) {
                Badge(text: "Today’s Entries", color: .blue)
                if todayEntries.isEmpty {
                    EmptyStateView(title: "Start your journal", message: "Write a short prayer or note for today.")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(todayEntries) { entry in
                            EntryRow(entry: entry).card()
                        }
                    }
                }
            }
            .card()
        }
        .onAppear { loadProfile(); loadTodayEntries() }
    }
    
    private func loadProfile() {
        let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
        fetchRequest.fetchLimit = 1
        do { profile = try viewContext.fetch(fetchRequest).first } catch { }
    }
    
    private func loadTodayEntries() {
        guard let profile = profile else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "profile == %@ AND createdAt >= %@ AND createdAt < %@", profile, today as NSDate, tomorrow as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)]
        todayEntries = (try? viewContext.fetch(fetchRequest)) ?? []
    }
    
    private func saveEntry() {
        guard let profile = profile, !content.isEmpty else { return }
        let newEntry = Entry(context: viewContext)
        newEntry.id = UUID(); newEntry.createdAt = Date(); newEntry.kind = selectedKind
        newEntry.content = content
        newEntry.emotion = emotion.isEmpty ? nil : emotion
        newEntry.tags = tags.isEmpty ? nil : tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        newEntry.profile = profile
        do {
            try viewContext.save()
            content = ""; emotion = ""; tags = ""; loadTodayEntries()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    }
}

struct EntryRow: View {
    let entry: Entry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Badge(text: entry.kind?.capitalized ?? ""); Spacer(); Text(entry.createdAt ?? Date(), style: .time).font(AppFontV3.caption()).foregroundStyle(.secondary) }
            Text(entry.content ?? "").font(AppFontV3.body()).lineLimit(3)
            if let emotion = entry.emotion, !emotion.isEmpty { HStack { Image(systemName: "heart.fill"); Text("Feeling: \(emotion)").font(AppFontV3.caption()).foregroundStyle(.secondary) } }
            if let tags = entry.tags, !tags.isEmpty {
                HStack { ForEach(tags, id: \.self) { tag in Text(tag).font(AppFontV3.caption()).padding(.horizontal, 8).padding(.vertical, 4).background(Color(.systemGray5)).clipShape(Capsule()) } }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    JournalView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 