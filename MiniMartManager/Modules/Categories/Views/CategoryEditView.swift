//
//  CategoryEditView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData

struct CategoryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var categoryToEdit: Category?
    
    @State private var name: String = ""
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var navigationTitle: String {
        categoryToEdit == nil ? "Tạo Danh Mục" : "Sửa Danh Mục"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Tên danh mục")) {
                    TextField("Tên danh mục (bắt buộc)", text: $name)
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
                if let category = categoryToEdit {
                    name = category.name
                }
            }
        }
    }
    
    private func save() {
        if let category = categoryToEdit {
            category.name = name
        } else {
            let newCategory = Category(name: name)
            modelContext.insert(newCategory)
        }
        dismiss()
    }
}
