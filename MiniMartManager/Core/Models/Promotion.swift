import Foundation
import SwiftData

// Enum định nghĩa các loại khuyến mãi
enum PromotionType: String, Codable, CaseIterable, Identifiable {
    case percentageDiscount = "Giảm giá phần trăm" // Giảm % trên tổng hóa đơn
    case fixedAmountDiscount = "Giảm giá số tiền cố định" // Giảm một số tiền cụ thể
    var id: Self { self }
}

@Model
final class Promotion {
    @Attribute(.unique) var id: UUID
    var name: String // Tên chương trình, VD: "Sale cuối tuần"
    var promotionType: PromotionType
    var value: Double // Giá trị khuyến mãi (VD: 10 cho 10%, 50000 cho 50.000đ)
    
    // Điều kiện áp dụng
    var minimumSpend: Double = 0.0 // Số tiền tối thiểu để được áp dụng
    
    // Thời gian áp dụng
    var startDate: Date
    var endDate: Date
    var isActive: Bool = true

    init(id: UUID = UUID(),
         name: String,
         promotionType: PromotionType,
         value: Double,
         minimumSpend: Double = 0.0,
         startDate: Date = .now,
         endDate: Date,
         isActive: Bool = true) {
        self.id = id
        self.name = name
        self.promotionType = promotionType
        self.value = value
        self.minimumSpend = minimumSpend
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
    }
    
    // Hàm kiểm tra xem chương trình có hợp lệ để áp dụng không
    func isValid(for totalAmount: Double) -> Bool {
        let now = Date()
        return isActive && now >= startDate && now <= endDate && totalAmount >= minimumSpend
    }
    
    // Hàm tính toán số tiền được giảm giá
    func calculateDiscount(on totalAmount: Double) -> Double {
        guard isValid(for: totalAmount) else { return 0 }
        
        switch promotionType {
        case .percentageDiscount:
            return (totalAmount * value) / 100
        case .fixedAmountDiscount:
            return min(value, totalAmount) // Đảm bảo không giảm giá nhiều hơn tổng tiền
        }
    }
}
