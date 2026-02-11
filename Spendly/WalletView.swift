//
//  WalletView.swift
//  Spendly
//
//  Created by francisco eduardo aramburo reyes on 05/02/26.
//

import SwiftUI
import SwiftData
import Charts

struct WalletView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var categories: [Category]

    @State private var showEditBalance = false
    @State private var showAddCategory = false
    @State private var selectedCategory: Category? = nil
    @State private var animateRing = false

    // MARK: - Computed

    var budget: Budget? { budgets.first }
    var totalBalance: Double { budget?.totalAmount ?? 0 }

    var filteredExpenses: [Expense] {
        guard let cat = selectedCategory else { return expenses }
        return expenses.filter { $0.category?.id == cat.id }
    }

    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var filteredSpent: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var remaining: Double { totalBalance - totalSpent }

    var spentPercentage: Double {
        guard totalBalance > 0 else { return 0 }
        return min(totalSpent / totalBalance, 1.0)
    }

    var isNearLimit: Bool { spentPercentage >= 0.80 }
    var isOverLimit: Bool { remaining < 0 }

    var currencySymbol: String {
        let c = UserDefaults.standard.string(forKey: "preferredCurrency") ?? "USD"
        switch c {
        case "USD", "MXN": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        default: return "$"
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Alert banner
                    if isOverLimit {
                        alertBanner(
                            icon: "exclamationmark.triangle.fill",
                            message: "You've exceeded your balance by \(currencySymbol)\(String(format: "%.2f", abs(remaining)))",
                            color: .red
                        )
                    } else if isNearLimit {
                        alertBanner(
                            icon: "bell.badge.fill",
                            message: "Heads up! You've used \(Int(spentPercentage * 100))% of your balance.",
                            color: .orange
                        )
                    }

                    balanceCard
                    categoryFilter
                    statsRow
                    movementHistory
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddCategory = true
                    } label: {
                        Label("New Category", systemImage: "tag.badge.plus")
                            .font(.subheadline)
                    }
                    .tint(Color(hex: "6BBE66"))
                }
            }
            .sheet(isPresented: $showEditBalance) {
                EditBalanceSheet(budget: budget)
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animateRing = true
                }
            }
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: isOverLimit
                        ? [Color(hex: "C0392B"), Color(hex: "922B21")]
                        : isNearLimit
                            ? [Color(hex: "E67E22"), Color(hex: "CA6F1E")]
                            : [Color(hex: "1A1A2E"), Color(hex: "16213E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 200)
                    .offset(x: 110, y: -60)
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 130)
                    .offset(x: -90, y: 70)

                HStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 10)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: animateRing ? CGFloat(spentPercentage) : 0)
                            .stroke(
                                isOverLimit ? Color.red : isNearLimit ? Color.orange : Color(hex: "6BBE66"),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.0), value: animateRing)

                        VStack(spacing: 0) {
                            Text("\(Int(spentPercentage * 100))%")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("used")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Balance")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            Text("\(currencySymbol)\(String(format: "%.2f", totalBalance))")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }

                        Divider().background(Color.white.opacity(0.15))

                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Spent")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.55))
                                Text("\(currencySymbol)\(String(format: "%.2f", totalSpent))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "F08080"))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Left")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.55))
                                Text("\(currencySymbol)\(String(format: "%.2f", remaining))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(isOverLimit ? .red : Color(hex: "90EE90"))
                            }
                        }
                    }

                    Spacer()
                }
                .padding(22)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))

            Button(action: { showEditBalance = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.caption)
                    Text("Edit Balance")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color(hex: "6BBE66"))
                .padding(.vertical, 10)
            }
        }
        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(name: "All", color: "green", isSelected: selectedCategory == nil) {
                    withAnimation(.spring(response: 0.3)) { selectedCategory = nil }
                }
                ForEach(categories) { cat in
                    filterChip(
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
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    private func filterChip(name: String, color: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Circle()
                    .fill(walletColor(color))
                    .frame(width: 7, height: 7)
                Text(name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? walletColor(color).opacity(0.15) : Color(.systemGray6))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? walletColor(color) : Color.clear, lineWidth: 1.5))
        }
        .foregroundColor(isSelected ? walletColor(color) : .primary)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        let catTitle = selectedCategory == nil ? "All Categories" : selectedCategory!.name
        let catIcon  = selectedCategory == nil ? "tray.full.fill" : "tag.fill"
        let catColor = selectedCategory == nil ? Color(hex: "6BBE66") : walletColor(selectedCategory!.color)
        let largest  = filteredExpenses.max(by: { $0.amount < $1.amount })

        return HStack(spacing: 12) {
            walletStatCard(
                title: catTitle,
                value: "\(currencySymbol)\(String(format: "%.2f", filteredSpent))",
                subtitle: "\(filteredExpenses.count) transactions",
                icon: catIcon,
                color: catColor
            )
            walletStatCard(
                title: "Largest",
                value: largest != nil ? "\(currencySymbol)\(String(format: "%.2f", largest!.amount))" : "-",
                subtitle: largest?.desc ?? "No expenses",
                icon: "arrow.up.circle.fill",
                color: Color(hex: "F5825B")
            )
        }
    }

    private func walletStatCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Spacer()
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .lineLimit(1)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Movement History

    private var movementHistory: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(selectedCategory == nil ? "All Movements" : "\(selectedCategory!.name) Movements")
                    .font(.headline)
                Spacer()
                Text("\(filteredExpenses.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 2)

            if filteredExpenses.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No movements here yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(filteredExpenses) { expense in
                    movementRow(expense)
                    if expense.id != filteredExpenses.last?.id {
                        Divider().padding(.leading, 52)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func movementRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(walletColor(expense.category?.color ?? "gray").opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: categoryIcon(expense.category?.name ?? ""))
                    .font(.system(size: 15))
                    .foregroundColor(walletColor(expense.category?.color ?? "gray"))
            }

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
                        Text("·").font(.caption).foregroundColor(.secondary)
                        Text(cat.name).font(.caption).foregroundColor(walletColor(cat.color))
                    }
                }
            }

            Spacer()

            Text("−\(currencySymbol)\(String(format: "%.2f", expense.amount))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "C0392B"))
        }
    }

    // MARK: - Alert Banner

    private func alertBanner(icon: String, message: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Helpers

    private func walletColor(_ name: String) -> Color {
        switch name.lowercased() {
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

    private func categoryIcon(_ name: String) -> String {
        switch name.lowercased() {
        case "food", "comida":            return "fork.knife"
        case "transport", "transporte":   return "car.fill"
        case "shopping", "compras":       return "bag.fill"
        case "home", "hogar":             return "house.fill"
        case "health", "salud":           return "heart.fill"
        case "entertainment":             return "gamecontroller.fill"
        case "gym", "fitness":            return "dumbbell.fill"
        case "education", "educacion":    return "book.fill"
        case "travel", "viaje":           return "airplane"
        case "subscriptions":             return "repeat.circle.fill"
        default:                          return "tag.fill"
        }
    }
}

// MARK: - Edit Balance Sheet

struct EditBalanceSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let budget: Budget?

    @State private var amountText: String = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "wallet.bifold.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "6BBE66"), Color(hex: "4A9D46")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Set Your Balance")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Enter the total amount of money you have available.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                VStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 4) {
                        Text(currencySymbol)
                            .font(.system(size: 32, weight: .light, design: .rounded))
                            .foregroundColor(.secondary)

                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 220)
                    }

                    Rectangle()
                        .fill(Color(hex: "6BBE66"))
                        .frame(height: 2)
                        .padding(.horizontal, 60)
                }

                if showError {
                    Text("Please enter a valid amount greater than 0")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Spacer()

                Button(action: save) {
                    Text("Save Balance")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "6BBE66"), Color(hex: "4A9D46")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "6BBE66").opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(Color(hex: "6BBE66"))
                }
            }
            .onAppear {
                if let b = budget {
                    amountText = String(format: "%.2f", b.totalAmount)
                }
            }
        }
    }

    private var currencySymbol: String {
        let c = UserDefaults.standard.string(forKey: "preferredCurrency") ?? "USD"
        switch c {
        case "USD", "MXN": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        default: return "$"
        }
    }

    private func save() {
        let clean = amountText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(clean), value > 0 else {
            showError = true
            return
        }
        if let existing = budget {
            existing.totalAmount = value
            existing.lastUpdated = Date()
        } else {
            let newBudget = Budget(totalAmount: value)
            modelContext.insert(newBudget)
        }
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Add Category Sheet

struct AddCategorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColor: String = "blue"
    @State private var showError = false

    let availableColors: [(name: String, display: Color)] = [
        ("orange", .orange),
        ("blue",   .blue),
        ("green",  Color(hex: "6BBE66")),
        ("purple", .purple),
        ("red",    .red),
        ("pink",   .pink),
        ("yellow", .yellow),
        ("teal",   .teal),
        ("cyan",   .cyan),
        ("indigo", .indigo),
        ("mint",   .mint),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category name (e.g. Gym, Netflix...)", text: $name)
                        .autocorrectionDisabled()
                } header: {
                    Text("Name")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
                        ForEach(availableColors, id: \.name) { item in
                            Button(action: { selectedColor = item.name }) {
                                ZStack {
                                    Circle()
                                        .fill(item.display)
                                        .frame(width: 38, height: 38)
                                    if selectedColor == item.name {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Color")
                }

                if showError {
                    Section {
                        Text("Category name cannot be empty.")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(Color(hex: "6BBE66"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .tint(Color(hex: "6BBE66"))
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            showError = true
            return
        }
        let category = Category(name: trimmed, color: selectedColor)
        modelContext.insert(category)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Expense.self, Category.self, Budget.self,
        configurations: config
    )
    let ctx = container.mainContext

    let budget = Budget(totalAmount: 12000)
    ctx.insert(budget)

    let food      = Category(name: "Food",      color: "orange")
    let gym       = Category(name: "Gym",        color: "blue")
    let transport = Category(name: "Transport",  color: "teal")
    let shopping  = Category(name: "Shopping",   color: "purple")
    ctx.insert(food)
    ctx.insert(gym)
    ctx.insert(transport)
    ctx.insert(shopping)

    let cal = Calendar.current
    let now = Date()
    let data: [(Double, String, Category, Int)] = [
        (450,  "Supermarket",    food,      -1),
        (800,  "Monthly gym",    gym,       -2),
        (120,  "Uber",           transport, -3),
        (2300, "Clothes haul",   shopping,  -4),
        (85,   "Lunch downtown", food,      -5),
        (650,  "Groceries",      food,      -7),
        (500,  "Nike shoes",     shopping,  -9),
        (200,  "Metro card",     transport, -11),
    ]
    for (amt, desc, cat, days) in data {
        let e = Expense(
            amount: amt,
            date: cal.date(byAdding: .day, value: days, to: now) ?? now,
            desc: desc,
            category: cat
        )
        ctx.insert(e)
    }

    WalletView()
        .modelContainer(container)
}
