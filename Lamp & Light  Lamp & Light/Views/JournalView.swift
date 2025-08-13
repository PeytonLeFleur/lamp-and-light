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
            VStack(spacing: 20) {
                // Entry Creation Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("New Entry")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Kind Selection
                    Picker("Entry Type", selection: $selectedKind) {
                        ForEach(entryKinds, id: \.self) { kind in
                            Text(kind.capitalized)
                                .tag(kind)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Content Editor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Optional Fields
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Emotion")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("How are you feeling?", text: $emotion)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("faith, trust, hope", text: $tags)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    Button(action: saveEntry) {
                        Text("Save Entry")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(content.isEmpty ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(content.isEmpty)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // Today's Entries
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Entries")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if todayEntries.isEmpty {
                        Text("No entries yet today")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        List {
                            ForEach(todayEntries) { entry in
                                EntryRow(entry: entry)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Journal")
            .onAppear {
                loadProfile()
                loadTodayEntries()
            }
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
        } catch {
            print("Error saving entry: \(error)")
        }
    }
}

struct EntryRow: View {
    let entry: Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.kind?.capitalized ?? "")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(kindColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(entry.createdAt ?? Date(), style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(entry.content ?? "")
                .font(.body)
                .lineLimit(3)
            
            if let emotion = entry.emotion, !emotion.isEmpty {
                Text("Feeling: \(emotion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let tags = entry.tags, !tags.isEmpty {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var kindColor: Color {
        switch entry.kind {
        case "prayer":
            return .blue
        case "journal":
            return .green
        case "insight":
            return .orange
        default:
            return .gray
        }
    }
}

#Preview {
    JournalView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 