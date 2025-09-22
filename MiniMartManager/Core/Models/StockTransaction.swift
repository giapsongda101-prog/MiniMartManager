//
//  StockTransaction.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import Foundation
import SwiftData

@Model
final class StockTransaction {
    @Attribute(.unique) var id: UUID
    var quantityChange: Int // Số dương cho Tăng, số âm cho Giảm
    var transactionDate: Date
    var transactionType: String // NHAPKHO, BANHANG, KHACH_TRAHANG, DIEUCHINH_TANG, DIEUCHINH_GIAM, TRAHANG_NCC
    var reason: String
    
    // Relationship to the product
    var product: Product?
    
    init(id: UUID = UUID(), product: Product?, quantityChange: Int, transactionDate: Date, transactionType: String, reason: String) {
        self.id = id
        self.product = product
        self.quantityChange = quantityChange
        self.transactionDate = transactionDate
        self.transactionType = transactionType
        self.reason = reason
    }
}
