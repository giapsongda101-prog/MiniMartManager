// MiniMartManager/Modules/Categories/Views/CategoryListView.swift
import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    
    @State private var isShowingEditSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    NavigationLink(destination: CategoryEditView(categoryToEdit: category)) {
                        Text(category.name)
                    }
                }
                .onDelete(perform: deleteCategories)
            }
            .navigationTitle("Danh mục")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isShowingEditSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingEditSheet) {
                CategoryEditView()
            }
            .alert("Không thể xóa", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let categoryToDelete = categories[index]
            
            // KIỂM TRA: Nếu danh mục đã có sản phẩm thì không cho xóa
            if !categoryToDelete.products.isEmpty {
                alertMessage = "Không thể xóa danh mục '\(categoryToDelete.name)' vì đang có sản phẩm thuộc danh mục này."
                showAlert = true
                continue // Bỏ qua và không xóa
            }
            
            modelContext.delete(categoryToDelete)
        }
    }
}
