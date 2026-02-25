//
//  DashboardView.swift
//  Spendly
//
//  Created by francisco eduardo aramburo reyes on 05/02/26.
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var selectedPeriod: Period = .month
    @State private var animateChart = false

    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    // MARK: - Filtered expenses by period

    var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }

        return expenses.filter { $0.date >= startDate }
    }

    // MARK: - Computed totals

    var totalSpent: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var averageExpense: Double {
        filteredExpenses.isEmpty ? 0 : totalSpent / Double(filteredExpenses.count)
    }

    var largestExpense: Expense? {
        filteredExpenses.max(by: { $0.amount < $1.amount })
    }

    // MARK: - Category breakdown

    var categoryTotals: [(name: String, color: String, total: Double)] {
        var dict: [String: (color: String, total: Double)] = [:]

        for expense in filteredExpenses {
            let name = expense.category?.name ?? "Other"
            let color = expense.category?.color ?? "gray"
            let existing = dict[name] ?? (color: color, total: 0)
            dict[name] = (color: color, total: existing.total + expense.amount)
        }

        return dict
            .map { (name: $0.key, color: $0.value.color, total: $0.value.total) }
            .sorted { $0.total > $1.total }
    }

    // MARK: - Daily breakdown for bar chart

    var dailyTotals: [(day: String, total: Double)] {
        var dict: [String: Double] = [:]
        let formatter = DateFormatter()

        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "d MMM"
        case .year:
            formatter.dateFormat = "MMM"
        }

        for expense in filteredExpenses {
            let key = formatter.string(from: expense.date)
            dict[key, default: 0] += expense.amount
        }

        let sorted = filteredExpenses
            .map { formatter.string(from: $0.date) }
            .removingDuplicates()
            .compactMap { day -> (day: String, total: Double)? in
                guard let total = dict[day] else { return nil }
                return (day: day, total: total)
            }

        return sorted
    }

    // MARK: - Currency

    var currencySymbol: String {
        let currency = UserDefaults.standard.string(forKey: "preferredCurrency") ?? "USD"
        switch currency {
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

                    periodSelector

                    if filteredExpenses.isEmpty {
                        emptyState
                    } else {
                        totalCard
                        spendingBarChart
                        statsRow
                        categoryBreakdown
                        recentTransactions
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateChart = true
                }
            }
            .onChange(of: selectedPeriod) {
                animateChart = false
                withAnimation(.easeOut(duration: 0.6)) {
                    animateChart = true
                }
            }
        }
    }

    // MARK: - Subviews

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(Period.allCases, id: \.self) { period in
                Button(action: { selectedPeriod = period }) {
                    Text(period.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedPeriod == period ? .semibold : .regular)
                        .foregroundColor(selectedPeriod == period ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedPeriod == period
                            ? LinearGradient(
                                colors: [Color(hex: "6BBE66"), Color(hex: "4A9D46")],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                            : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPeriod)
            }
        }
        .padding(4)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private var totalCard: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "6BBE66"), Color(hex: "3A8A36")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 160, height: 160)
                .offset(x: 120, y: -50)

            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 100, height: 100)
                .offset(x: -100, y: 60)

            VStack(alignment: .leading, spacing: 6) {
                Text("Total Spent")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))

                Text("\(currencySymbol)\(String(format: "%.2f", totalSpent))")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(filteredExpenses.count) transactions this \(selectedPeriod.rawValue.lowercased())")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(hex: "6BBE66").opacity(0.35), radius: 12, x: 0, y: 6)
    }

    private var spendingBarChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Over Time")
                .font(.headline)
                .padding(.horizontal, 4)

            if dailyTotals.isEmpty {
                Text("No data to display")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                Chart(dailyTotals, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Amount", animateChart ? item.total : 0)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "6BBE66"), Color(hex: "4A9D46")],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(6)
                }
                .frame(height: 160)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("\(currencySymbol)\(Int(amount))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .animation(.easeOut(duration: 0.7), value: animateChart)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Average",
                value: "\(currencySymbol)\(String(format: "%.2f", averageExpense))",
                icon: "chart.line.uptrend.xyaxis",
                color: Color(hex: "5B8BF5")
            )

            StatCard(
                title: "Largest",
                value: largestExpense != nil ? "\(currencySymbol)\(String(format: "%.2f", largestExpense!.amount))" : "-",
                icon: "arrow.up.circle.fill",
                color: Color(hex: "F5825B")
            )
        }
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("By Category")
                .font(.headline)
                .padding(.horizontal, 4)

            if categoryTotals.isEmpty {
                Text("No categories yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(categoryTotals, id: \.name) { item in
                    CategoryRow(
                        name: item.name,
                        color: item.color,
                        total: item.total,
                        percentage: totalSpent > 0 ? item.total / totalSpent : 0,
                        currencySymbol: currencySymbol,
                        animate: animateChart
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var recentTransactions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(filteredExpenses.prefix(5)) { expense in
                HStack(spacing: 12) {
                    Circle()
                        .fill(colorFromString(expense.category?.color ?? "gray").opacity(0.18))
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

                        Text(expense.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(currencySymbol)\(String(format: "%.2f", expense.amount))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "3A8A36"))
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 52))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "6BBE66"), Color(hex: "4A9D46")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(0.5)

            Text("No expenses this \(selectedPeriod.rawValue.lowercased())")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Add your first expense to see your dashboard come to life.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
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

            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let name: String
    let color: String
    let total: Double
    let percentage: Double
    let currencySymbol: String
    let animate: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Circle()
                    .fill(colorFromString(color))  // uses global from ColorUtils.swift
                    .frame(width: 10, height: 10)

                Text(name)
                    .font(.subheadline)

                Spacer()

                Text("\(currencySymbol)\(String(format: "%.2f", total))")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("(\(Int(percentage * 100))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 42, alignment: .trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorFromString(color))  // uses global from ColorUtils.swift
                        .frame(width: animate ? geo.size.width * percentage : 0, height: 6)
                        .animation(.easeOut(duration: 0.7), value: animate)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Array extension

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - Preview

#Preview {
    @MainActor in
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Expense.self, Category.self, configurations: config)

    let ctx = container.mainContext
    let food = Category(name: "Food", color: "orange")
    let transport = Category(name: "Transport", color: "blue")
    let shopping = Category(name: "Shopping", color: "green")
    ctx.insert(food)
    ctx.insert(transport)
    ctx.insert(shopping)

    let calendar = Calendar.current
    let now = Date()

    let sampleExpenses: [(Double, String, Category, Int)] = [
        (45.50,  "Lunch at Taco Bell",  food,      -1),
        (120.00, "Uber to airport",     transport, -2),
        (89.99,  "New shoes",           shopping,  -3),
        (32.00,  "Coffee & breakfast",  food,      -4),
        (15.00,  "Metro card",          transport, -5),
        (210.00, "Groceries",           food,      -6),
        (55.00,  "Dinner out",          food,      -7),
    ]

    for (amount, desc, category, daysAgo) in sampleExpenses {
        let date = calendar.date(byAdding: .day, value: daysAgo, to: now) ?? now
        let expense = Expense(amount: amount, date: date, desc: desc, category: category)
        ctx.insert(expense)
    }

    return DashboardView()
        .modelContainer(container)
}
