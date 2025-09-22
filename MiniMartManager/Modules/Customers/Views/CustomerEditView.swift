//
//  CustomerEditView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData

struct CustomerEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var customerToEdit: Customer?
    
    @State private var name: String = ""
    @State private var phone: String = ""
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var navigationTitle: String {
        customerToEdit == nil ? "Tạo Khách Hàng" : "Sửa Khách Hàng"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Thông tin khách hàng")) {
                    TextField("Tên khách hàng (bắt buộc)", text: $name)
                    TextField("Số điện thoại", text: $phone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { save() }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                if let customer = customerToEdit {
                    name = customer.name
                    phone = customer.phone
                }
            }
        }
    }
    
    private func save() {
        if let customer = customerToEdit {
            customer.name = name
            customer.phone = phone
        } else {
            let newCustomer = Customer(name: name, phone: phone)
            modelContext.insert(newCustomer)
        }
        dismiss()
    }
}
