//
//  Category.swift
//  MiniMartManager
//
//  Created by [Your Name] on 9/11/25.
//

import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    
    // Relationship: A category can have many products
    @Relationship(deleteRule: .nullify, inverse: \Product.category)
    var products: [Product] = []
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
