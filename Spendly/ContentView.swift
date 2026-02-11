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
    @Query private var categories: [Category]

    @State private var showAddExpense = false
    @State private var showEditExpense = false
    @State private var expenseToEdit: Expense? = nil
    @State private var searchText = ""
    @State private var selectedCategory: Category? = nil

    // MARK: - Filtered expenses

    var filteredExpenses: [Expense] {
        expenses.filter { expense in
            let matchesSearch = searchText.isEmpty
                || expense.desc.localizedCaseInsensitiveContains(searchText)
                || (expense.category?.name.localizedCaseInsensitiveContains(searchText) ?? false)

            let matchesCategory = selectedCategory == nil
                || expense.category?.id == selectedCategory?.id

            return matchesSearch && matchesCategory
        }
    }

    // MARK: - Body

    var body: some View {
        TabView {
            expensesTab
                .tabItem {
                    Label("Expenses", systemImage: "list.bullet.rectangle")
                }

            WalletView()
                .tabItem {
                    Label("Wallet", systemImage: "wallet.bifold.fill")
                }

            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
        }
        .tint(Color(hex: "6BBE66"))
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView()
        }
        .sheet(isPresented: $showEditExpense) {
            if let expense = expenseToEdit {
                AddExpenseView(expenseToEdit: expense)
            }
        }
    }

    // MARK: - Expenses Tab

    private var expensesTab: some View {
        NavigationStack {
            Group {
                if expenses.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        if !categories.isEmpty {
                            categoryFilterBar
                        }

                        if filteredExpenses.isEmpty {
                            noResultsState
                        } else {
                            expenseList
                        }
                    }
                }
            }
            .navigationTitle("Spendly")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search expenses..."
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddExpense = true }) {
                        Image(systemName: "plus")
                    }
                    .tint(Color(hex: "6BBE66"))
                }
            }
        }
    }

    // MARK: - Category Filter Bar

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(name: "All", color: "green", isSelected: selectedCategory == nil) {
                    withAnimation(.spring(response: 0.3)) { selectedCategory = nil }
                }
                ForEach(categories) { cat in
                    categoryChip(
                        name: cat.name,
                        color: cat.color,
                        isSelected: selectedCategory?.id == cat.id
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = selectedCategory?.id == cat.id ? nil : cat
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func categoryChip(name: String, color: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Circle()
                    .fill(colorFromString(color))
                    .frame(width: 7, height: 7)
                Text(name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? colorFromString(color).opacity(0.15) : Color(.systemGray6))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? colorFromString(color) : Color.clear, lineWidth: 1.5))
        }
        .foregroundColor(isSelected ? colorFromString(color) : .primary)
    }

    // MARK: - Expense List

    private var expenseList: some View {
        List {
            ForEach(filteredExpenses) { expense in
                Button(action: {
                    expenseToEdit = expense
                    showEditExpense = true
                }) {
                    HStack(spacing: 12) {
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
                                .foregroundColor(.primary)

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

                        Text("\(currencySymbol())\(expense.amount, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: deleteExpenses)
        }
    }

    // MARK: - Empty States

    private var emptyState: some View {
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
    }

    private var noResultsState: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No results found")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Try a different search or category.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Actions

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredExpenses[index])
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, Category.self, Budget.self])
}
