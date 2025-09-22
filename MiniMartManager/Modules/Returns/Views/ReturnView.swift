//
//  ReturnView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData

struct ReturnView: View {
    @Query(sort: \Invoice.creationDate, order: .reverse) private var allInvoices: [Invoice]
    @State private var searchText = ""
    
    private var filteredInvoices: [Invoice] {
        if searchText.isEmpty {
            return allInvoices
        }
        return allInvoices.filter {
            // A simple search by invoice creation time (you can improve this)
            $0.creationDate.formatted().localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredInvoices) { invoice in
                NavigationLink(destination: ReturnFromInvoiceView(invoice: invoice)) {
                    VStack(alignment: .leading) {
                        Text("Ngày: \(invoice.creationDate.formatted(date: .numeric, time: .shortened))")
                        Text("Tổng tiền: \(invoice.totalAmount.formattedAsCurrency())")
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Tạo Phiếu Trả Hàng")
            .searchable(text: $searchText, prompt: "Tìm hóa đơn...")
        }
    }
}
