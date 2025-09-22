import SwiftUI
import SwiftData

struct ProductPickerForReturnView: View {
    @Environment(\.dismiss) private var dismiss
    
    let invoiceDetails: [InvoiceDetail]
    @Binding var returnItems: [ReturnItem]
    
    @State private var searchText = ""
    
    private var filteredDetails: [InvoiceDetail] {
        invoiceDetails.filter { detail in
            let isAlreadyAdded = returnItems.contains(where: { $0.product?.id == detail.product?.id })
            guard !isAlreadyAdded else { return false }
            
            if let productName = detail.product?.name {
                return searchText.isEmpty || productName.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredDetails) { detail in
                    Button(action: { addProductToReturn(detail) }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(detail.product?.name ?? "N/A").font(.headline)
                                Text("Giá bán: \(detail.pricePerUnitAtSale.formattedAsCurrency()) / \(detail.unitName)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("Đã bán: \(detail.quantity) \(detail.unitName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Tìm tên sản phẩm")
            .navigationTitle("Chọn Sản Phẩm Trả Lại")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Xong") { dismiss() }
                }
            }
        }
    }
    
    private func addProductToReturn(_ detail: InvoiceDetail) {
        let newItem = ReturnItem(
            product: detail.product,
            quantity: 1,
            maxQuantity: detail.quantity, // Lấy số lượng đã mua từ hóa đơn chi tiết
            pricePerUnit: detail.pricePerUnitAtSale
        )
        returnItems.append(newItem)
        dismiss() // Đóng sheet sau khi chọn
    }
}
