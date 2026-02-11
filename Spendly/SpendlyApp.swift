//
//  SpendlyApp.swift
//  Spendly
//
//  Created by francisco eduardo aramburo reyes on 05/02/26.
//

import SwiftUI
import SwiftData

@main
struct SpendlyApp: App {
    @State private var showOnboarding = false

    private let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Expense.self,
                Category.self,
                Budget.self       // ← nuevo modelo
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    checkFirstLaunch()
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView()
                }
        }
        .modelContainer(container)
    }

    private func checkFirstLaunch() {
        let context = container.mainContext
        let fetchDescriptor = FetchDescriptor<Category>()
        do {
            let categories = try context.fetch(fetchDescriptor)
            showOnboarding = categories.isEmpty
        } catch {
            showOnboarding = true
        }
    }
}
