//
//  ColorUtils.swift
//  Spendly
//
//  Created by Francisco Eduardo Aramburo Reyes on 05/02/26.
//

import SwiftUI

/// Shared helper used by ContentView, DashboardView, WalletView and AddExpenseView.
/// Remove the local `colorFromString` / `walletColor` functions from those files.
func colorFromString(_ colorName: String) -> Color {
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

/// Shared currency symbol helper
func currencySymbol() -> String {
    let currency = UserDefaults.standard.string(forKey: "preferredCurrency") ?? "USD"
    switch currency {
    case "USD", "MXN": return "$"
    case "EUR":        return "€"
    case "GBP":        return "£"
    case "JPY":        return "¥"
    default:           return "$"
    }
}
