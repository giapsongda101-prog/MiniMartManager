import SwiftUI
import SwiftData

struct ExchangeRateEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var fromCurrency: Currency = .LAK
    @State private var toCurrency: Currency = .VND
    @State private var rate: Double = 0.0
    
    var rateToEdit: ExchangeRate?
    
    private var isFormValid: Bool {
        rate > 0 && fromCurrency != toCurrency
    }
    
    init(rate: ExchangeRate?) {
        self.rateToEdit = rate
        if let rate = rate {
            self._fromCurrency = State(initialValue: Currency(rawValue: rate.fromCurrency) ?? .LAK)
            self._toCurrency = State(initialValue: Currency(rawValue: rate.toCurrency) ?? .VND)
            self._rate = State(initialValue: rate.rate)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cặp tiền tệ") {
                    Picker("Từ", selection: $fromCurrency) {
                        ForEach(Currency.allCases.filter { $0 != .VND }) { currency in
                            Text(currency.rawValue).tag(currency)
                        }
                    }
                    
                    Picker("Đến", selection: $toCurrency) {
                        Text(Currency.VND.rawValue).tag(Currency.VND)
                    }
                    .disabled(true)
                }
                
                Section("Tỷ giá") {
                    HStack {
                        Text("1 \(fromCurrency.rawValue) =")
                        TextField("Tỷ giá", value: $rate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle(rateToEdit == nil ? "Thêm Tỷ giá mới" : "Sửa Tỷ giá")
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
        if let rateToEdit = rateToEdit {
            rateToEdit.fromCurrency = fromCurrency.rawValue
            rateToEdit.toCurrency = toCurrency.rawValue
            rateToEdit.rate = rate
            rateToEdit.lastUpdatedDate = .now
        } else {
            let newRate = ExchangeRate(fromCurrency: fromCurrency.rawValue, toCurrency: toCurrency.rawValue, rate: rate)
            modelContext.insert(newRate)
        }
        dismiss()
    }
}
