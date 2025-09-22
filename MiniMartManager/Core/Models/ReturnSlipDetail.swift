import Foundation
import SwiftData

@Model
final class ReturnSlipDetail {
    @Attribute(.unique) var id: UUID
    var quantity: Int
    var priceAtReturn: Double // Giữ tên này cho rõ nghĩa
    
    var returnSlip: ReturnSlip?
    var product: Product?
    
    // Sửa lại init cho khớp
    init(id: UUID = UUID(), quantity: Int, priceAtReturn: Double, product: Product?) {
        self.id = id
        self.quantity = quantity
        self.priceAtReturn = priceAtReturn
        self.product = product
    }
}
