import SwiftUI
import SwiftData

struct FinancialReportView: View {
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
    @State private var endDate: Date = .now
    
    @Query private var invoices: [Invoice]
    @Query private var returnSlips: [ReturnSlip]
    
    private var reportData: ReportData {
        calculateReportData()
    }
    
    struct ReportData {
        let totalRevenue: Double
        let totalCostOfGoods: Double
        let totalRefunds: Double
        var grossProfit: Double {
            totalRevenue - totalCostOfGoods - totalRefunds
        }
    }
    
    init() { }
    
    var body: some View {
        Form {
            Section("Chọn khoảng thời gian") {
                DatePicker("Từ ngày", selection: $startDate, displayedComponents: .date)
                DatePicker("Đến ngày", selection: $endDate, in: startDate..., displayedComponents: .date)
            }
            
            Section("Kết quả kinh doanh") {
                ReportRow(label: "Tổng doanh thu", value: reportData.totalRevenue, color: .blue)
                ReportRow(label: "Tổng giá vốn hàng bán", value: reportData.totalCostOfGoods, color: .orange)
                ReportRow(label: "Tổng tiền hoàn trả", value: reportData.totalRefunds, color: .red)
                
                Divider()
                
                ReportRow(label: "Lợi nhuận gộp", value: reportData.grossProfit, color: .green, isBold: true)
            }
        }
        .navigationTitle("Báo Cáo Tài Chính")
    }
    
    private func calculateReportData() -> ReportData {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: endDate).addingTimeInterval(24 * 60 * 60 - 1)
        
        let filteredInvoices = invoices.filter { $0.creationDate >= startDate && $0.creationDate <= endOfDay }
        let filteredReturns = returnSlips.filter { $0.returnDate >= startDate && $0.returnDate <= endOfDay }
        
        // SỬA LỖI: Tính toán doanh thu bằng cách cộng lại số tiền giảm giá
        let totalRevenue = filteredInvoices.reduce(0) { $0 + ($1.totalAmount + $1.discountAmount) }
        let totalCostOfGoods = filteredInvoices.reduce(0) { $0 + $1.totalCost }
        let totalRefunds = filteredReturns.reduce(0) { $0 + $1.totalRefundAmount }
        
        return ReportData(totalRevenue: totalRevenue, totalCostOfGoods: totalCostOfGoods, totalRefunds: totalRefunds)
    }
}

private struct FinancialReportContentForPDF: View {
    let reportData: FinancialReportView.ReportData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Báo Cáo Tài Chính")
                .font(.title2.bold())
                .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                ReportRow(label: "Tổng doanh thu", value: reportData.totalRevenue, color: .blue)
                ReportRow(label: "Tổng giá vốn hàng bán", value: reportData.totalCostOfGoods, color: .orange)
                ReportRow(label: "Tổng tiền hoàn trả", value: reportData.totalRefunds, color: .red)
                
                Divider()
                
                ReportRow(label: "Lợi nhuận gộp", value: reportData.grossProfit, color: .green, isBold: true)
            }
        }
        .padding()
    }
}

struct ReportRow: View {
    let label: String
    let value: Double
    let color: Color
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(isBold ? .bold : .regular)
            Spacer()
            Text(value.formattedAsCurrency())
                .foregroundColor(color)
                .fontWeight(isBold ? .bold : .regular)
        }
    }
}
