//
//  SupplierEditView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData

struct SupplierEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var supplierToEdit: Supplier?
    
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var navigationTitle: String {
        supplierToEdit == nil ? "Tạo Nhà Cung Cấp" : "Sửa Nhà Cung Cấp"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Thông tin nhà cung cấp")) {
                    TextField("Tên nhà cung cấp (bắt buộc)", text: $name)
                    TextField("Số điện thoại", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Địa chỉ", text: $address)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") { save() }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                if let supplier = supplierToEdit {
                    name = supplier.name
                    phone = supplier.phone
                    address = supplier.address
                }
            }
        }
    }
    
    private func save() {
        if let supplier = supplierToEdit {
            supplier.name = name
            supplier.phone = phone
            supplier.address = address
        } else {
            let newSupplier = Supplier(name: name, phone: phone, address: address)
            modelContext.insert(newSupplier)
        }
        dismiss()
    }
}
