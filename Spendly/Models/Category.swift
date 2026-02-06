import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var color: String 
    
    @Relationship(deleteRule: .cascade, inverse: \Expense.category)
    var expenses: [Expense]?
    
    init(name: String, color: String) {
        self.id = UUID()
        self.name = name
        self.color = color
    }
}
