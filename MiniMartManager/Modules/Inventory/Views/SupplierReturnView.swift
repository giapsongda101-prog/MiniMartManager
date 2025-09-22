import SwiftUI
import SwiftData

struct SupplierReturnView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Supplier.name) private var suppliers: [Supplier]
    @Query(sort: \Product.name) private var allProducts: [Product]
    
    @State private var selectedSupplier: Supplier?
    @State private var returnItems: [SupplierReturnItem] = []
    // THÊM: Biến trạng thái để lưu loại tiền tệ và tỷ giá
    @State private var selectedCurrency: Currency = .VND
    @State private var exchangeRate: Double = 1.0

    private var totalAmount: Double {
        returnItems.reduce(0) { $0 + (Double($1.quantity) * $1.costPrice) }
    }
    
    private var isFormValid: Bool {
        !returnItems.isEmpty && selectedSupplier != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Nhà cung cấp") {
                    Picker("Chọn nhà cung cấp", selection: $selectedSupplier) {
                        Text("Chưa chọn").tag(Supplier?.none)
                        ForEach(suppliers) { supplier in
                            Text(supplier.name).tag(supplier as Supplier?)
                        }
                    }
                }
                
                Section("Sản phẩm trả lại") {
                    ForEach($returnItems) { $item in
                        VStack(alignment: .leading) {
                            Text(item.product.name).font(.headline)
                            HStack {
                                Text("Số lượng")
                                Spacer()
                                TextField("Số lượng", value: $item.quantity, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                            }
                            HStack {
                                Text("Giá trả lại")
                                Spacer()
                                TextField("Giá", value: $item.costPrice, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                        }
                    }
                    .onDelete(perform: removeReturnItem)
                    
                    Button("Thêm sản phẩm") {
                        // Mở product picker
                    }
                }
                
                Section("Tổng tiền trả lại") {
                    HStack {
                        Text("Tổng cộng")
                        Spacer()
                        Text(totalAmount.formattedAsCurrency())
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Tạo Phiếu Trả Hàng NCC")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { saveReturnSlip() }.disabled(!isFormValid)
                }
            }
        }
    }
    
    private func saveReturnSlip() {
        guard let supplier = selectedSupplier else { return }
        
        // THÊM MỚI: Liên kết phiếu trả hàng với phiếu nhập gốc
        let newReturnSlip = SupplierReturnSlip(
            returnDate: .now,
            totalAmount: totalAmount,
            supplier: supplier,
            goodsReceipt: nil // Cần thêm logic để chọn phiếu nhập gốc
        )
        
        for item in returnItems {
            let detail = SupplierReturnSlipDetail(
                quantity: item.quantity,
                costPriceAtReturn: item.costPrice,
                product: item.product
            )
            newReturnSlip.details.append(detail)
            
            // SỬA LỖI: CẬP NHẬT TỒN KHO VÀ TẠO GIAO DỊCH
            item.product.stockQuantity -= item.quantity
            
            let stockTx = StockTransaction(
                product: item.product,
                quantityChange: -item.quantity,
                transactionDate: .now,
                transactionType: "TRATHANG_NCC",
                reason: "Trả \(item.quantity) \(item.product.unit) cho NCC: \(supplier.name)"
            )
            modelContext.insert(stockTx)
        }
        
        // SỬA LỖI: Giao dịch quỹ CHI cho việc trả hàng
        let fundTx = FundTransaction(
            type: "CHI",
            amount: totalAmount,
            currency: selectedCurrency.rawValue,
            exchangeRateAtTransaction: exchangeRate,
            reason: "Trả hàng cho nhà cung cấp \(supplier.name)",
            transactionDate: .now,
            isSystemGenerated: true
        )
        modelContext.insert(fundTx)
        
        modelContext.insert(newReturnSlip)
        
        dismiss()
    }
    
    private func removeReturnItem(at offsets: IndexSet) {
        returnItems.remove(atOffsets: offsets)
    }
}

// Cấu trúc tạm thời để chứa item trong phiếu trả hàng
struct SupplierReturnItem: Identifiable {
    var id: UUID = UUID()
    let product: Product
    var quantity: Int
    var costPrice: Double
}
