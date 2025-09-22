//
//  InvoiceDetail.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import Foundation
import SwiftData

@Model
final class InvoiceDetail {
    @Attribute(.unique) var id: UUID
    
    var quantity: Int
    var unitName: String
    var pricePerUnitAtSale: Double
    var costPriceAtSale: Double
    
    // THÊM MỚI: Lưu lại hệ số quy đổi tại thời điểm bán
    var conversionFactorAtSale: Int
    
    // Relationship
    var invoice: Invoice?
    var product: Product?
    
    init(id: UUID = UUID(),
         quantity: Int,
         unitName: String,
         pricePerUnitAtSale: Double,
         costPriceAtSale: Double,
         conversionFactorAtSale: Int, // Thêm vào init
         product: Product? = nil) {
        self.id = id
        self.quantity = quantity
        self.unitName = unitName
        self.pricePerUnitAtSale = pricePerUnitAtSale
        self.costPriceAtSale = costPriceAtSale
        self.conversionFactorAtSale = conversionFactorAtSale // Thêm vào init
        self.product = product
    }
}
