import SwiftUI
import SwiftData

@MainActor
class CartManager: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var selectedCustomer: Customer?
    
    // THÊM MỚI: State để lưu chương trình khuyến mãi được chọn
    @Published var appliedPromotion: Promotion?
    
    // Tổng tiền hàng trước khi giảm giá
    var subtotal: Double {
        items.reduce(0) { $0 + $1.lineTotal }
    }
    
    // Số tiền được giảm giá từ chương trình khuyến mãi
    var discountAmount: Double {
        appliedPromotion?.calculateDiscount(on: subtotal) ?? 0
    }
    
    // Tổng tiền cuối cùng sau khi đã áp dụng khuyến mãi
    var totalAmount: Double {
        subtotal - discountAmount
    }
    
    var isCartValid: Bool {
        guard !items.isEmpty else { return false }
        for item in items {
            let quantityInBaseUnit = item.quantity * item.selectedUnit.conversionFactor
            if quantityInBaseUnit > item.product.stockQuantity {
                return false
            }
        }
        return true
    }
    
    func addProduct(_ product: Product, quantity: Int = 1) {
        let losUnit = product.alternativeUnits.first(where: { $0.name == "Lố" })
        let defaultUnit = losUnit != nil
            ? SalesUnit(name: losUnit!.name, conversionFactor: losUnit!.conversionFactor)
            : SalesUnit(name: product.unit, conversionFactor: 1)
        
        if let index = items.firstIndex(where: { $0.product.id == product.id && $0.selectedUnit == defaultUnit }) {
            items[index].quantity += quantity
        } else {
            var newItem = CartItem(product: product, quantity: quantity)
            newItem.selectedUnit = defaultUnit
            items.append(newItem)
        }
    }
    
    func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
    }
    
    func clearCart() {
        items = []
        selectedCustomer = nil
        appliedPromotion = nil // Reset khuyến mãi khi tạo đơn mới
    }
    
    // CẬP NHẬT HÀM CHECKOUT
    func checkout(paid: Bool, modelContext: ModelContext, user: User?) -> Invoice? {
        var totalCostOfGoods = 0.0
        let newInvoice = Invoice(
            creationDate: .now,
            subtotal: subtotal, // THÊM MỚI: Lưu tổng tiền hàng ban đầu
            totalAmount: totalAmount, // Lưu tổng tiền cuối cùng
            totalCost: 0,
            discountAmount: discountAmount,
            paymentStatus: paid ? "PAID" : "UNPAID",
            amountPaid: paid ? totalAmount : 0,
            customer: selectedCustomer
        )
        
        // Gán người dùng vào hóa đơn
        newInvoice.user = user

        // Thêm thông tin khuyến mãi vào hóa đơn (để xem lại sau)
        if let promotion = appliedPromotion {
            newInvoice.appliedPromotionName = promotion.name
            newInvoice.discountAmount = discountAmount
        }
        
        var details: [InvoiceDetail] = []
        for item in items {
            let detail = InvoiceDetail(
                quantity: item.quantity,
                unitName: item.selectedUnit.name,
                pricePerUnitAtSale: item.finalPricePerSelectedUnit,
                costPriceAtSale: item.product.costPrice,
                conversionFactorAtSale: item.selectedUnit.conversionFactor,
                product: item.product
            )
            details.append(detail)
            
            let totalBaseQuantity = item.quantity * item.selectedUnit.conversionFactor
            totalCostOfGoods += item.product.costPrice * Double(totalBaseQuantity)
            
            // Tạm thời comment out logic trừ kho theo lô để đơn giản hóa
            item.product.stockQuantity -= totalBaseQuantity
            
            let stockTx = StockTransaction(
                product: item.product,
                quantityChange: -totalBaseQuantity,
                transactionDate: .now,
                transactionType: "BANHANG",
                reason: "Bán \(item.quantity) \(item.selectedUnit.name) cho \(selectedCustomer?.name ?? "Khách lẻ")"
            )
            modelContext.insert(stockTx)
        }
        
        newInvoice.details = details
        newInvoice.totalCost = totalCostOfGoods
        modelContext.insert(newInvoice)
        
        if paid {
            // SỬA LỖI: Thêm các tham số 'currency' và 'exchangeRateAtTransaction'
            let fundTx = FundTransaction(
                type: "THU",
                amount: totalAmount,
                currency: "VNĐ",
                exchangeRateAtTransaction: 1.0,
                reason: "Bán hàng trực tiếp cho: \(selectedCustomer?.name ?? "Khách lẻ")",
                transactionDate: .now,
                isSystemGenerated: true
            )
            modelContext.insert(fundTx)
        }
        
        clearCart()
        return newInvoice
    }
}
