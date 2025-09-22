//
//  CreateFundTransactionView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData

enum FundTransactionType: String, CaseIterable, Identifiable {
    case income = "THU"
    case expense = "CHI"
    var id: Self { self }
    
    var localizedName: String {
        switch self {
        case .income:
            return "Phiếu Thu"
        case .expense:
            return "Phiếu Chi"
        }
    }
}

struct CreateFundTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var type: FundTransactionType = .expense
    @State private var amount: Double = 0.0
    @State private var reason: String = ""
    
    // THÊM: State để chọn loại tiền tệ
    @State private var selectedCurrency: Currency = .VND
    // THÊM: Query để lấy tỷ giá hối đoái
    @Query private var exchangeRates: [ExchangeRate]

    private var isFormValid: Bool {
        amount > 0 && !reason.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // TÍNH TOÁN TỶ GIÁ TẠI THỜI ĐIỂM HIỆN TẠI
    private var currentExchangeRate: Double {
        if selectedCurrency == .VND {
            return 1.0
        }
        return exchangeRates.first(where: { $0.fromCurrency == selectedCurrency.rawValue && $0.toCurrency == "VNĐ" })?.rate ?? 0.0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Loại phiếu", selection: $type) {
                        ForEach(FundTransactionType.allCases) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text("Số tiền")
                        Spacer()
                        TextField("0", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Tiền tệ", selection: $selectedCurrency) {
                        ForEach(Currency.allCases) { currency in
                            Text(currency.rawValue).tag(currency)
                        }
                    }
                    
                    // Hiển thị giá trị quy đổi nếu không phải VNĐ
                    if selectedCurrency != .VND {
                        LabeledContent("Giá trị quy đổi (VNĐ)", value: (amount * currentExchangeRate).formatted(.number))
                            .foregroundStyle(.secondary)
                    }
                    
                    TextField("Nội dung giao dịch", text: $reason)
                }
            }
            .navigationTitle("Tạo Phiếu Mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { save() }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func save() {
        let newTransaction = FundTransaction(
            type: type.rawValue,
            amount: amount,
            currency: selectedCurrency.rawValue,
            exchangeRateAtTransaction: currentExchangeRate,
            reason: reason,
            transactionDate: .now,
            isSystemGenerated: false
        )
        modelContext.insert(newTransaction)
        dismiss()
    }
}
