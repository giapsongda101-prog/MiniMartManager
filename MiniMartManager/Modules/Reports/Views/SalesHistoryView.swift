// MiniMartManager/Modules/Reports/Views/SalesHistoryView.swift
import SwiftUI
import SwiftData

struct SalesHistoryView: View {
    @Query(sort: \Invoice.creationDate, order: .reverse) private var invoices: [Invoice]
    @State private var searchText: String = ""
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
    @State private var endDate: Date = .now

    @State private var pdfURLToShare: URL?
    @State private var showShareSheet = false
    
    private var filteredInvoices: [Invoice] {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: endDate).addingTimeInterval(24 * 60 * 60 - 1)
        
        let dateFilteredInvoices = invoices.filter { $0.creationDate >= startDate && $0.creationDate <= endOfDay }
        
        if searchText.isEmpty {
            return dateFilteredInvoices
        }
        return dateFilteredInvoices.filter { invoice in
            let customerName = invoice.customer?.name ?? "Khách lẻ"
            let creationDate = invoice.creationDate.formatted()
            
            return customerName.localizedCaseInsensitiveContains(searchText) ||
                   creationDate.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredInvoices) { invoice in
                NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(invoice.customer?.name ?? "Khách lẻ")
                                .font(.headline)
                            Text(invoice.creationDate.formatted(date: .numeric, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(invoice.totalAmount.formattedAsCurrency())
                            .font(.headline.bold())
                    }
                }
            }
            .navigationTitle("Lịch Sử Bán Hàng")
            .searchable(text: $searchText, prompt: "Tìm theo khách hàng, ngày...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        let reportContent = SalesHistoryContentForPDF(invoices: filteredInvoices)
                        self.pdfURLToShare = PDFRenderer.render(view: reportContent)
                        self.showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .safeAreaModifier {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Chọn khoảng thời gian")
                        .font(.headline)
                    DatePicker("Từ ngày", selection: $startDate, displayedComponents: .date)
                    DatePicker("Đến ngày", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURLToShare {
                ShareSheet(items: [url])
            }
        }
    }
}

private struct SalesHistoryContentForPDF: View {
    let invoices: [Invoice]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lịch Sử Bán Hàng")
                .font(.title2.bold())
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(invoices) { invoice in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(invoice.customer?.name ?? "Khách lẻ")
                                .font(.headline)
                            Text(invoice.creationDate.formatted(date: .numeric, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(invoice.totalAmount.formattedAsCurrency())
                            .font(.headline.bold())
                    }
                }
            }
        }
        .padding()
    }
}

struct InvoiceDetailView: View {
    let invoice: Invoice
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            InvoiceView(invoice: invoice)
        }
        .navigationTitle("Chi Tiết Hóa Đơn")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "printer.fill")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL = PDFRenderer.render(view: InvoiceView(invoice: invoice)) {
                ShareSheet(items: [pdfURL])
            }
        }
    }
}

extension View {
    func safeAreaModifier<T: View>(@ViewBuilder content: () -> T) -> some View {
        self.safeAreaInset(edge: .top) {
            content()
                .padding()
                .background(.bar)
                .shadow(radius: 1)
        }
    }
}
