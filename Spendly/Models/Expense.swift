import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var amount: Double
    var date: Date
    var desc: String
    var category: Category?
    
    init(amount: Double, date: Date, desc: String, category: Category? = nil) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.desc = desc
        self.category = category
    }
}
