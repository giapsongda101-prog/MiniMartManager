// MiniMartManager/Modules/Debt/Views/CustomerDebtListView.swift
import SwiftUI
import SwiftData

struct CustomerDebtListView: View {
    @Query(filter: #Predicate<Invoice> { $0.paymentStatus != "PAID" },
           sort: \Invoice.creationDate, order: .reverse)
    private var unpaidInvoices: [Invoice]
    
    @State private var selectedInvoice: Invoice?
    // THÊM MỚI: State cho thanh tìm kiếm
    @State private var searchText = ""

    private var filteredInvoices: [Invoice] {
        if searchText.isEmpty {
            return unpaidInvoices
        } else {
            return unpaidInvoices.filter { invoice in
                let customerName = invoice.customer?.name ?? "Khách lẻ"
                // NÂNG CẤP: Tìm kiếm theo cả tên khách hàng và ID hóa đơn
                let invoiceIdPrefix = invoice.id.uuidString.prefix(8)
                return customerName.localizedCaseInsensitiveContains(searchText) ||
                       invoiceIdPrefix.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredInvoices) { invoice in
                VStack(alignment: .leading, spacing: 5) {
                    // NÂNG CẤP: Hiển thị ID hóa đơn
                    Text("HĐ số: \(invoice.id.uuidString.prefix(8))")
                        .font(.headline)
                    Text("Khách hàng: \(invoice.customer?.name ?? "Khách lẻ")")
                        .font(.subheadline)
                    
                    let amountDue = invoice.totalAmount - invoice.amountPaid
                    Text("Còn nợ: \(amountDue.formattedAsCurrency())")
                        .font(.body.bold())
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Text("Trạng thái: \(invoice.paymentStatus == "PARTIAL" ? "Nợ một phần" : "Chưa thanh toán")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedInvoice = invoice
                }
            }
            .navigationTitle("Công Nợ Phải Thu")
            .searchable(text: $searchText, prompt: "Tìm theo khách hàng, mã HĐ...")
            .sheet(item: $selectedInvoice) { invoice in
                CustomerPaymentView(invoice: invoice)
            }
        }
    }
}

// View mới để thu nợ khách hàng
struct CustomerPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var invoice: Invoice
    
    @State private var paymentAmount: Double = 0.0
    private var amountDue: Double {
        invoice.totalAmount - invoice.amountPaid
    }
    
    private var isFormValid: Bool {
        paymentAmount > 0 && paymentAmount <= amountDue
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin hóa đơn") {
                    LabeledContent("Khách hàng", value: invoice.customer?.name ?? "Khách lẻ")
                    LabeledContent("Tổng tiền hóa đơn", value: invoice.totalAmount.formattedAsCurrency())
                    LabeledContent("Đã thanh toán", value: invoice.amountPaid.formattedAsCurrency())
                    LabeledContent("Còn phải thu", value: amountDue.formattedAsCurrency())
                        .foregroundStyle(.red).bold()
                }
                
                Section("Số tiền thanh toán") {
                    TextField("Số tiền khách trả", value: $paymentAmount, format: .number)
                        .keyboardType(.decimalPad)
                    
                    Button("Trả hết (\(amountDue.formattedAsCurrency()))") {
                        paymentAmount = amountDue
                    }
                }
            }
            .navigationTitle("Thu Nợ Khách Hàng")
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
        invoice.amountPaid += paymentAmount
        
        if invoice.amountPaid >= invoice.totalAmount {
            invoice.paymentStatus = "PAID"
        } else {
            invoice.paymentStatus = "PARTIAL"
        }
        
        // ĐÃ SỬA LỖI: Thêm các tham số còn thiếu
        let fundTx = FundTransaction(
            type: "THU",
            amount: paymentAmount,
            currency: "VND", // Tiền tệ mặc định cho giao dịch nợ
            exchangeRateAtTransaction: 1.0, // Tỷ giá mặc định
            reason: "Thu nợ từ khách: \(invoice.customer?.name ?? "Khách lẻ")",
            transactionDate: .now,
            isSystemGenerated: true
        )
        modelContext.insert(fundTx)
        
        dismiss()
    }
}
