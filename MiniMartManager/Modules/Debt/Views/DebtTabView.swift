//
//  DebtTabView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData
import Charts

struct DebtTabView: View {
    // SỬA LỖI: Query tất cả hóa đơn và phiếu nhập để tính toán
    @Query(filter: #Predicate<Invoice> { $0.paymentStatus != "PAID" })
    private var unpaidInvoices: [Invoice]
    
    @Query(filter: #Predicate<GoodsReceipt> { $0.paymentStatus != "PAID" })
    private var unpaidReceipts: [GoodsReceipt]
    
    // THÊM MỚI: Tính toán tổng công nợ phải thu và phải trả
    private var totalReceivable: Double {
        unpaidInvoices.reduce(0) { $0 + ($1.totalAmount - $1.amountPaid) }
    }
    
    private var totalPayable: Double {
        unpaidReceipts.reduce(0) { $0 + ($1.totalAmount - $1.amountPaid) }
    }
    
    // THÊM MỚI: Cấu trúc dữ liệu cho biểu đồ
    private var debtData: [DebtType] {
        [
            DebtType(name: "Phải Thu", amount: totalReceivable, color: .orange),
            DebtType(name: "Phải Trả", amount: totalPayable, color: .red)
        ]
    }
    
    var body: some View {
        NavigationStack {
            List {
                // NÂNG CẤP: Section tổng quan công nợ với biểu đồ
                Section("Tổng quan công nợ") {
                    HStack {
                        Text("Tổng phải thu")
                        Spacer()
                        Text(totalReceivable.formattedAsCurrency())
                            .foregroundStyle(.orange)
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Tổng phải trả")
                        Spacer()
                        Text(totalPayable.formattedAsCurrency())
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                    }
                    
                    if totalReceivable > 0 || totalPayable > 0 {
                        Chart(debtData) { data in
                            SectorMark(
                                angle: .value("Số tiền", data.amount)
                            )
                            .foregroundStyle(by: .value("Loại công nợ", data.name))
                        }
                        .frame(height: 200)
                        .chartLegend(position: .bottom)
                        .padding(.vertical)
                    }
                }
                
                Section("Chi tiết công nợ") {
                    NavigationLink(destination: CustomerDebtListView()) {
                        Label("Công Nợ Phải Thu", systemImage: "arrow.down.left.circle.fill")
                    }
                    NavigationLink(destination: SupplierDebtListView()) {
                        Label("Công Nợ Phải Trả", systemImage: "arrow.up.right.circle.fill")
                    }
                }
            }
            .navigationTitle("Quản Lý Công Nợ")
        }
    }
}

// THÊM MỚI: Struct cho dữ liệu biểu đồ
struct DebtType: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let color: Color
}
