//
//  AscensionApp.swift
//  Ascension
//
//  Created by Orion Goodman on 7/4/25.
//

import SwiftUI
import SwiftData

@main
struct AscensionApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()


    var body: some Scene {
        WindowGroup {
            AscensionHomeView()
        }
        .modelContainer(sharedModelContainer)

#if os(macOS)
        WindowGroup(id: "ArkheionMap") {
            NavigationStack {
                ArkheionMapView()
            }
        }
        .modelContainer(sharedModelContainer)
#endif
    }
}
