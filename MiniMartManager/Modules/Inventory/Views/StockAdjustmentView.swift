//
//  StockAdjustmentView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData

enum AdjustmentType: String, CaseIterable, Identifiable {
    case increase = "Tăng tồn kho"
    case decrease = "Giảm tồn kho"
    var id: Self { self }
}

struct StockAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Product.name) private var products: [Product]
    
    @State private var selectedProduct: Product?
    @State private var adjustmentType: AdjustmentType = .decrease
    @State private var quantity: Int = 1
    @State private var reason: String = ""
    
    private var isFormValid: Bool {
        selectedProduct != nil && quantity > 0 && !reason.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin điều chỉnh") {
                    Picker("Sản phẩm", selection: $selectedProduct) {
                        Text("Chọn sản phẩm").tag(Product?.none)
                        ForEach(products) {
                            Text($0.name).tag($0 as Product?)
                        }
                    }
                    
                    Picker("Loại điều chỉnh", selection: $adjustmentType) {
                        ForEach(AdjustmentType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Stepper("Số lượng: \(quantity)", value: $quantity, in: 1...1000)
                    
                    TextField("Lý do (bắt buộc)", text: $reason)
                }
            }
            .navigationTitle("Điều Chỉnh Tồn Kho")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { saveAdjustment() }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func saveAdjustment() {
        guard let product = selectedProduct else { return }
        
        let quantityChange = (adjustmentType == .increase) ? quantity : -quantity
        let transactionType = (adjustmentType == .increase) ? "DIEUCHINH_TANG" : "DIEUCHINH_GIAM"
        
        // 1. Update product stock
        product.stockQuantity += quantityChange
        
        // 2. Create stock transaction log
        let stockTx = StockTransaction(
            product: product,
            quantityChange: quantityChange,
            transactionDate: .now,
            transactionType: transactionType,
            reason: reason
        )
        modelContext.insert(stockTx)
        
        dismiss()
    }
}
