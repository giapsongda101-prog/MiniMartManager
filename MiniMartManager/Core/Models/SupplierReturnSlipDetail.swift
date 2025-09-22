//
//  SupplierReturnSlipDetail.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import Foundation
import SwiftData

@Model
final class SupplierReturnSlipDetail {
    @Attribute(.unique) var id: UUID
    var quantity: Int
    var costPriceAtReturn: Double
    
    // Relationship: The detail belongs to a supplier return slip
    var product: Product?
    
    // SỬA LỖI: Thêm thuộc tính liên kết ngược
    var supplierReturnSlip: SupplierReturnSlip?
    
    init(id: UUID = UUID(), quantity: Int, costPriceAtReturn: Double, product: Product?, supplierReturnSlip: SupplierReturnSlip? = nil) {
        self.id = id
        self.quantity = quantity
        self.costPriceAtReturn = costPriceAtReturn
        self.product = product
        self.supplierReturnSlip = supplierReturnSlip
    }
}
