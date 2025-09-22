//
//  InventoryReportView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData

struct InventoryReportView: View {
    @Query(sort: \Product.name) private var products: [Product]
    @State private var searchText = ""
    
    private var filteredProducts: [Product] {
        guard !searchText.isEmpty else { return products }
        return products.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            Section("Tổng quan tồn kho") {
                HStack {
                    Text("Tổng số sản phẩm")
                    Spacer()
                    Text("\(products.count)").fontWeight(.semibold)
                }
                HStack {
                    Text("Số sản phẩm sắp hết hàng")
                    Spacer()
                    Text("\(products.filter { $0.stockQuantity <= $0.minimumStockLevel }.count)")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
            
            Section("Chi tiết tồn kho") {
                ForEach(filteredProducts) { product in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name).font(.headline)
                            Text("Mã sản phẩm: \(product.sku)").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Tồn kho: \(product.stockQuantity) \(product.unit)")
                                .fontWeight(.semibold)
                                .foregroundColor(product.stockQuantity <= product.minimumStockLevel ? .red : .primary)
                            
                            if product.stockQuantity <= product.minimumStockLevel {
                                Text("Sắp hết hàng!").font(.caption).foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Báo cáo Tồn kho")
        .searchable(text: $searchText, prompt: "Tìm kiếm sản phẩm")
    }
}

#Preview {
    InventoryReportView()
}
