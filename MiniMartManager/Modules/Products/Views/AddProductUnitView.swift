//
//  AddProductUnitView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData

struct AddProductUnitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let product: Product
    let unitToEdit: ProductUnit?
    
    @State private var name: String = ""
    @State private var conversionFactor: Int = 2
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && conversionFactor > 1
    }
    
    private var navigationTitle: String {
        unitToEdit == nil ? "Thêm Đơn vị Quy đổi" : "Sửa Đơn vị Quy đổi"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin đơn vị tính") {
                    TextField("Tên đơn vị (VD: Lốc, Thùng)", text: $name)
                    
                    Stepper("1 \(name.isEmpty ? "..." : name) = \(conversionFactor) \(product.unit)",
                            value: $conversionFactor,
                            in: 2...1000)
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
            .onAppear {
                // Nếu là sửa, điền thông tin có sẵn
                if let unit = unitToEdit {
                    name = unit.name
                    conversionFactor = unit.conversionFactor
                }
            }
        }
    }
    
    private func save() {
        if let unit = unitToEdit {
            // Cập nhật đơn vị đã có
            unit.name = name
            unit.conversionFactor = conversionFactor
        } else {
            // Tạo đơn vị mới
            let newUnit = ProductUnit(
                name: name,
                conversionFactor: conversionFactor,
                product: product
            )
            modelContext.insert(newUnit)
        }
        dismiss()
    }
}
