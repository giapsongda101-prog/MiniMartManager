// MiniMartManager/Modules/Sales/Views/CheckoutView.swift
import SwiftUI
import SwiftData

struct CheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @ObservedObject var cartManager: CartManager
    
    // Callback để xử lý sau khi thanh toán thành công
    var onCheckoutSuccess: (Invoice) -> Void
    
    @State private var amountReceived: Double?
    @State private var isProcessing = false
    
    // THÊM: Biến môi trường để truy cập người dùng hiện tại
    @EnvironmentObject var authManager: AuthenticationManager
    
    private var totalAmount: Double { cartManager.totalAmount }
    private var changeDue: Double {
        guard let amount = amountReceived else { return 0 }
        return amount - totalAmount
    }
    
    private var isCashPaymentValid: Bool {
        guard let amount = amountReceived else { return false }
        return amount >= totalAmount
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tóm tắt đơn hàng") {
                    LabeledContent("Tổng cộng", value: totalAmount.formattedAsCurrency())
                        .font(.headline)
                    LabeledContent("Khách hàng", value: cartManager.selectedCustomer?.name ?? "Khách lẻ")
                }
                
                Section("Thanh toán bằng tiền mặt") {
                    TextField("Số tiền khách đưa", value: $amountReceived, format: .currency(code: "VND"))
                        .keyboardType(.decimalPad)
                        .font(.title2)
                    
                    if let amount = amountReceived, amount > 0 {
                        LabeledContent("Tiền thừa trả lại", value: changeDue.formattedAsCurrency())
                            .font(.headline)
                            .foregroundStyle(changeDue >= 0 ? .green : .red)
                    }
                    
                    quickInputButtons
                }
                
                Section("Phương thức thanh toán") {
                    Button(action: { processCheckout(paid: true) }) {
                        Label("Thanh toán ngay bằng tiền mặt", systemImage: "dollarsign.circle.fill")
                    }
                    .buttonStyle(VividButtonStyle())
                    .disabled(!isCashPaymentValid)
                    
                    Button(action: { processCheckout(paid: false) }) {
                        Label("Thanh toán & Ghi nợ", systemImage: "list.bullet.rectangle.portrait.fill")
                    }
                    .tint(.orange)
                    .disabled(cartManager.selectedCustomer == nil)
                }
            }
            .navigationTitle("Thanh Toán")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
            }
            .disabled(isProcessing)
            .overlay {
                if isProcessing {
                    ProgressView("Đang xử lý...")
                }
            }
        }
    }
    
    private var quickInputButtons: some View {
        HStack {
            Button("\(totalAmount.formattedAsCurrency())") { amountReceived = totalAmount }
                .buttonStyle(.bordered)
            
            if totalAmount < 500000 {
                Button("500.000đ") { amountReceived = 500000 }
                    .buttonStyle(.bordered)
            }
        }
    }
    
    private func processCheckout(paid: Bool) {
        isProcessing = true
        // Dùng Task để xử lý bất đồng bộ, tránh block UI
        Task {
            // SỬA: Truyền người dùng hiện tại vào phương thức checkout
            if let newInvoice = cartManager.checkout(paid: paid, modelContext: modelContext, user: authManager.currentUser) {
                onCheckoutSuccess(newInvoice)
                dismiss()
            }
            isProcessing = false
        }
    }
}
