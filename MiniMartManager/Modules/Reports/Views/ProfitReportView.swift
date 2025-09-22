import SwiftUI
import SwiftData
import Charts

// Struct để giữ dữ liệu lợi nhuận theo ngày
struct DailyProfit: Identifiable {
    let id = UUID()
    let date: Date
    let profit: Double
}

struct ProfitReportView: View {
    @Query(sort: \Invoice.creationDate, order: .forward) private var invoices: [Invoice]
    
    @State private var selectedTimeRange: TimeRange = .last7Days
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
    @State private var customEndDate: Date = .now
    
    private var profitData: [DailyProfit] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var daysToGoBack: Int
        var startDate: Date
        
        switch selectedTimeRange {
        case .last7Days:
            daysToGoBack = 7
            startDate = calendar.date(byAdding: .day, value: -(daysToGoBack - 1), to: today)!
        case .last30Days:
            daysToGoBack = 30
            startDate = calendar.date(byAdding: .day, value: -(daysToGoBack - 1), to: today)!
        case .custom:
            startDate = Calendar.current.startOfDay(for: customStartDate)
            let endDate = Calendar.current.startOfDay(for: customEndDate)
            daysToGoBack = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day! + 1
        default:
            daysToGoBack = 7
            startDate = calendar.date(byAdding: .day, value: -(daysToGoBack - 1), to: today)!
        }
        
        let filteredInvoices = invoices.filter { $0.creationDate >= startDate }
        
        var dailyProfit: [Date: Double] = [:]
        for invoice in filteredInvoices {
            let invoiceDay = calendar.startOfDay(for: invoice.creationDate)
            // SỬA LỖI: Cập nhật lại công thức tính lợi nhuận
            let profit = (invoice.totalAmount + invoice.discountAmount) - invoice.totalCost
            dailyProfit[invoiceDay, default: 0] += profit
        }
        
        return (0..<daysToGoBack).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
            return DailyProfit(date: date, profit: dailyProfit[date] ?? 0)
        }.sorted(by: { $0.date < $1.date })
    }
    
    private var totalProfit: Double {
        profitData.reduce(0) { $0 + $1.profit }
    }
    
    var body: some View {
        VStack {
            Picker("Chọn khoảng thời gian", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedTimeRange == .custom {
                DatePicker("Từ ngày", selection: $customStartDate, displayedComponents: .date)
                    .padding(.horizontal)
                DatePicker("Đến ngày", selection: $customEndDate, in: customStartDate..., displayedComponents: .date)
                    .padding(.horizontal)
            }
            
            ProfitReportContent(profitData: profitData, totalProfit: totalProfit)
            
            Spacer()
        }
        .navigationTitle("Báo cáo Lợi nhuận")
    }
}

private struct ProfitReportContentForPDF: View {
    let profitData: [DailyProfit]
    let totalProfit: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Báo Cáo Lợi Nhuận")
                .font(.title2.bold())
            Text("Tổng lợi nhuận: " + totalProfit.formattedAsCurrency())
                .font(.headline)
            
            Chart(profitData) { data in
                LineMark(
                    x: .value("Ngày", data.date, unit: .day),
                    y: .value("Lợi nhuận", data.profit)
                )
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Ngày", data.date, unit: .day),
                    y: .value("Lợi nhuận", data.profit)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.green.opacity(0.4), .green.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .frame(height: 300)
            .padding()
        }
        .padding()
    }
}

private struct ProfitReportContent: View {
    let profitData: [DailyProfit]
    let totalProfit: Double
    
    var body: some View {
        VStack {
            if profitData.isEmpty {
                ContentUnavailableView("Chưa có dữ liệu lợi nhuận", systemImage: "chart.bar.xaxis")
            } else {
                ScrollView {
                    Chart(profitData) { data in
                        LineMark(
                            x: .value("Ngày", data.date, unit: .day),
                            y: .value("Lợi nhuận", data.profit)
                        )
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Ngày", data.date, unit: .day),
                            y: .value("Lợi nhuận", data.profit)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.green.opacity(0.4), .green.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 7)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    }
                    .padding()
                    
                    HStack {
                        Text("Tổng lợi nhuận:")
                            .font(.headline)
                        Spacer()
                        Text(totalProfit.formattedAsCurrency())
                            .font(.title2.bold())
                            .foregroundColor(.green)
                    }
                    .padding()
                }
            }
        }
    }
}
