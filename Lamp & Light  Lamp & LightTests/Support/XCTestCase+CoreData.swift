import XCTest
import CoreData
@testable import Lamp___Light__Lamp___Light

extension XCTestCase {
    func inMemoryContainer() -> NSPersistentContainer {
        // Try to load the model from the app bundle using known names
        let possibleNames = ["Lamp___Light__Lamp___Light", "LampAndLight"]
        var model: NSManagedObjectModel? = nil
        for name in possibleNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "momd"), let m = NSManagedObjectModel(contentsOf: url) {
                model = m
                break
            }
        }
        if model == nil {
            model = NSManagedObjectModel.mergedModel(from: [Bundle.main])
        }
        let container = NSPersistentContainer(name: "Lamp___Light__Lamp___Light", managedObjectModel: model!)
        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [desc]
        container.loadPersistentStores { _, _ in }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }

    func seedProfile(_ ctx: NSManagedObjectContext, name: String = "Test") -> Profile {
        let p = Profile(context: ctx)
        p.id = UUID()
        p.createdAt = Date()
        p.displayName = name
        p.weeklyGoal = 5
        try? ctx.save()
        return p
    }
} 