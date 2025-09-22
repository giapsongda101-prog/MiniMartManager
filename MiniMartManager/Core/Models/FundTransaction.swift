import Foundation
import SwiftData

@Model
final class FundTransaction {
    var id: UUID
    var type: String // "THU" or "CHI"
    var amount: Double
    var currency: String // THÊM MỚI: Đơn vị tiền tệ của giao dịch
    var exchangeRateAtTransaction: Double // THÊM MỚI: Tỷ giá tại thời điểm giao dịch
    var amountInVND: Double // THÊM MỚI: Giá trị đã quy đổi ra VNĐ
    var reason: String
    var transactionDate: Date
    var isSystemGenerated: Bool // THÊM MỚI

    // SỬA LỖI: Xóa các thuộc tính này để loại bỏ tham chiếu tuần hoàn
    // var invoice: Invoice?
    // var goodsReceipt: GoodsReceipt?

    init(type: String, amount: Double, currency: String, exchangeRateAtTransaction: Double, reason: String, transactionDate: Date, isSystemGenerated: Bool) {
        self.id = UUID()
        self.type = type
        self.amount = amount
        self.currency = currency
        self.exchangeRateAtTransaction = exchangeRateAtTransaction
        self.amountInVND = amount * exchangeRateAtTransaction
        self.reason = reason
        self.transactionDate = transactionDate
        self.isSystemGenerated = isSystemGenerated
    }
}
