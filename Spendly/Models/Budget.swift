//
//  Budget.swift
//  Spendly
//
//  Created by francisco eduardo aramburo reyes on 05/02/26.
//

import Foundation
import SwiftData

@Model
final class Budget {
    var id: UUID
    var totalAmount: Double
    var lastUpdated: Date

    init(totalAmount: Double) {
        self.id = UUID()
        self.totalAmount = totalAmount
        self.lastUpdated = Date()
    }
}
