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
            TabView {
                TodayView()
                    .tabItem {
                        Image(systemName: "sun.max")
                        Text("Today")
                    }
                
                JournalView()
                    .tabItem {
                        Image(systemName: "book")
                        Text("Journal")
                    }
                
                TimelineView()
                    .tabItem {
                        Image(systemName: "clock")
                        Text("Timeline")
                    }
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
