//
//  AddExpenseView.swift
//  Spendly
//
//  Created by francisco eduardo aramburo reyes on 05/02/26.
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]

    // Pass an existing expense to enable edit mode
    var expenseToEdit: Expense? = nil

    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var selectedCategory: Category?
    @State private var date: Date = Date()
    @State private var showError = false
    @State private var errorMessage = ""

    private var isEditing: Bool { expenseToEdit != nil }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Amount Section
                Section {
                    HStack {
                        Text(currencySymbol())
                            .font(.title2)
                            .foregroundColor(.secondary)

                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.leading)
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Amount")
                        .font(.subheadline)
                }

                // Details Section
                Section {
                    TextField("Description", text: $description)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            HStack {
                                Circle()
                                    .fill(colorFromString(category.color))
                                    .frame(width: 12, height: 12)
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                } header: {
                    Text("Details")
                }
            }
            .navigationTitle(isEditing ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .tint(Color(hex: "6BBE66"))
                    .disabled(amount.isEmpty || description.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                populateFieldsIfEditing()
            }
        }
    }

    // MARK: - Populate fields when editing

    private func populateFieldsIfEditing() {
        guard let expense = expenseToEdit else { return }
        amount = String(format: "%.2f", expense.amount)
        description = expense.desc
        date = expense.date
        selectedCategory = expense.category
    }

    // MARK: - Save / Update

    private func saveExpense() {
        let clean = amount.replacingOccurrences(of: ",", with: ".")
        guard let amountValue = Double(clean), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }

        if let expense = expenseToEdit {
            // Update existing
            expense.amount = amountValue
            expense.date = date
            expense.desc = description
            expense.category = selectedCategory
        } else {
            // Create new
            let expense = Expense(
                amount: amountValue,
                date: date,
                desc: description,
                category: selectedCategory
            )
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Could not save expense: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: [Expense.self, Category.self])
}
