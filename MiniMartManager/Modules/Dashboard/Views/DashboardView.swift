// MiniMartManager/Modules/Dashboard/Views/DashboardView.swift
import SwiftUI
import SwiftData
import Charts

// Struct để biểu diễn dữ liệu doanh thu theo ngày cho biểu đồ
struct DailyRevenue: Identifiable {
    let id = UUID()
    let date: Date
    let revenue: Double
}

struct DashboardView: View {
    // MARK: - SwiftData Queries
    @Query private var invoices: [Invoice]
    @Query private var goodsReceipts: [GoodsReceipt]
    @Query private var allProducts: [Product]
    @Query(filter: #Predicate<Product> {
        $0.stockQuantity <= $0.minimumStockLevel && $0.minimumStockLevel > 0
    })
    private var lowStockProducts: [Product]

    // MARK: - State Properties
    @State private var selectedDate: Date?
    // SỬA LỖI: Sử dụng enum TimeRange từ file mới
    @State private var selectedTimeRange: TimeRange = .today

    // MARK: - Computed Properties
    
    private var filteredInvoices: [Invoice] {
        let calendar = Calendar.current
        var startDate: Date
        
        switch selectedTimeRange {
        case .today:
            startDate = calendar.startOfDay(for: .now)
        case .thisWeek:
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now))!
        case .thisMonth:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: .now))!
        case .thisYear:
            startDate = calendar.date(from: calendar.dateComponents([.year], from: .now))!
        case .last7Days: // THÊM LẠI để tương thích với biểu đồ
            startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: .now))!
        case .last30Days: // THÊM LẠI để tương thích với biểu đồ
            startDate = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: .now))!
        case .custom:
            // SỬA LỖI: Cần thêm state cho customStartDate và customEndDate
            startDate = .distantPast
        }
        
        return invoices.filter { $0.creationDate >= startDate }
    }
    
    private var totalRevenue: Double {
        filteredInvoices.reduce(0) { $0 + $1.totalAmount }
    }

    private var totalProfit: Double {
        filteredInvoices.reduce(0) { $0 + ($1.totalAmount - $1.totalCost) }
    }
    
    private var totalDebtReceivable: Double {
        invoices
            .filter { $0.paymentStatus != "PAID" }
            .reduce(0) { $0 + ($1.totalAmount - $1.amountPaid) }
    }
    
    private var totalInventoryValue: Double {
        allProducts.reduce(0) { $0 + ($1.costPrice * Double($1.stockQuantity)) }
    }
    
    private var totalDebtPayable: Double {
        goodsReceipts
            .filter { $0.paymentStatus != "PAID" }
            .reduce(0) { $0 + ($1.totalAmount - $1.amountPaid) }
    }

    private var revenueForSelectedDate: Double? {
        guard let selectedDate = selectedDate else { return nil }
        return invoices
            .filter { Calendar.current.isDate($0.creationDate, inSameDayAs: selectedDate) }
            .reduce(0) { $0 + $1.totalAmount }
    }
    
    private var last7DaysRevenueData: [DailyRevenue] {
        var dailyData: [Date: Double] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        
        for invoice in invoices {
            let invoiceDay = calendar.startOfDay(for: invoice.creationDate)
            if let daysAgo = calendar.dateComponents([.day], from: invoiceDay, to: today).day, daysAgo < 7 {
                dailyData[invoiceDay, default: 0] += invoice.totalAmount
            }
        }
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            return DailyRevenue(date: date, revenue: dailyData[date] ?? 0)
        }.sorted(by: { $0.date < $1.date })
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    lowStockWarningSection
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            KPIView(title: "Doanh thu", value: totalRevenue.formattedAsCurrency(), color: .blue, icon: "dollarsign.square.fill")
                            KPIView(title: "Lợi nhuận", value: totalProfit.formattedAsCurrency(), color: .green, icon: "chart.line.uptrend.xyaxis")
                            KPIView(title: "Công nợ phải thu", value: totalDebtReceivable.formattedAsCurrency(), color: .orange, icon: "arrow.down.left.circle.fill")
                            KPIView(title: "Công nợ phải trả", value: totalDebtPayable.formattedAsCurrency(), color: .red, icon: "arrow.up.right.circle.fill")
                            KPIView(title: "Giá trị tồn kho", value: totalInventoryValue.formattedAsCurrency(), color: .purple, icon: "archivebox.fill")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 10)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Doanh thu 7 ngày gần nhất")
                            .font(.headline)
                        
                        Picker("Khoảng thời gian", selection: $selectedTimeRange) {
                            Text("Hôm nay").tag(TimeRange.today)
                            Text("Tuần này").tag(TimeRange.thisWeek)
                            Text("Tháng này").tag(TimeRange.thisMonth)
                            Text("Năm nay").tag(TimeRange.thisYear)
                        }
                        .pickerStyle(.segmented)
                        
                        Chart(last7DaysRevenueData) { dataPoint in
                            BarMark(
                                x: .value("Ngày", dataPoint.date, unit: .day),
                                y: .value("Doanh thu", dataPoint.revenue)
                            )
                            .foregroundStyle(Color.accentColor.gradient)
                            .opacity(opacity(for: dataPoint.date))
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.weekday(.narrow))
                            }
                        }
                        .chartOverlay { proxy in
                            GeometryReader { geometry in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                guard let plotFrame = proxy.plotFrame else { return }
                                                let xPosition = value.location.x - geometry[plotFrame].origin.x
                                                if let date: Date = proxy.value(atX: xPosition),
                                                   let closestDate = last7DaysRevenueData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })?.date {
                                                    selectedDate = Calendar.current.startOfDay(for: closestDate)
                                                }
                                            }
                                            .onEnded { _ in selectedDate = nil }
                                    )
                            }
                        }
                        .frame(height: 250)
                        
                        if let selectedDate, let revenue = revenueForSelectedDate {
                            Text("Doanh thu ngày \(selectedDate.formatted(date: .abbreviated, time: .omitted)): \(revenue.formattedAsCurrency())")
                                .font(.subheadline).fontWeight(.bold).foregroundColor(.accentColor).padding(.top, 1)
                        }
                    }
                    .padding()
                    .background(.background)
                    .cornerRadius(12)
                    .shadow(radius: 3, x: 0, y: 2)
                    
                    reportsLink
                }
                .padding()
            }
            .navigationTitle("Tổng Quan")
            .background(Color(uiColor: .systemGroupedBackground))
            .onAppear(perform: checkForLowStockAndNotify)
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var lowStockWarningSection: some View {
        if !lowStockProducts.isEmpty {
            NavigationLink(destination: LowStockWarningView()) {
                HStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("Cảnh báo tồn kho")
                            .fontWeight(.bold)
                        Text("Có \(lowStockProducts.count) sản phẩm sắp hết hàng")
                            .font(.subheadline)
                    }
                    .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.background)
                .cornerRadius(12)
                .shadow(radius: 3, x: 0, y: 2)
            }
        }
    }
    
    private var reportsLink: some View {
        NavigationLink(destination: ReportsListView()) {
           Label("Xem thêm báo cáo chi tiết", systemImage: "doc.text.fill")
        }
        .buttonStyle(VividButtonStyle())
    }
    
    // MARK: - Methods
    private func checkForLowStockAndNotify() {
        if !lowStockProducts.isEmpty {
            NotificationManager.shared.scheduleLowStockNotification(lowStockProductCount: lowStockProducts.count)
        }
    }
    
    private func opacity(for date: Date) -> Double {
        if let selectedDate {
            return Calendar.current.isDate(date, inSameDayAs: selectedDate) ? 1.0 : 0.4
        }
        return 1.0
    }
}
// THÊM MỚI: KPIView với nhiều thuộc tính hơn để tái sử dụng
struct KPIView: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title.bold())
                .foregroundColor(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding()
        .frame(width: 170, height: 120) // Đặt kích thước cố định để các card đồng đều
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
