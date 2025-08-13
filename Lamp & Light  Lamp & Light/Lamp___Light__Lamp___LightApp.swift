//
//  Lamp___Light__Lamp___LightApp.swift
//  Lamp & Light  Lamp & Light
//
//  Created by Titan Lead Gen on 8/12/25.
//

import SwiftUI

@main
struct Lamp___Light__Lamp___LightApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
