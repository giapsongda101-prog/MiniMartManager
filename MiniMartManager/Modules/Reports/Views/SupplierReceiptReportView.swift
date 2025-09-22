//
//  SupplierReceiptReportView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData
import Charts

struct SupplierReceiptData: Identifiable {
    let id: UUID
    let name: String
    let totalValue: Double
}

struct SupplierReceiptReportView: View {
    @Query private var goodsReceipts: [GoodsReceipt]
    @Query private var suppliers: [Supplier]
    
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
    @State private var endDate: Date = .now
    
    private var receiptsBySupplier: [SupplierReceiptData] {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: endDate).addingTimeInterval(24 * 60 * 60 - 1)
        
        let filteredReceipts = goodsReceipts.filter {
            $0.receiptDate >= startDate && $0.receiptDate <= endOfDay && $0.supplier != nil
        }
        
        var supplierTotals: [UUID: Double] = [:]
        
        for receipt in filteredReceipts {
            if let supplierId = receipt.supplier?.id {
                supplierTotals[supplierId, default: 0] += receipt.totalAmount
            }
        }
        
        return supplierTotals
            .map { (supplierId, totalValue) in
                let supplierName = suppliers.first { $0.id == supplierId }?.name ?? "N/A"
                return SupplierReceiptData(id: supplierId, name: supplierName, totalValue: totalValue)
            }
            .sorted { $0.totalValue > $1.totalValue }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Section("Chọn khoảng thời gian") {
                    DatePicker("Từ ngày", selection: $startDate, displayedComponents: .date)
                    DatePicker("Đến ngày", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                .padding()
                
                SupplierReceiptContent(data: receiptsBySupplier)
            }
        }
        .navigationTitle("Nhập hàng theo NCC")
    }
}

private struct SupplierReceiptContentForPDF: View {
    let data: [SupplierReceiptData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Giá trị nhập hàng theo Nhà cung cấp")
                .font(.title2.bold())
                .padding(.bottom, 8)
            
            if data.isEmpty {
                Text("Chưa có dữ liệu nhập hàng trong khoảng thời gian này.")
                    .padding()
            } else {
                Chart(data) { supplierData in
                    BarMark(
                        x: .value("Nhà cung cấp", supplierData.name),
                        y: .value("Giá trị", supplierData.totalValue)
                    )
                    .foregroundStyle(by: .value("Nhà cung cấp", supplierData.name))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                       AxisGridLine()
                       AxisTick()
                       AxisValueLabel()
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 300)
                .padding()
                
                List {
                    Section("Chi tiết giá trị nhập hàng") {
                        ForEach(data) { d in
                            HStack {
                                Text(d.name)
                                Spacer()
                                Text(d.totalValue.formattedAsCurrency())
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: CGFloat(data.count * 45) + 50)
            }
        }
        .padding()
    }
}

private struct SupplierReceiptContent: View {
    let data: [SupplierReceiptData]
    
    var body: some View {
        VStack {
            Text("Giá trị nhập hàng theo Nhà cung cấp")
                .font(.headline)
                .padding()
            
            if data.isEmpty {
                ContentUnavailableView("Chưa có dữ liệu nhập hàng trong khoảng thời gian này.", systemImage: "chart.bar.xaxis")
            } else {
                Chart(data) { d in
                    BarMark(
                        x: .value("Nhà cung cấp", d.name),
                        y: .value("Giá trị", d.totalValue)
                    )
                    .foregroundStyle(by: .value("Nhà cung cấp", d.name))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                       AxisGridLine()
                       AxisTick()
                       AxisValueLabel()
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 300)
                .padding()
                
                List {
                    Section("Chi tiết giá trị nhập hàng") {
                        ForEach(data) { d in
                            HStack {
                                Text(d.name)
                                Spacer()
                                Text(d.totalValue.formattedAsCurrency())
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(data.count * 45) + 50)
            }
        }
    }
}
