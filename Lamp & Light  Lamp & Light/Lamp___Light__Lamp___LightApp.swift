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
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboarded")
    @StateObject private var purchaseManager = PurchaseManager.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                TodayView()
                    .tabItem {
                        Image(systemName: "sun.max.fill")
                        Text("Today")
                    }
                
                JournalView()
                    .tabItem {
                        Image(systemName: "square.and.pencil")
                        Text("Journal")
                    }
                
                TimelineView()
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("Timeline")
                    }
                
                RecapView()
                    .tabItem {
                        Image(systemName: "doc.text.image")
                        Text("Recap")
                    }
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
            }
            .tint(AppColor.primaryGreen)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .sheet(isPresented: $showOnboarding) { OnboardingView() }
            .task { await purchaseManager.load() }
        }
    }
}
