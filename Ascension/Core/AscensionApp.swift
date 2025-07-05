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

    @StateObject private var progressModel = ArkheionProgressModel()

    var body: some Scene {
        WindowGroup {
            AscensionHomeView()
                .environmentObject(progressModel)
        }
        .modelContainer(sharedModelContainer)

#if os(macOS)
        WindowGroup(id: "ArkheionMap") {
            NavigationStack {
                ArkheionMapView()
            }
            .environmentObject(progressModel)
        }
        .modelContainer(sharedModelContainer)
#endif
    }
}
