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
    @Query private var expenses: [Expense]
    @State private var showAddExpense = false
    
    var body: some View {
        NavigationStack {
            VStack {
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
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.top)
                    }
                } else {
                    // Expenses list
                    List {
                        ForEach(expenses) { expense in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(expense.desc)
                                        .font(.headline)
                                    
                                    Text(expense.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("$\(expense.amount, specifier: "%.2f")")
                                    .font(.headline)
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
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                Text("AddExpenseView - To be implemented")
            }
        }
    }
    
    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(expenses[index])
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, Category.self])
}
