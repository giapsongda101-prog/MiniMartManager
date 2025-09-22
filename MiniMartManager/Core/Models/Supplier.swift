//
//  Supplier.swift
//  MiniMartManager
//
//  Created by [Your Name] on 9/11/25.
//

import Foundation
import SwiftData

@Model
final class Supplier {
    @Attribute(.unique) var id: UUID
    var name: String
    var phone: String
    var address: String
    
    // Relationship: A supplier can provide many products
    @Relationship(deleteRule: .nullify, inverse: \Product.supplier)
    var products: [Product] = []
    
    init(id: UUID = UUID(), name: String, phone: String = "", address: String = "") {
        self.id = id
        self.name = name
        self.phone = phone
        self.address = address
    }
}
