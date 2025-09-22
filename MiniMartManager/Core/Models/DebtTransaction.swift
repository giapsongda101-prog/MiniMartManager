//
//  DebtTransaction.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import Foundation
import SwiftData

@Model
final class DebtTransaction {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var transactionDate: Date
    var type: String // "PAYMENT" (khách trả nợ), "PURCHASE" (ghi nợ khi mua hàng)
    
    // Relationship: A transaction belongs to a customer
    var customer: Customer?
    
    // THÊM MỚI: Liên kết với hóa đơn hoặc phiếu nhập
    var invoice: Invoice?
    var goodsReceipt: GoodsReceipt?
    
    init(id: UUID = UUID(), amount: Double, transactionDate: Date, type: String, customer: Customer?, invoice: Invoice? = nil, goodsReceipt: GoodsReceipt? = nil) {
        self.id = id
        self.amount = amount
        self.transactionDate = transactionDate
        self.type = type
        self.customer = customer
        self.invoice = invoice
        self.goodsReceipt = goodsReceipt
    }
}
