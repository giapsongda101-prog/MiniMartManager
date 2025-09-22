// MiniMartManager/Modules/Products/Views/LowStockWarningView.swift
import SwiftUI
import SwiftData

struct LowStockWarningView: View {
    // Query để lấy các sản phẩm có tồn kho thấp hơn hoặc bằng mức tối thiểu
    // và có mức tối thiểu > 0
    @Query(filter: #Predicate<Product> {
        $0.stockQuantity <= $0.minimumStockLevel && $0.minimumStockLevel > 0
    }, sort: \Product.name)
    private var lowStockProducts: [Product]
    
    var body: some View {
        Group {
            if lowStockProducts.isEmpty {
                ContentUnavailableView(
                    "Không có sản phẩm nào sắp hết hàng",
                    systemImage: "checkmark.circle.fill",
                    description: Text("Tất cả các sản phẩm đều có số lượng tồn kho trên mức tối thiểu.")
                )
            } else {
                List(lowStockProducts) { product in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(.headline)
                            Text("Tối thiểu: \(product.minimumStockLevel)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Còn lại: \(product.stockQuantity)")
                            .font(.headline.bold())
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Cảnh báo Tồn kho")
    }
}
