//
//  StockTransactionHistoryView.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import SwiftUI
import SwiftData

struct StockTransactionHistoryView: View {
    @Query(sort: \StockTransaction.transactionDate, order: .reverse)
    private var transactions: [StockTransaction]
    
    var body: some View {
        List(transactions) { tx in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tx.product?.name ?? "N/A").font(.headline)
                    Text(tx.reason).font(.caption)
                    Text(tx.transactionDate.formatted(date: .numeric, time: .shortened))
                        .font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Text(String(format: "%+d", tx.quantityChange))
                    .font(.title2.bold())
                    .foregroundColor(tx.quantityChange > 0 ? .green : .red)
            }
        }
        .navigationTitle("Lịch Sử Kho")
    }
}
