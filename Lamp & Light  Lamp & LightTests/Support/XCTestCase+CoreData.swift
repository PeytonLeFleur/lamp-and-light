import XCTest
import CoreData
@testable import Lamp___Light__Lamp___Light

extension XCTestCase {
    func inMemoryContainer() -> NSPersistentContainer {
        let mom = NSManagedObjectModel.mergedModel(from: [Bundle.main, Bundle(for: type(of: self))])!
        let container = NSPersistentContainer(name: "Model", managedObjectModel: mom)
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