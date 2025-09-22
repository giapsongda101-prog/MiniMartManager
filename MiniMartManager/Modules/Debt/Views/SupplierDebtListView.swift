// MiniMartManager/Modules/Debt/Views/SupplierDebtListView.swift
import SwiftUI
import SwiftData

struct SupplierDebtListView: View {
    @Query(filter: #Predicate<GoodsReceipt> { $0.paymentStatus != "PAID" },
           sort: \GoodsReceipt.receiptDate, order: .reverse)
    private var unpaidReceipts: [GoodsReceipt]
    
    @State private var selectedReceipt: GoodsReceipt?
    // THÊM MỚI: State cho thanh tìm kiếm
    @State private var searchText = ""

    private var filteredReceipts: [GoodsReceipt] {
        if searchText.isEmpty {
            return unpaidReceipts
        } else {
            return unpaidReceipts.filter { receipt in
                let supplierName = receipt.supplier?.name ?? "N/A"
                // NÂNG CẤP: Tìm kiếm theo cả tên NCC và ID phiếu nhập
                let receiptIdPrefix = receipt.id.uuidString.prefix(8)
                return supplierName.localizedCaseInsensitiveContains(searchText) ||
                       receiptIdPrefix.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredReceipts) { receipt in
                VStack(alignment: .leading, spacing: 5) {
                    // NÂNG CẤP: Hiển thị ID phiếu nhập
                    Text("Phiếu nhập số: \(receipt.id.uuidString.prefix(8))")
                        .font(.headline)
                    Text("Nhà cung cấp: \(receipt.supplier?.name ?? "N/A")")
                        .font(.subheadline)
                    
                    let amountDue = receipt.totalAmount - receipt.amountPaid
                    Text("Còn nợ: \(amountDue.formattedAsCurrency())")
                        .font(.body.bold())
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Text("Trạng thái: \(receipt.paymentStatus == "PARTIAL" ? "Nợ một phần" : "Chưa thanh toán")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedReceipt = receipt
                }
            }
            .navigationTitle("Công Nợ Phải Trả")
            .searchable(text: $searchText, prompt: "Tìm theo NCC, mã phiếu...")
            .sheet(item: $selectedReceipt) { receipt in
                SupplierPaymentView(receipt: receipt)
            }
        }
    }
}

// View phụ để xác nhận thanh toán cho NCC
struct SupplierPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var receipt: GoodsReceipt
    
    @State private var paymentAmount: Double = 0.0
    private var amountDue: Double {
        receipt.totalAmount - receipt.amountPaid
    }
    
    private var isFormValid: Bool {
        paymentAmount > 0 && paymentAmount <= amountDue
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin phiếu nhập") {
                    LabeledContent("Nhà cung cấp", value: receipt.supplier?.name ?? "N/A")
                    LabeledContent("Tổng tiền", value: receipt.totalAmount.formattedAsCurrency())
                    LabeledContent("Đã trả", value: receipt.amountPaid.formattedAsCurrency())
                    LabeledContent("Còn nợ", value: amountDue.formattedAsCurrency())
                        .foregroundStyle(.red).bold()
                }
                
                Section("Số tiền thanh toán") {
                    TextField("Số tiền trả NCC", value: $paymentAmount, format: .number)
                        .keyboardType(.decimalPad)
                    
                    Button("Trả hết (\(amountDue.formattedAsCurrency()))") {
                        paymentAmount = amountDue
                    }
                }
            }
            .navigationTitle("Thanh Toán NCC")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Đóng") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xác nhận") { recordPayment() }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                paymentAmount = amountDue
            }
        }
    }
    
    private func recordPayment() {
        receipt.amountPaid += paymentAmount
        
        if receipt.amountPaid >= receipt.totalAmount {
            receipt.paymentStatus = "PAID"
        } else {
            receipt.paymentStatus = "PARTIAL"
        }
        
        // ĐÃ SỬA LỖI: Thêm các tham số còn thiếu
        let fundTx = FundTransaction(
            type: "CHI",
            amount: paymentAmount,
            currency: "VND", // Tiền tệ mặc định cho giao dịch nợ
            exchangeRateAtTransaction: 1.0, // Tỷ giá mặc định
            reason: "Thanh toán công nợ cho NCC: \(receipt.supplier?.name ?? "")",
            transactionDate: .now,
            isSystemGenerated: true
        )
        modelContext.insert(fundTx)
        
        dismiss()
    }
}
