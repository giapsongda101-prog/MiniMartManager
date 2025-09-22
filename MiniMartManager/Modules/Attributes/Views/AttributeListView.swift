// MiniMartManager/Modules/Attributes/Views/AttributeListView.swift
import SwiftUI
import SwiftData

struct AttributeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProductAttribute.name) private var attributes: [ProductAttribute]
    
    @State private var isShowingEditSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(attributes) { attr in
                    NavigationLink(destination: AttributeEditView(attributeToEdit: attr)) {
                        Text(attr.name)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Loại Thuộc Tính")
            .toolbar {
                Button { isShowingEditSheet = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $isShowingEditSheet) { AttributeEditView() }
            .alert("Không thể xóa", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let attributeToDelete = attributes[index]

            // SỬA LỖI TẠI ĐÂY
            // Gán id vào một biến tạm để trình biên dịch có thể xử lý đúng kiểu dữ liệu
            let idToDelete = attributeToDelete.id
            let fetchDescriptor = FetchDescriptor<ProductAttributeValue>(predicate: #Predicate {
                $0.attribute?.id == idToDelete
            })
            
            do {
                let valueCount = try modelContext.fetchCount(fetchDescriptor)
                if valueCount > 0 {
                    alertMessage = "Không thể xóa thuộc tính '\(attributeToDelete.name)' vì đã có sản phẩm sử dụng thuộc tính này."
                    showAlert = true
                    continue
                }
            } catch {
                print("Lỗi khi kiểm tra giá trị thuộc tính: \(error)")
            }
            
            modelContext.delete(attributeToDelete)
        }
    }
}
