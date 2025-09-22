// MiniMartManager/Modules/Reports/Views/ReportsListView.swift
import SwiftUI

struct ReportsListView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Báo cáo Kinh doanh") {
                    NavigationLink(destination: SalesHistoryView()) {
                        Label("Lịch sử bán hàng", systemImage: "list.bullet.rectangle.portrait")
                    }
                    NavigationLink(destination: TopSellingProductsView()) {
                        Label("Sản phẩm bán chạy", systemImage: "star.fill")
                    }
                    NavigationLink(destination: CategorySalesReportView()) {
                        Label("Doanh số theo danh mục", systemImage: "square.stack.3d.up")
                    }
                    NavigationLink(destination: EmployeeSalesReportView()) {
                        Label("Doanh thu theo NV", systemImage: "person.2.fill")
                    }
                }
                
                Section("Báo cáo Tài chính") {
                    NavigationLink(destination: FinancialReportView()) {
                        Label("Tổng hợp Tài chính", systemImage: "doc.text.fill")
                    }
                    NavigationLink(destination: ProfitReportView()) {
                        Label("Lợi nhuận gộp", systemImage: "chart.bar.fill")
                    }
                    //NavigationLink(destination: FundLedgerView()) {
                    //    Label("Sổ quỹ Thu - Chi", systemImage: "creditcard.fill")
                    //}
                }
                
                Section("Báo cáo khác") {
                    NavigationLink(destination: InventoryReportView()) {
                        Label("Báo cáo Tồn kho", systemImage: "chart.pie.fill")
                    }
                    NavigationLink(destination: SupplierReceiptReportView()) {
                        Label("Nhập hàng từ NCC", systemImage: "truck.box.fill")
                    }
                    NavigationLink(destination: StockTransactionHistoryView()) {
                        Label("Lịch sử giao dịch tồn kho", systemImage: "shippingbox.fill")
                    }
                    NavigationLink(destination: ExchangeRateListView()) {
                        Label("Quản lý Tỷ giá", systemImage: "arrow.left.arrow.right.circle.fill")
                    }
                }
            }
            .navigationTitle("Báo Cáo")
        }
    }
}

#Preview {
    ReportsListView()
}
