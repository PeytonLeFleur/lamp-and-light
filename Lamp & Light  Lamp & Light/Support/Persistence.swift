import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create a sample profile for preview
        let sampleProfile = Profile(context: viewContext)
        sampleProfile.id = UUID()
        sampleProfile.createdAt = Date()
        sampleProfile.displayName = "Sample User"
        sampleProfile.denomination = "Christian"
        sampleProfile.goals = "Grow in faith and prayer"
        
        // Create a sample daily plan
        let samplePlan = DailyPlan(context: viewContext)
        samplePlan.id = UUID()
        samplePlan.day = Date()
        samplePlan.scriptureRef = "Psalm 46:1-3"
        samplePlan.scriptureText = "God is our refuge and strength, a very present help in trouble."
        samplePlan.application = "A short reflection on this passage for today."
        samplePlan.prayer = "Lord, help me trust you and walk in your word today. Amen."
        samplePlan.challenge = "Spend five quiet minutes praying through this passage."
        samplePlan.status = "active"
        samplePlan.profile = sampleProfile
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Lamp___Light__Lamp___Light")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Enable lightweight migration
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        // Create profile on first run
        createProfileIfNeeded()
    }
    
    private func createProfileIfNeeded() {
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let existingProfiles = try context.fetch(fetchRequest)
            if existingProfiles.isEmpty {
                // Create default profile
                let newProfile = Profile(context: context)
                newProfile.id = UUID()
                newProfile.createdAt = Date()
                newProfile.displayName = "User"
                newProfile.denomination = ""
                newProfile.goals = ""
                
                try context.save()
                print("Created default profile")
            }
        } catch {
            print("Error checking/creating profile: \(error)")
        }
    }
} 