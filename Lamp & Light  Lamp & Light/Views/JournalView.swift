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
        NavigationView {
            AppBackground {
                VStack(spacing: 20) {
                    // Entry Creation Section
                    VStack(alignment: .leading, spacing: 16) {
                        Badge(text: "New Entry", color: AppColor.primaryGreen)
                        
                        Picker("Entry Type", selection: $selectedKind) {
                            ForEach(entryKinds, id: \.self) { kind in
                                Text(kind.capitalized).tag(kind)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content").font(AppFont.headline()).foregroundColor(AppColor.ink)
                            TextEditor(text: $content)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(AppColor.mist)
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColor.softGreen.opacity(0.3), lineWidth: 1))
                                .accessibilityLabel(Text("Entry content"))
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Emotion").font(AppFont.headline()).foregroundColor(AppColor.ink)
                                TextField("How are you feeling?", text: $emotion)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColor.softGreen.opacity(0.3), lineWidth: 1))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tags").font(AppFont.headline()).foregroundColor(AppColor.ink)
                                TextField("faith, trust, hope", text: $tags)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColor.softGreen.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal)
                        
                        PillButton(title: "Save Entry", style: .primary, systemImage: "plus.circle.fill") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { saveEntry() }
                        }
                        .disabled(content.isEmpty)
                        .padding(.horizontal)
                        .accessibilityHint(Text("Saves your journal entry"))
                    }
                    .card()
                    
                    // Today's Entries
                    VStack(alignment: .leading, spacing: 12) {
                        Badge(text: "Today's Entries", color: AppColor.sky)
                        
                        if todayEntries.isEmpty {
                            EmptyStateView(title: "Start your journal", message: "Write a short prayer or note for today.", actionTitle: "Add entry") {
                                // focus editor hint: no direct focus API, ensure visible
                            }
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
                    
                    Spacer()
                }
            }
            .navigationTitle("Journal")
            .onAppear { loadProfile(); loadTodayEntries() }
        }
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
    
    private func loadTodayEntries() {
        guard let profile = profile else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "profile == %@ AND createdAt >= %@ AND createdAt < %@", profile, today as NSDate, tomorrow as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)]
        
        do {
            todayEntries = try viewContext.fetch(fetchRequest)
        } catch {
            print("Error loading today's entries: \(error)")
        }
    }
    
    private func saveEntry() {
        guard let profile = profile, !content.isEmpty else { return }
        
        let newEntry = Entry(context: viewContext)
        newEntry.id = UUID()
        newEntry.createdAt = Date()
        newEntry.kind = selectedKind
        newEntry.content = content
        newEntry.emotion = emotion.isEmpty ? nil : emotion
        newEntry.tags = tags.isEmpty ? nil : tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        newEntry.profile = profile
        
        do {
            try viewContext.save()
            
            // Reset form
            content = ""
            emotion = ""
            tags = ""
            
            // Reload entries
            loadTodayEntries()
            
            // Haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("Error saving entry: \(error)")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

struct EntryRow: View {
    let entry: Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Badge(text: entry.kind?.capitalized ?? "", color: kindColor)
                Spacer()
                Text(entry.createdAt ?? Date(), style: .time)
                    .font(AppFont.caption())
                    .foregroundColor(AppColor.slate.opacity(0.7))
            }
            
            Text(entry.content ?? "")
                .font(AppFont.body())
                .lineLimit(3)
                .foregroundColor(AppColor.ink)
            
            if let emotion = entry.emotion, !emotion.isEmpty {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(AppColor.coral)
                    Text("Feeling: \(emotion)")
                        .font(AppFont.caption())
                        .foregroundColor(AppColor.slate)
                }
            }
            
            if let tags = entry.tags, !tags.isEmpty {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(AppFont.caption())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColor.softGreen.opacity(0.3))
                            .foregroundColor(AppColor.deepGreen)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var kindColor: Color {
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
}

#Preview {
    JournalView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 