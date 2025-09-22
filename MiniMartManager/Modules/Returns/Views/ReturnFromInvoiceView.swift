import SwiftUI
import SwiftData

// Cấu trúc được cập nhật để chứa thông tin số lượng tối đa có thể trả lại
struct ReturnItem: Identifiable {
    var id: UUID = UUID()
    let product: Product?
    var quantity: Int
    let maxQuantity: Int // Số lượng tối đa có thể trả lại
    let pricePerUnit: Double
}

struct ReturnFromInvoiceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var invoice: Invoice
    
    @State private var returnItems: [ReturnItem] = []
    
    // THÊM MỚI: Biến để điều khiển hiển thị ProductPicker
    @State private var isShowingProductPicker = false
    
    private var totalRefundAmount: Double {
        returnItems.reduce(0) { $0 + (Double($1.quantity) * $1.pricePerUnit) }
    }
    
    private var isReturnSlipValid: Bool {
        // Kiểm tra xem phiếu trả hàng có rỗng không và tất cả các mục có hợp lệ không
        !returnItems.isEmpty && returnItems.allSatisfy { $0.quantity > 0 && $0.quantity <= $0.maxQuantity }
    }
    
    init(invoice: Invoice) {
        self._invoice = State(initialValue: invoice)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin hóa đơn gốc") {
                    Text("Số hóa đơn: \(invoice.id.uuidString.prefix(8))")
                    Text("Ngày: \(invoice.creationDate.formatted(date: .numeric, time: .shortened))")
                    Text("Khách hàng: \(invoice.customer?.name ?? "Khách lẻ")")
                }
                
                Section("Sản phẩm trả lại") {
                    ForEach($returnItems) { $item in
                        VStack(alignment: .leading) {
                            Text(item.product?.name ?? "N/A").font(.headline)
                            
                            HStack {
                                Text("Số lượng")
                                Spacer()
                                // THAY THẾ TextField bằng HStack có nút +-
                                HStack(spacing: 8) {
                                    Button(action: {
                                        if item.quantity > 1 {
                                            item.quantity -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    TextField("SL", value: $item.quantity, format: .number)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 40)
                                    
                                    Button(action: {
                                        if item.quantity < item.maxQuantity {
                                            item.quantity += 1
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 4)
                            }
                            
                            HStack {
                                Text("Giá hoàn lại")
                                Spacer()
                                Text(item.pricePerUnit.formattedAsCurrency())
                            }
                            
                            // THÊM MỚI: Thông báo lỗi khi số lượng vượt quá giới hạn
                            if item.quantity > item.maxQuantity {
                                Text("Số lượng trả lại không được vượt quá số lượng đã mua (\(item.maxQuantity))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .onDelete(perform: removeReturnItem)
                    
                    Button("Thêm sản phẩm") {
                        isShowingProductPicker = true
                    }
                }
                
                Section("Tổng tiền hoàn trả") {
                    HStack {
                        Text("Tổng cộng")
                        Spacer()
                        Text(totalRefundAmount.formattedAsCurrency())
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Tạo Phiếu Trả Hàng")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    // Vô hiệu hóa nút "Lưu" nếu phiếu trả hàng không hợp lệ
                    Button("Lưu") { saveReturnSlip() }.disabled(!isReturnSlipValid)
                }
            }
            .sheet(isPresented: $isShowingProductPicker) {
                ProductPickerForReturnView(
                    invoiceDetails: invoice.details,
                    returnItems: $returnItems
                )
            }
        }
    }
    
    private func saveReturnSlip() {
        let newReturnSlip = ReturnSlip(
            returnDate: .now,
            totalRefundAmount: totalRefundAmount,
            customer: invoice.customer,
            invoice: invoice
        )
        
        for item in returnItems {
            let detail = ReturnSlipDetail(
                quantity: item.quantity,
                priceAtReturn: item.pricePerUnit,
                product: item.product
            )
            newReturnSlip.details.append(detail)
            
            if let product = item.product {
                product.stockQuantity += item.quantity
                
                let stockTx = StockTransaction(
                    product: product,
                    quantityChange: item.quantity,
                    transactionDate: .now,
                    transactionType: "TRAHANG_KH",
                    reason: "Khách trả \(item.quantity) \(product.unit) từ hóa đơn \(invoice.id.uuidString.prefix(8))"
                )
                modelContext.insert(stockTx)
            }
        }
        
        // SỬA LỖI: Thêm các tham số 'currency' và 'exchangeRateAtTransaction'
        let fundTx = FundTransaction(
            type: "CHI",
            amount: totalRefundAmount,
            currency: "VNĐ",
            exchangeRateAtTransaction: 1.0,
            reason: "Hoàn tiền cho khách hàng: \(invoice.customer?.name ?? "Khách lẻ")",
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
