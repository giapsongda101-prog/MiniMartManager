// MiniMartManager/Modules/Customers/Views/CustomerListView.swift
import SwiftUI
import SwiftData

struct CustomerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Customer.name) private var customers: [Customer]
    
    @State private var isShowingEditSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(customers) { customer in
                    NavigationLink(destination: CustomerEditView(customerToEdit: customer)) {
                        VStack(alignment: .leading) {
                            Text(customer.name).font(.headline)
                            if !customer.phone.isEmpty {
                                Text(customer.phone).font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteCustomers)
            }
            // SỬA LỖI: Sử dụng cú pháp cũ hơn
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Khách Hàng")
            .toolbar {
                Button { isShowingEditSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $isShowingEditSheet) {
                CustomerEditView()
            }
            .alert("Không thể xóa", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func deleteCustomers(at offsets: IndexSet) {
        for index in offsets {
            let customerToDelete = customers[index]
            
            let idToDelete = customerToDelete.id
            let fetchDescriptor = FetchDescriptor<Invoice>(predicate: #Predicate {
                $0.customer?.id == idToDelete
            })

            do {
                let invoiceCount = try modelContext.fetchCount(fetchDescriptor)
                if invoiceCount > 0 {
                    alertMessage = "Không thể xóa khách hàng '\(customerToDelete.name)' vì đã có lịch sử mua hàng."
                    showAlert = true
                    continue
                }
            } catch {
                print("Lỗi khi kiểm tra hóa đơn: \(error)")
            }

            modelContext.delete(customerToDelete)
        }
    }
}
