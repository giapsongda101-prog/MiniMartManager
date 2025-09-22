import SwiftUI
import SwiftData

struct PromotionEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var promotionToEdit: Promotion?
    
    @State private var name: String = ""
    @State private var promotionType: PromotionType = .percentageDiscount
    @State private var value: Double = 0.0
    @State private var minimumSpend: Double = 0.0
    @State private var startDate: Date = .now
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: .now)!
    @State private var isActive: Bool = true
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && value > 0
    }
    
    private var navigationTitle: String {
        promotionToEdit == nil ? "Tạo Khuyến Mãi Mới" : "Sửa Khuyến Mãi"
    }
    
    private var valueFieldLabel: String {
        switch promotionType {
        case .percentageDiscount:
            return "Phần trăm giảm (%)"
        case .fixedAmountDiscount:
            return "Số tiền giảm (đ)"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin chương trình") {
                    TextField("Tên chương trình (bắt buộc)", text: $name)
                    Toggle("Kích hoạt chương trình", isOn: $isActive)
                }
                
                Section("Loại và giá trị khuyến mãi") {
                    Picker("Loại khuyến mãi", selection: $promotionType) {
                        ForEach(PromotionType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    TextField(valueFieldLabel, value: $value, format: .number)
                        .keyboardType(.decimalPad)
                }
                
                Section("Điều kiện áp dụng") {
                    TextField("Áp dụng cho hóa đơn từ (đ)", value: $minimumSpend, format: .number)
                        .keyboardType(.decimalPad)
                }
                
                Section("Thời gian hiệu lực") {
                    DatePicker("Ngày bắt đầu", selection: $startDate, displayedComponents: .date)
                    DatePicker("Ngày kết thúc", selection: $endDate, displayedComponents: .date)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { save() }.disabled(!isFormValid)
                }
            }
            .onAppear(perform: loadPromotionData)
        }
    }
    
    private func loadPromotionData() {
        if let promo = promotionToEdit {
            name = promo.name
            promotionType = promo.promotionType
            value = promo.value
            minimumSpend = promo.minimumSpend
            startDate = promo.startDate
            endDate = promo.endDate
            isActive = promo.isActive
        }
    }
    
    private func save() {
        if let promo = promotionToEdit {
            // Cập nhật
            promo.name = name
            promo.promotionType = promotionType
            promo.value = value
            promo.minimumSpend = minimumSpend
            promo.startDate = startDate
            promo.endDate = endDate
            promo.isActive = isActive
        } else {
            // Tạo mới
            let newPromotion = Promotion(
                name: name,
                promotionType: promotionType,
                value: value,
                minimumSpend: minimumSpend,
                startDate: startDate,
                endDate: endDate,
                isActive: isActive
            )
            modelContext.insert(newPromotion)
        }
        dismiss()
    }
}
