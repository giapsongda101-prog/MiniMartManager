//
//  SupplierReturnSlip.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import Foundation
import SwiftData

@Model
final class SupplierReturnSlip {
    @Attribute(.unique) var id: UUID
    var returnDate: Date
    var totalAmount: Double
    
    var supplier: Supplier?
    
    // THÊM MỚI: Liên kết với phiếu nhập gốc
    var goodsReceipt: GoodsReceipt?

    @Relationship(deleteRule: .cascade, inverse: \SupplierReturnSlipDetail.supplierReturnSlip)
    var details: [SupplierReturnSlipDetail] = []
    
    init(id: UUID = UUID(), returnDate: Date = .now, totalAmount: Double = 0.0, supplier: Supplier? = nil, goodsReceipt: GoodsReceipt? = nil) {
        self.id = id
        self.returnDate = returnDate
        self.totalAmount = totalAmount
        self.supplier = supplier
        self.goodsReceipt = goodsReceipt
    }
}
