

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
    
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var selectedCategory: Category?
    @State private var date: Date = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Amount Section
                Section {
                    HStack {
                        Text(getCurrencySymbol())
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
                    
                    // Category Picker
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
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .disabled(amount.isEmpty || description.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveExpense() {
        // Validate amount
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")),
              amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }
        
        // Create expense
        let expense = Expense(
            amount: amountValue,
            date: date,
            desc: description,
            category: selectedCategory
        )
        
        modelContext.insert(expense)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Could not save expense: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func getCurrencySymbol() -> String {
        let currency = UserDefaults.standard.string(forKey: "preferredCurrency") ?? "USD"
        switch currency {
        case "USD": return "$"
        case "MXN": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        default: return "$"
        }
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        case "gray": return .gray
        default: return .gray
        }
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: [Expense.self, Category.self])
}
