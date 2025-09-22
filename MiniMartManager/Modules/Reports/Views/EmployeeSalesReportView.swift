//
//  EmployeeSalesReportView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData
import Charts

struct EmployeeSalesData: Identifiable {
    let id: UUID
    let name: String
    let totalRevenue: Double
}

struct EmployeeSalesReportView: View {
    @Query private var users: [User]
    @Query private var invoices: [Invoice]
    
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
    @State private var endDate: Date = .now
    
    private var salesByEmployee: [EmployeeSalesData] {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: endDate).addingTimeInterval(24 * 60 * 60 - 1)
        
        let filteredInvoices = invoices.filter {
            $0.creationDate >= startDate && $0.creationDate <= endOfDay && $0.user != nil
        }
        
        var employeeSales: [UUID: Double] = [:]
        for invoice in filteredInvoices {
            if let userId = invoice.user?.id {
                // SỬA LỖI: Tính toán doanh thu bằng cách cộng lại số tiền giảm giá
                employeeSales[userId, default: 0] += (invoice.totalAmount + invoice.discountAmount)
            }
        }
        
        return employeeSales
            .map { (userId, totalRevenue) in
                let userName = users.first { $0.id == userId }?.username ?? "N/A"
                return EmployeeSalesData(id: userId, name: userName, totalRevenue: totalRevenue)
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
                
                EmployeeSalesReportContent(salesByEmployee: salesByEmployee)
            }
        }
        .navigationTitle("Doanh thu theo NV")
    }
}

private struct EmployeeSalesReportContentForPDF: View {
    let salesByEmployee: [EmployeeSalesData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Doanh thu theo Nhân viên")
                .font(.title2.bold())
                .padding(.bottom, 8)
            
            if salesByEmployee.isEmpty {
                Text("Chưa có dữ liệu bán hàng trong khoảng thời gian này.")
                    .padding()
            } else {
                Chart(salesByEmployee, id: \.id) { data in
                    BarMark(
                        x: .value("Doanh thu", data.totalRevenue),
                        y: .value("Nhân viên", data.name)
                    )
                    .foregroundStyle(by: .value("Nhân viên", data.name))
                }
                .chartLegend(.hidden)
                .frame(height: CGFloat(salesByEmployee.count * 40) + 50)
                .padding()
                
                List {
                    Section("Chi tiết doanh thu") {
                        ForEach(salesByEmployee) { data in
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
                .frame(height: CGFloat(salesByEmployee.count * 45) + 50)
            }
        }
        .padding()
    }
}

private struct EmployeeSalesReportContent: View {
    let salesByEmployee: [EmployeeSalesData]
    
    var body: some View {
        VStack {
            if salesByEmployee.isEmpty {
                ContentUnavailableView("Chưa có dữ liệu bán hàng trong khoảng thời gian này.", systemImage: "chart.bar.xaxis")
            } else {
                Chart(salesByEmployee, id: \.id) { data in
                    BarMark(
                        x: .value("Doanh thu", data.totalRevenue),
                        y: .value("Nhân viên", data.name)
                    )
                    .foregroundStyle(by: .value("Nhân viên", data.name))
                }
                .chartLegend(.hidden)
                .frame(height: CGFloat(salesByEmployee.count * 40) + 50)
                .padding()
                
                List {
                    Section("Chi tiết doanh thu") {
                        ForEach(salesByEmployee) { data in
                            HStack {
                                Text(data.name)
                                Spacer()
                                Text(data.totalRevenue.formattedAsCurrency())
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(salesByEmployee.count * 45) + 50)
            }
        }
    }
}
