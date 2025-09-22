//
//  ReturnSlip.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import Foundation
import SwiftData

@Model
final class ReturnSlip {
    @Attribute(.unique) var id: UUID
    var returnDate: Date
    var totalRefundAmount: Double
    
    var customer: Customer?
    
    // THÊM MỚI: Liên kết với hóa đơn gốc
    var invoice: Invoice?
    
    @Relationship(deleteRule: .cascade, inverse: \ReturnSlipDetail.returnSlip)
    var details: [ReturnSlipDetail] = []
    
    init(id: UUID = UUID(), returnDate: Date = .now, totalRefundAmount: Double = 0.0, customer: Customer? = nil, invoice: Invoice? = nil) {
        self.id = id
        self.returnDate = returnDate
        self.totalRefundAmount = totalRefundAmount
        self.customer = customer
        self.invoice = invoice
    }
}
