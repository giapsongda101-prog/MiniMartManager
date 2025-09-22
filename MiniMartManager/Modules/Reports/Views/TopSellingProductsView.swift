//
//  TopSellingProductsView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData
import Charts

struct ProductSalesData: Identifiable {
    var id: UUID
    let name: String
    let quantitySold: Int
}

struct TopSellingProductsView: View {
    @Query private var invoices: [Invoice]
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
    @State private var endDate: Date = .now
    
    private var topSellingProducts: [ProductSalesData] {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: endDate).addingTimeInterval(24 * 60 * 60 - 1)
        
        let filteredInvoices = invoices.filter { $0.creationDate >= startDate && $0.creationDate <= endOfDay }
        
        var productSales: [UUID: Int] = [:]
        var productNames: [UUID: String] = [:]

        for invoice in filteredInvoices {
            for detail in invoice.details {
                if let product = detail.product {
                    let baseQuantitySold = detail.quantity * detail.conversionFactorAtSale
                    productSales[product.id, default: 0] += baseQuantitySold
                    productNames[product.id] = product.name
                }
            }
        }
        
        return productSales
            .map { (productId, totalQuantity) in
                ProductSalesData(id: productId, name: productNames[productId] ?? "N/A", quantitySold: totalQuantity)
            }
            .sorted { $0.quantitySold > $1.quantitySold }
            .prefix(10)
            .map { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Section("Chọn khoảng thời gian") {
                    DatePicker("Từ ngày", selection: $startDate, displayedComponents: .date)
                    DatePicker("Đến ngày", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                .padding()
                
                TopSellingProductsContent(products: topSellingProducts)
            }
        }
        .navigationTitle("Sản Phẩm Bán Chạy")
    }
}

private struct TopSellingProductsContentForPDF: View {
    let products: [ProductSalesData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 10 Sản phẩm Bán chạy nhất")
                .font(.title2.bold())
                .padding(.bottom, 8)

            if products.isEmpty {
                Text("Chưa có dữ liệu bán hàng.")
                    .padding()
            } else {
                Chart(products) { productData in
                    BarMark(
                        x: .value("Số lượng", productData.quantitySold),
                        y: .value("Sản phẩm", productData.name)
                    )
                    .foregroundStyle(by: .value("Sản phẩm", productData.name))
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                       AxisGridLine()
                       AxisTick()
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 400)
                .padding()

                List {
                    Section("Chi tiết số lượng đã bán") {
                        ForEach(products) { data in
                            HStack {
                                Text(data.name)
                                Spacer()
                                Text("\(data.quantitySold)")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: CGFloat(products.count * 45) + 50)
            }
        }
        .padding()
    }
}

private struct TopSellingProductsContent: View {
    let products: [ProductSalesData]
    
    var body: some View {
        VStack {
            Text("Top 10 Sản phẩm Bán chạy nhất (Theo số lượng)")
                .font(.headline)
                .padding()
            
            if products.isEmpty {
                ContentUnavailableView("Chưa có dữ liệu bán hàng", systemImage: "chart.bar.xaxis")
            } else {
                Chart(products) { productData in
                    BarMark(
                        x: .value("Số lượng", productData.quantitySold),
                        y: .value("Sản phẩm", productData.name)
                    )
                    .foregroundStyle(by: .value("Sản phẩm", productData.name))
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                       AxisGridLine()
                       AxisTick()
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 400)
                .padding()

                List {
                    Section("Chi tiết số lượng đã bán") {
                        ForEach(products) { data in
                            HStack {
                                Text(data.name)
                                Spacer()
                                Text("\(data.quantitySold)")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(products.count * 45) + 50)
            }
        }
    }
}
