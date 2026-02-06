//
//  OnboardingView.swift
//  Spendly
//
//  Created by francisco eduardo aramburo reyes on 05/02/26.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCurrency = "MXN"
    @State private var isProcessing = false
    
    let currencies = ["USD", "MXN", "EUR", "GBP", "JPY"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                // Logo de la app
                Image("AppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // Título y descripción
                VStack(spacing: 12) {
                    Text("Spendly")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "6BBE66"), Color(hex: "4A9D46")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Track your spending,\nsave more money")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                // Selector de moneda
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferred Currency")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Menu {
                        ForEach(currencies, id: \.self) { currency in
                            Button(action: { selectedCurrency = currency }) {
                                HStack {
                                    Text(currency)
                                    if selectedCurrency == currency {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCurrency)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                
                // Botón de inicio
                Button(action: setupApp) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Get Started")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "6BBE66"), Color(hex: "4A9D46")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "6BBE66").opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .disabled(isProcessing)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func setupApp() {
        isProcessing = true
        
        // Save currency preference
        UserDefaults.standard.set(selectedCurrency, forKey: "preferredCurrency")
        
        // Create default categories
        createDefaultCategories()
        
        // Smooth transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
            dismiss()
        }
    }
    
    private func createDefaultCategories() {
        let defaultCategories: [(String, String)] = [
            ("Food", "orange"),
            ("Transport", "blue"),
            ("Shopping", "green"),
            ("Home", "purple"),
            ("Health", "red"),
            ("Entertainment", "pink"),
            ("Other", "gray")
        ]
        
        for (name, color) in defaultCategories {
            let category = Category(name: name, color: color)
            modelContext.insert(category)
        }
        
        try? modelContext.save()
    }
}

// Helper para usar colores hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [Category.self, Expense.self])
}
