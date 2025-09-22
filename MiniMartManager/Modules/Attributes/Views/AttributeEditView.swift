//
//  AttributeEditView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData

struct AttributeEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var attributeToEdit: ProductAttribute?
    @State private var name: String = ""
    
    private var isFormValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var navigationTitle: String { attributeToEdit == nil ? "Tạo Loại Thuộc Tính" : "Sửa Thuộc Tính" }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Tên thuộc tính (VD: Màu sắc)", text: $name)
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
                if let attr = attributeToEdit { name = attr.name }
            }
        }
    }
    
    private func save() {
        if let attr = attributeToEdit {
            attr.name = name
        } else {
            let newAttr = ProductAttribute(name: name)
            modelContext.insert(newAttr)
        }
        dismiss()
    }
}
