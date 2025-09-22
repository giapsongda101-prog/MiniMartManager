// MiniMartManager/Core/Models/Invoice.swift
import Foundation
import SwiftData

@Model
final class Invoice {
    var id: UUID
    var creationDate: Date
    // THÊM MỚI: Tổng tiền hàng trước khi giảm giá
    var subtotal: Double
    var totalAmount: Double
    var totalCost: Double
    var discountAmount: Double
    var paymentStatus: String // "PAID", "UNPAID", "PARTIAL"
    var amountPaid: Double
    var isReturned: Bool
    
    // Nâng cấp: Liên kết với khách hàng
    var customer: Customer?
    
    // Nâng cấp: Liên kết với người dùng
    var user: User?
    
    // SỬA LỖI: Thêm thuộc tính để lưu tên khuyến mãi
    var appliedPromotionName: String?
    
    @Relationship(deleteRule: .cascade, inverse: \InvoiceDetail.invoice)
    var details: [InvoiceDetail] = []
    
    // SỬA LỖI: Xóa thuộc tính này để loại bỏ tham chiếu tuần hoàn
    // @Relationship(deleteRule: .nullify, inverse: \FundTransaction.invoice)
    // var fundTransactions: [FundTransaction] = []
    
    init(id: UUID = UUID(), creationDate: Date = .now, subtotal: Double = 0.0, totalAmount: Double = 0.0, totalCost: Double = 0.0, discountAmount: Double = 0.0, paymentStatus: String = "UNPAID", amountPaid: Double = 0.0, isReturned: Bool = false, customer: Customer? = nil, user: User? = nil, appliedPromotionName: String? = nil) {
        self.id = id
        self.creationDate = creationDate
        self.subtotal = subtotal
        self.totalAmount = totalAmount
        self.totalCost = totalCost
        self.discountAmount = discountAmount
        self.paymentStatus = paymentStatus
        self.amountPaid = amountPaid
        self.isReturned = isReturned
        self.customer = customer
        self.user = user
        self.appliedPromotionName = appliedPromotionName
    }
}
