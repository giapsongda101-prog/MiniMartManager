// MiniMartManager/Core/Models/GoodsReceipt.swift
import Foundation
import SwiftData

@Model
final class GoodsReceipt {
    @Attribute(.unique) var id: UUID
    var receiptDate: Date
    var totalAmount: Double
    var paymentStatus: String // PAID, UNPAID, PARTIAL
    var amountPaid: Double = 0.0 // SỐ TIỀN ĐÃ TRẢ
    
    // Relationship: A receipt belongs to one supplier
    var supplier: Supplier?
    
    // THÊM MỚI: Liên kết với người dùng
    var user: User?
    
    // Relationship: A receipt has many detail lines
    @Relationship(deleteRule: .cascade, inverse: \GoodsReceiptDetail.receipt)
    var details: [GoodsReceiptDetail] = []
    
    // SỬA LỖI: Chuyển sang mối quan hệ một-nhiều và đặt inverse
    @Relationship(deleteRule: .nullify)
    var fundTransactions: [FundTransaction] = []
    
    init(id: UUID = UUID(), receiptDate: Date, totalAmount: Double, paymentStatus: String, amountPaid: Double = 0.0, supplier: Supplier? = nil, user: User? = nil) {
        self.id = id
        self.receiptDate = receiptDate
        self.totalAmount = totalAmount
        self.paymentStatus = paymentStatus
        self.amountPaid = amountPaid
        self.supplier = supplier
        self.user = user
    }
}
