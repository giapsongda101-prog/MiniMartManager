//
//  Customer.swift
//  MiniMartManager
//
//  Created by [Your Name] on 9/11/25.
//

import Foundation
import SwiftData

@Model
final class Customer {
    @Attribute(.unique) var id: UUID
    var name: String
    var phone: String
    
    // We will add relationships to invoices and debts later
    
    init(id: UUID = UUID(), name: String, phone: String = "") {
        self.id = id
        self.name = name
        self.phone = phone
    }
}
