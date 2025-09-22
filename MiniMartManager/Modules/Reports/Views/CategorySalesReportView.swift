//
//  CategorySalesReportView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData
import Charts

struct CategorySalesData: Identifiable {
    var id: UUID
    let name: String
    let totalRevenue: Double
}

struct CategorySalesReportView: View {
    @Query private var categories: [Category]
    @Query private var invoices: [Invoice]
    
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
    @State private var endDate: Date = .now
    
    private var salesByCategory: [CategorySalesData] {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: endDate).addingTimeInterval(24 * 60 * 60 - 1)
        
        let filteredInvoices = invoices.filter { $0.creationDate >= startDate && $0.creationDate <= endOfDay }
        
        var categorySales: [UUID: Double] = [:]
        
        for invoice in filteredInvoices {
            for detail in invoice.details {
                if let categoryId = detail.product?.category?.id {
                    // SỬA LỖI: Ép kiểu quantity sang Double để thực hiện phép nhân
                    let totalSale = Double(detail.quantity) * detail.pricePerUnitAtSale
                    categorySales[categoryId, default: 0] += totalSale
                }
            }
        }
        
        return categorySales
            .map { (categoryId, totalRevenue) in
                let categoryName = categories.first { $0.id == categoryId }?.name ?? "N/A"
                return CategorySalesData(id: categoryId, name: categoryName, totalRevenue: totalRevenue)
            }
            .sorted { $0.totalRevenue > $1.totalRevenue }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Section("Chọn khoảng thời gian") {
                    DatePicker("Từ ngày", selection: $startDate, displayedComponents: .date)
                    DatePicker("Đến ngày", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                .padding()
                
                CategorySalesReportContent(salesByCategory: salesByCategory)
            }
        }
        .navigationTitle("Doanh thu theo Danh mục")
    }
}

private struct CategorySalesReportContentForPDF: View {
    let salesByCategory: [CategorySalesData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Báo cáo Doanh thu theo Danh mục")
                .font(.title2.bold())
                .padding(.bottom, 8)
            
            if salesByCategory.isEmpty {
                Text("Chưa có dữ liệu bán hàng trong khoảng thời gian này.")
                    .padding()
            } else {
                Chart(salesByCategory, id: \.id) { data in
                    BarMark(
                        x: .value("Doanh thu", data.totalRevenue),
                        y: .value("Danh mục", data.name)
                    )
                    .foregroundStyle(by: .value("Danh mục", data.name))
                }
                .chartLegend(.hidden)
                .frame(height: CGFloat(salesByCategory.count * 40) + 50)
                .padding()
                
                List {
                    Section("Chi tiết doanh thu") {
                        ForEach(salesByCategory) { data in
                            HStack {
                                Text(data.name)
                                Spacer()
                                Text(data.totalRevenue.formattedAsCurrency())
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: CGFloat(salesByCategory.count * 45) + 50)
            }
        }
        .padding()
    }
}

private struct CategorySalesReportContent: View {
    let salesByCategory: [CategorySalesData]
    
    var body: some View {
        VStack {
            if salesByCategory.isEmpty {
                ContentUnavailableView("Chưa có dữ liệu bán hàng trong khoảng thời gian này.", systemImage: "chart.bar.xaxis")
            } else {
                Chart(salesByCategory, id: \.id) { data in
                    BarMark(
                        x: .value("Doanh thu", data.totalRevenue),
                        y: .value("Danh mục", data.name)
                    )
                    .foregroundStyle(by: .value("Danh mục", data.name))
                }
                .chartLegend(.hidden)
                .frame(height: CGFloat(salesByCategory.count * 40) + 50)
                .padding()
                
                List {
                    Section("Chi tiết doanh thu") {
                        ForEach(salesByCategory) { data in
                            HStack {
                                Text(data.name)
                                Spacer()
                                Text(data.totalRevenue.formattedAsCurrency())
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(salesByCategory.count * 45) + 50)
            }
        }
    }
}
