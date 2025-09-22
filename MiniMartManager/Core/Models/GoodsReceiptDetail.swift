//
//  GoodsReceiptDetail.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import Foundation
import SwiftData

@Model
final class GoodsReceiptDetail {
    @Attribute(.unique) var id: UUID
    var quantity: Int
    var costPriceAtTimeOfReceipt: Double
    
    // Relationship: This detail line belongs to one receipt
    var receipt: GoodsReceipt?
    
    // Relationship: This detail line is for one product
    var product: Product?
    
    init(id: UUID = UUID(), quantity: Int, costPriceAtTimeOfReceipt: Double, product: Product? = nil) {
        self.id = id
        self.quantity = quantity
        self.costPriceAtTimeOfReceipt = costPriceAtTimeOfReceipt
        self.product = product
    }
}
