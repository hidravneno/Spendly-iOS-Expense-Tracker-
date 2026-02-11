//
//  ContentView.swift
//  Spendly
//
//  Created by Francisco Eduardo Aramburo Reyes on 05/02/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var showAddExpense = false

    var body: some View {
        TabView {
            // Tab 1 — Expenses list
            expensesTab
                .tabItem {
                    Label("Expenses", systemImage: "list.bullet.rectangle")
                }

            // Tab 2 — Wallet / Balance
            WalletView()
                .tabItem {
                    Label("Wallet", systemImage: "wallet.bifold.fill")
                }

            // Tab 3 — Dashboard
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
        }
        .tint(Color(hex: "6BBE66"))
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView()
        }
    }

    // MARK: - Expenses Tab

    private var expensesTab: some View {
        NavigationStack {
            Group {
                if expenses.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("Your history is empty!")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Start by adding your first expense")
                            .foregroundColor(.secondary)

                        Button(action: { showAddExpense = true }) {
                            Label("Add first expense", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "6BBE66"), Color(hex: "4A9D46")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .padding(.top)
                    }
                } else {
                    List {
                        ForEach(expenses) { expense in
                            HStack(spacing: 12) {
                                // Category color circle
                                Circle()
                                    .fill(colorFromString(expense.category?.color ?? "gray").opacity(0.15))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .fill(colorFromString(expense.category?.color ?? "gray"))
                                            .frame(width: 12, height: 12)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(expense.desc)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(1)

                                    HStack(spacing: 4) {
                                        Text(expense.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        if let cat = expense.category {
                                            Text("·")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(cat.name)
                                                .font(.caption)
                                                .foregroundColor(colorFromString(cat.color))
                                        }
                                    }
                                }

                                Spacer()

                                Text("$\(expense.amount, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .onDelete(perform: deleteExpenses)
                    }
                }
            }
            .navigationTitle("Spendly")
            .toolbar {
                if !expenses.isEmpty {
                    Button(action: { showAddExpense = true }) {
                        Image(systemName: "plus")
                            .tint(Color(hex: "6BBE66"))
                    }
                }
            }
        }
    }

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(expenses[index])
        }
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "orange": return .orange
        case "blue":   return .blue
        case "green":  return Color(hex: "6BBE66")
        case "purple": return .purple
        case "red":    return .red
        case "pink":   return .pink
        case "yellow": return .yellow
        case "teal":   return .teal
        case "cyan":   return .cyan
        case "indigo": return .indigo
        case "mint":   return .mint
        default:       return .gray
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, Category.self, Budget.self])
}
