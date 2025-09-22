// MiniMartManager/Modules/Suppliers/Views/SupplierListView.swift
import SwiftUI
import SwiftData

struct SupplierListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Supplier.name) private var suppliers: [Supplier]
    
    @State private var isShowingEditSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(suppliers) { supplier in
                    NavigationLink(destination: SupplierEditView(supplierToEdit: supplier)) {
                        VStack(alignment: .leading) {
                            Text(supplier.name).font(.headline)
                            if !supplier.phone.isEmpty {
                                Text(supplier.phone).font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteSuppliers)
            }
            .navigationTitle("Nhà Cung Cấp")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isShowingEditSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingEditSheet) {
                SupplierEditView()
            }
            .alert("Không thể xóa", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func deleteSuppliers(at offsets: IndexSet) {
        for index in offsets {
            let supplierToDelete = suppliers[index]
            
            // SỬA LỖI 1: Bỏ dấu '?' vì 'products' không phải là optional
            if !supplierToDelete.products.isEmpty {
                alertMessage = "Không thể xóa nhà cung cấp '\(supplierToDelete.name)' vì đã có sản phẩm được liên kết."
                showAlert = true
                continue
            }
            
            // SỬA LỖI 2: Gán id vào một biến tạm
            let idToDelete = supplierToDelete.id
            let fetchDescriptor = FetchDescriptor<GoodsReceipt>(predicate: #Predicate {
                $0.supplier?.id == idToDelete
            })

            do {
                let receiptCount = try modelContext.fetchCount(fetchDescriptor)
                if receiptCount > 0 {
                    alertMessage = "Không thể xóa nhà cung cấp '\(supplierToDelete.name)' vì đã có lịch sử nhập hàng."
                    showAlert = true
                    continue
                }
            } catch {
                print("Lỗi khi kiểm tra phiếu nhập: \(error)")
            }
            
            modelContext.delete(supplierToDelete)
        }
    }
}
